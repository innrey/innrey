"""Собирает гид из plan/guide.txt в Plan.lua (блок между GUIDE-BEGIN и GUIDE-END).

Названия квестов и NPC проверяются по базе QuestieDB (tools/questie_db.py): опечатка,
неоднозначное название или квест не для ночного эльфа-друида - ошибка сборки.

    python tools/build_guide.py            # собрать и записать в ForeverCoach/Plan.lua
    python tools/build_guide.py --check    # только проверить

Формат plan/guide.txt - один шаг на строку:

    @guide race=NightElf class=DRUID at=02.11 12:00     # заголовок (один раз)
    # комментарий
    accept "The Balance of Nature"                      # условие и квест (название или ID)
    complete 456 | Убей 7 саблезубов и 4 кабана         # свой текст после |
    turnin 456
    level 6 | Добей 6 уровень
    zone 1453 @1439 32.4,43.7 | Корабль в Штормград     # прибыть в зону; стрелка к причалу
    learn 18960 npc="Loganaar" cost=4s | Выучи Телепорт: Лунная поляна || заметка
    bind npc="Innkeeper Keldamyr" | Камень в Доланааре
    goto @1438 56.1,60.0 radius=20 | Дойти до пещеры
    manual | Купи 4 сумки                                # только /fc next

Опции шага: npc="Имя"|ID, object=ID, @map x,y, radius=N, cost=1g2s3c.
"""
import argparse
import pathlib
import re
import shlex
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from questie_db import QuestieDB, find_db  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
SPEC = ROOT / "plan" / "guide.txt"
PLAN = ROOT / "ForeverCoach" / "Plan.lua"
BEGIN, END = "-- GUIDE-BEGIN", "-- GUIDE-END"
NIGHTELF, DRUID = 8, 1024
QUEST_CONDS = {"accept": "Возьми", "complete": "Выполни", "turnin": "Сдай"}


class SpecError(Exception):
    pass


def money(s: str) -> int:
    m = re.fullmatch(r"(?:(\d+)g)?(?:(\d+)s)?(?:(\d+)c)?", s)
    if not s or not m:
        raise SpecError(f"cost: ожидается вида 1g2s3c, а не {s!r}")
    g, sv, c = (int(x or 0) for x in m.groups())
    return g * 10000 + sv * 100 + c


def lua_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


