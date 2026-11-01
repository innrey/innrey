-- ForeverCoach: сбор состояния персонажа, история, предупреждения.
-- Аддон ничего не делает за игрока: только читает данные игры и показывает их.
-- Снимок попадает на диск (SavedVariables) при /reload, выходе из игры или /fc sync.
local ADDON, ns = ...

ns.VERSION = "0.1.0"
ns.FONT = "Fonts\\ARIALN.TTF" -- есть во всех клиентах и поддерживает кириллицу

local HEARTHSTONE_ITEM = 6948
local TELEPORT_MOONGLADE = 18960
local HISTORY_MAX = 300
local STALE_LEVELS = 1

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ForeverCoach:|r " .. tostring(msg))
end
ns.Print = Print

local function Plan()
  if type(ForeverCoachPlan) == "table" then return ForeverCoachPlan end
  return nil
end
ns.Plan = Plan

-- Ошибки не роняют аддон: запоминаем их для /fc test и пишем в чат один раз
ns.errors = {}
local reportedErrors = {}
function ns.SafeCall(fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then
    err = tostring(err)
    if not reportedErrors[err] then
      reportedErrors[err] = true
      table.insert(ns.errors, err)
      Print("ошибка: " .. err .. " (/fc test - отчёт для Claude)")
    end
  end
  return ok
end

---------------------------------------------------------------------------
-- Совместимость API: Classic Era, Forever и более новые клиенты
---------------------------------------------------------------------------
local CC = C_Container

local function BagFreeSlots(bag)
  if CC and CC.GetContainerNumFreeSlots then return CC.GetContainerNumFreeSlots(bag) end
  if GetContainerNumFreeSlots then return GetContainerNumFreeSlots(bag) end
  return 0, 0
end

local function BagNumSlots(bag)
  if CC and CC.GetContainerNumSlots then return CC.GetContainerNumSlots(bag) end
  if GetContainerNumSlots then return GetContainerNumSlots(bag) end
  return 0
end

-- Возвращает quality, stackCount, link, noValue
local function BagItem(bag, slot)
  if CC and CC.GetContainerItemInfo then
    local info = CC.GetContainerItemInfo(bag, slot)
    if info then return info.quality, info.stackCount, info.hyperlink, info.hasNoValue end
    return nil
  end
  if GetContainerItemInfo then
    local _, count, _, quality, _, _, link, _, noValue = GetContainerItemInfo(bag, slot)
    return quality, count, link, noValue
  end
end

local function Remaining(start, duration)
  if not start or not duration or start == 0 or duration <= 1.5 then return 0 end -- 1.5 сек = глобальный КД
  local r = start + duration - GetTime()
  if r < 0 then r = 0 end
  return r
end

local function ItemCooldown(itemID)
  local f = (CC and CC.GetItemCooldown) or GetItemCooldown
  if not f then return nil end
  local start, duration = f(itemID)
  return Remaining(start, duration)
end

local function KnowsSpell(spellID)
  if IsPlayerSpell then return IsPlayerSpell(spellID) and true or false end
  if IsSpellKnown then return IsSpellKnown(spellID) and true or false end
  return false
end

local function SpellCooldown(spellID)
  if C_Spell and C_Spell.GetSpellCooldown then
    local info = C_Spell.GetSpellCooldown(spellID)
    if info then return Remaining(info.startTime, info.duration) end
    return nil
  end
  if GetSpellCooldown then
    local start, duration = GetSpellCooldown(spellID)
    return Remaining(start, duration)
  end
end

---------------------------------------------------------------------------
-- Форматирование
---------------------------------------------------------------------------
function ns.Money(copper)
  copper = math.floor(copper or 0)
  local g = math.floor(copper / 10000)
  local s = math.floor((copper % 10000) / 100)
  local c = copper % 100
  if g > 0 then return string.format("%dg %ds %dc", g, s, c) end
  if s > 0 then return string.format("%ds %dc", s, c) end
  return string.format("%dc", c)
end

function ns.Clock(sec)
  if sec == nil then return "?" end
  if sec <= 0 then return "готов" end
  sec = math.floor(sec + 0.5)
  local h = math.floor(sec / 3600)
  local m = math.floor((sec % 3600) / 60)
  local s = sec % 60
  if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
  return string.format("%d:%02d", m, s)
end

local function Round1(v)
  if not v then return nil end
  return math.floor(v * 10 + 0.5) / 10
end

---------------------------------------------------------------------------
-- Метки квестов из Plan.lua
---------------------------------------------------------------------------
function ns.TagFor(id, title)
  local P = Plan()
  if not P then return nil end
  local function check(byId, byTitle, tag)
    if id and type(byId) == "table" and byId[id] then return tag, byId[id] end
    if title and type(byTitle) == "table" and byTitle[title] then return tag, byTitle[title] end
  end
  local tag, why = check(P.skip, P.skipTitle, "skip")
  if tag then return tag, why end
  tag, why = check(P.optional, P.optionalTitle, "opt")
  if tag then return tag, why end
  return check(P.key, P.keyTitle, "key")
end

function ns.PlanNow(s)
  local P = Plan()
  if not P or type(P.now) ~= "table" then return nil end
  local now = P.now
  if now.char and s and now.char ~= s.name then return nil end
  local stale = (now.level and s and s.level > now.level + STALE_LEVELS) and true or false
  return now, stale
end

function ns.RouteFor(level)
  local P = Plan()
  if not P or type(P.route) ~= "table" or #P.route == 0 then return nil end
  for _, r in ipairs(P.route) do
    if level >= r.min and level < r.max then return r end
  end
  return P.route[#P.route]
end

---------------------------------------------------------------------------
-- Журнал квестов
---------------------------------------------------------------------------
local function ReadQuests()
  local quests, header, expected = {}, nil, nil
  if GetNumQuestLogEntries and GetQuestLogTitle then
    local numEntries, numQuests = GetNumQuestLogEntries()
    expected = numQuests
    for i = 1, (numEntries or 0) do
      local title, level, group, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
      if isHeader then
        header = title
      elseif title then
        local q = {
          id = questID, title = title, level = level, zone = header,
          group = (group and group > 0) and group or nil,
          done = (isComplete == 1) or nil,
          failed = (isComplete == -1) or nil,
          obj = {},
        }
        local n = GetNumQuestLeaderBoards and GetNumQuestLeaderBoards(i) or 0
        for j = 1, n do
          local text, _, finished = GetQuestLogLeaderBoard(j, i)
          if text then q.obj[#q.obj + 1] = { text = text, done = finished and true or false } end
        end
        quests[#quests + 1] = q
      end
    end
  elseif C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
    local numEntries, numQuests = C_QuestLog.GetNumQuestLogEntries()
    expected = numQuests
    for i = 1, (numEntries or 0) do
      local info = C_QuestLog.GetInfo(i)
      if info and info.isHeader then
        header = info.title
      elseif info and not info.isHidden then
        local id = info.questID
        local q = {
          id = id, title = info.title, level = info.level, zone = header,
          group = (info.suggestedGroup and info.suggestedGroup > 0) and info.suggestedGroup or nil,
          done = (C_QuestLog.IsComplete and C_QuestLog.IsComplete(id)) or nil,
          obj = {},
        }
        local objs = C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(id)
        if objs then
          for _, o in ipairs(objs) do
            q.obj[#q.obj + 1] = { text = o.text, done = o.finished and true or false }
          end
        end
        quests[#quests + 1] = q
      end
    end
  end
  local hidden = expected and (expected - #quests) or 0
  if hidden < 0 then hidden = 0 end
  return quests, hidden
end

---------------------------------------------------------------------------
-- Снимок состояния
---------------------------------------------------------------------------
function ns.Collect()
  local s = { v = 1, updated = time(), addon = ns.VERSION }
  s.name = UnitName("player")
  s.realm = GetRealmName and GetRealmName() or "?"
  local _, classFile = UnitClass("player")
  local _, raceFile = UnitRace("player")
  s.class, s.race = classFile, raceFile
  s.faction = UnitFactionGroup and UnitFactionGroup("player") or nil
  s.level = UnitLevel("player") or 0
  s.xp, s.xpMax = UnitXP("player") or 0, UnitXPMax("player") or 0
  s.rested = (GetXPExhaustion and GetXPExhaustion()) or 0
  s.resting = (IsResting and IsResting()) and true or false
  s.money = GetMoney and GetMoney() or 0
  s.dead = (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) and true or false

  -- Где игрок
  s.zone = GetZoneText and GetZoneText() or nil
  s.subzone = GetSubZoneText and GetSubZoneText() or nil
  if C_Map and C_Map.GetBestMapForUnit then
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
      s.mapID = mapID
      local pos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
      if pos then
        local x, y = pos:GetXY()
        if x and y then s.x, s.y = Round1(x * 100), Round1(y * 100) end
      end
    end
  end

  -- Сумки и серые предметы
  local free, total, junk, junkValue = 0, 0, 0, 0
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    local slots = BagNumSlots(bag) or 0
    local nfree, family = BagFreeSlots(bag)
    if slots > 0 and (family == nil or family == 0) then -- только обычные сумки
      total = total + slots
      free = free + (nfree or 0)
    end
    for slot = 1, slots do
      local quality, count, link, noValue = BagItem(bag, slot)
      if quality == 0 and not noValue then
        junk = junk + 1
        local price = link and GetItemInfo and select(11, GetItemInfo(link))
        if price then junkValue = junkValue + price * (count or 1) end
      end
    end
  end
  s.bagFree, s.bagTotal, s.junk, s.junkValue = free, total, junk, junkValue

  -- Камень возвращения и телепорт друида
  s.hsHave = ((GetItemCount and GetItemCount(HEARTHSTONE_ITEM)) or 0) > 0
  s.hsCD = s.hsHave and ItemCooldown(HEARTHSTONE_ITEM) or nil
  s.hsBind = GetBindLocation and GetBindLocation() or nil
  if KnowsSpell(TELEPORT_MOONGLADE) then s.tpCD = SpellCooldown(TELEPORT_MOONGLADE) end

  -- Таланты, прочность, облики
  if UnitCharacterPoints then
    s.talents = UnitCharacterPoints("player")
  elseif GetUnspentTalentPoints then
    s.talents = GetUnspentTalentPoints()
  end
  local minDur
  if GetInventoryItemDurability then
    for slot = 1, 18 do
      local cur, max = GetInventoryItemDurability(slot)
      if cur and max and max > 0 then
        local p = cur / max
        if not minDur or p < minDur then minDur = p end
      end
    end
  end
  s.durMin = minDur and Round1(minDur * 100) or nil
  s.forms = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0

  -- Квесты
  s.quests, s.questsHidden = ReadQuests()
  local ready = 0
  for _, q in ipairs(s.quests) do
    if q.done then ready = ready + 1 end
    q.tag, q.why = ns.TagFor(q.id, q.title)
  end
  s.questsReady = ready

  ns.state = s
  return s
end

---------------------------------------------------------------------------
-- Текст снимка: его читает Claude (из файла или из /fc status)
---------------------------------------------------------------------------
function ns.BuildText(s, history)
  local L = {}
  local function add(fmt, ...) L[#L + 1] = string.format(fmt, ...) end
  local pct = s.xpMax > 0 and math.floor(s.xp / s.xpMax * 100) or 0
  local restPct = s.xpMax > 0 and math.floor((s.rested or 0) / s.xpMax * 100) or 0

  add("ForeverCoach v%s | снимок %s", ns.VERSION, date("%Y-%m-%d %H:%M:%S", s.updated))
  add("Персонаж: %s (%s %s, %s) ур. %d, %d%% (%d/%d), отдых %d XP (%d%% уровня)%s%s",
    tostring(s.name), tostring(s.race), tostring(s.class), tostring(s.faction),
    s.level, pct, s.xp, s.xpMax, s.rested or 0, restPct,
    s.resting and " [в таверне]" or "", s.dead and " [МЁРТВ]" or "")
  add("Где: %s / %s (map %s) %s, %s", tostring(s.zone),
    (s.subzone and s.subzone ~= "") and s.subzone or "-",
    tostring(s.mapID), tostring(s.x), tostring(s.y))
  add("Сумки: свободно %d из %d; серое: %d шт. (~%s)", s.bagFree, s.bagTotal, s.junk, ns.Money(s.junkValue))
  add("ХС: %s, привязан: %s%s",
    s.hsHave and ns.Clock(s.hsCD) or "нет в сумках", tostring(s.hsBind),
    s.tpCD and (" | Телепорт: Лунная поляна: " .. ns.Clock(s.tpCD)) or "")
  add("Таланты свободно: %s | Прочность мин.: %s%% | Деньги: %s | Обликов: %d",
    tostring(s.talents), tostring(s.durMin), ns.Money(s.money), s.forms or 0)
  add("Квесты: %d, готово к сдаче: %d%s", #s.quests, s.questsReady,
    (s.questsHidden or 0) > 0 and string.format(", СКРЫТО свёрнутыми заголовками: %d", s.questsHidden) or "")
  for _, q in ipairs(s.quests) do
    local objs = {}
    for _, o in ipairs(q.obj) do objs[#objs + 1] = (o.done and "+" or "-") .. o.text end
    add("- [%s] %s (ур.%s, %s)%s%s%s%s",
      tostring(q.id), tostring(q.title), tostring(q.level), tostring(q.zone),
      q.group and (" группа " .. q.group) or "",
      q.done and " ГОТОВ" or (q.failed and " ПРОВАЛЕН" or ""),
      q.tag and (" {" .. q.tag .. "}") or "",
      #objs > 0 and (" :: " .. table.concat(objs, "; ")) or "")
  end
  if history and #history > 0 then
    local parts = {}
    for i = math.max(1, #history - 29), #history do
      local h = history[i]
      parts[#parts + 1] = string.format("%s %s%s%s", date("%d.%m %H:%M", h.t), h.e,
        h.v ~= nil and ("=" .. tostring(h.v)) or "", h.x and ("(+" .. h.x .. "xp)") or "")
    end
    add("История: %s", table.concat(parts, ", "))
  end
  return table.concat(L, "\n")
end

---------------------------------------------------------------------------
-- История (уровни, смерти, сдачи квестов, смены зон) — для оценки темпа
---------------------------------------------------------------------------
local function Hist(e, v, x)
  local c = ns.char
  if not c then return end
  c.history = c.history or {}
  table.insert(c.history, { t = time(), e = e, v = v, x = x })
  while #c.history > HISTORY_MAX do table.remove(c.history, 1) end
end
ns.Hist = Hist

---------------------------------------------------------------------------
-- Предупреждения в чат (срабатывают один раз при пересечении порога)
---------------------------------------------------------------------------
local alerted = {}

function ns.CheckAlerts(prev, s)
  local P = Plan() or {}
  local A = P.alerts or {}
  local bagMin = A.bagFreeMin or 3
  if s.bagTotal > 0 and s.bagFree <= bagMin then
    if not alerted.bags then
      alerted.bags = true
      Print(string.format("Сумки почти полны: свободно %d. Серого на %s - продай у ближайшего торговца.",
        s.bagFree, ns.Money(s.junkValue)))
    end
  elseif s.bagFree > bagMin + 2 then
    alerted.bags = nil
  end

  local durMin = (A.durabilityMin or 0.3) * 100
  if s.durMin and s.durMin < durMin then
    if not alerted.dur then
      alerted.dur = true
      Print(string.format("Прочность %s%% - почини у ближайшего торговца с ремонтом.", tostring(s.durMin)))
    end
  else
    alerted.dur = nil
  end

  if prev and prev.quests then
    local was = {}
    for _, q in ipairs(prev.quests) do if q.done and q.id then was[q.id] = true end end
    for _, q in ipairs(s.quests) do
      if q.done and q.id and not was[q.id] then
        Print("Выполнено: " .. tostring(q.title) .. string.format(" (готово к сдаче: %d)", s.questsReady))
      end
    end
  end
end

local function OnLevel(level)
  Hist("L", level)
  local P = Plan() or {}
  local m = P.milestones and P.milestones[level]
  if m then
    Print("|cffffd100Уровень " .. level .. ":|r " .. m)
  elseif level % 2 == 0 then
    Print("Уровень " .. level .. ": у тренера новые ранги - загляни, когда будешь рядом.")
  end
end

---------------------------------------------------------------------------
-- Обновление
---------------------------------------------------------------------------
function ns.Update()
  if not ns.char then return end
  local prev = ns.state
  local s = ns.Collect()
  ns.char.snap = s
  ns.char.text = ns.BuildText(s, ns.char.history)
  ns.CheckAlerts(prev, s)
  if ns.RefreshUI then ns.RefreshUI() end
end

local pending = false
function ns.RequestUpdate()
  if pending or not ns.char then return end
  pending = true
  C_Timer.After(0.5, function()
    pending = false
    ns.SafeCall(ns.Update)
  end)
end

-- Раз в 5 секунд: только кулдауны и окно, без полного сканирования
function ns.Tick()
  local s = ns.state
  if not s then return end
  if s.hsHave then
    local cd = ItemCooldown(HEARTHSTONE_ITEM)
    if s.hsCD and s.hsCD > 0 and cd == 0 then
      Print("Камень возвращения готов (" .. tostring(s.hsBind) .. ").")
    end
    s.hsCD = cd
  end
  if s.tpCD ~= nil then
    local cd = SpellCooldown(TELEPORT_MOONGLADE)
    if s.tpCD > 0 and cd == 0 then Print("Телепортация: Лунная поляна готова.") end
    s.tpCD = cd
  end
  if ns.RefreshUI then ns.RefreshUI() end
end

function ns.Sync()
  if InCombatLockdown and InCombatLockdown() then
    Print("Синхронизация после боя.")
    return
  end
  ns.SafeCall(ns.Update)
  ReloadUI()
end

---------------------------------------------------------------------------
-- События
---------------------------------------------------------------------------
local function InitDB()
  ForeverCoachDB = ForeverCoachDB or {}
  local db = ForeverCoachDB
  db.v = 1
  db.chars = db.chars or {}
  db.ui = db.ui or {}
  ns.db = db
end

local function InitChar()
  local key = tostring(UnitName("player")) .. "-" .. tostring(GetRealmName and GetRealmName() or "?")
  ns.db.chars[key] = ns.db.chars[key] or {}
  ns.char, ns.charKey = ns.db.chars[key], key
end

local events = CreateFrame("Frame")
local EVENTS = {
  "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_LOGOUT", "PLAYER_ENTERING_WORLD",
  "PLAYER_LEVEL_UP", "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "PLAYER_UPDATE_RESTING",
  "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "BAG_UPDATE_DELAYED", "BAG_UPDATE",
  "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "PLAYER_MONEY", "UPDATE_INVENTORY_DURABILITY",
  "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "CHARACTER_POINTS_CHANGED",
  "SPELLS_CHANGED", "UPDATE_SHAPESHIFT_FORMS", "HEARTHSTONE_BOUND",
}
ns.unsupportedEvents = {}
for _, ev in ipairs(EVENTS) do
  -- в каком-то клиенте события может не быть
  if not pcall(events.RegisterEvent, events, ev) then
    table.insert(ns.unsupportedEvents, ev)
  end
end

events:SetScript("OnEvent", function(_, ev, ...)
  if ev == "ADDON_LOADED" then
    local name = ...
    if name == ADDON then InitDB() end
    return
  elseif ev == "PLAYER_LOGIN" then
    if not ns.db then InitDB() end
    InitChar()
    Hist("LOGIN")
    ns.SafeCall(ns.Update)
    C_Timer.NewTicker(5, function() ns.SafeCall(ns.Tick) end)
    if ns.CreateUI then ns.SafeCall(ns.CreateUI) end
    if not Plan() then
      Print("Plan.lua не загрузился - проверь синтаксис файла. Аддон работает без плана.")
    end
    return
  elseif ev == "PLAYER_LOGOUT" then
    if ns.char then
      Hist("LOGOUT")
      ns.SafeCall(ns.Update)
    end
    return
  elseif ev == "PLAYER_LEVEL_UP" then
    local level = ...
    if ns.char then OnLevel(level) end
  elseif ev == "QUEST_TURNED_IN" then
    local questID, xp = ...
    Hist("Q", questID, xp)
  elseif ev == "PLAYER_DEAD" then
    Hist("D")
  elseif ev == "ZONE_CHANGED_NEW_AREA" then
    Hist("Z", GetZoneText and GetZoneText() or nil)
  end
  ns.RequestUpdate()
end)

---------------------------------------------------------------------------
-- Слэш-команды и клавиши
---------------------------------------------------------------------------
BINDING_HEADER_FOREVERCOACH = "ForeverCoach"
BINDING_NAME_FOREVERCOACH_SYNC = "Sync (save + /reload)"
BINDING_NAME_FOREVERCOACH_COPY = "Copy status for Claude"
BINDING_NAME_FOREVERCOACH_TOGGLE = "Show / hide window"

function ForeverCoach_Sync() ns.Sync() end
function ForeverCoach_Copy() if ns.ShowCopy then ns.ShowCopy() end end
function ForeverCoach_Toggle() if ns.Toggle then ns.Toggle() end end

SLASH_FOREVERCOACH1 = "/fc"
SLASH_FOREVERCOACH2 = "/coach"
SlashCmdList["FOREVERCOACH"] = function(msg)
  local cmd = (msg or ""):lower():match("^%s*(.-)%s*$")
  if cmd == "" or cmd == "show" or cmd == "hide" or cmd == "toggle" then
    ForeverCoach_Toggle()
  elseif cmd == "status" or cmd == "copy" then
    ForeverCoach_Copy()
  elseif cmd == "sync" then
    ns.Sync()
  elseif cmd == "test" then
    if ns.SelfTest then ns.SafeCall(ns.SelfTest) end
  elseif cmd == "lock" or cmd == "unlock" then
    ns.db.ui.locked = (cmd == "lock") or nil
    Print(cmd == "lock" and "Окно закреплено." or "Окно можно двигать.")
  elseif cmd == "reset" then
    ns.db.ui.point, ns.db.ui.relPoint, ns.db.ui.x, ns.db.ui.y = nil, nil, nil, nil
    Print("Позиция окна сброшена - сделай /reload.")
  else
    Print("/fc - окно; /fc status - текст для Claude; /fc sync - сохранить и /reload; /fc test - самопроверка; /fc lock|unlock; /fc reset")
  end
end
