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
  add("API экипировки: %s + %s", First("GetInventoryItemLink"), First("C_Item.GetItemInfo", "GetItemInfo"))
  add("API дерева талантов: %s", First("GetTalentInfo"))
  add("API книги заклинаний: %s", First("GetSpellBookItemName", "C_SpellBook.GetSpellBookItemName"))
  add("API навыков: %s", First("GetSkillLineInfo", "GetProfessionInfo"))
  add("API типов предметов: %s", First("C_Item.GetItemInfoInstant", "GetItemInfoInstant"))
  add("API баффов: %s", First("C_UnitAuras.GetAuraDataByIndex", "UnitAura"))
  add("API репутации: %s", First("GetFactionInfo", "C_Reputation.GetFactionDataByIndex"))
  add("API характеристик: %s; группы: %s", First("UnitStat"), First("GetNumGroupMembers"))
  add("Гид: стрелка %s; база точек %s + %s; размер карты %s; сданные квесты %s",
    First("TomTom.AddWaypoint"), First("QuestDB.Get"), First("QuestieLoader.ImportModule"),
    First("C_Map.GetMapWorldSize"), First("C_QuestLog.IsQuestFlaggedCompleted", "IsQuestFlaggedCompleted"))
  local gs = ns.GuideStatus and ns.GuideStatus()
  if gs and not gs.done then
    local pt = gs.point
    add("Гид: шаг %d/%d «%s», точка: %s", gs.step, gs.total, gs.text,
      pt and string.format("карта %s %.1f, %.1f", pt.map, pt.x, pt.y) or "нет")
  else
    add("Гид: %s", gs and "пройден" or "нет в Plan.lua")
  end
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
    local spent, spells, skills = 0, 0, 0
    for _, t in ipairs(s.talentTabs or {}) do spent = spent + t.spent end
    for _, t in ipairs(s.spells or {}) do spells = spells + #t.list end
    for _, h in ipairs(s.skills or {}) do skills = skills + #h.list end
    add("Экипировка: %s; талантов вложено: %s; заклинаний: %s; навыков: %s",
      s.gear and string.format("надето %d, пусто %d", #s.gear.items, #s.gear.empty) or "НЕТ",
      s.talentTabs and tostring(spent) or "НЕТ", s.spells and tostring(spells) or "НЕТ",
      s.skills and tostring(skills) or "НЕТ")
    local bank = ns.char and ns.char.bank
    add("В сумках предметов: %s; банк: %s; баффов: %s, дебаффов: %s; фракций: %s; характеристики: %s",
      s.inv and tostring(#s.inv.items) or "НЕТ",
      bank and string.format("%d предм. на %s", #bank.items, date("%d.%m %H:%M", bank.at)) or "не открывался",
      s.buffs and tostring(#s.buffs) or "НЕТ", s.debuffs and tostring(#s.debuffs) or "НЕТ",
      s.rep and tostring(#s.rep) or "НЕТ", s.stats and "есть" or "НЕТ")
    add("Сейчас: здоровье %s%%, в бою: %s; цель: %s; группа: %s",
      tostring(s.vitals and s.vitals.hp), (s.vitals and s.vitals.combat) and "да" or "нет",
      s.target and "есть" or "нет", s.group and tostring(s.group.size) or "нет")
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
