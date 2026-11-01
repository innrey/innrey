-- Минимальные заглушки WoW API для проверки аддона вне игры (Lua 5.1).
-- MODE задаётся до загрузки: "classic" (старые глобальные функции) или "modern" (C_* API).

MOCK = {
  level = 9, now = 1000, hsStart = 0, hsDur = 0, q3done = nil,
  chat = {}, reloads = 0, frames = {}, fontstrings = {}, pending = {},
}

local function NewObj(kind, name)
  local o = { _scripts = {}, _shown = true, _text = "", _kind = kind, _events = {}, _id = 1 }
  setmetatable(o, { __index = function() return function() end end })
  o.SetScript = function(self, ev, fn) self._scripts[ev] = fn end
  o.GetScript = function(self, ev) return self._scripts[ev] end
  o.RegisterEvent = function(self, ev)
    if ev == "HEARTHSTONE_BOUND" then error("Attempt to register unknown event") end
    self._events[ev] = true
  end
  o.IsShown = function(self) return self._shown end
  o.Show = function(self) self._shown = true end
  o.Hide = function(self) self._shown = false end
  o.SetText = function(self, t) self._text = t end
  o.GetText = function(self) return self._text end
  o.GetStringHeight = function() return 100 end
  o.GetPoint = function() return "CENTER", nil, "CENTER", 10, 20 end
  o.GetID = function(self) return self._id end
  o.CreateFontString = function()
    local fs = NewObj("FontString")
    table.insert(MOCK.fontstrings, fs)
    return fs
  end
  if kind == "Frame" or kind == "Button" or kind == "EditBox" or kind == "ScrollFrame" then
    o.SetBackdrop = function() end
  end
  if name then _G[name] = o end
  return o
end
MOCK.NewObj = NewObj

function CreateFrame(kind, name)
  local o = NewObj(kind, name)
  table.insert(MOCK.frames, o)
  return o
end

DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) table.insert(MOCK.chat, m) end }
UIParent = NewObj("Frame")
UISpecialFrames = {}
BackdropTemplateMixin = {}
NUM_BAG_SLOTS = 4
SlashCmdList = {}
date = os.date
time = os.time
function GetTime() return MOCK.now end
C_Timer = {
  After = function(_, fn) table.insert(MOCK.pending, fn) end,
  NewTicker = function(_, fn) MOCK.ticker = fn; return {} end,
}
function InCombatLockdown() return false end
function ReloadUI() MOCK.reloads = MOCK.reloads + 1 end
function hooksecurefunc(name, fn)
  local orig = _G[name]
  _G[name] = function(...) orig(...); fn(...) end
end

function GetBuildInfo() return "1.15.9", "65000", "Jul 1 2026", 11509 end
function GetLocale() return "ruRU" end
function UnitName() return "Лунолист" end
function GetRealmName() return "Forever" end
function UnitClass() return "Друид", "DRUID" end
function UnitRace() return "Ночной эльф", "NightElf" end
function UnitFactionGroup() return "Alliance" end
function UnitLevel() return MOCK.level end
function UnitXP() return 1234 end
function UnitXPMax() return 4000 end
function GetXPExhaustion() return 1500 end
function IsResting() return false end
function GetMoney() return 12345 end
function UnitIsDeadOrGhost() return false end
function GetZoneText() return "Darkshore" end
function GetSubZoneText() return "Auberdine" end
C_Map = {
  GetBestMapForUnit = function() return 1439 end,
  GetPlayerMapPosition = function() return { GetXY = function() return 0.3651, 0.4521 end } end,
}
function GetItemCount(id) return id == 6948 and 1 or 0 end
function GetBindLocation() return "Auberdine" end
function IsPlayerSpell(id) return id == 18960 end
function GetSpellCooldown() return 0, 0, 1 end
function UnitCharacterPoints() return 1 end
function GetInventoryItemDurability(slot)
  if slot == 5 then return 20, 100 end
  if slot == 7 then return 70, 70 end
end
function GetNumShapeshiftForms() return 1 end
function GetItemInfo(link)
  return "Junk", link, 0, 1, 1, "Junk", "Junk", 20, "", "icon", 25
end

