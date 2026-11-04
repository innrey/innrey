"""Собирает метки квестов (skip / optional / key) в Plan.lua (блок между TAGS-BEGIN и TAGS-END).

Берёт все квесты зон маршрута (plan/tags.txt, строки zone) из базы QuestieDB, убирает квесты
из гида (plan/guide.txt) и каждому оставшемуся ставит [SKIP] с причиной: подземелье, элита,
профессия, повторяемый, высокий уровень, зона проездом или «не по маршруту». Свои причины,
[?] и [!] - строками skip / opt / key в plan/tags.txt.

    python tools/build_tags.py            # собрать и записать в ForeverCoach/Plan.lua
    python tools/build_tags.py --check    # только показать сводку
"""
import argparse
import collections
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from build_guide import PLAN, SPEC, Builder, SpecError, lua_str  # noqa: E402
from questie_db import QuestieDB, find_db  # noqa: E402

TAGS = PLAN.parent.parent / "plan" / "tags.txt"
BEGIN, END = "-- TAGS-BEGIN", "-- TAGS-END"
NIGHTELF, DRUID = 8, 1024
ELITE_RANKS = {1, 2, 3}  # элита, редкая элита, босс
BATTLEGROUNDS = {"Warsong Gulch", "Arathi Basin", "Alterac Valley"}
HOLIDAY_LEVEL = 55
SKILLS = {185: "кулинария", 129: "первая помощь", 356: "рыбалка", 182: "травничество", 186: "горное дело",
          393: "снятие шкур", 164: "кузнечное дело", 165: "кожевничество", 171: "алхимия", 197: "портняжное дело",
          202: "инженерное дело", 333: "наложение чар"}


def parse_tags(text: str):
    zones, manual = {}, {}
    for n, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        body, _, why = (p.strip() for p in line.partition("|"))
        words = body.split()
        if words[0] == "zone":
            m = re.fullmatch(r"(\d+)-(\d+)", words[3])
            if len(words) != 4 or words[2] not in ("main", "pass") or not m:
                raise SpecError(f"строка {n}: zone <uiMapID> main|pass <мин>-<макс> | Название")
            zones[int(words[1])] = (words[2], int(m.group(1)), int(m.group(2)), why)
        elif words[0] in ("skip", "opt", "key") and len(words) == 2 and words[1].isdigit() and why:
            manual[int(words[1])] = (words[0], why)
        else:
            raise SpecError(f"строка {n}: непонятно - {raw.strip()}")
    return zones, manual