class Builder:
    def __init__(self, db: QuestieDB):
        self.db = db
        self.quest_steps: list[tuple[int, str, int]] = []  # (строка, условие, квест) - для проверки цепочек

    def check_chains(self) -> list[str]:
        """Квест берётся после сдачи предыдущего в цепочке; выполнить и сдать можно только взятый."""
        first: dict[tuple[str, int], int] = {}
        for i, (_, cond, qid) in enumerate(self.quest_steps):
            first.setdefault((cond, qid), i)
        errors = []
        for (cond, qid), i in first.items():
            line = self.quest_steps[i][0]
            if cond == "accept":
                pre = self.db.get(self.db.quest_db, qid, "preQuestSingle") or []
                for p in pre if isinstance(pre, list) else [pre]:
                    t = first.get(("turnin", p))
                    if t is not None and t > i:
                        errors.append(f"строка {line}: accept {qid} раньше, чем сдан предыдущий квест {p} "
                                      f"(строка {self.quest_steps[t][0]})")
            elif ("accept", qid) not in first:
                errors.append(f"строка {line}: {cond} {qid}, но в гиде нет accept {qid}")
            elif first[("accept", qid)] > i:
                errors.append(f"строка {line}: {cond} {qid} раньше accept")
        return errors

    def quest(self, ref: str) -> tuple[int, str]:
        g = lambda qid, f: self.db.get(self.db.quest_db, qid, f)  # noqa: E731
        if ref.isdigit():
            qid = int(ref)
            name = g(qid, "name")
            if name is None:
                raise SpecError(f"квеста {qid} нет в базе")
            ids = [qid]
        else:
            ids = [i for i in self.db.find("quest", ref) if (self.db.names("quest")[i] or "").lower() == ref.lower()]
            if not ids:
                raise SpecError(f"квест {ref!r} не найден (проверь название)")
        ok = []
        for qid in ids:
            races, classes = g(qid, "requiredRaces") or 0, g(qid, "requiredClasses") or 0
            if (not races or races & NIGHTELF) and (not classes or classes & DRUID):
                ok.append(qid)
        if not ok:
            raise SpecError(f"квест {ref!r} ({ids}) недоступен ночному эльфу-друиду")
        if len(ok) > 1:
            desc = ", ".join(f"{i} (ур.{g(i, 'questLevel')})" for i in ok)
            raise SpecError(f"квест {ref!r} неоднозначен: {desc} - укажи ID")
        return ok[0], g(ok[0], "name")

    def npc(self, ref: str) -> int:
        if ref.isdigit():
            if self.db.get(self.db.npc_db, int(ref), "name") is None:
                raise SpecError(f"NPC {ref} нет в базе")
            return int(ref)
        ids = [i for i in self.db.find("npc", ref) if (self.db.names("npc")[i] or "").lower() == ref.lower()]
        ids = [i for i in ids if self.db.get(self.db.npc_db, i, "spawns")]
        if len(ids) != 1:
            raise SpecError(f"NPC {ref!r}: {'не найден' if not ids else 'неоднозначен: ' + str(ids)}")
        return ids[0]

    def step(self, line: str, n: int = 0) -> str:
        text = note = None
        if "||" in line:
            line, note = (p.strip() for p in line.split("||", 1))
        if "|" in line:
            line, text = (p.strip() for p in line.split("|", 1))
        point = None
        m = re.search(r"@(\d+)\s+([\d.]+)\s*,\s*([\d.]+)", line)
        if m:
            point = (int(m.group(1)), float(m.group(2)), float(m.group(3)))
            line = line[:m.start()] + line[m.end():]
        words = shlex.split(line)
        cond, args = words[0], words[1:]
        fields: list[str] = []

        if cond in QUEST_CONDS:
            if not args:
                raise SpecError(f"{cond}: нужен квест")
            qid, name = self.quest(args.pop(0))
            fields.append(f"{cond} = {qid}")
            self.quest_steps.append((n, cond, qid))
            text = text or f"{QUEST_CONDS[cond]} {name}"
        elif cond in ("level", "zone", "learn"):
            if not args or not args[0].isdigit():
                raise SpecError(f"{cond}: нужно число")
            fields.append(f"{cond} = {int(args.pop(0))}")
        elif cond == "bind":
            fields.append("bind = true")
        elif cond not in ("goto", "manual"):
            raise SpecError(f"неизвестное условие {cond!r}")
        if cond == "goto" and not point:
            raise SpecError("goto: нужна точка @map x,y")
        if not text:
            raise SpecError(f"{cond}: нужен текст после |")

        for opt in args:
            key, _, value = opt.partition("=")
            if key == "npc":
                fields.append(f"npc = {self.npc(value)}")
            elif key == "object" and value.isdigit():
                fields.append(f"object = {int(value)}")
            elif key == "radius" and value.isdigit():
                fields.append(f"radius = {int(value)}")
            elif key == "cost":
                fields.append(f"cost = {money(value)}")
            else:
                raise SpecError(f"непонятная опция {opt!r}")
        if point:
            fields.append(f"map = {point[0]}, x = {point[1]}, y = {point[2]}")
        if note:
            fields.append(f"note = {lua_str(note)}")
        return "    { text = " + lua_str(text) + (", " + ", ".join(fields) if fields else "") + " },"

    def build(self, spec: str) -> tuple[str, int]:
        header, steps, errors = None, [], []
        for n, raw in enumerate(spec.splitlines(), 1):
            line = raw.split(" #", 1)[0].strip() if not raw.strip().startswith("#") else ""
            if not line:
                continue
            if line.startswith("@guide"):
                header = dict(re.findall(r"(\w+)=([^=]+?)(?=\s+\w+=|$)", line[len("@guide"):].strip()))
                continue
            try:
                steps.append(self.step(line, n))
            except SpecError as e:
                errors.append(f"строка {n}: {e}\n    {raw.strip()}")
        errors += self.check_chains()
        if errors:
            raise SpecError("\n".join(errors))
        if not header:
            raise SpecError("нет строки @guide")
        head = ", ".join(f"{k} = {lua_str(v.strip())}" for k, v in header.items())
        lua = f"  guide = {{ {head}, steps = {{\n" + "\n".join(steps) + "\n  } },"
        return lua, len(steps)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="только проверить, не записывать Plan.lua")
    ap.add_argument("--db", help="папка QuestieDB")
    ap.add_argument("--flavor", default="Forever")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    builder = Builder(QuestieDB(find_db(args.db), args.flavor))
    try:
        lua, n = builder.build(SPEC.read_text(encoding="utf-8"))
    except SpecError as e:
        print("Ошибки в plan/guide.txt:\n" + str(e))
        return 1
    if args.check:
        print(f"plan/guide.txt в порядке: {n} шагов.")
        return 0
    plan = PLAN.read_text(encoding="utf-8")
    start, end = plan.find(BEGIN), plan.find(END)
    if start < 0 or end < start:
        print(f"В Plan.lua нет меток {BEGIN} / {END}")
        return 1
    start = plan.index("\n", start) + 1
    PLAN.write_text(plan[:start] + lua + "\n  " + plan[end:], encoding="utf-8")
    print(f"Гид записан в Plan.lua: {n} шагов. Проверь: python tests/check_plan.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
