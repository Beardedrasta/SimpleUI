--[[
SimpleUI Utility Functions for WoW Vanilla 1.12 - Turtle WoW
Author: BeardedRasta
Description: Modular functions for handling colors, abbreviations, status bars, timers, and general utilities.
--]]

-- Setup up Environment

SUI_Util = {}
local U = SimpleUI.Util

local _G = getfenv(0)
setmetatable(SUI_Util, { __index = getfenv(1) })
setfenv(1, SUI_Util)

UnitXPSP3 = pcall(UnitXP, "inSight", "player", "player");
SuperWoW = SpellInfo ~= nil;

--------------------------------------------------------------------------------
-- 1) Basic Utility Functions
--------------------------------------------------------------------------------

local Insert = table.insert;
local Remove = table.remove;
local Getnum = table.getn;

local Gfind = string.gmatch or string.gfind;
local Find = string.find;
local Strlower = string.lower;
local Format = string.format;
local Sub = string.gsub;

local Max = math.max;
local Min = math.min;
local Abs = math.abs;
local Floor = math.floor;
local Square = math.sqrt;
local Random = math.random;

local Pairs = pairs;

local CreateFrame = CreateFrame;

-- Adjust element size
function SetSize(f, w, h)
    f:SetWidth(w)
    f:SetHeight(h)
end

-- Converts RGB(A) vlues to a hexadecimal color string
function Rgbhex(r, g, b, a)
    if type(r) == "table" then
        r, g, b, a = r.r or r[1], r.g or r[2], r.b or r[3], r.a or r[4] or 1
    elseif tonumber(r) then
        r, g, b, a = r, g, b, (a or 1)
    end
    r, g, b, a = Min(r, 1), Min(g, 1), Min(b, 1), Min(a, 1)
    return string.format("|c%02x%02x%02x%02x", a * 255, r * 255, g * 255, b * 255)
end

-- Rounds a number to the specified number of decimal places
function Round(value, decimals)
    local scale = 10 ^ (decimals or 0)
    return Floor(value * scale + 0.5) / scale
end

-- Abbreviates large numbers (e.g., 1000 -> 1k, 1000000 -> 1m)
function Abbreviate(number)
    local profile = SimpleUIDB.Profiles[SimpleUIProfile].unitframes
    if profile and profile.abbrevnum then
        local sign = number < 0 and -1 or 1
        number = Abs(number)

        if number > 1000000 then
            return Round(number / 1000000 * sign, 2) .. "m"
        elseif number > 1000 then
            return Round(number / 1000 * sign, 2) .. "k"
        end
    end

    return number
end

function Strsplit(delimiter, subject)
    if not subject then return end
    local fields = {}
    local pattern = Format("([^%s]+)", delimiter or ":")
    Sub(subject, pattern, function(c) Insert(fields, c) end)
    return unpack(fields)
end

--------------------------------------------------------------------------------
-- 2) Colors & Gradients
--------------------------------------------------------------------------------

-- Generates a color gradient based on a percentage
local gradientColors = {}
function GetColorGradient(perc)
    perc = Max(0, Min(1, perc))
    if not gradientColors[perc] then
        local r1, g1, b1, r2, g2, b2

        if perc <= 0.5 then
            r1, g1, b1, r2, g2, b2 = 1, 0, 0, 1, 1, 0
            perc = perc * 2
        else
            r1, g1, b1, r2, g2, b2 = 1, 1, 0, 0, 1, 0
            perc = (perc - 0.5) * 2
        end

        local r = r1 + (r2 - r1) * perc
        local g = g1 + (g2 - g1) * perc
        local b = b1 + (b2 - b1) * perc
        local h = Rgbhex(r, g, b)

        gradientColors[perc] = { r = r, g = g, b = b, h = h }
    end
    local color = gradientColors[perc]
    return color.r, color.g, color.b, color.h
end

