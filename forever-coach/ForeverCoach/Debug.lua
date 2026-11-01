-- ForeverCoach: самопроверка (/fc test).
-- Показывает, какие функции игры доступны в этом клиенте и что аддон видит.
-- Отчёт открывается в окне копирования и сохраняется в SavedVariables (поле selftest).
local ADDON, ns = ...

local function Has(path)
  local t = _G
  for part in path:gmatch("[^%.]+") do
    if type(t) ~= "table" then return false end
    t = t[part]
  end
  return t ~= nil
end

local function First(...)
  for i = 1, select("#", ...) do
    local path = select(i, ...)
    if Has(path) then return path end
  end
  return "НЕТ"
end

function ns.SelfTest()
  ns.SafeCall(ns.Update)
  local L = {}
  local function add(fmt, ...) L[#L + 1] = string.format(fmt, ...) end

  local version, build, _, toc = GetBuildInfo()
  add("ForeverCoach %s: самопроверка, %s", ns.VERSION, date("%Y-%m-%d %H:%M:%S"))
  add("Клиент: %s (сборка %s), интерфейс %s, язык %s",
    tostring(version), tostring(build), tostring(toc), GetLocale and GetLocale() or "?")
  add("Персонаж: %s, запись в ForeverCoachDB: %s", tostring(ns.charKey), ns.char and "да" or "НЕТ")

  local P = ns.Plan()
  if P then
    add("Plan.lua: загружен, обновлён %s, участков маршрута %d, шаги Claude: %s",
      tostring(P.updated), type(P.route) == "table" and #P.route or 0,
      type(P.now) == "table" and ("есть, ур. " .. tostring(P.now.level)) or "нет")
  else
    add("Plan.lua: НЕ ЗАГРУЖЕН")
  end

  add("API сумок: %s", First("C_Container.GetContainerNumFreeSlots", "GetContainerNumFreeSlots"))
  add("API предметов в сумках: %s", First("C_Container.GetContainerItemInfo", "GetContainerItemInfo"))
  add("API КД предметов: %s", First("C_Container.GetItemCooldown", "GetItemCooldown"))
  add("API КД заклинаний: %s", First("C_Spell.GetSpellCooldown", "GetSpellCooldown"))
  add("API изученных заклинаний: %s", First("IsPlayerSpell", "IsSpellKnown"))
  add("API журнала квестов: %s", First("GetQuestLogTitle", "C_QuestLog.GetInfo"))
  add("API талантов: %s", First("UnitCharacterPoints", "GetUnspentTalentPoints"))
  add("API карты: %s", First("C_Map.GetBestMapForUnit"))
  local hook
  if ns.questLogHooked then
    hook = "стоят (хук QuestLog_Update)"
  elseif type(QuestLog_Update) == "function" then
    hook = "НЕТ: хук не поставлен"
  else
    hook = "НЕТ: в клиенте другой журнал квестов"
  end
  add("Метки в журнале квестов: %s", hook)
  add("Окно аддона: %s",
    ForeverCoachFrame and (ForeverCoachFrame:IsShown() and "показано" or "скрыто (/fc)") or "НЕ СОЗДАНО")

  local s = ns.state
  if s then
    add("Снимок: ур. %d, %d/%d XP, отдых %d, в таверне: %s",
      s.level, s.xp, s.xpMax, s.rested or 0, s.resting and "да" or "нет")
    add("Место: %s / %s, map %s, координаты %s, %s",
      tostring(s.zone), tostring(s.subzone), tostring(s.mapID), tostring(s.x), tostring(s.y))
    add("Сумки: свободно %d из %d, серое %d (~%s)", s.bagFree, s.bagTotal, s.junk, ns.Money(s.junkValue))
    add("Камень: %s, КД %s, привязан: %s; телепорт на Лунную поляну: %s",
      s.hsHave and "в сумках" or "НЕТ в сумках", ns.Clock(s.hsCD), tostring(s.hsBind),
      s.tpCD and ns.Clock(s.tpCD) or "не изучен")
    add("Таланты свободно: %s; прочность мин.: %s%%; обликов: %d; деньги: %s",
      tostring(s.talents), tostring(s.durMin), s.forms or 0, ns.Money(s.money))
    local tagged = 0
    for _, q in ipairs(s.quests) do if q.tag then tagged = tagged + 1 end end
    add("Квесты: %d, готово к сдаче %d, скрыто свёрнутыми %d, с метками %d",
      #s.quests, s.questsReady, s.questsHidden or 0, tagged)
  else
    add("Снимок: НЕТ")
  end
  local hist = ns.char and ns.char.history
  add("История: записей %d", hist and #hist or 0)
  add("Неподдерживаемые события: %s",
    #ns.unsupportedEvents > 0 and table.concat(ns.unsupportedEvents, ", ") or "нет")
  add("Ошибки: %s", #ns.errors > 0 and table.concat(ns.errors, " | ") or "нет")

  local text = table.concat(L, "\n")
  if ns.char then ns.char.selftest = text end
  ns.ShowCopy(text)
  return text
end