-- Сумки: рюкзак на 16 слотов, 2 свободно, 3 серых предмета
local function free(bag) if bag == 0 then return 2, 0 end return 0, 0 end
local function slots(bag) if bag == 0 then return 16 end return 0 end
local function iteminfo(bag, slot)
  if bag == 0 and slot <= 3 then return { quality = 0, stackCount = 2, hyperlink = "item:" .. slot, hasNoValue = false } end
  if bag == 0 and slot <= 14 then return { quality = 1, stackCount = 1, hyperlink = "item:99", hasNoValue = false } end
end

-- Квесты
local QUESTS = {
  { header = true, title = "Teldrassil" },
  { title = "Twisted Hatred", level = 10, id = 932, obj = { { "Lord Melenas: 0/1", false } } },
  { title = "Cleansing of the Infected", level = 14, id = 2138, obj = { { "Rabid Thistle Bear: 3/20", false } } },
  { title = "Flight to Auberdine", level = 10, id = 6342, obj = {} },
}

if MODE == "modern" then
  C_Container = {
    GetContainerNumFreeSlots = free,
    GetContainerNumSlots = slots,
    GetContainerItemInfo = iteminfo,
    GetItemCooldown = function() return MOCK.hsStart, MOCK.hsDur, 1 end,
  }
  C_QuestLog = {
    GetNumQuestLogEntries = function() return #QUESTS, #QUESTS - 1 end,
    GetInfo = function(i)
      local q = QUESTS[i]
      if q.header then return { title = q.title, isHeader = true } end
      return { title = q.title, level = q.level, questID = q.id, isHeader = false, suggestedGroup = 0 }
    end,
    IsComplete = function(id) return id == 2138 and MOCK.q3done == 1 end,
    GetQuestObjectives = function(id)
      for _, q in ipairs(QUESTS) do
        if q.id == id then
          local out = {}
          for _, o in ipairs(q.obj) do table.insert(out, { text = o[1], finished = o[2] }) end
          return out
        end
      end
    end,
  }
else
  GetContainerNumFreeSlots = free
  GetContainerNumSlots = slots
  function GetContainerItemInfo(bag, slot)
    local i = iteminfo(bag, slot)
    if i then return "icon", i.stackCount, false, i.quality, false, false, i.hyperlink, false, i.hasNoValue, 1 end
  end
  function GetItemCooldown() return MOCK.hsStart, MOCK.hsDur, 1 end
  function GetNumQuestLogEntries() return #QUESTS, #QUESTS - 1 end
  function GetQuestLogTitle(i)
    local q = QUESTS[i]
    if not q then return nil end
    if q.header then return q.title, 0, 0, true end
    local complete = (q.id == 2138) and MOCK.q3done or nil
    return q.title, q.level, 0, false, false, complete, 0, q.id
  end
  function GetNumQuestLeaderBoards(i) return QUESTS[i] and QUESTS[i].obj and #QUESTS[i].obj or 0 end
  function GetQuestLogLeaderBoard(j, i)
    local o = QUESTS[i].obj[j]
    return o[1], "monster", o[2]
  end
  -- Журнал квестов в стиле Classic: три видимые строки
  QUESTS_DISPLAYED = 3
  for n = 1, 3 do
    local b = NewObj("Button", "QuestLogTitle" .. n)
    b._id = n + 1
  end
  function QuestLog_Update()
    for n = 1, QUESTS_DISPLAYED do
      local b = _G["QuestLogTitle" .. n]
      b._text = "  [" .. QUESTS[b._id].level .. "] " .. QUESTS[b._id].title
    end
  end
end

function MOCK.Fire(ev, ...)
  for _, f in ipairs(MOCK.frames) do
    local h = f._scripts.OnEvent
    if h then h(f, ev, ...) end
  end
end

function MOCK.Flush()
  while #MOCK.pending > 0 do
    local p = MOCK.pending
    MOCK.pending = {}
    for _, fn in ipairs(p) do fn() end
  end
end

-- SavedVariables не умеют хранить функции и userdata: проверяем это
function MOCK.AssertSerializable(t, path, seen)
  seen = seen or {}
  assert(not seen[t], "cycle at " .. path)
  seen[t] = true
  for k, v in pairs(t) do
    local tk, tv = type(k), type(v)
    assert(tk == "string" or tk == "number", "bad key type at " .. path)
    assert(tv ~= "function" and tv ~= "userdata" and tv ~= "thread", "bad value " .. tv .. " at " .. path .. "." .. tostring(k))
    if tv == "table" then MOCK.AssertSerializable(v, path .. "." .. tostring(k), seen) end
  end
end