local stringColorCache = {}
function GetStringColor(colorstr)
    if not stringColorCache[colorstr] then
        local r, g, b, a = Strsplit(",", colorstr)
        stringColorCache[colorstr] = {
            tonumber(r) or 1,
            tonumber(g) or 1,
            tonumber(b) or 1,
            tonumber(a) or 1 }
    end
    return unpack(stringColorCache[colorstr])
end

function Colorize(text, r, g, b)
    if type(r) == "table" then
        r = r[1]
        g = g[2]
        b = b[3]
    end
    return "|cFF" .. Format("%02x%02x%02x", r * 255, g * 255, b * 255) .. text .. "|r"
end

local classColors = {
    ["DRUID"] = { 1.0, 0.49, 0.04 },
    ["HUNTER"] = { 0.67, 0.83, 0.45 },
    ["MAGE"] = { 0.41, 0.8, 0.94 },
    ["PALADIN"] = { 0.96, 0.55, 0.73 },
    ["PRIEST"] = { 1.0, 1.0, 1.0 },
    ["ROGUE"] = { 1.0, 0.96, 0.41 },
    ["SHAMAN"] = { 0.14, 0.35, 1.0 },
    ["WARLOCK"] = { 0.58, 0.51, 0.79 },
    ["WARRIOR"] = { 0.78, 0.61, 0.43 }
}
function GetClassColor(class, asArray)
    local color = classColors[class]
    if not color then -- Unknown class
        color = { 0.7, 0.7, 0.7 }
    end
    if asArray then
        return color
    end
    return color[1], color[2], color[3]
end

function GetClass(unit)
    local _, class = UnitClass(unit)
    return class
end

--------------------------------------------------------------------------------
-- 3) Time Formatting
--------------------------------------------------------------------------------

local color_cache = {
    day    = Rgbhex(0.2, 0.2, 1),
    hour   = Rgbhex(0.2, 0.5, 1),
    minute = Rgbhex(1.0, 0.82, 0.0),
    low    = Rgbhex(1, 0.2, 0.2),
    normal = Rgbhex(1, 1, 1),
}


-- Formats time into a colored string based on remaining time
function GetColoredTimeString(remaining)
    if not remaining then return "" end

    if remaining > 86400 then
        return color_cache.day .. Round(remaining / 86400) .. "|r d"
    elseif remaining > 3600 then
        return color_cache.hour .. Round(remaining / 3600) .. "|r h"
    elseif remaining > 60 then
        return color_cache.minute .. Round(remaining / 60) .. "|r m"
    elseif remaining <= 5 then
        return color_cache.low .. Format("%.1f", remaining)
    else
        return color_cache.normal .. Round(remaining)
    end
end

--------------------------------------------------------------------------------
-- 4) hooking & pattern utilities
--------------------------------------------------------------------------------


