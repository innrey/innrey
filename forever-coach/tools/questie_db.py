"""Поиск квестов и NPC в базе QuestieDB без игры (для Claude, когда он пишет гид).

QuestieDB хранит базу в метаданных .toc (CBOR в Base64). Скрипт загружает код QuestieDB
в Lua 5.1 (lupa) с заглушками нескольких функций WoW, а данные отдаёт из .toc.

    pip install lupa cbor2
    python tools/questie_db.py quest "The Balance of Nature"      # по названию или ID
    python tools/questie_db.py npc "Conservator Ilthalaine"
    python tools/questie_db.py zone-quests 141 --min 1 --max 12   # квесты зоны (areaId)

Папку QuestieDB ищет в клиентах WoW (или --db путь), вариант базы: --flavor Forever|Vanilla.
"""
import argparse
import base64
import pathlib
import sys
import zlib

import cbor2
from lupa.lua51 import LuaRuntime

WOW = pathlib.Path(r"C:\Program Files (x86)\World of Warcraft")
CLIENTS = ["_forever_", "_classic_era_", "_classic_beta_"]

RACES = {1: "Human", 2: "Orc", 4: "Dwarf", 8: "NightElf", 16: "Undead", 32: "Tauren", 64: "Gnome", 128: "Troll"}

WOW_STUBS = r"""
UnitFactionGroup = function() return "Alliance" end
UnitClassBase = function() return "DRUID", 11 end
UnitClass = function() return "Druid", "DRUID", 11 end
UnitRace = function() return "Night Elf", "NightElf", 4 end
UnitLevel = function() return 1 end
GetLocale = function() return "enUS" end
GetBuildInfo = function() return "1.60.1", "70707", "", 16001 end
C_Seasons = { GetActiveSeason = function() return 0 end }
local function noop() end
CreateFrame = function() return setmetatable({}, { __index = function() return noop end }) end
tinsert, tremove, wipe = table.insert, table.remove, function(t) for k in pairs(t) do t[k] = nil end return t end
strsplit = function(sep, s)
  local out = {}
  for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = part end
  return unpack(out)
end
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
format, floor, ceil, max, min, abs = string.format, math.floor, math.ceil, math.max, math.min, math.abs
"""


def find_db(explicit: str | None) -> pathlib.Path:
    if explicit:
        return pathlib.Path(explicit)
    for client in CLIENTS:
        p = WOW / client / "Interface" / "AddOns" / "QuestieDB"
        if p.is_dir():
            return p
    sys.exit("QuestieDB не найден: укажи --db <папка QuestieDB>")


