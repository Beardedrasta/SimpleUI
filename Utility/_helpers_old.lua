--[[
SimpleUI Utility Functions for WoW Vanilla 1.12 - Turtle WoW
Author: BeardedRasta
Description: Modular functions for handling colors, abbreviations, status bars, timers, and general utilities.
--]]

-- Setup up Environment
local U = SimpleUI.Util
local _G = getfenv(0)
UnitXPSP3 = pcall(UnitXP, "inSight", "player", "player")
SuperWoW = SpellInfo ~= nil

-- Utility Functions -------------------------------------------------------------

-- Set Element size
function U:SetSize(f, w, h)
    f:SetWidth(w)
    f:SetHeight(h)
end

-- Converts RGB(A) vlues to a hexadecimal color string
function U.rgbhex(r, g, b, a)
    if type(r) == "table" then
        r, g, b, a = r.r or r[1], r.g or r[2], r.b or r[3], r.a or r[4] or 1
    elseif tonumber(r) then
        r, g, b, a = r, g, b, (a or 1)
    end
    r, g, b, a = math.min(r, 1), math.min(g, 1), math.min(b, 1), math.min(a, 1)
    return string.format("|c%02x%02x%02x%02x", a * 255, r * 255, g * 255, b * 255)
end

-- Rounds a number to the specified number of decimal places
function U.round(value, decimals)
    local scale = 10 ^ (decimals or 0)
    return math.floor(value * scale + 0.5) / scale
end

-- Abbreviates large numbers (e.g., 1000 -> 1k, 1000000 -> 1m)
function U.Abbreviate(number)
    local profile = SimpleUIDB.Profiles[SimpleUIProfile].unitframes
    if profile and profile.abbrevnum then
        local sign = number < 0 and -1 or 1
        number = math.abs(number)

        if number > 1000000 then
            return U.round(number / 1000000 * sign, 2) .. "m"
        elseif number > 1000 then
            return U.round(number / 1000 * sign, 2) .. "k"
        end
    end

    return number
end

-- Generates a color gradient based on a percentage
local gradientColors = {}
function U.GetColorGradient(perc)
    perc = math.max(0, math.min(1, perc))
    if not gradientColors[perc] then
        local r1, g1, b1, r2, g2, b2

        if perc <= 0.5 then
            r1, g1, b1, r2, g2, b2 = 1, 0, 0, 1, 1, 0
            perc = perc * 2
        else
            r1, g1, b1, r2, g2, b2 = 1, 1, 0, 0, 1, 0
            perc = (perc - 0.5) * 2 --perc * 2 - 1
        end

        gradientColors[perc] = {
            r = r1 + (r2 - r1) * perc,
            g = g1 + (g2 - g1) * perc,
            b = b1 + (b2 - b1) * perc,
            h = U.rgbhex(r1 + (r2 - r1) * perc, g1 + (g2 - g1) * perc, b1 + (b2 - b1) * perc)
        }

        --[[         local r = U.round(r1 + (r2 - r1) * perc, 4)
        local g = U.round(g1 + (g2 - g1) * perc, 4)
        local b = U.round(b1 + (b2 - b1) * perc, 4)
        local h = U.rgbhex(r, g, b)

        gradientcolors[index] = {}
        gradientcolors[index].r = r
        gradientcolors[index].g = g
        gradientcolors[index].b = b
        gradientcolors[index].h = h ]]
    end
    local color = gradientColors[perc]
    return color.r, color.g, color.b, color.h
    --[[     return gradientcolors[index].r,
        gradientcolors[index].g,
        gradientcolors[index].b,
        gradientcolors[index].h ]]
end

-- Time Formatting -------------------------------------------------------------


local color_cache = {
    day = U.rgbhex(0.2, 0.2, 1),
    hour = U.rgbhex(0.2, 0.5, 1),
    minute = U.rgbhex(1.0, 0.8196, 0.0),
    low = U.rgbhex(1, 0.2, 0.2),
    normal = U.rgbhex(1, 1, 1),
}

