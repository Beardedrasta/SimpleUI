--[[
SimpleUI Range Checker for WoW Vanilla 1.12 - Turtle WoW
Author: BeardedRasta
Description: A tooltip scanning utility for extracting and analyzing tooltip text and attributes.
--]]

-- Setup Environments
local U = SimpleUI.Util;
local _G = getfenv(0);

if U.range then return end

local _, class = UnitClass("player");
local druid = class == "DRUID"
local targetEvent = TargetFrame_OnEvent
local range = CreateFrame("Frame", "SimpleUIRangeChecker", UIParent);

local insert = table.insert;
local getn = table.getn;
local target_noop = function() return end

local units = {};
local unitcache = {};
local unitdata = {};
local cAvail

local play = PlaySound
local off = function() return end

range.id = 1

local spells = {
    ["PALADIN"] = {
        "Interface\\Icons\\Spell_Holy_FlashHeal",
        "Interface\\Icons\\Spell_Holy_HolyBolt",
    },
    ["PRIEST"] = {
        "Interface\\Icons\\Spell_Holy_FlashHeal",
        "Interface\\Icons\\Spell_Holy_LesserHeal",
        "Interface\\Icons\\Spell_Holy_Heal",
        "Interface\\Icons\\Spell_Holy_GreaterHeal",
        "Interface\\Icons\\Spell_Holy_Renew",
    },
    ["DRUID"] = {
        "Interface\\Icons\\Spell_Nature_HealingTouch",
        "Interface\\Icons\\Spell_Nature_ResistNature",
        "Interface\\Icons\\Spell_Nature_Rejuvenation",
    },
    ["SHAMAN"] = {
        "Interface\\Icons\\Spell_Nature_MagicImmunity",
        "Interface\\Icons\\Spell_Nature_HealingWaveLesser",
        "Interface\\Icons\\Spell_Nature_HealingWaveGreater",
    },
};

local events = {
    "ACTIONBAR_SLOT_CHANGED",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_ENTER_COMBAT",
    "PLAYER_LEAVE_COMBAT"
}

local function addUnits(prefix, count)
    for i = 1, count do
        insert(units, prefix .. i)
    end
end
insert(units, "pet")
addUnits("party", 4)
addUnits("partypet", 4)
addUnits("raid", 40)
addUnits("raidpet", 40)
local numunits = getn(units)

local auto = CreateFrame("Frame", "SimpleUIAutoDetection")
auto:RegisterEvent("START_AUTOREPEAT_SPELL")
auto:RegisterEvent("STOP_AUTOREPEAT_SPELL")
auto:SetScript("OnEvent", function()
    PlayerFrame.wandCombat = event == "START_AUTOREPEAT_SPELL" and true or nil
end)

local c = CreateFrame("Frame", "SimpleUIcAvailDetect")
c:RegisterEvent("PLAYER_COMBO_POINTS")
c:SetScript("OnEvent", function()
    cAvail = GetComboPoints() > 0
end)

range:Hide()
for _, event in ipairs(events) do
    range:RegisterEvent(event)
end
range:SetScript("OnEvent", function()
    if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].rangecheck == 0 or not spells[class] then
        this:Hide()
        return
    end
    this.interval = 4 / numunits
    if event == "ACTIONBAR_SLOT_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        range.slot = this:GetRangeSlot()
        this:Show()
    elseif event == "PLAYER_ENTER_COMBAT" then
        this.lastattack = GetTime()
        this:Hide()
    elseif event == "PLAYER_LEAVE_COMBAT" then
        if not this:ReAttack() then
            this:Show()
        end
    end
end)

range:SetScript("OnUpdate", function()
    if (this.tick or 1) > GetTime() then
        return
    else
        this.tick = GetTime() + this.interval
    end

    while not this:NeedRangeScan(units[this.id]) and this.id <= numunits do
        this.id = this.id + 1
    end

    if this.id <= numunits and range.slot then
        local unit = units[this.id]
        if not UnitIsUnit("target", unit) then
            if SUPERWOW_VERSION then
                local x1, y1, z1 = UnitPosition("player")
                local x2, y2, z2 = UnitPosition(unit)
                -- only continue if we got position values
                if x1 and y1 and z1 and x2 and y2 and z2 then
                    local distance = ((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2) ^ .5
                    unitdata[unit] = distance < 45 and 1 or 0
                    this.id = this.id + 1
                    return
                end
            end

            if LootFrame and LootFrame:IsShown() then return nil end
            if InspectFrame and InspectFrame:IsShown() then return nil end
            if TradeFrame and TradeFrame:IsShown() then return nil end
            if PlayerFrame and PlayerFrame.inCombat then return nil end
            if PlayerFrame and PlayerFrame.wandCombat then return nil end
            if druid and UnitPowerType("player") == 3 then return nil end
            if cAvail then return nil end

            _G.PlaySound = off
            SimpleUIScanActive = true
            targetEvent = TargetFrame_OnEvent
            _G.TargetFrame_OnEvent = target_noop
            TargetUnit(unit)
            unitdata[unit] = IsActionInRange(range.slot)
            TargetLastTarget()
            _G.TargetFrame_OnEvent = targetEvent
            _G.PlaySound = play
            SimpleUIScanActive = false

            this:ReAttack()
        end
        this.id = this.id + 1
    else
        this.id = 1
    end
end)

function range:ReAttack()
    if this.lastattack and this.lastattack + this.interval > GetTime() and UnitCanAttack("player", "target") then
        AttackTarget()
        return true
    else
        return nil
    end
end

function range:NeedRangeScan(unit)
    if not UnitExists(unit) then
        return nil
    end
    if not UnitIsVisible(unit) then
        return nil
    end
    if CheckInteractDistance(unit, 4) then
        return nil
    end
    return true
end

function range:GetRealUnit(unit)
    if unitdata[unit] then
        return unit
    end
    if unitcache[unit] then
        if UnitIsUnit(unitcache[unit], unit) then
            return unitcache[unit]
        end
    end

    for _, realunit in pairs(units) do
        if UnitIsUnit(realunit, unit) then
            unitcache[unit] = realunit
            return realunit
        end
    end

    return unit
end

function range:GetRangeSlot()
    local texture
    for i = 1, 120 do
        texture = GetActionTexture(i)
        if texture and not GetActionText(i) then
            for _, check in pairs(spells[class]) do
                if check == texture then
                    return 1
                end
            end
        end
    end
    return nil
end

function range:UnitInSpellRange(unit)
    if not range.slot then
        return nil
    end
    if UnitIsUnit("target", unit) then
        return IsActionInRange(range.slot) == 1 and 1 or nil
    end
    local unit = range:GetRealUnit(unit)
    if unitdata[unit] and unitdata[unit] == 1 then
        return 1
    elseif not unitdata[unit] then
        return 1
    else
        return nil
    end
end

U.range = range
