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
function UnitName(u) if u == "target" then return "Plainstrider" end return "Лунолист" end
function GetRealmName() return "Forever" end
function UnitClass(u) if u == "party1" then return "Воин", "WARRIOR" end return "Друид", "DRUID" end
function UnitRace() return "Ночной эльф", "NightElf" end
function UnitFactionGroup() return "Alliance" end
function UnitLevel(u)
  if u == "target" then return 2 end
  if u == "party1" then return 11 end
  return MOCK.level
end

-- Состояние: здоровье 80%, мана 50%, цель - обычный враждебный моб, в группе один воин
MOCK.target = true
function UnitExists(u) return u == "player" or u == "party1" or (u == "target" and MOCK.target) end
function UnitHealth(u) return u == "target" and 100 or 80 end
function UnitHealthMax() return 100 end
function UnitPower() return 50 end
function UnitPowerMax() return 100 end
function UnitClassification() return "normal" end
function UnitCanAttack() return true end
function UnitIsDead() return false end
function UnitIsPlayer() return false end
function UnitIsConnected() return true end
function GetNumGroupMembers() return 2 end
function IsInRaid() return false end
local STATS = { 20, 15, 22, 18, 21 }
function UnitStat(_, i) return STATS[i] - 2, STATS[i] end
function UnitArmor() return 40, 50 end
FACTION_STANDING_LABEL5 = "Friendly"
function UnitXP() return 1234 end
function UnitXPMax() return 4000 end
function GetXPExhaustion() return 1500 end
function IsResting() return false end
function GetMoney() return 12345 end
function UnitIsDeadOrGhost() return false end
function GetZoneText() return "Darkshore" end
function GetSubZoneText() return "Auberdine" end
MOCK.px, MOCK.py = 0.3651, 0.4521
C_Map = {
  GetBestMapForUnit = function() return 1439 end,
  GetPlayerMapPosition = function() return { GetXY = function() return MOCK.px, MOCK.py end } end,
}

