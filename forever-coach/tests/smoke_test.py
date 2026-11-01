"""Прогон аддона ForeverCoach на заглушках WoW API (Lua 5.1 через lupa).

Запуск:  pip install lupa  &&  python tests/smoke_test.py
Проверяет три сценария: старый API Classic, новый C_* API и сломанный Plan.lua.
"""
import pathlib
import sys

from lupa.lua51 import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parent.parent
ADDON = ROOT / "ForeverCoach"
MOCK = ROOT / "tests" / "wow_mock.lua"

SCENARIO = r"""
local ns = {}
local function load(name)
  local chunk = assert(loadfile(ADDON_DIR .. name))
  chunk("ForeverCoach", ns)
end
if LOAD_PLAN then load("Plan.lua") end
load("Core.lua")
load("Guide.lua")
load("UI.lua")
load("Debug.lua")

MOCK.Fire("ADDON_LOADED", "ForeverCoach")
MOCK.Fire("PLAYER_LOGIN")
MOCK.Flush()

local char = ForeverCoachDB.chars["Лунолист-Forever"]
assert(char and char.snap and char.text, "нет снимка после входа")
local s = char.snap
assert(s.level == 9 and s.class == "DRUID" and s.race == "NightElf", "персонаж")
assert(s.bagFree == 2 and s.bagTotal == 16, "сумки: " .. s.bagFree .. "/" .. s.bagTotal)
assert(s.junk == 3 and s.junkValue == 150, "серое: " .. s.junk .. " " .. s.junkValue)
assert(s.hsCD == 0 and s.hsBind == "Auberdine", "камень")
assert(s.tpCD == 0, "телепорт")
assert(s.talents == 1 and s.durMin == 20 and s.forms == 1, "таланты/прочность/облики")
assert(s.x == 36.5 and s.y == 45.2, "координаты " .. tostring(s.x) .. "," .. tostring(s.y))
assert(#s.quests == 3 and s.questsReady == 0 and s.questsHidden == 0, "квесты")
if LOAD_PLAN then
  assert(s.quests[1].tag == "skip", "Twisted Hatred должен быть skip")
  assert(s.quests[3].tag == "key", "Flight to Auberdine должен быть key")
else
  assert(s.quests[1].tag == nil, "без плана меток нет")
end

-- Экипировка, таланты, заклинания, навыки
assert(#s.gear.items == 3 and #s.gear.empty == 14, "экипировка: " .. #s.gear.items .. "/" .. #s.gear.empty)
local cap = s.gear.items[1]
assert(cap.slot == "Голова" and cap.id == 90001 and cap.name == "Test Cap" and cap.q == 2 and cap.ilvl == 12, "шлем")
local feral = s.talentTabs[2]
assert(#s.talentTabs == 3 and feral.name == "Feral Combat" and feral.spent == 5, "дерево талантов")
assert(#feral.list == 1 and feral.list[1].name == "Ferocity" and feral.list[1].max == 5, "вложенные таланты")
assert(#s.spells[1].list == 1, "пассивка пропущена")
local balance = s.spells[2]
assert(balance.tab == "Balance" and #balance.list == 2, "Balance: старший ранг, без неизученных: " .. #balance.list)
assert(balance.list[1].name == "Wrath" and balance.list[1].rank == 2, "старший ранг Wrath")
if MODE == "classic" then
  assert(s.skills[1].header == "Professions" and s.skills[1].list[1].rank == 45, "профессии")
  assert(#s.skills[2].list == 0 and s.skills[3].collapsed, "доспехи пропущены, оружие свёрнуто")
  assert(char.text:find("Навыки: Professions: Herbalism 45/75 | Weapon Skills: СВЁРНУТО", 1, true), "навыки в тексте")
else
  assert(#s.skills[1].list == 2 and s.skills[1].list[2].name == "Cooking", "профессии (modern)")
end
assert(char.text:find("Экипировка: Голова [90001] Test Cap (зелёный, iLvl 12)", 1, true), "экипировка в тексте")
assert(char.text:find("Дерево талантов: Balance 0 | Feral Combat 5: Ferocity 5/5 | Restoration 0", 1, true), "таланты в тексте")
assert(char.text:find("Balance: Wrath 2, Moonfire 1", 1, true), "заклинания в тексте")

-- Сумки, состояние, цель, группа, характеристики, репутация
assert(#s.inv.bags == 1 and s.inv.bags[1].name == "Backpack" and s.inv.bags[1].free == 2, "сумки по отдельности")
assert(#s.inv.items == 6, "предметов в сумках: " .. #s.inv.items)
assert(s.vitals.hp == 80 and s.vitals.mana == 50 and s.vitals.combat == false, "здоровье и мана")
assert(#s.buffs == 1 and s.buffs[1].left == 1700 and #s.debuffs == 1, "баффы и дебаффы")
assert(s.target.name == "Plainstrider" and s.target.enemy and s.target.hp == 100, "цель")
assert(s.group.size == 2 and s.group.members[1].class == "WARRIOR", "группа")
assert(s.stats.sta == 22 and s.stats.armor == 50, "характеристики")
assert(#s.rep == 2 and s.rep[1].name == "Darnassus" and s.rep[1].cur == 1200 and s.rep[2].collapsed, "репутация")
for _, line in ipairs({
  "Сейчас: здоровье 80%, мана 50%",
  "Цель: Plainstrider, ур. 2, враг, здоровье 100%",
  "Группа: 2 чел.: WARRIOR 11",
  "Баффы: Mark of the Wild 28:20 | Дебаффы: Resurrection Sickness 5:00",
  "Сумки по отдельности: Backpack 16 (свободно 2)",
  "В сумках: Экипировка: [90011] Test Boots (зелёный, iLvl 8, треб. 6, INVTYPE_FEET) | Квестовое: [90010] Test Quest Item | Расходники: [99] Test Water x9 | Прочее: [1] Junk x2",
  "Характеристики: сила 20, ловкость 15, выносливость 22, интеллект 18, дух 21, броня 50",
  "Репутация: Darnassus: Friendly 1200/6000; Other: СВЁРНУТО",
}) do
  assert(char.text:find(line, 1, true), "нет в тексте: " .. line)
end
assert(not char.text:find("Банк", 1, true), "банк ещё не открывали")

-- Квест выполнен -> сообщение в чат
MOCK.q3done = 1
MOCK.Fire("QUEST_LOG_UPDATE")
MOCK.Flush()
assert(char.snap.questsReady == 1, "готово к сдаче")

-- Уровень 10 -> веха из плана и запись в историю
MOCK.level = 10
MOCK.Fire("PLAYER_LEVEL_UP", 10)
MOCK.Flush()
local last = char.history[#char.history]
assert(last.e == "L" and last.v == 10, "история уровня")

-- Камень на КД, потом готов -> сообщение
MOCK.hsStart, MOCK.hsDur = 900, 3600
MOCK.Fire("BAG_UPDATE_DELAYED")
MOCK.Flush()
assert(char.snap.hsCD > 3000, "КД камня")
MOCK.now = 5000
MOCK.ticker()
assert(char.snap.hsCD == 0, "камень готов")

-- Сдача квеста и смерть в истории
MOCK.Fire("QUEST_TURNED_IN", 2138, 1150)
MOCK.Fire("PLAYER_DEAD")
MOCK.Flush()

-- Банк: содержимое запоминается у банкира и остаётся в снимке после ухода
MOCK.bankOpen = true
MOCK.Fire("BANKFRAME_OPENED")
MOCK.Flush()
MOCK.bankOpen = nil
MOCK.Fire("BANKFRAME_CLOSED")
MOCK.Flush()
assert(char.bank and #char.bank.items == 1 and char.bank.items[1].n == 8, "банк")
assert(char.text:find("Банк (на ", 1, true) and char.text:find("[90020] Test Bank Ore x8", 1, true), "банк в тексте")

-- План Claude в окне
if LOAD_PLAN then
  ForeverCoachPlan.now = { char = "Лунолист", level = 10, at = "05.11 03:10", steps = { "Сдать квесты", "Бежать на север" } }
  ns.RefreshUI()
  local found = false
  for _, fs in ipairs(MOCK.fontstrings) do
    if fs._text:find("План Claude", 1, true) and fs._text:find("Бежать на север", 1, true) then found = true end
  end
  assert(found, "шаги плана в окне")
end

-- Метки в журнале квестов (только Classic-интерфейс)
if QuestLog_Update then
  QuestLog_Update()
  if LOAD_PLAN then
    assert(QuestLogTitle1._text:find("[SKIP]", 1, true), "метка SKIP в журнале: " .. QuestLogTitle1._text)
    assert(QuestLogTitle3._text:find("[!]", 1, true), "метка ! в журнале")
  end
end

-- Слэш-команды
SlashCmdList.FOREVERCOACH("status")
assert(ForeverCoachCopyFrame and ForeverCoachCopyFrame:IsShown(), "окно копирования")
SlashCmdList.FOREVERCOACH("")
SlashCmdList.FOREVERCOACH("")
SlashCmdList.FOREVERCOACH("help")
SlashCmdList.FOREVERCOACH("sync")
assert(MOCK.reloads == 1, "sync делает /reload")

-- Самопроверка
SlashCmdList.FOREVERCOACH("test")
assert(char.selftest and char.selftest:find("интерфейс 11509", 1, true), "самопроверка: клиент")
assert(char.selftest:find("Ошибки: нет", 1, true), "самопроверка: ошибок быть не должно")

-- Ошибка в API не роняет аддон, а попадает в отчёт
local realMoney = GetMoney
GetMoney = function() error("boom") end
MOCK.Fire("PLAYER_MONEY")
MOCK.Flush()
GetMoney = realMoney
assert(#ns.errors == 1 and ns.errors[1]:find("boom", 1, true), "ошибка должна попасть в ns.errors")
SlashCmdList.FOREVERCOACH("test")
assert(char.selftest:find("boom", 1, true), "ошибка должна попасть в самопроверку")

-- Сломанный раздел (другое API талантов) теряется один, остальной снимок цел
local realTalentInfo = GetTalentInfo
GetTalentInfo = function() error("talents api") end
MOCK.Fire("CHARACTER_POINTS_CHANGED")
MOCK.Flush()
GetTalentInfo = realTalentInfo
assert(#ns.errors == 2 and ns.errors[2]:find("talents api", 1, true), "ошибка раздела в ns.errors")
assert(char.snap.talentTabs == nil and char.snap.gear and char.snap.spells, "пропал только раздел талантов")
assert(char.text:find("Экипировка:", 1, true) and not char.text:find("Дерево талантов:", 1, true), "текст без талантов")

-- Гид: шаги из Plan.lua, точки из Questie, стрелка TomTom (modern) или расстояние по карте (classic)
if LOAD_PLAN then
  ForeverCoachPlan.guide = { char = "Лунолист", at = "test", steps = {
    { text = "Взять Flight to Auberdine", accept = 6342 },
    { text = "Убить Lord Melenas", complete = 932 },
    { text = "Сдать Twisted Hatred", turnin = 932 },
    { text = "К причалу", map = 1439, x = 33, y = 40 },
    { text = "Получить 12 уровень", level = 12 },
    { text = "Выполнить квест, которого нет в журнале", complete = 9999 },
    { text = "Плыть в Штормград", zone = 1453, cost = 20000, note = "корабль у причала" },
    { text = "Выучить булавы", learn = 198 },
    { text = "Привязать камень", bind = true },
    { text = "Поговорить с хозяином таверны" },
  } }
  ns.GuideCheck()
  assert(char.guide.step == 2, "шаг 1 (квест уже в журнале) должен закрыться сам: " .. char.guide.step)
  ForeverCoachPlan.guide.race = "Tauren"
  assert(ns.GuideStatus() == nil, "гид для другой расы не показывается")
  ForeverCoachPlan.guide.race = "NightElf"
  local pt = ns.guidePoint
  assert(pt and pt.map == 1439 and pt.x == 40 and pt.y == 50, "точка цели квеста: ближайшая из Questie")
  if MODE == "modern" then
    assert(MOCK.waypoint and MOCK.waypoint.x == 0.4 and MOCK.waypoint.opts.crazy, "стрелка TomTom")
  end
  ns.RefreshUI()
  local shown = false
  for _, fs in ipairs(MOCK.fontstrings) do
    if fs._text:find("Шаг 2/10:", 1, true) and fs._text:find("Убить Lord Melenas", 1, true) then shown = true end
  end
  assert(shown, "шаг гида в окне")

  MOCK.q1done = 1
  MOCK.Fire("QUEST_LOG_UPDATE")
  MOCK.Flush()
  assert(char.guide.step == 3 and ns.guidePoint.x == 37, "после выполнения цели - к тому, кто принимает квест")

  MOCK.Fire("QUEST_TURNED_IN", 932, 500)
  MOCK.Flush()
  assert(char.guide.step == 4 and ns.guidePoint.x == 33, "после сдачи - к явной точке")

  -- Приход в точку: в modern расстояние даёт TomTom, в classic - размер карты
  MOCK.tomtomDist = 10
  MOCK.px, MOCK.py = 0.331, 0.401
  MOCK.ticker()
  assert(char.guide.step == 5, "приход в точку: " .. char.guide.step)

  -- Уровень; затем шаг по квесту, которого нет в журнале, пропускается сам
  MOCK.level = 12
  MOCK.Fire("PLAYER_LEVEL_UP", 12)
  MOCK.Flush()
  assert(char.guide.step == 7, "уровень 12 и пропуск квеста не из журнала: " .. char.guide.step)
  assert(char.text:find("Гид: шаг 7/10 «Плыть в Штормград», нужно 2g 0s 0c, есть 1g 23s 45c - НЕ ХВАТАЕТ", 1, true),
    "стоимость шага в снимке")
  assert(ns.GuideStatus().note == "корабль у причала", "заметка к шагу")

  -- Прибытие в зону, изучение заклинания, привязка камня
  MOCK.map = 1453
  MOCK.ticker()
  assert(char.guide.step == 8, "прибытие в Штормград")
  MOCK.spells[198] = true
  MOCK.ticker()
  assert(char.guide.step == 9, "булавы изучены")
  MOCK.ticker()
  assert(char.guide.step == 9, "камень ещё не привязан")
  MOCK.Fire("HEARTHSTONE_BOUND")
  MOCK.Flush()
  assert(char.guide.step == 10, "камень привязан")

  SlashCmdList.FOREVERCOACH("next")
  assert(char.guide.step == 11 and ns.guidePoint == nil, "/fc next закрывает шаг без условия")
  if MODE == "modern" then assert(MOCK.waypoint == nil, "стрелка убрана после конца гида") end
  assert(MOCK.chat[#MOCK.chat]:find("Гид пройден", 1, true), "сообщение о конце гида")
end

-- Выход из игры: данные персонажа уже выгружены, последний полный снимок не должен затереться
MOCK.unloaded = true
MOCK.Fire("PLAYER_LOGOUT")
assert(char.snap.bagTotal == 16 and #char.snap.gear.items == 3, "снимок затёрт при выходе")
assert(char.history[#char.history].e == "LOGOUT" and char.text:find("LOGOUT", 1, true), "выход в истории")
MOCK.AssertSerializable(ForeverCoachDB, "ForeverCoachDB")
return char.text .. "\n--- самопроверка ---\n" .. char.selftest, table.concat(MOCK.chat, "\n")
"""


def run(mode: str, load_plan: bool) -> None:
    lua = LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.MODE = mode
    g.LOAD_PLAN = load_plan
    g.ADDON_DIR = str(ADDON) + "/"
    lua.execute(MOCK.read_text(encoding="utf-8"))
    text, chat = lua.execute(SCENARIO)
    print(f"=== {mode}, план {'есть' if load_plan else 'сломан'}: OK")
    print("--- снимок для Claude ---")
    print(text)
    print("--- чат ---")
    print(chat)
    print()


if __name__ == "__main__":
    try:
        run("classic", True)
        run("modern", True)
        run("classic", False)
    except Exception as exc:  # noqa: BLE001
        print("FAIL:", exc)
        sys.exit(1)
    print("Все сценарии прошли.")