-- Securely hooks a function to an existing global
function Hooksecurefunc(name, func, append)
    local oldFunc = _G[name]
    if not oldFunc then
        return
    end

    _G[name] = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        if append then
            oldFunc(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        end
        func(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        if not append then
            oldFunc(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        end
    end
end

local sanitize_cache = {}
-- Sanitizes Lua patterns to avoid special character conflicts
function SanitizePattern(pattern)
    if not sanitize_cache[pattern] then
        local sanitized = pattern
        sanitized = gsub(sanitized, "([%+%-%*%(%)%?%[%]%^])", "%%%1")      -- Escape magic characters
        sanitized = gsub(sanitized, "%d%$", "")                            -- Remove capture indexes
        sanitized = gsub(sanitized, "(%%%a)", "%(%1+%)")                   -- Catch all characters
        sanitized = gsub(sanitized, "%%s%+", ".+")                         -- Convert %s to .+
        sanitized = gsub(sanitized, "%(.%+%)%(%%d%+%)", "%(.-%)%(%%d%+%)") -- Set priority to numbers
        sanitize_cache[pattern] = sanitized
    end
    return sanitize_cache[pattern]
end

--Retrieves capture groups from a pattern
local capture_cache = {}
function GetCaptures(pattern)
    if not capture_cache[pattern] then
        local sanitized = SanitizePattern(pattern) --gsub(pattern, "%d%$", "%%(.-)$")
        local captures = {}
        for a, b, c, d, e, a in Gfind(pattern, sanitized) do
            captures = { a, b, c, d, e }
            break
        end
        capture_cache[pattern] = captures
    end
    return unpack(capture_cache[pattern] or {})
end

-- Matches strings against patterns and returns capture values
function Cmatch(str, pattern)
    local a, b, c, d, e = GetCaptures(pattern)
    local _, _, va, vb, vc, vd, ve = Find(str, SanitizePattern(pattern))
    return
        e == 1 and ve or d == 1 and vd or c == 1 and vc or b == 1 and vb or va,
        e == 2 and ve or d == 2 and vd or c == 2 and vc or a == 2 and va or vb,
        e == 3 and ve or d == 3 and vd or a == 3 and va or b == 3 and vb or vc,
        e == 4 and ve or a == 4 and va or c == 4 and vc or b == 4 and vb or vd,
        a == 5 and va or d == 5 and vd or c == 5 and vc or b == 5 and vb or ve
end

--------------------------------------------------------------------------------
-- 5) Range Checking
--------------------------------------------------------------------------------

local function getDistance(x1, z1, x2, z2)
    local dx, dz = (x2 - x1), (z2 - z1)
    return Square(dx * dx + dz * dz)
end

local function GetDistanceBetween_SuperWow(unit1, unit2)
    local x1, z1 = UnitPosition(unit1)
    local x2, z2 = UnitPosition(unit2)
    if not x1 or not x2 then
        return 0
    end
    return getDistance(x1, z1, x2, z2)
end

-- Check if a unit is in range (~35-40 yards) using various checks
function UnitInRange(unit)
    if not UnitExists(unit) or not UnitIsVisible(unit) then
        return nil
    elseif UnitXPSP3 then
        -- Extended API check
        local distance = UnitXP("distanceBetween", "player", unit)
        if distance and distance < 40 then
            return 1
        end
    elseif CheckInteractDistance(unit, 4) then
        return 1
    else
        return U.range:UnitInSpellRange(unit)
    end
end

function IsInSight(unit)
    if not UnitXPSP3 then
        if UnitExists(unit) or UnitIsVisible(unit) then
            return true
        end
    end
    return UnitXP("inSight", "player", unit) -- UnitXP SP3 modded function
end

function IsFeigning(unit)
    local unitClass = GetClass(unit)
    if unitClass == "HUNTER" then
        local superwow = SuperWoW
        for i = 1, 32 do
            local texture, _, id = UnitBuff(unit, i)
            if superwow then -- Use the ID if SuperWoW is present
                if id == 5384 then -- 5384 is Feign Death
                    return true
                end
            else -- Use the texture otherwise
                if texture == "Interface\\Icons\\Ability_Rogue_FeignDeath" then
                    return true
                end
            end
        end
    end
    return false
end

function IsDeadFriend(unit)
    return (UnitIsDead(unit) or UnitIsCorpse(unit)) and UnitIsFriend("player", unit) and not IsFeigning(unit)
end

--------------------------------------------------------------------------------
-- 6) Valid Units for SimpleUI
--------------------------------------------------------------------------------

SimpleUIValidUnits = {
    pet = true,
    player = true,
    target = true,
    mouseover = true,
    pettarget = true,
    playertarget = true,
    targettarget = true,
    mouseovertarget = true,
    targettargettarget = true,
}

for i = 1, 4 do
    SimpleUIValidUnits["party" .. i] = true
    SimpleUIValidUnits["partypet" .. i] = true
    SimpleUIValidUnits["party" .. i .. "target"] = true
    SimpleUIValidUnits["partypet" .. i .. "target"] = true
end

for i = 1, 40 do
    SimpleUIValidUnits["raid" .. i] = true
    SimpleUIValidUnits["raidpet" .. i] = true
    SimpleUIValidUnits["raid" .. i .. "target"] = true
    SimpleUIValidUnits["raidpet" .. i .. "target"] = true
end

PowerTypes = {
    ["WARRIOR"] = "rage",
    ["PALADIN"] = "mana",
    ["HUNTER"] = "mana",
    ["ROGUE"] = "energy",
    ["PRIEST"] = "mana",
    ["SHAMAN"] = "mana",
    ["MAGE"] = "mana",
    ["WARLOCK"] = "mana",
    ["DRUID"] = "mana"
}

local classes = { "HUNTER", "ROGUE", "PRIEST", "PALADIN", "DRUID", "SHAMAN", "WARRIOR", "MAGE", "WARLOCK" }
function GetClasses()
    return classes
end

function GetRandomClass()
    return classes[Random(1, 9)]
end

--------------------------------------------------------------------------------
-- 7) Status Bar Animations & Creation
--------------------------------------------------------------------------------