-- База Questie (QuestieDB + ZoneDB из Questie): зона 148 -> карта 1439.
-- Twisted Hatred (932): цель - NPC 2000, принимает NPC 3000
MOCK.completed = {}
NpcDB = {
  Get = function(id, key)
    if key ~= "spawns" then return nil end
    if id == 2000 then return { [148] = { { 70, 80 }, { 40, 50 } } } end
    if id == 3000 then return { [148] = { { 37, 44 } } } end
  end,
}
QuestDB = {
  Get = function(id, key)
    if id == 932 and key == "objectives" then return { { { 2000, nil, 1 } } } end
    if id == 932 and key == "finishedBy" then return { { 3000 } } end
  end,
}
QuestieLoader = {
  ImportModule = function(_, name)
    if name == "ZoneDB" then
      return { GetUiMapIdByAreaId = function(_, areaId) return areaId == 148 and 1439 or nil end }
    end
  end,
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

-- Экипировка: надеты голова, грудь и посох, остальные 14 слотов пусты
local GEAR = { [1] = 90001, [5] = 90002, [16] = 90003 }
-- name, quality, iLvl, требуемый уровень, classID, слот
local ITEMS = {
  [90001] = { "Test Cap", 2, 12, 1, 4, "INVTYPE_HEAD" },
  [90002] = { "Test Robe", 1, 5, 1, 4, "INVTYPE_ROBE" },
  [90003] = { "Test Staff", 3, 15, 1, 2, "INVTYPE_2HWEAPON" },
  [99] = { "Test Water", 1, 5, 1, 0, "INVTYPE_NON_EQUIP_IGNORE" }, -- так Classic Era помечает неэкипируемое
  [90010] = { "Test Quest Item", 1, 1, 1, 12, "" },
  [90011] = { "Test Boots", 2, 8, 6, 4, "INVTYPE_FEET" },
  [90020] = { "Test Bank Ore", 1, 10, 1, 7, "" },
}
local function LinkID(link) return tonumber(tostring(link):match("item:(%d+)")) end
function GetInventoryItemLink(_, slot)
  local id = GEAR[slot]
  if id then return "|cffffffff|Hitem:" .. id .. "::::::::9:::::::|h[" .. ITEMS[id][1] .. "]|h|r" end
end
function GetItemInfo(link)
  local it = ITEMS[LinkID(link)]
  if it then return it[1], link, it[2], it[3], it[4], "Armor", "Cloth", 1, it[6], "icon", 10 end
  return "Junk", link, 0, 1, 1, "Junk", "Junk", 20, "", "icon", 25
end
function GetItemInfoInstant(link)
  local id = LinkID(link)
  local it = ITEMS[id]
  if it then return id, "Type", "Sub", it[6], "icon", it[5] end
  return id, "Junk", "Junk", "", "icon", 15
end

-- Баффы и дебаффы: name, count, duration, expires
local AURAS = {
  HELPFUL = { { "Mark of the Wild", 0, 1800, 1700 } },
  HARMFUL = { { "Resurrection Sickness", 0, 600, 300 } },
}
local function Aura(i, filter)
  local a = AURAS[filter] and AURAS[filter][i]
  if a then return a[1], a[2], a[3], MOCK.now + a[4] end
end

-- Репутация: name, standing, barMin, barMax, value, isHeader, isCollapsed, hasRep
local FACTIONS = {
  { "Alliance", 0, 0, 0, 0, true, false, false },
  { "Darnassus", 5, 3000, 9000, 4200, false, false, true },
  { "Other", 0, 0, 0, 0, true, true, false },
}

-- Таланты: в Feral Combat вложено 5 очков
local TALENTS = {
  { "Balance", { { "Improved Wrath", 0, 5 } } },
  { "Feral Combat", { { "Ferocity", 5, 5 }, { "Feral Instinct", 0, 5 } } },
  { "Restoration", { { "Improved Mark of the Wild", 0, 5 } } },
}
function GetNumTalentTabs() return #TALENTS end
function GetNumTalents(tab) return #TALENTS[tab][2] end
function GetTalentInfo(tab, i)
  local t = TALENTS[tab][2][i]
  return t[1], "icon", 1, i, t[2], t[3]
end
function GetTalentTabInfo(tab)
  local t = TALENTS[tab]
  if MODE == "modern" then return 280 + tab, t[1], "desc", "icon", 0 end -- порядок как в Wrath и новее
  return t[1], "icon", 0, "file"
end

-- Книга заклинаний: Wrath в двух рангах, одна пассивка; в modern ещё и не изученный Starfire
local SPELLS = {
  { "General", { { "Attack" }, { "Nature Resistance", "Racial Passive", passive = true } } },
  { "Balance", { { "Wrath", "Rank 1" }, { "Wrath", "Rank 2" }, { "Moonfire", "Rank 1" }, { "Starfire", "Rank 1", future = true } } },
  { "Feral Combat", { { "Bear Form", "Shapeshift" } } },
}
local BOOK, TABS = {}, {}
for _, tab in ipairs(SPELLS) do
  local offset = #BOOK
  for _, sp in ipairs(tab[2]) do
    if MODE == "modern" or not sp.future then BOOK[#BOOK + 1] = sp end
  end
  TABS[#TABS + 1] = { name = tab[1], offset = offset, num = #BOOK - offset }
end

-- Сумки: рюкзак на 16 слотов, 2 свободно, 3 серых предмета, 9 воды, квестовый предмет и сапоги.
-- Банк (контейнер -1) виден, только пока MOCK.bankOpen
local function free(bag) if bag == 0 then return 2, 0 end return 0, 0 end
local function slots(bag)
  if MOCK.unloaded then return 0 end -- выход из игры: сумки уже выгружены
  if bag == 0 then return 16 end
  if bag == -1 and MOCK.bankOpen then return 24 end
  return 0
end
local function bagname(bag) if bag == 0 then return "Backpack" end end
local function iteminfo(bag, slot)
  if bag == -1 and slot <= 2 then return { quality = 1, stackCount = slot == 1 and 5 or 3, hyperlink = "item:90020" } end
  if bag ~= 0 then return nil end
  if slot <= 3 then return { quality = 0, stackCount = 2, hyperlink = "item:" .. slot, hasNoValue = false } end
  if slot <= 12 then return { quality = 1, stackCount = 1, hyperlink = "item:99", hasNoValue = false } end
  if slot == 13 then return { quality = 1, stackCount = 1, hyperlink = "item:90010", hasNoValue = true } end
  if slot == 14 then return { quality = 2, stackCount = 1, hyperlink = "item:90011", hasNoValue = false } end
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
    GetBagName = bagname,
    GetItemCooldown = function() return MOCK.hsStart, MOCK.hsDur, 1 end,
  }
  C_QuestLog = {
    GetNumQuestLogEntries = function() return #QUESTS, #QUESTS - 1 end,
    GetInfo = function(i)
      local q = QUESTS[i]
      if q.header then return { title = q.title, isHeader = true } end
      return { title = q.title, level = q.level, questID = q.id, isHeader = false, suggestedGroup = 0 }
    end,
    IsComplete = function(id) return (id == 2138 and MOCK.q3done == 1) or (id == 932 and MOCK.q1done == 1) end,
    IsQuestFlaggedCompleted = function(id) return MOCK.completed[id] or false end,
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
  Enum = { SpellBookSpellBank = { Player = 0 }, SpellBookItemType = { Spell = 1, FutureSpell = 2 } }
  C_SpellBook = {
    GetNumSpellBookSkillLines = function() return #TABS end,
    GetSpellBookSkillLineInfo = function(t)
      return { name = TABS[t].name, itemIndexOffset = TABS[t].offset, numSpellBookItems = TABS[t].num }
    end,
    GetSpellBookItemName = function(i) return BOOK[i][1], BOOK[i][2] end,
    GetSpellBookItemType = function(i) return BOOK[i].future and 2 or 1, 0 end,
    IsSpellBookItemPassive = function(i) return BOOK[i].passive or false end,
  }
  C_UnitAuras = {
    GetAuraDataByIndex = function(_, i, filter)
      local name, count, duration, expires = Aura(i, filter)
      if name then return { name = name, applications = count, duration = duration, expirationTime = expires } end
    end,
  }
  C_Reputation = {
    GetNumFactions = function() return #FACTIONS end,
    GetFactionDataByIndex = function(i)
      local f = FACTIONS[i]
      return {
        name = f[1], reaction = f[2], currentReactionThreshold = f[3], nextReactionThreshold = f[4],
        currentStanding = f[5], isHeader = f[6], isCollapsed = f[7], isHeaderWithRep = f[6] and f[8],
      }
    end,
  }
  -- Стрелка TomTom (в classic её нет: расстояние считается по размеру карты)
  MOCK.tomtomDist = 500
  TomTom = {
    AddWaypoint = function(_, map, x, y, opts)
      MOCK.waypoint = { map = map, x = x, y = y, opts = opts }
      return MOCK.waypoint
    end,
    RemoveWaypoint = function(_, uid) if MOCK.waypoint == uid then MOCK.waypoint = nil end end,
    GetDistanceToWaypoint = function() return MOCK.tomtomDist end,
  }
  function GetProfessions() return 1, nil, nil, nil, 2 end
  function GetProfessionInfo(i)
    if i == 1 then return "Herbalism", "icon", 45, 75 end
    if i == 2 then return "Cooking", "icon", 10, 75 end
  end
else
  GetContainerNumFreeSlots = free
  GetContainerNumSlots = slots
  GetBagName = bagname
  function IsQuestFlaggedCompleted(id) return MOCK.completed[id] or false end
  C_Map.GetMapWorldSize = function() return 4000, 2600 end
  function UnitAura(_, i, filter)
    local name, count, duration, expires = Aura(i, filter)
    if name then return name, "icon", count, nil, duration, expires end
  end
  function GetNumFactions() return #FACTIONS end
  function GetFactionInfo(i)
    local f = FACTIONS[i]
    return f[1], "desc", f[2], f[3], f[4], f[5], false, false, f[6], f[7], f[8]
  end
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
    local complete = (q.id == 2138 and MOCK.q3done) or (q.id == 932 and MOCK.q1done) or nil
    return q.title, q.level, 0, false, false, complete, 0, q.id
  end
  function GetNumQuestLeaderBoards(i) return QUESTS[i] and QUESTS[i].obj and #QUESTS[i].obj or 0 end
  function GetQuestLogLeaderBoard(j, i)
    local o = QUESTS[i].obj[j]
    return o[1], "monster", o[2]
  end
  function GetNumSpellTabs() return #TABS end
  function GetSpellTabInfo(t) return TABS[t].name, "icon", TABS[t].offset, TABS[t].num end
  function GetSpellBookItemName(i) return BOOK[i][1], BOOK[i][2] end
  function IsPassiveSpell(i) return BOOK[i].passive and 1 or nil end
  -- Навыки: доспехи 1/1 пропускаются, оружейные навыки свёрнуты
  local SKILLS = {
    { "Professions", true, true },
    { "Herbalism", false, false, 45, 0, 0, 75 },
    { "Armor Proficiencies", true, true },
    { "Leather", false, false, 1, 0, 0, 1 },
    { "Weapon Skills", true, false },
  }
  function GetNumSkillLines() return #SKILLS end
  function GetSkillLineInfo(i) return unpack(SKILLS[i]) end
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