-- Formats time into a colored string based on remaining time
function U.GetColoredTimeString(remaining)
    if not remaining then return "" end

    if remaining > 86400 then
        return color_cache.day .. U.round(remaining / 86400) .. "|r d"
    elseif remaining > 3600 then
        return color_cache.hour .. U.round(remaining / 3600) .. "|r h"
    elseif remaining > 60 then
        return color_cache.minute .. U.round(remaining / 60) .. "|r m"
    elseif remaining <= 5 then
        return color_cache.low .. string.format("%.1f", remaining)
    else
        return color_cache.normal .. U.round(remaining)
    end
end

-- String and Color Utilities -------------------------------------------------------------

--
function U.strsplit(delimiter, subject)
    if not subject then return nil end
    local delimiter, fields = delimiter or ":", {}
    local pattern = string.format("([^%s]+)", delimiter)
    string.gsub(subject, pattern, function(c) fields[table.getn(fields) + 1] = c end)
    return unpack(fields)
end

-- Caches string colors for efficiency
local stringColorCache = {}
function U.GetStringColor(colorstr)
    if not stringColorCache[colorstr] then
        local r, g, b, a = U.strsplit(",", colorstr)
        stringColorCache[colorstr] = { tonumber(r), tonumber(g), tonumber(b), tonumber(a) or 1 }
    end
    return unpack(stringColorCache[colorstr])
end

function U.Colorize(text, r, g, b)
    if type(r) == "table" then
        local rgb = r
        r = rgb[1]
        g = rgb[2]
        b = rgb[3]
    end
    return "|cFF" .. string.format("%02x%02x%02x", r * 255, g * 255, b * 255) .. text .. "|r"
end