do
    -- Smoothly animates a status bar's value
    local animations = {}
    local animateFrame = CreateFrame("Frame", "SimpleUIStatusBarAnimation", UIParent)
    animateFrame:SetScript("OnUpdate", function()
        local framerate = Max(GetFramerate(), 30)
        for bar, _ in pairs(animations) do
            if bar.value ~= bar.displayValue then
                local step = (bar.value - bar.displayValue) / framerate
                if Abs(step) < 0.01 then
                    bar.displayValue = bar.value
                else
                    bar.displayValue = bar.displayValue + step
                end
                bar:DisplayValue(bar.displayValue)
            else
                animations[bar] = nil
            end
        end
    end)

    -- Creates a status bar with smooth animations
    function CreateStatusBar(name, parent)
        local bar = CreateFrame("Button", name, parent)
        bar:EnableMouse(false)

        bar.bar = bar:CreateTexture(nil, "ARTWORK")
        bar.bar:SetAllPoints(bar)

        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints(bar)

        bar.min, bar.max, bar.val = 0, 100, 0
        bar.displayValue = 0
        bar.mode = "horizontal"

        ----------------------------------------------------------------
        -- a) Functions
        ----------------------------------------------------------------

        bar.DisplayValue = function(self, val)
            if val > self.max then val = self.max end
            if val < self.min then val = self.min end

            --[[             if val == self.val_ then
                animations[self] = nil
            end

            self.val_ = val ]]

            local dimension
            if self.mode == "vertical" then
                local height = self:GetHeight() / self:GetEffectiveScale()
                dimension = (height / (self.max - self.min)) * (val - self.min)
                dimension = Max(0, Min(height, dimension))

                self.bar:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -height + dimension)
                self.bar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)

                self.bg:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
                self.bg:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, dimension)
            else
                local width = self:GetWidth() / self:GetEffectiveScale()
                dimension = (width / (self.max - self.min)) * (val - self.min)
                dimension = Max(0, Min(width, dimension))

                self.bar:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
                self.bar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -width + dimension, 0)

                self.bg:SetPoint("TOPLEFT", self, "TOPLEFT", dimension, 0)
                self.bg:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
            end
        end

        bar.SetMinMaxValues = function(self, newMin, newMax, smooth)
            if smooth and self.max and self.max ~= 0 and newMax > 0 and (self.max ~= newMax) then
                local pct = (self.displayValue or self.value) / self.max
                self.displayValue = pct * newMax
            end
            self.min, self.max = newMin, newMax
            self:DisplayValue(self.displayValue)
        end

        bar.SetValue = function(self, val)
            self.val = val or 0
            if self.val ~= self.displayValue then
                animations[self] = true
            end
        end

        bar.SetStatusBarTexture = function(self, r, g, b, a)
            self.bar:SetTexture(r, g, b, a)
        end

        bar.SetStatusBarColor = function(self, r, g, b, a)
            self.bar:SetVertexColor(r, g, b, a)
        end

        bar.SetStatusBarBackgroundTexture = function(self, r, g, b, a)
            self.bg:SetTexture(r, g, b, a)
        end

        bar.SetStatusBarBackgroundColor = function(self, r, g, b, a)
            self.bg:SetVertexColor(r, g, b, a)
        end

        bar.SetOrientation = function(self, mode)
            self.mode = Strlower(mode or "horizontal")
        end


        return bar
    end

    --------------------------------------------------------------------------------
    -- 8) Perfect Pixel Calculation
    --------------------------------------------------------------------------------

    -- Returns a perfect pixel size based on UI scale
    function GetPerfectPixel()
        if not SimpleUI.pixel then
            local scale = UIParent:GetEffectiveScale()
            local resolution = GetCVar("gxResolution")
            local _, _, width, height = Find(resolution, "(%d+)x(%d+)")
            SimpleUI.pixel = Min(768 / tonumber(height) / scale, 1)
        end
        return SimpleUI.pixel
    end

    --------------------------------------------------------------------------------
    -- 9) Checking Buffs
    --------------------------------------------------------------------------------

    function UnitHasBuff(unit, buff)
        for i = 1, 32 do
            if UnitBuff(unit, i) == buff then
                return true
            end
        end
        return false
    end

    --------------------------------------------------------------------------------
    -- 10) Queued Function Execution
    --------------------------------------------------------------------------------

    local timer
    function QueueFunction(a1, a2, a3, a4, a5, a6, a7, a8, a9)
        if not timer then
            timer = CreateFrame("Frame")
            timer.queue = {}
            timer.interval = TOOLTIP_UPDATE_TIME

            timer.DeQueue = function()
                local item = Remove(timer.queue, 1)
                if item then
                    item[1](unpack(item, 2))
                end
                if Getnum(timer.queue) == 0 then
                    timer:Hide()
                end
            end

            timer:SetScript("OnUpdate", function()
                this.sinceLast = (this.sinceLast or 0) + arg1
                while this.sinceLast > this.interval do
                    this.DeQueue()
                    this.sinceLast = this.sinceLast - this.interval
                end
            end)
        end
        Insert(timer.queue, { a1, a2, a3, a4, a5, a6, a7, a8, a9 })
        timer:Show() -- start the OnUpdate
    end

    --------------------------------------------------------------------------------
    -- 11) Bag Family / Gold String
    --------------------------------------------------------------------------------


    function GetBagFamily(bag)
        if bag == -2 then return "KEYRING" end
        if bag == 0 then return "BAG" end  -- backpack
        if bag == -1 then return "BAG" end -- bank

        local link = GetInventoryItemLink("player", ContainerIDToInventoryID(bag))
        if link then
            local _, _, id = Find(link, "item: (%d+)")
            if id then
                local itemName, _, _, _, _, itemType, subType = GetItemInfo(id)
                local bagsubtype = SimpleUI_BagList and SimpleUI_BagList["bagtypes"] and
                    SimpleUI_BagList["bagtypes"][subType]

                if bagsubtype == "DEFAULT" then
                    return "BAG"
                elseif bagsubtype == "SOULBAG" then
                    return "SOULBAG"
                elseif bagsubtype == "QUIVER" then
                    return "QUIVER"
                elseif bagsubtype == nil then
                    return "SPECIAL"
                end
            end
        end
        return nil
    end

    function CreateGoldString(money)
        if type(money) ~= "number" then
            return "-"
        end

        local gold = Floor(money / 100 / 100)
        local silver = Floor(mod((money / 100), 100))
        local copper = Floor(mod(money, 100))

        local str = ""
        if gold > 0 then
            str = str .. "|cffffffff" .. gold .. "|cffffd700g"
        end
        if silver > 0 or gold > 0 then
            str = str .. "|cffffffff " .. silver .. "|cffc7c7cfs"
        end
        str = str .. "|cffffffff " .. copper .. "|cffeda55fc"

        return str
    end

    --------------------------------------------------------------------------------
    -- 12) Table Wipe & Backdrops
    --------------------------------------------------------------------------------

    function Wipe(src)
        if not src then
            return
        end
        local mt = getmetatable(src) or {}
        if mt.__mode == nil or mt.__mode ~= "kv" then
            mt.__mode = "kv"
            setmetatable(src, mt)
        end
        for k in pairs(src) do
            src[k] = nil
        end
        return src
    end

    SimpleUI.backdrop_default = {
        bgFile = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\background.blp",
        tile = false,
        tileSize = 0,
        insets = { left = 7, right = 7, top = 7, bottom = 7 },
    }

    SimpleUI.backdrop_default_border = {
        edgeFile = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\thick-border.blp",
        edgeSize = 14,
    }

    SimpleUI.backdrop_thin = {
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    }

    SimpleUI.backdrop_blizz_border = {
        edgeFile = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\thick-border.blp",
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    }

    --local backdrop, b, level, rawborder, border, br, bg, bb, ba, er, eg, eb, ea
    function CreateBackdrop(frame, inset, legacy, backdropSetting, blizz)
        if not frame then
            return
        end

        local rawborder = (inset or 2) / GetPerfectPixel()
        local border = inset or 2

        local baseBackdrop = backdropSetting or SimpleUI.backdrop_default
        local level = frame:GetFrameLevel()

        if legacy then
            frame:SetBackdrop(baseBackdrop)
            frame:SetBackdropColor(0, 0, 0, 1)
            frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        else
            frame:SetBackdrop(nil)
            if not frame.backdrop then
                frame.backdrop = CreateFrame("Frame", nil, frame)
                local bdLevel = Max(0, level - 1)
                frame.backdrop:SetFrameLevel(bdLevel)

                frame.backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", -inset or -2, inset or 2)
                frame.backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", inset or 2, -inset or -2)
                frame.backdrop:SetBackdrop(baseBackdrop)

                frame.backdrop.border = CreateFrame("Frame", nil, frame)
                frame.backdrop.border:SetAllPoints(frame.backdrop)
                frame.backdrop.border:SetBackdrop(SimpleUI.backdrop_default_border)

                return frame.backdrop, frame.backdrop.border
            end

            if blizz then
                if not frame.backdrop_border then
                    frame.backdrop_border = CreateFrame("Frame", nil, frame)
                    frame.backdrop_border:SetFrameLevel(level + 1)
                    frame.backdrop_border:SetPoint("TOPLEFT", frame.backdrop, "TOPLEFT", -4.8, 4.8)
                    frame.backdrop_border:SetPoint("BOTTOMRIGHT", frame.backdrop, "BOTTOMRIGHT", 4.8, -4.8)
                    frame.backdrop_border:SetBackdropBorderColor(1, 1, 1, 1)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 13) Frame Position (Relocator)
