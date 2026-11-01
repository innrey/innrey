-- ForeverCoach: гид по шагам от Claude со стрелкой TomTom.
-- Шаги пишет Claude в Plan.lua (поле guide). Аддон сам отмечает выполненные шаги по журналу
-- квестов, уровню и приходу в точку и переводит стрелку дальше. За игрока ничего не делает.
-- Точки: явные координаты из шага или места из базы Questie (QuestDB/NpcDB от QuestieDB,
-- перевод зон в карты - ZoneDB из Questie).
local ADDON, ns = ...

local ARRIVE_YARDS = 15
local DIRS = { "север", "северо-восток", "восток", "юго-восток", "юг", "юго-запад", "запад", "северо-запад" }

local function Guide()
  local P = ns.Plan()
  local g = P and P.guide
  if type(g) ~= "table" or type(g.steps) ~= "table" or #g.steps == 0 then return nil end
  if g.char and g.char ~= UnitName("player") then return nil end
  return g
end

-- Прогресс хранится в SavedVariables: после /reload гид продолжает с того же шага.
-- Новый guide.at от Claude - начинаем сначала (выполненные шаги пролистаются сами).
local function Progress(g)
  local p = ns.char.guide
  if not p or p.at ~= tostring(g.at) then
    p = { at = tostring(g.at), step = 1 }
    ns.char.guide = p
  end
  return p
end

---------------------------------------------------------------------------
-- Выполнен ли шаг
---------------------------------------------------------------------------
local function QuestInLog(id)
  for _, q in ipairs(ns.state and ns.state.quests or {}) do
    if q.id == id then return q end
  end
end

local function QuestTurnedIn(id)
  if ns.turnedIn[id] then return true end
  local f = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
  return (f and f(id)) and true or false
end

-- true/false по журналу квестов и уровню; nil - условие только приход в точку или /fc next
local function StepDone(st)
  if st.turnin then return QuestTurnedIn(st.turnin) end
  if st.complete then
    local q = QuestInLog(st.complete)
    return (q and q.done) and true or QuestTurnedIn(st.complete)
  end
  if st.accept then return QuestInLog(st.accept) ~= nil or QuestTurnedIn(st.accept) end
  if st.level then return (UnitLevel("player") or 0) >= st.level end
  return nil
end

---------------------------------------------------------------------------
-- Где игрок и далеко ли точка
---------------------------------------------------------------------------
local function PlayerPos()
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
  local map = C_Map.GetBestMapForUnit("player")
  local pos = map and C_Map.GetPlayerMapPosition(map, "player")
  if not pos then return nil end
  local x, y = pos:GetXY()
  if not x or not y then return nil end
  return map, x * 100, y * 100
end

local function Distance(point)
  if ns.waypoint and TomTom and TomTom.GetDistanceToWaypoint then
    local d = TomTom:GetDistanceToWaypoint(ns.waypoint)
    if d then return d end
  end
  local pm, px, py = PlayerPos()
  if pm ~= point.map or not (C_Map.GetMapWorldSize) then return nil end
  local w, h = C_Map.GetMapWorldSize(pm)
  if not w or w <= 0 then return nil end
  return math.sqrt(((point.x - px) / 100 * w) ^ 2 + ((point.y - py) / 100 * h) ^ 2)
end

local function Direction(point)
  local pm, px, py = PlayerPos()
  if pm ~= point.map then return nil end
  local a = math.atan2(point.x - px, py - point.y) -- 0 = север, по часовой стрелке
  return DIRS[math.floor(a / (2 * math.pi) * 8 + 0.5) % 8 + 1]
end

local function Arrived(st, point)
  if not point then return false end
  local d = Distance(point)
  if d then return d <= (st.radius or ARRIVE_YARDS) end
  -- размер карты неизвестен: ~0.6% карты зоны, это 15-25 ярдов
  local pm, px, py = PlayerPos()
  return pm == point.map and ((point.x - px) ^ 2 + (point.y - py) ^ 2) < 0.36
end

