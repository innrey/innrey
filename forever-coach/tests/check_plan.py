"""Проверка ForeverCoach/Plan.lua: синтаксис Lua 5.1 и структура таблицы.

Запуск:  pip install lupa  &&  python tests/check_plan.py
Запускай после каждой правки Plan.lua: сломанный файл аддон просто не загрузит.
"""
import pathlib
import sys

from lupa.lua51 import LuaRuntime

PLAN = pathlib.Path(__file__).resolve().parent.parent / "ForeverCoach" / "Plan.lua"

CHECK = r"""
local P = ForeverCoachPlan
assert(type(P) == "table", "ForeverCoachPlan не таблица")
local function strmap(name, keytype)
  local t = P[name]
  if t == nil then return end
  assert(type(t) == "table", name .. " не таблица")
  for k, v in pairs(t) do
    assert(type(k) == keytype, name .. ": ключ " .. tostring(k) .. " должен быть " .. keytype)
    assert(type(v) == "string", name .. "[" .. tostring(k) .. "]: значение должно быть строкой")
  end
end
strmap("skip", "number"); strmap("optional", "number"); strmap("key", "number")
strmap("skipTitle", "string"); strmap("optionalTitle", "string"); strmap("keyTitle", "string")
strmap("milestones", "number")
if P.now ~= nil then
  assert(type(P.now) == "table", "now должен быть таблицей или nil")
  assert(type(P.now.steps) == "table" and #P.now.steps > 0, "now.steps: нужен список шагов")
  for i, s in ipairs(P.now.steps) do assert(type(s) == "string", "now.steps[" .. i .. "] не строка") end
  assert(P.now.level == nil or type(P.now.level) == "number", "now.level должен быть числом")
end
if P.guide ~= nil then
  assert(type(P.guide) == "table", "guide должен быть таблицей или nil")
  assert(type(P.guide.steps) == "table" and #P.guide.steps > 0, "guide.steps: нужен список шагов")
  for _, k in ipairs({ "char", "race", "class" }) do
    assert(P.guide[k] == nil or type(P.guide[k]) == "string", "guide." .. k .. " должно быть строкой")
  end
  local CONDS = { "accept", "complete", "turnin", "level", "zone", "learn", "bind" }
  for i, st in ipairs(P.guide.steps) do
    local w = "guide.steps[" .. i .. "]"
    assert(type(st) == "table", w .. " не таблица")
    assert(type(st.text) == "string" and st.text ~= "", w .. ".text: нужен текст")
    for _, k in ipairs({ "accept", "complete", "turnin", "level", "zone", "learn", "npc", "object", "map", "x", "y",
      "radius", "cost" }) do
      assert(st[k] == nil or type(st[k]) == "number", w .. "." .. k .. " должно быть числом")
    end
    assert(st.bind == nil or st.bind == true, w .. ".bind: только true")
    assert(st.note == nil or type(st.note) == "string", w .. ".note: строка")
    assert((st.map == nil) == (st.x == nil) and (st.x == nil) == (st.y == nil), w .. ": map, x, y задаются вместе")
    if st.x then assert(st.x >= 0 and st.x <= 100 and st.y >= 0 and st.y <= 100, w .. ": x, y от 0 до 100") end
    local conds = 0
    for _, k in ipairs(CONDS) do if st[k] then conds = conds + 1 end end
    assert(conds <= 1, w .. ": больше одного условия (" .. table.concat(CONDS, "/") .. ")")
  end
end
assert(type(P.route) == "table" and #P.route > 0, "route пустой")
local prevMax
for i, r in ipairs(P.route) do
  assert(type(r.min) == "number" and type(r.max) == "number" and r.min < r.max, "route[" .. i .. "]: min/max")
  assert(type(r.text) == "string", "route[" .. i .. "]: text")
  if prevMax then assert(r.min == prevMax, "route[" .. i .. "]: разрыв или наложение диапазонов") end
  prevMax = r.max
end
return #P.route
"""


def main() -> int:
    lua = LuaRuntime(unpack_returned_tuples=True)
    try:
        lua.execute(PLAN.read_text(encoding="utf-8"))
        n = lua.execute(CHECK)
    except Exception as exc:  # noqa: BLE001
        print("Plan.lua СЛОМАН:", exc)
        return 1
    print(f"Plan.lua в порядке: {n} участков маршрута.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