class QuestieDB:
    def __init__(self, db_dir: pathlib.Path, flavor: str):
        toc = db_dir / f"QuestieDB_{flavor}.toc"
        self.meta: dict[str, str] = {}
        files: list[str] = []
        for line in toc.read_text(encoding="utf-8-sig").splitlines():
            if line.startswith("## "):
                key, _, value = line[3:].partition(":")
                self.meta[key.strip()] = value.strip()
            elif line and not line.startswith("#"):
                files.append(line.strip())

        self.lua = lua = LuaRuntime(encoding=None, unpack_returned_tuples=True)
        g = lua.globals()
        lua.execute(WOW_STUBS.encode())
        g.C_EncodingUtil = lua.table_from({
            b"DecodeBase64": lambda s: base64.b64decode(s + b"=" * (-len(s) % 4)),
            b"DecompressString": self._decompress,
            b"DeserializeCBOR": lambda data: self._to_lua(cbor2.loads(data)),
        })
        get_meta = lambda _addon, key: self._meta(key)  # noqa: E731
        g.C_AddOns = lua.table_from({b"GetAddOnMetadata": get_meta})
        g.GetAddOnMetadata = get_meta

        run = lua.eval(b"function(code, name, ns) local f = assert(loadstring(code, name)); return f('QuestieDB', ns) end")
        self.ns = lua.table()
        for rel in files:
            code = (db_dir / rel.replace("\\", "/")).read_bytes()
            if code.startswith(b"\xef\xbb\xbf"):
                code = code[3:]
            run(code, rel.encode(), self.ns)
        self.quest_db = g[b"QuestDB"]
        self.npc_db = g[b"NpcDB"]
        self.object_db = g[b"ObjectDB"]
        self._names: dict[str, dict[int, str]] = {}

        # areaId (зоны Questie) -> uiMapID (карты, как в снимке и в guide): строки "return {...}"
        zone_private = self.ns[b"Support"].Get(b"ZoneDB")[b"private"]
        self.area_to_map: dict[int, int] = {}
        for key in (b"areaIdToUiMapId", b"areaIdToUiMapIdOverride"):
            table = lua.execute(zone_private[key])
            self.area_to_map.update(self._py(table) if table is not None else {})

    def _meta(self, key):
        value = self.meta.get(key.decode() if isinstance(key, bytes) else key)
        return value.encode() if value is not None else None

    @staticmethod
    def _decompress(data, _method=None):
        for wbits in (zlib.MAX_WBITS, -zlib.MAX_WBITS, zlib.MAX_WBITS | 16):
            try:
                return zlib.decompress(data, wbits)
            except zlib.error:
                pass
        raise ValueError("не удалось распаковать данные QuestieDB")

    def _to_lua(self, v):
        if isinstance(v, str):
            return v.encode()
        if isinstance(v, list):
            t = self.lua.table()
            for i, x in enumerate(v, 1):
                t[i] = self._to_lua(x)
            return t
        if isinstance(v, dict):
            t = self.lua.table()
            for k, x in v.items():
                t[self._to_lua(k)] = self._to_lua(x)
            return t
        return v

    # --- чтение -------------------------------------------------------------------------
    def _py(self, v):
        if isinstance(v, bytes):
            return v.decode("utf-8", "replace")
        if v is not None and type(v).__name__ == "_LuaTable":
            keys = list(v.keys())
            if keys and all(isinstance(k, int) for k in keys) and sorted(keys) == list(range(1, len(keys) + 1)):
                return [self._py(v[k]) for k in sorted(keys)]
            return {self._py(k): self._py(v[k]) for k in keys}
        return v

    def get(self, db, eid: int, field: str):
        return self._py(db.Get(eid, field.encode()))

    def all_ids(self, db) -> list[int]:
        return sorted(self._py(db.GetAllIds()) or [])

    def names(self, kind: str) -> dict[int, str]:
        if kind not in self._names:
            db = self.quest_db if kind == "quest" else self.npc_db
            self._names[kind] = {i: self.get(db, i, "name") or "" for i in self.all_ids(db)}
        return self._names[kind]

    def find(self, kind: str, query: str) -> list[int]:
        if query.isdigit():
            return [int(query)]
        q = query.lower()
        names = self.names(kind)
        exact = [i for i, n in names.items() if n.lower() == q]
        return exact or [i for i, n in names.items() if q in n.lower()][:25]


def fmt_spawns(db: "QuestieDB", spawns) -> str:
    """Места в формате guide: map <uiMapID> x,y (до трёх точек на зону)."""
    if not spawns:
        return "-"
    if isinstance(spawns, list):  # зоны подряд с 1 - lupa отдаёт список
        spawns = dict(enumerate(spawns, 1))
    parts = []
    for area, coords in spawns.items():
        pts = ", ".join(f"{c[0]:.1f},{c[1]:.1f}" for c in (coords or [])[:3] if c and c[0] >= 0)
        more = f" (+{len(coords) - 3})" if coords and len(coords) > 3 else ""
        parts.append(f"map {db.area_to_map.get(area, '?')} (area {area}): {pts or 'подземелье'}{more}")
    return "; ".join(parts)


def races(mask) -> str:
    if not mask:
        return "все"
    return ",".join(n for bit, n in RACES.items() if mask & bit) or str(mask)