---------------------------------------------------------------------------
-- Точка шага: явные координаты или ближайшее место из базы Questie
---------------------------------------------------------------------------
local function ZoneDB()
  if not (QuestieLoader and QuestieLoader.ImportModule) then return nil end
  local ok, z = pcall(QuestieLoader.ImportModule, QuestieLoader, "ZoneDB")
  if ok and type(z) == "table" and z.GetUiMapIdByAreaId then return z end
end

-- spawns из Questie: { [areaId] = { {x, y}, ... } }, координаты 0-100; -1 - внутри подземелья
local function AddSpawns(out, zones, spawns)
  if type(spawns) ~= "table" then return end
  for areaId, coords in pairs(spawns) do
    local map = zones:GetUiMapIdByAreaId(areaId)
    if map and map > 0 and type(coords) == "table" then
      for _, c in ipairs(coords) do
        if type(c[1]) == "number" and c[1] >= 0 and type(c[2]) == "number" then
          out[#out + 1] = { map = map, x = c[1], y = c[2] }
        end
      end
    end
  end
end

local function AddEntities(out, zones, db, ids)
  if not (db and db.Get) or type(ids) ~= "table" then return end
  for _, id in ipairs(ids) do AddSpawns(out, zones, db.Get(id, "spawns")) end
end

local function QuestiePoints(st)
  local zones = ZoneDB()
  if not (zones and NpcDB and QuestDB) then return nil end
  local out = {}
  if st.npc then AddEntities(out, zones, NpcDB, { st.npc }) end
  if st.object then AddEntities(out, zones, ObjectDB, { st.object }) end
  if #out > 0 then return out end
  if st.turnin or st.accept then
    -- startedBy: { NPC, объекты, предметы }; finishedBy: { NPC, объекты }
    local who = QuestDB.Get(st.turnin or st.accept, st.turnin and "finishedBy" or "startedBy")
    if type(who) == "table" then
      AddEntities(out, zones, NpcDB, who[1])
      AddEntities(out, zones, ObjectDB, who[2])
    end
  elseif st.complete then
    -- objectives: { существа {id, текст, n}, объекты, предметы, ... }
    local obj = QuestDB.Get(st.complete, "objectives")
    if type(obj) == "table" then
      for _, c in ipairs(obj[1] or {}) do AddEntities(out, zones, NpcDB, { c[1] }) end
      for _, o in ipairs(obj[2] or {}) do AddEntities(out, zones, ObjectDB, { o[1] }) end
      for _, it in ipairs(obj[3] or {}) do
        if ItemDB and ItemDB.Get then
          AddEntities(out, zones, NpcDB, ItemDB.Get(it[1], "npcDrops"))
          AddEntities(out, zones, ObjectDB, ItemDB.Get(it[1], "objectDrops"))
        end
      end
    end
    if #out == 0 then
      -- квесты «дойти до места»: triggerEnd = { текст, spawns }
      local trigger = QuestDB.Get(st.complete, "triggerEnd")
      if type(trigger) == "table" then AddSpawns(out, zones, trigger[2]) end
    end
  end
  return out
end

local function Nearest(points)
  local pm, px, py = PlayerPos()
  local best, bestD
  for _, p in ipairs(points) do
    local d = (p.map == pm and px) and ((p.x - px) ^ 2 + (p.y - py) ^ 2) or math.huge
    if not best or d < bestD then best, bestD = p, d end
  end
  return best
end

local function Point(st)
  if st.map and st.x and st.y then return { map = st.map, x = st.x, y = st.y } end
  local points = QuestiePoints(st)
  return points and #points > 0 and Nearest(points) or nil
end

---------------------------------------------------------------------------
-- Стрелка TomTom
---------------------------------------------------------------------------
local function SetArrow(point, title)
  if not (TomTom and TomTom.AddWaypoint) then return end
  if ns.waypoint and TomTom.RemoveWaypoint then pcall(TomTom.RemoveWaypoint, TomTom, ns.waypoint) end
  ns.waypoint = nil
  if point then
    ns.waypoint = TomTom:AddWaypoint(point.map, point.x / 100, point.y / 100, {
      title = title, from = ADDON, persistent = false, crazy = true, silent = true,
      cleardistance = 0, -- шаг закрывает ForeverCoach, а не TomTom
    })
  end
end

local function Activate(g, p)
  local st = g.steps[p.step]
  ns.guideTries = 0
  ns.guidePoint = st and Point(st) or nil
  SetArrow(ns.guidePoint, st and st.text)
end

---------------------------------------------------------------------------
-- Проверка шагов: из ns.Update (квесты, уровень) и раз в секунду из ns.Tick (приход в точку)
---------------------------------------------------------------------------
function ns.GuideCheck()
  local g = ns.char and Guide()
  if not g then
    if ns.waypoint then SetArrow(nil) end
    ns.guideKey = nil
    return
  end
  local p = Progress(g)
  local key = p.at .. ":" .. p.step
  if ns.guideKey ~= key then Activate(g, p) end

  local advanced = false
  while p.step <= #g.steps do
    local st = g.steps[p.step]
    local done = StepDone(st)
    if done == nil then done = Arrived(st, ns.guidePoint) end
    if not done then break end
    p.step = p.step + 1
    advanced = true
    Activate(g, p)
  end
  ns.guideKey = p.at .. ":" .. p.step

  if advanced then
    if p.step > #g.steps then
      ns.Print("|cff33ff33Гид пройден.|r Спроси Claude, куда дальше, и сделай /fc sync.")
    else
      ns.Print(string.format("|cffffd100Шаг %d/%d:|r %s", p.step, #g.steps, g.steps[p.step].text))
    end
  end

  -- База Questie догружается после входа: пока точки нет, пробуем ещё (до 30 раз)
  if p.step <= #g.steps and not ns.guidePoint and (ns.guideTries or 0) < 30 then
    ns.guideTries = (ns.guideTries or 0) + 1
    ns.guidePoint = Point(g.steps[p.step])
    if ns.guidePoint then SetArrow(ns.guidePoint, g.steps[p.step].text) end
  end
end

function ns.GuideNext()
  local g = ns.char and Guide()
  if not g then
    ns.Print("Гида нет: спроси Claude «куда дальше» и сделай /fc sync.")
    return
  end
  local p = Progress(g)
  if p.step <= #g.steps then p.step = p.step + 1 end
  ns.guideKey = nil
  ns.GuideCheck()
  ns.GuideShow()
end

function ns.GuideShow()
  local gs = ns.GuideStatus()
  if not gs then
    ns.Print("Гида нет: спроси Claude «куда дальше» и сделай /fc sync.")
  elseif gs.done then
    ns.Print("Гид пройден. Спроси Claude, куда дальше.")
  else
    ns.Print(string.format("|cffffd100Шаг %d/%d:|r %s%s", gs.step, gs.total, gs.text,
      gs.where and (" (" .. gs.where .. ")") or ""))
    if ns.guidePoint then SetArrow(ns.guidePoint, gs.text) end
  end
end

-- Для окна и снимка: текущий шаг, прогресс цели квеста, расстояние и направление
function ns.GuideStatus()
  local g = ns.char and Guide()
  if not g then return nil end
  local p = Progress(g)
  local total = #g.steps
  if p.step > total then return { done = true, total = total, at = g.at } end
  local st = g.steps[p.step]
  local gs = { step = p.step, total = total, text = tostring(st.text), at = g.at }
  local q = st.complete and QuestInLog(st.complete)
  if q then
    for _, o in ipairs(q.obj) do
      if not o.done then
        gs.objective = o.text
        break
      end
    end
  end
  local point = ns.guidePoint
  local parts = {}
  if point then
    local d, dir = Distance(point), Direction(point)
    if d then parts[#parts + 1] = string.format("%d ярд.", math.floor(d + 0.5)) end
    if dir then parts[#parts + 1] = "на " .. dir end
    if not d and not dir then parts[#parts + 1] = string.format("карта %s: %.1f, %.1f", point.map, point.x, point.y) end
    gs.point = point
  elseif st.npc or st.object or st.accept or st.turnin or st.complete or st.map then
    parts[#parts + 1] = "точка не найдена: нужен Questie или координаты от Claude"
  end
  if gs.objective then table.insert(parts, 1, gs.objective) end
  gs.where = #parts > 0 and table.concat(parts, ", ") or nil
  return gs
end