class Tagger:
    def __init__(self, db: QuestieDB):
        self.db = db
        zp = db.ns[b"Support"].Get(b"ZoneDB")[b"private"]
        self.dungeons = {}
        for area, info in (db._py(zp[b"dungeons"]) or {}).items():
            name = info[0] if isinstance(info, list) else info.get(1)
            self.dungeons[area] = name or ""

    def q(self, qid, field):
        return self.db.get(self.db.quest_db, qid, field)

    def maps_of(self, entity_db, ids):
        out = set()
        for eid in ids or []:
            spawns = self.db.get(entity_db, eid, "spawns") or {}
            if isinstance(spawns, list):
                spawns = dict(enumerate(spawns, 1))
            for area, coords in spawns.items():
                if coords and any(c and c[0] >= 0 for c in coords):
                    out.add(self.db.area_to_map.get(area))
        return out

    def starter_maps(self, qid):
        refs = self.q(qid, "startedBy") or []
        if isinstance(refs, dict):
            refs = [refs.get(1), refs.get(2), refs.get(3)]
        maps = self.maps_of(self.db.npc_db, refs[0] if len(refs) > 0 else None)
        maps |= self.maps_of(self.db.object_db, refs[1] if len(refs) > 1 else None)
        item_only = not maps and len(refs) > 2 and bool(refs[2])
        zone = self.q(qid, "zoneOrSort") or 0
        if not maps and zone > 0:
            maps.add(self.db.area_to_map.get(zone))
        return maps, item_only

    def elite_target(self, qid):
        obj = self.q(qid, "objectives") or []
        if isinstance(obj, dict):
            obj = [obj.get(1)]
        for c in (obj[0] if obj and obj[0] else []):
            cid = c.get(1) if isinstance(c, dict) else c[0]
            if (self.db.get(self.db.npc_db, cid, "rank") or 0) in ELITE_RANKS:
                return self.db.get(self.db.npc_db, cid, "name")
        return None

    def reason(self, qid, kind, zmax):
        name = self.q(qid, "name")
        skill = self.q(qid, "requiredSkill")
        if skill:
            return f"{name}: профессия ({SKILLS.get(skill[0], 'навык ' + str(skill[0]))})"
        zone = self.q(qid, "zoneOrSort") or 0
        if self.dungeons.get(zone) in BATTLEGROUNDS:
            return f"{name}: поле боя (PvP) - не для прокачки"
        if zone in self.dungeons:
            return f"{name}: квест подземелья - только с группой"
        elite = self.elite_target(qid)
        if elite:
            return f"{name}: элита ({elite}) - нужна группа"
        if (self.q(qid, "specialFlags") or 0) & 1:
            return f"{name}: повторяемый - не нужен"
        if kind == "pass":
            return f"{name}: зона проездом - не по маршруту"
        if (self.q(qid, "questLevel") or 0) > zmax:
            return f"{name}: {self.q(qid, 'questLevel')} ур. - из зоны уйдёшь раньше"
        return f"{name}: не по маршруту - мало опыта за время или крюк"

    def build(self, zones, manual, guide_ids):
        tags = {}
        stats = collections.Counter()
        for qid in self.db.names("quest"):
            if qid in guide_ids or qid in manual:
                continue
            races, classes = self.q(qid, "requiredRaces") or 0, self.q(qid, "requiredClasses") or 0
            if (races and not races & NIGHTELF) or (classes and not classes & DRUID):
                continue
            maps, item_only = self.starter_maps(qid)
            zone = next((zones[m] + (m,) for m in maps if m in zones and zones[m][0] == "main"), None) \
                or next((zones[m] + (m,) for m in maps if m in zones), None)
            if not zone:
                continue
            kind, _zmin, zmax, zname, _m = zone
            if (self.q(qid, "requiredLevel") or 0) > zmax:
                continue  # там его ещё не взять
            if (self.q(qid, "questLevel") or 0) >= HOLIDAY_LEVEL:
                continue  # праздничные и события 60 уровня - на прокачке не встретишь
            why = self.reason(qid, kind, zmax)
            if item_only and kind == "main" and "не по маршруту" in why:
                why = f"{self.q(qid, 'name')}: начинается с выпавшего предмета - не по маршруту"
            tags[qid] = ("skip", why)
            stats[zname] += 1
        for qid, (tag, why) in manual.items():
            if qid in guide_ids and tag == "skip":
                raise SpecError(f"квест {qid} в гиде, а в tags.txt помечен skip")
            if self.q(qid, "name") is None:
                raise SpecError(f"квеста {qid} нет в базе")
            tags[qid] = (tag, why)
        return tags, stats


def to_lua(tags) -> str:
    parts = []
    for tag, field, comment in (("skip", "skip", "брось"), ("opt", "optional", "по желанию"), ("key", "key", "важный")):
        rows = [f"    [{qid}] = {lua_str(why)}," for qid, (t, why) in sorted(tags.items()) if t == tag]
        parts.append(f"  {field} = {{ -- {comment}: {len(rows)}\n" + "\n".join(rows) + "\n  },")
    return "\n".join(parts)


def update_plan(db: QuestieDB, builder: Builder, write: bool = True) -> str:
    """Пересчитать метки по уже собранному гиду (builder.build вызван) и записать в Plan.lua."""
    zones, manual = parse_tags(TAGS.read_text(encoding="utf-8"))
    tags, stats = Tagger(db).build(zones, manual, {qid for _, _, qid in builder.quest_steps})
    count = collections.Counter(t for t, _ in tags.values())
    report = (f"Метки: skip {count['skip']}, по желанию {count['opt']}, важных {count['key']}\n"
              "Автоматических skip по зонам: " + ", ".join(f"{z} {n}" for z, n in stats.most_common()))
    if write:
        plan = PLAN.read_text(encoding="utf-8")
        start, end = plan.find(BEGIN), plan.find(END)
        if start < 0 or end < start:
            raise SpecError(f"В Plan.lua нет меток {BEGIN} / {END}")
        start = plan.index("\n", start) + 1
        PLAN.write_text(plan[:start] + to_lua(tags) + "\n  " + plan[end:], encoding="utf-8")
    return report


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="только сводка, не записывать Plan.lua")
    ap.add_argument("--db", help="папка QuestieDB")
    ap.add_argument("--flavor", default="Forever")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    db = QuestieDB(find_db(args.db), args.flavor)
    builder = Builder(db)
    try:
        builder.build(SPEC.read_text(encoding="utf-8"))
        print(update_plan(db, builder, write=not args.check))
    except SpecError as e:
        print("Ошибка:\n" + str(e))
        return 1
    if not args.check:
        print("Записано в Plan.lua. Проверь: python tests/check_plan.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