-- Securely hooks a function to an existing global
function U.hooksecurefunc(name, func, append)
    local oldFunc = _G[name]
    if not oldFunc then
        return
    end

    --[[     local old_func = _G[name]
        local new_func = func ]]

    _G[name] = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        if append then
            oldFunc(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        end
        func(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        if not append then
            oldFunc(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        end
    end

    --[[     if not _G[name] then return end

    local old_func = _G[name]
    local new_func = func

    _G[name] = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        if append then
            old_func(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
            new_func(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        else
            new_func(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
            old_func(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        end
    end ]]
end

-- Pixel Calculation ----------------------------------------------------------------------------

-- Returns a perfect pixel size based on UI scale
function U.GetPerfectPixel()
    if not SimpleUI.pixel then
        local scale, resolution = UIParent:GetEffectiveScale(), GetCVar("gxResolution")
        local _, _, width, height = string.find(resolution, "(%d+)x(%d+)")
        SimpleUI.pixel = math.min(768 / tonumber(height) / scale, 1)
    end
    --[[     if SimpleUI.pixel then
        return SimpleUI.pixel
    end
    local scale, resolution = GetCVar("uiscale"), GetCVar("gxResolution")
    local _, _, screenWidth, screenHeight = strfind(resolution, "(.+)x(.+)")
    SimpleUI.pixel = math.min(768 / screenHeight / scale, 1)
    if SimpleUI.pixel then return SimpleUI.pixel end

    -- autodetect and zoom for HiDPI displays
    SimpleUI.pixel = SimpleUI.pixel < .5 and SimpleUI.pixel * 2 or SimpleUI.pixel


    SimpleUI.backdrop = {
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = SimpleUI.pixel,
        insets = { left = -SimpleUI.pixel, right = -SimpleUI.pixel, top = -SimpleUI.pixel, bottom = -SimpleUI.pixel },
    }

    SimpleUI.backdrop_thin = {
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = SimpleUI.pixel,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    } ]]

    return SimpleUI.pixel
end

-- Checks if a specific buff is active on a unit
function U:UnitHasBuff(unit, buff)
    for i = 1, 32 do
        if UnitBuff(unit, i) == buff then
            return true
        end
    end
    return false
end

-- Queue Function Execution -----------------------------------------------------------------------

-- A queue system to execute functions in sequence with a delay
local timer
function U.QueueFunction(a1, a2, a3, a4, a5, a6, a7, a8, a9)
    if not timer then
        timer = CreateFrame("Frame")
        timer.queue = {}
        timer.interval = TOOLTIP_UPDATE_TIME
        timer.DeQueue = function()
            local item = table.remove(timer.queue, 1)
            if item then
                item[1](unpack(item, 2))
                --item[1](item[2], item[3], item[4], item[5], item[6], item[7], item[8], item[9])
            end
            if table.getn(timer.queue) == 0 then
                timer:Hide() -- no need to run the OnUpdate when the queue is empty
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
    table.insert(timer.queue, { a1, a2, a3, a4, a5, a6, a7, a8, a9 })
    timer:Show() -- start the OnUpdate
end

-- Pattern Utilities ----------------------------------------------------------------------------------

-- Caches sanitized patterns for efficiency
local sanitize_cache = {}

-- Sanitizes Lua patterns to avoid special character conflicts
function U.SanitizePattern(pattern)
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

-- Advanced String Parsing

--Retrieves capture groups from a pattern
local gfind = string.gmatch or string.gfind
local capture_cache = {}
function U.GetCaptures(pattern)
    if not capture_cache[pattern] then
        local sanitizedPattern = U.SanitizePattern(pattern) --gsub(pattern, "%d%$", "%%(.-)$")
        local captures = {}
        for a, b, c, d, e, a in gfind(gsub(pattern, "%((.+)%)", "%1"), sanitizedPattern) do
            captures = { a, b, c, d, e }
            break
        end
        capture_cache[pattern] = captures
    end
    return unpack(capture_cache[pattern] or {})
end

-- Matches strings against patterns and returns capture values
function U.cmatch(str, pattern)
    --[[     local captures = { U.GetCaptures(pattern) }
    local values = { string.match(str, U.SanitizePattern(pattern)) }
    return unpack(values or {}) ]]
    local a, b, c, d, e = U.GetCaptures(pattern)
    local _, _, va, vb, vc, vd, ve = string.find(str, U.SanitizePattern(pattern))

    return
        e == 1 and ve or d == 1 and vd or c == 1 and vc or b == 1 and vb or va,
        e == 2 and ve or d == 2 and vd or c == 2 and vc or a == 2 and va or vb,
        e == 3 and ve or d == 3 and vd or a == 3 and va or b == 3 and vb or vc,
        e == 4 and ve or a == 4 and va or c == 4 and vc or b == 4 and vb or vd,
        a == 5 and va or d == 5 and vd or c == 5 and vc or b == 5 and vb or ve
end

-- Range Utilities ----------------------------------------------------------------------------

local function getDistance(x1, z1, x2, z2)
    local dx = x2 - x1
    local dz = z2 - z1
    return math.sqrt(dx*dx + dz*dz)
end


function GetDistanceBetween_SuperWow(unit1, unit2)
    local x1, z1 = UnitPosition(unit1)
    local x2, z2 = UnitPosition(unit2)
    if not x1 or not x2 then
        return 0
    end
    return getDistance(x1, z1, x2, z2)
end

-- Checks if a unit is within a specific range
local RangeCache = {}
function U.UnitInRange(unit)
    if not UnitExists(unit) or not UnitIsVisible(unit) then
        return nil
    elseif UnitXPSP3 then
        local distance = UnitXP("distanceBetween", "player", unit)
        if distance and distance < 40 then
            return 1
        end
    elseif SuperWoW then
        local distance = (GetDistanceBetween_SuperWow("player", unit))
        if distance and distance < 35 then
            return 1
        end
    elseif CheckInteractDistance(unit, 4) then
        return 1
    else
        return U.range:UnitInSpellRange(unit)
    end
end

-- Valid Unit Setup ----------------------------------------------------------------------------

-- Defines valid units for use in the addon
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

-- Adds party and raid members to the list of valid units
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

-- Status Bar Utilities ----------------------------------------------------------------------------

do
    -- Smoothly animates a status bar's value
    local animations = {}
    local animateFrame = CreateFrame("Frame", "SimpleUIStatusBarAnimation", UIParent)
    animateFrame:SetScript("OnUpdate", function()
        for bar, _ in pairs(animations) do
            if bar.value ~= bar.displayValue then
                local step = (bar.value - bar.displayValue) / math.max(GetFramerate(), 30)
                bar.displayValue = math.abs(step) < 0.01 and bar.value or bar.displayValue + step
                bar:DisplayValue(bar.displayValue)
            else
                animations[bar] = nil
            end
        end
    end)
    local stepsize, value
    local width, height, point

    --[[     local animate = CreateFrame("Frame", "SimpleUIStatusBarAnimation", UIParent)
    animate:SetScript("OnUpdate", function()
        stepsize = 5
        for bar in pairs(animations) do
            if not bar.val_ or abs(bar.val_ - bar.val) < stepsize or bar.instant then
                bar:DisplayValue(bar.val)
            elseif bar.val ~= bar.val_ then
                bar:DisplayValue(bar.val_ +
                    min((bar.val - bar.val_) / stepsize, max(bar.val - bar.val_, 30 / GetFramerate())))
            end
        end
    end) ]]

    -- Creates a status bar with smooth animations
    function U.CreateStatusBar(name, parent)
        local bar = CreateFrame("Button", name, parent)
        bar:EnableMouse(nil)

        bar.bar = bar:CreateTexture(nil, "HIGH")
        bar.bar:SetAllPoints(bar)

        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints(bar)

        bar.min, bar.max, bar.val = 0, 100, 0

        bar.DisplayValue = function(self, val)
            val = val > self.max and self.max or val
            val = val < self.min and self.min or val

            if val == self.val_ then
                animations[self] = nil
            end

            self.val_ = val

            if self.mode == "vertical" then
                height = self:GetHeight()
                height = height / self:GetEffectiveScale()
                point = height / (self.max - self.min) * (val - self.min)

                point = math.min(height, point)
                point = math.max(0, point)

                if val == 0 then point = 0 end

                self.bar:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -height + point)
                self.bar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)

                self.bg:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
                self.bg:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, point)
            else
                width = self:GetWidth()
                width = width / self:GetEffectiveScale()
                point = width / (self.max - self.min) * (val - self.min)

                point = math.min(width, point)
                point = math.max(0, point)

                if val == 0 then point = 0 end

                self.bar:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
                self.bar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -width + point, 0)

                self.bg:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
                self.bg:SetPoint("TOPLEFT", self, "TOPLEFT", point, 0)
            end
        end

        bar.SetMinMaxValues = function(self, smin, smax, smooth)
            -- smoothen the transition by keeping the value at the same percentage as before
            if smooth and self.max and self.max > 0 and smax > 0 and self.max ~= smax then
                self.val_ = (self.val_ or self.val) / self.max * smax
            end

            self.min, self.max = smin, smax
            self:DisplayValue(self.val_ or self.val)
        end

        bar.SetValue = function(self, val)
            self.val = val or 0

            if self.val_ ~= self.val then
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
            self.mode = strlower(mode)
        end


        return bar
    end

    function U.GetBagFamily(bag)
        if bag == -2 then return "KEYRING" end
        if bag == 0 then return "BAG" end  -- backpack
        if bag == -1 then return "BAG" end -- bank

        local _, _, id = strfind(GetInventoryItemLink("player", ContainerIDToInventoryID(bag)) or "", "item:(%d+)")
        if id then
            local _, _, _, _, _, itemType, subType = GetItemInfo(id)
            local bagsubtype = SimpleUI_BagList["bagtypes"][subType]

            if bagsubtype == "DEFAULT" then return "BAG" end
            if bagsubtype == "SOULBAG" then return "SOULBAG" end
            if bagsubtype == "QUIVER" then return "QUIVER" end
            if bagsubtype == nil then return "SPECIAL" end
        end

        return nil
    end

    function U.CreateGoldString(money)
        if type(money) ~= "number" then return "-" end

        local gold = floor(money / 100 / 100)
        local silver = floor(mod((money / 100), 100))
        local copper = floor(mod(money, 100))

        local string = ""
        if gold > 0 then string = string .. "|cffffffff" .. gold .. "|cffffd700g" end
        if silver > 0 or gold > 0 then string = string .. "|cffffffff " .. silver .. "|cffc7c7cfs" end
        string = string .. "|cffffffff " .. copper .. "|cffeda55fc"

        return string
    end

    function U.wipe(src)
        local mt = getmetatable(src) or {}
        if mt.__mode == nil or mt.__mode ~= "kv" then
            mt.__mode = "kv"
            src = setmetatable(src, mt)
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
    local backdrop, b, level, rawborder, border, br, bg, bb, ba, er, eg, eb, ea

    function U:CreateBackdrop(frame, inset, legacy, backdropSetting, blizz)
        if not frame then return end

        rawborder, border = 2, 2
        if inset then
            rawborder = inset / U.GetPerfectPixel()
            border = inset
        end

        backdrop = backdropSetting or SimpleUI.backdrop_default
        level = frame:GetFrameLevel()

        local borderColor = { 0.2, 0.2, 0.2, 1 }
        local bgColor = { 0, 0, 0, 1 }

        if legacy then
            if backdropSetting then frame:Setbackdrop(backdropSetting) end
            frame:SetBackdrop(backdrop)
            frame:SetBackdropColor(br, bg, bb, ba)
            frame:SetBackdropBorderColor(er, eg, eb, ea)
        else
            -- More complex handling, including setting a secondary border
            frame:SetBackdrop(nil)
            if not frame.backdrop then
                local bd = CreateFrame("Frame", nil, frame)
                level = frame:GetFrameLevel()
                if level < 1 then
                    bd:SetFrameLevel(level)
                else
                    bd:SetFrameLevel(level - 1)
                end
                frame.backdrop = bd

                --frame.backdrop = CreateFrame("Frame", nil, frame)
                frame.backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", -inset or -2, inset or 2)
                frame.backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", inset or 2, -inset or -2)
                frame.backdrop:SetFrameLevel(math.max(0, level - 1))
                frame.backdrop:SetBackdrop(backdrop)

                frame.backdrop.border = CreateFrame("Frame", nil, frame)
                frame.backdrop.border:SetAllPoints(frame.backdrop)
                frame.backdrop.border:SetBackdrop(SimpleUI.backdrop_default_border)


                return frame.backdrop, frame.backdrop.border
            end
            --frame.backdrop:SetBackdropColor(unpack(bgColor))
            --frame.backdrop:SetBackdropBorderColor(unpack(borderColor))

            if blizz then
                if not frame.backdrop_border then
                    frame.backdrop_border = CreateFrame("Frame", nil, frame)
                    frame.backdrop_border:SetFrameLevel(level + 1)
                    frame.backdrop_border:SetPoint("TOPLEFT", frame.backdrop, "TOPLEFT", -4.8, 4.8)
                    frame.backdrop_border:SetPoint("BOTTOMRIGHT", frame.backdrop, "BOTTOMRIGHT", 4.8, -4.8)
                    --frame.backdrop_border:SetBackdrop(SimpleUI.backdrop_blizz_border)
                    frame.backdrop_border:SetBackdropBorderColor(1, 1, 1, 1)
                end
            end
        end
    end
end

function U.LoadRelocator(frame, init)
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

function U.SaveRelocator(frame, scale)
    local anchor, _, _, xpos, ypos = frame:GetPoint()
    SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].position[frame:GetName()] = SimpleUIDB.Profiles
    [SimpleUIProfile]["Entities"]["Unitframes"].position[frame:GetName()] or {}
    SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].position[frame:GetName()]["xpos"] = U.round(xpos)
    SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].position[frame:GetName()]["ypos"] = U.round(ypos)
    SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].position[frame:GetName()]["anchor"] = anchor
    SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].position[frame:GetName()]["parent"] = frame:GetParent() and frame:GetParent():GetName() or nil
    if scale then
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].position[frame:GetName()]["scale"] = frame:GetScale()
    end
end

function U.UpdateRelocator(frame, init)
    local name = frame:GetName()

    frame:SetClampedToScreen(true)

    if not SimpleUI.movables[name] then
        SimpleUI.movables[name] = frame
    end

    U.LoadRelocator(frame, init)
end

function U.RemoveRelocator(frame)
    local name = frame:GetName()
    SimpleUI.movables[name] = nil
end