def who(db: QuestieDB, refs) -> str:
    if not refs:
        return "-"
    if isinstance(refs, dict):  # разреженная таблица: только объекты или предметы
        refs = [refs.get(1), refs.get(2), refs.get(3)]
    out = []
    for npc in (refs[0] if len(refs) > 0 else None) or []:
        out.append(f"NPC {npc} {db.get(db.npc_db, npc, 'name')} [{fmt_spawns(db, db.get(db.npc_db, npc, 'spawns'))}]")
    for obj in (refs[1] if len(refs) > 1 else None) or []:
        out.append(f"объект {obj} {db.get(db.object_db, obj, 'name')} [{fmt_spawns(db, db.get(db.object_db, obj, 'spawns'))}]")
    for item in (refs[2] if len(refs) > 2 else None) or []:
        out.append(f"предмет {item}")
    return "; ".join(out) or "-"


def show_quest(db: QuestieDB, qid: int) -> None:
    g = lambda f: db.get(db.quest_db, qid, f)  # noqa: E731
    name = g("name")
    if name is None:
        print(f"квест {qid}: нет в базе")
        return
    print(f"квест {qid}: {name} | ур. {g('questLevel')}, взять с {g('requiredLevel')} | расы: {races(g('requiredRaces'))}"
          f" | зона/сорт {g('zoneOrSort')}")
    print(f"  даёт: {who(db, g('startedBy'))}")
    print(f"  принимает: {who(db, g('finishedBy'))}")
    obj = g("objectives") or []
    if isinstance(obj, dict):
        obj = [obj.get(i) for i in range(1, 7)]
    for kind, label, edb in ((0, "убить", db.npc_db), (1, "объект", db.object_db), (2, "предмет", None)):
        for o in (obj[kind] if len(obj) > kind and obj[kind] else []):
            oid = o[1] if isinstance(o, dict) else o[0]
            if edb is not None:
                print(f"  цель ({label}) {oid} {db.get(edb, oid, 'name')}: {fmt_spawns(db, db.get(edb, oid, 'spawns'))}")
            else:
                print(f"  цель ({label}) {oid}")
    for f in ("preQuestSingle", "preQuestGroup", "nextQuestInChain", "exclusiveTo", "breadcrumbForQuestId"):
        v = g(f)
        if v:
            print(f"  {f}: {v}")


def show_npc(db: QuestieDB, nid: int) -> None:
    g = lambda f: db.get(db.npc_db, nid, f)  # noqa: E731
    name = g("name")
    if name is None:
        print(f"NPC {nid}: нет в базе")
        return
    sub = g("subName")
    print(f"NPC {nid}: {name}{' <' + sub + '>' if sub else ''} | ур. {g('minLevel')}-{g('maxLevel')} | зона {g('zoneID')}")
    print(f"  где: {fmt_spawns(db, g('spawns'))}")
    starts, ends = g("questStarts"), g("questEnds")
    if starts:
        print(f"  даёт квесты: {starts}")
    if ends:
        print(f"  принимает: {ends}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("kind", choices=["quest", "npc", "zone-quests"])
    ap.add_argument("query", help="название (часть названия), ID или areaId для zone-quests")
    ap.add_argument("--db", help="папка QuestieDB")
    ap.add_argument("--flavor", default="Forever", help="Forever (по умолчанию) или Vanilla")
    ap.add_argument("--min", type=int, default=0)
    ap.add_argument("--max", type=int, default=100)
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    db = QuestieDB(find_db(args.db), args.flavor)
    if args.kind == "zone-quests":
        area = int(args.query)
        for qid, name in db.names("quest").items():
            if db.get(db.quest_db, qid, "zoneOrSort") != area:
                continue
            lvl = db.get(db.quest_db, qid, "questLevel") or 0
            mask = db.get(db.quest_db, qid, "requiredRaces")
            if args.min <= lvl <= args.max and (not mask or mask & 8):
                print(f"{qid}\tур.{lvl}\tвзять с {db.get(db.quest_db, qid, 'requiredLevel')}\t{name}")
        return 0
    ids = db.find(args.kind, args.query)
    if not ids:
        print("не найдено")
        return 1
    for i in ids:
        (show_quest if args.kind == "quest" else show_npc)(db, i)
    return 0


if __name__ == "__main__":
    sys.exit(main())
