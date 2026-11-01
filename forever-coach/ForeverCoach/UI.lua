-- ForeverCoach: окно подсказок, окно копирования статуса, метки в журнале квестов.
local ADDON, ns = ...

local FONT = ns.FONT
local WIDTH = 330
local BACKDROP = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local frame, body, copyFrame, copyBox

local function Template()
  return BackdropTemplateMixin and "BackdropTemplate" or nil
end

local function Decorate(f)
  if f.SetBackdrop then
    f:SetBackdrop(BACKDROP)
    f:SetBackdropColor(0, 0, 0, 0.8)
    f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  end
end

local function Color(hex, text)
  return "|cff" .. hex .. text .. "|r"
end

local function MakeDraggable(f, savePosition)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self)
    if not (ns.db and ns.db.ui.locked) then self:StartMoving() end
  end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if savePosition and ns.db then
      local point, _, relPoint, x, y = self:GetPoint()
      ns.db.ui.point, ns.db.ui.relPoint, ns.db.ui.x, ns.db.ui.y = point, relPoint, x, y
    end
  end)
end

---------------------------------------------------------------------------
-- Основное окно
---------------------------------------------------------------------------
function ns.CreateUI()
  if frame then return end
  local ui = ns.db and ns.db.ui or {}

  frame = CreateFrame("Frame", "ForeverCoachFrame", UIParent, Template())
  frame:SetWidth(WIDTH)
  frame:SetHeight(120)
  frame:SetFrameStrata("MEDIUM")
  Decorate(frame)
  if ui.point then
    frame:SetPoint(ui.point, UIParent, ui.relPoint or ui.point, ui.x or 0, ui.y or 0)
  else
    frame:SetPoint("RIGHT", UIParent, "RIGHT", -40, 120)
  end
  MakeDraggable(frame, true)

  body = frame:CreateFontString(nil, "OVERLAY")
  body:SetFont(FONT, 12, "")
  body:SetPoint("TOPLEFT", 10, -10)
  body:SetWidth(WIDTH - 20)
  body:SetJustifyH("LEFT")
  body:SetJustifyV("TOP")

  local function Button(label, xOffset, onClick)
    local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    b:SetSize(64, 18)
    b:SetPoint("BOTTOMRIGHT", xOffset, 6)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    return b
  end
  Button("Sync", -8, function() ns.Sync() end)
  Button("Copy", -76, function() ns.ShowCopy() end)

  if ui.hidden then frame:Hide() end
  ns.RefreshUI()
  ns.HookQuestLog()
end

function ns.Toggle()
  if not frame then ns.CreateUI() end
  if frame:IsShown() then
    frame:Hide()
    ns.db.ui.hidden = true
  else
    frame:Show()
    ns.db.ui.hidden = nil
    ns.RefreshUI()
  end
end