--------------------------------------------------------------------------------

function LoadRelocator(frame, init)
    if not frame.posdata or init then
        frame.posdata = { scale = frame:GetScale(), pos = {} }
        for i = 1, frame:GetNumPoints() do
            frame.posdata.pos[i] = { frame:GetPoint(i) }
        end
    end

    if frame.posdata and frame.posdata.pos[1] then
        frame:ClearAllPoints()
        frame:SetScale(frame.posdata.scale)

        for _, point in pairs(frame.posdata.pos) do
            local a, b, c, d, e = unpack(point)
            if a and b then
                frame:SetPoint(a, b, c, d, e)
            end
        end
    end
end

function SaveRelocator(frame, scale)
    local anchor, _, _, xpos, ypos = frame:GetPoint()
    local store                    = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].position
    store[frame:GetName()]         = store[frame:GetName()] or {}

    store[frame:GetName()].xpos    = Round(xpos)
    store[frame:GetName()].ypos    = Round(ypos)
    store[frame:GetName()].anchor  = anchor
    store[frame:GetName()].parent  = frame:GetParent() and frame:GetParent():GetName() or nil

    if scale then
        store[frame:GetName()].scale = frame:GetScale()
    end
end

function UpdateRelocator(frame, init)
    local name = frame:GetName()

    frame:SetClampedToScreen(true)

    if not SimpleUI.movables[name] then
        SimpleUI.movables[name] = frame
    end

    LoadRelocator(frame, init)
end

function RemoveRelocator(frame)
    local name = frame:GetName()
    SimpleUI.movables[name] = nil
end