function ns.RefreshUI()
  if not frame or not frame:IsShown() then return end
  local s = ns.state
  if not s then
    body:SetText("ForeverCoach: жду данные...")
    frame:SetHeight(60)
    return
  end
  local P = ns.Plan() or {}
  local A = P.alerts or {}
  local L = {}

  local pct = s.xpMax > 0 and math.floor(s.xp / s.xpMax * 100) or 0
  local rest = s.xpMax > 0 and math.floor((s.rested or 0) / s.xpMax * 100) or 0
  L[#L + 1] = Color("33ff99", "ForeverCoach") ..
    string.format("   ур. %d  %d%%   отдых %d%%%s", s.level, pct, rest, s.resting and " (таверна)" or "")

  local gs = ns.GuideStatus and ns.GuideStatus()
  if gs and gs.done then
    L[#L + 1] = Color("33ff33", "Гид пройден - спроси Claude, куда дальше")
  elseif gs then
    L[#L + 1] = Color("ffd100", string.format("Шаг %d/%d: ", gs.step, gs.total)) .. gs.text
    if gs.where then L[#L + 1] = "   " .. gs.where end
  end

  local hs = s.hsHave and ns.Clock(s.hsCD) or "нет в сумках"
  if s.hsCD == 0 then hs = Color("33ff33", hs) end
  local line = "ХС: " .. hs .. " (" .. tostring(s.hsBind) .. ")"
  if s.tpCD then
    local tp = ns.Clock(s.tpCD)
    if s.tpCD == 0 then tp = Color("33ff33", tp) end
    line = line .. "   Телепорт: " .. tp
  end
  L[#L + 1] = line

  local bags = string.format("Сумки: свободно %d из %d", s.bagFree, s.bagTotal)
  if s.bagFree <= (A.bagFreeMin or 3) then bags = Color("ff5555", bags) end
  if s.junk > 0 then bags = bags .. string.format("   серое: %d (~%s)", s.junk, ns.Money(s.junkValue)) end
  L[#L + 1] = bags

  if s.talents and s.talents > 0 then
    L[#L + 1] = Color("ffd100", "! Свободные очки талантов: " .. s.talents)
  end
  if s.questsReady > 0 then
    L[#L + 1] = Color("ffd100", "! Готово к сдаче: " .. s.questsReady)
  end
  if s.durMin and s.durMin < (A.durabilityMin or 0.3) * 100 then
    L[#L + 1] = Color("ff5555", "! Прочность: " .. s.durMin .. "%")
  end
  if (s.questsHidden or 0) > 0 then
    L[#L + 1] = Color("ff5555", "! Разверни заголовки в журнале квестов (скрыто: " .. s.questsHidden .. ")")
  end
  if not ns.Plan() then
    L[#L + 1] = Color("ff5555", "! Plan.lua не загрузился")
  end

  local now, stale = ns.PlanNow(s)
  if now and type(now.steps) == "table" then
    L[#L + 1] = " "
    L[#L + 1] = Color("88ccff", "План Claude" .. (now.at and (" (" .. now.at .. ")") or "") .. ":") ..
      (stale and Color("ff5555", " устарел - /fc sync") or "")
    for i, step in ipairs(now.steps) do
      L[#L + 1] = i .. ". " .. tostring(step)
    end
  end
  if not now or stale then
    local r = ns.RouteFor(s.level)
    if r then
      L[#L + 1] = " "
      L[#L + 1] = Color("88ccff", string.format("Маршрут %d-%d: %s", r.min, r.max, tostring(r.zone)))
      L[#L + 1] = tostring(r.text)
    end
  end

  local skips = {}
  for _, q in ipairs(s.quests) do
    if q.tag == "skip" then skips[#skips + 1] = tostring(q.title) end
  end
  if #skips > 0 then
    L[#L + 1] = " "
    L[#L + 1] = Color("ff7777", "Можно бросить: ") .. table.concat(skips, ", ")
  end

  body:SetText(table.concat(L, "\n"))
  frame:SetHeight((body:GetStringHeight() or 80) + 40)
end

---------------------------------------------------------------------------
-- Окно копирования статуса (для вставки в чат с Claude)
---------------------------------------------------------------------------
function ns.ShowCopy(text)
  if not text then
    ns.SafeCall(ns.Update)
    text = ns.char and ns.char.text or ""
  end
  if not copyFrame then
    copyFrame = CreateFrame("Frame", "ForeverCoachCopyFrame", UIParent, Template())
    copyFrame:SetSize(560, 380)
    copyFrame:SetPoint("CENTER")
    copyFrame:SetFrameStrata("DIALOG")
    Decorate(copyFrame)
    MakeDraggable(copyFrame, false)

    local title = copyFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 13, "")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("Ctrl+A, Ctrl+C - и вставь в чат с Claude. Esc - закрыть.")

    local close = CreateFrame("Button", nil, copyFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    local scroll = CreateFrame("ScrollFrame", "ForeverCoachCopyScroll", copyFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -32)
    scroll:SetPoint("BOTTOMRIGHT", -32, 12)

    copyBox = CreateFrame("EditBox", nil, scroll)
    copyBox:SetMultiLine(true)
    copyBox:SetMaxLetters(0)
    copyBox:SetAutoFocus(true)
    copyBox:SetFont(FONT, 12, "")
    copyBox:SetWidth(500)
    copyBox:SetHeight(330)
    copyBox:SetScript("OnEscapePressed", function() copyFrame:Hide() end)
    scroll:SetScrollChild(copyBox)

    table.insert(UISpecialFrames, "ForeverCoachCopyFrame")
  end
  copyBox:SetText(text)
  copyFrame:Show()
  copyBox:SetFocus()
  copyBox:HighlightText()
end

---------------------------------------------------------------------------
-- Метки в стандартном журнале квестов (если его интерфейс как в Classic)
---------------------------------------------------------------------------
local LABELS = {
  skip = "|cffff5555[SKIP]|r",
  opt = "|cffffd100[?]|r",
  key = "|cff33ff33[!]|r",
}

function ns.HookQuestLog()
  if ns.questLogHooked or type(QuestLog_Update) ~= "function" or not GetQuestLogTitle then return end
  ns.questLogHooked = true
  hooksecurefunc("QuestLog_Update", function()
    for i = 1, (QUESTS_DISPLAYED or 0) do
      local button = _G["QuestLogTitle" .. i]
      if button and button:IsShown() and button.GetID then
        local ok, title, _, _, isHeader, _, _, _, questID = pcall(GetQuestLogTitle, button:GetID())
        if ok and title and not isHeader then
          local tag = ns.TagFor(questID, title)
          local label = tag and LABELS[tag]
          local text = button:GetText() or ""
          if label and not text:find(label, 1, true) then
            button:SetText(text .. " " .. label)
          end
        end
      end
    end
  end)
end
