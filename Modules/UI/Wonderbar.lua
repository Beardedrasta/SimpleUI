local Wonderbar = CreateFrame("Frame")
local _G = getfenv(0)
local u = SUI_Util

SimpleUI:AddModule("Wonderbar", function()
    if SimpleUI:IsDisabled("Wonderbar") then return end

    local function CreateWidget(parent, name, fontSize, tooltipCallback, clickCallback, updateCallback, eventCallback)
        local widget = CreateFrame("Button", name, parent)
        widget:EnableMouse(true)
        widget:SetWidth(150)
        widget:SetHeight(40)
        widget.text = widget:CreateFontString(nil, "OVERLAY")
        widget.text:SetFontObject(GameFontNormal)
        widget.text:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\6.ttf", fontSize or 12, "OUTLINE")
        widget.text:SetVertexColor(1, 1, 1, 1)
        widget.text:SetAllPoints()

        if tooltipCallback then
            widget:SetScript("OnEnter", function()
                tooltipCallback(widget)
            end)
            widget:SetScript("OnLeave", function()
                GameTooltip:Hide()
                GameTooltipStatusBar:Hide()
                widget.text:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\6.ttf", fontSize or 12, "OUTLINE")
            end)
        end

        if clickCallback then
            widget:SetScript("OnClick", clickCallback)
        end

        if updateCallback then
            widget:SetScript("OnUpdate", updateCallback)
        end

        if eventCallback then
            widget:SetScript("OnEvent", eventCallback)
        end

        widget:SetScript("OnMouseDown", function()
            widget.text:ClearAllPoints()
            widget.text:SetPoint("CENTER", widget, "CENTER", 2, -2)
        end)

        widget:SetScript("OnMouseUp", function()
            widget.text:ClearAllPoints()
            widget.text:SetPoint("CENTER", widget, "CENTER", 0, 0)
        end)

        return widget
    end

    function ConsctructBar()
        if this.bar then return end

        local bar = CreateFrame("Frame", "SimpleUIWonderBar", UIParent)
        bar:SetPoint("TOP", UIParent, "TOP", 0, 0)
        bar:SetWidth(UIParent:GetWidth() + 600)
        bar:SetFrameLevel(UIParent:GetFrameLevel())
        bar:SetHeight(50)

        bar.InCombat = nil

        local barBackground = bar:CreateTexture(nil, "BACKGROUND")
        barBackground:SetAllPoints()
        barBackground:SetTexture("Interface\\AddOns\\SimpleUI\\Media\\Textures\\SimpleFadeDark.tga")
        barBackground:SetVertexColor(0.5, 0.5, 0.5)
        barBackground:SetBlendMode("DISABLE")

        local leftPanel = CreateFrame("Frame", "SimpleUIWonderBarLeftPanel", bar)
        local middlePanel = CreateFrame("Frame", "SimpleUIWonderBarMiddlePanel", bar)
        local rightPanel = CreateFrame("Frame", "SimpleUIWonderBarRightPanel", bar)


        leftPanel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        leftPanel:SetPoint("TOPRIGHT", middlePanel, "TOPLEFT", -50, 0)
        leftPanel:SetHeight(40)
        middlePanel:SetPoint("CENTER", bar, "CENTER", 0, 0)
        middlePanel:SetWidth(150)
        middlePanel:SetHeight(40)
        rightPanel:SetPoint("TOPLEFT", middlePanel, "TOPRIGHT", 50, 0)
        rightPanel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
        rightPanel:SetHeight(40)

        leftPanel:RegisterEvent("PLAYER_TARGET_CHANGED")
        leftPanel:RegisterEvent("PLAYER_ENTER_COMBAT")
        leftPanel:RegisterEvent("PLAYER_LEAVE_COMBAT")
        leftPanel:RegisterEvent("PLAYER_REGEN_ENABLED")
        leftPanel:RegisterEvent("PLAYER_REGEN_DISABLED")
        leftPanel:RegisterEvent("UNIT_COMBAT")
        leftPanel:SetScript("OnEvent", function()
            if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_LEAVE_COMBAT" then
                bar.InCombat = nil
                leftPanel:SetAlpha(1)
            elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_ENTER_COMBAT" then
                bar.InCombat = 1
                leftPanel:SetAlpha(0)
            elseif event == "PLAYER_TARGET_CHANGED" and bar.InCombat == 1 then
                leftPanel:SetAlpha(0)
            end
        end)

        rightPanel:RegisterEvent("PLAYER_TARGET_CHANGED")
        rightPanel:RegisterEvent("PLAYER_ENTER_COMBAT")
        rightPanel:RegisterEvent("PLAYER_LEAVE_COMBAT")
        rightPanel:RegisterEvent("PLAYER_REGEN_ENABLED")
        rightPanel:RegisterEvent("PLAYER_REGEN_DISABLED")
        rightPanel:RegisterEvent("UNIT_COMBAT")
        rightPanel:SetScript("OnEvent", function()
            if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_LEAVE_COMBAT" then
                bar.InCombat = nil
                rightPanel:SetAlpha(1)
            elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_ENTER_COMBAT" then
                bar.InCombat = 1
                rightPanel:SetAlpha(0)
            elseif event == "PLAYER_TARGET_CHANGED" and bar.InCombat == 1 then
                rightPanel:SetAlpha(0)
            end
        end)

        leftPanel.panelName = "LeftPanel"
        middlePanel.panelName = "MiddlePanel"
        rightPanel.panelName = "RightPanel"

        bar.leftPanel = leftPanel
        bar.middlePanel = middlePanel
        bar.rightPanel = rightPanel
        bar.barBackground = barBackground

        bar.widgets = {}
        SimpleUI_cache["gold"] = SimpleUI_cache["gold"] or {}

        local clockWidget = CreateWidget(middlePanel, "SimpleUIWidgetClock", 18, function(widget)
                local h, m = GetGameTime()
                local noon = " AM"
                local servertime
                local time
                if h > 12 then
                    h = h - 12
                    noon = " PM"
                end
                time = date("%I:%M %p")
                servertime = string.format("%.2d:%.2d %s", h, m, noon)

                GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
                GameTooltip:SetText("|cff1a9fc0" .. "Time")
                GameTooltip:AddDoubleLine(u.Colorize("Local Time:", 1, 1, 0.5), time, 1, 1, 1)
                GameTooltip:AddDoubleLine(u.Colorize("Server Timer:", 1, 1, 0.5), servertime, 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(u.Colorize("Left-Click:", 0, 1, 0.5), u.Colorize("Start Timer", 0, 1, 0.5), 1,
                    1, 1)
                GameTooltip:AddDoubleLine(u.Colorize("Right-Click:", 0, 1, 0.5), u.Colorize("Reset Timer", 0, 1, 0.5), 1,
                    1, 1)
                GameTooltip:Show()
                this.text:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\6.ttf", 20, "OUTLINE")
            end,
            function(_, button)
                this:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                if TimeManagerFrame then
                    if TimeManagerClockButton.alarmFiring then
                        TimeManager_TurnOffAlarm()
                    end
                    ToggleTimeManager()
                    return
                end
                if arg1 == "LeftButton" then
                    if this.timerFrame:IsShown() then
                        this.timerFrame:Hide()
                    else
                        this.timerFrame:Show()
                    end
                elseif arg1 == "RightButton" then
                    this.timerFrame.Snapshot = GetTime()
                end
            end,
            function()
                if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
                local h, m = GetGameTime()
                local noon = " AM"
                local time = ""
                time = date("%I:%M %p")
                this.text:SetText(time)
            end
        )
        clockWidget.timerFrame = CreateFrame("Frame", "SimpleUITimer", UIParent)
        clockWidget.timerFrame:Hide()
        clockWidget.timerFrame:SetWidth(120)
        clockWidget.timerFrame:SetHeight(35)
        clockWidget.timerFrame:SetPoint("TOP", 0, -100)

        clockWidget.timerFrame.text = clockWidget.timerFrame:CreateFontString("Status", "LOW", "GameFontNormal")
        clockWidget.timerFrame.text:SetFontObject(GameFontWhite)
        clockWidget.timerFrame.text:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\SimpleUI.ttf", 12, "OUTLINE")
        clockWidget.timerFrame.text:SetAllPoints(clockWidget.timerFrame)
        clockWidget.timerFrame:SetScript("OnUpdate", function()
            if not clockWidget.timerFrame.Snapshot then clockWidget.timerFrame.Snapshot = GetTime() end
            clockWidget.timerFrame.curTime = SecondsToTime(floor(GetTime() - clockWidget.timerFrame.Snapshot))
            if clockWidget.timerFrame.curTime ~= "" then
                clockWidget.timerFrame.text:SetText("|c33cccccc" .. clockWidget.timerFrame.curTime)
            else
                clockWidget.timerFrame.text:SetText("|cffff3333 --- " .. "NEW TIMER" .. " ---")
            end
        end)
        clockWidget:SetPoint("CENTER", middlePanel, "CENTER", 0, 0)
        bar.widgets.time = clockWidget

        --#####LEFT SIDE #######

        local lagWidget = CreateWidget(leftPanel, "SimpleUIWidgetLag", 12,
            function(widget)
                local lag, fps, laghex, fpshex, _
                local active = 0
                GameTooltip:SetOwner(widget, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetText("|cff1a9fc0" .. "System Info")
                for i = 1, GetNumAddOns() do
                    if IsAddOnLoaded(i) then
                        active = active + 1
                    end
                end

                local memkb, gckb = gcinfo()
                local memmb = memkb and memkb > 0 and u.Round((memkb or 0) / 1000, 2) .. " MB" or UNAVAILABLE
                local gcmb = gckb and gckb > 0 and u.Round((gckb or 0) / 1000, 2) .. " MB" or UNAVAILABLE

                local nin, nout, nping = GetNetStats()

                GameTooltip:AddDoubleLine(u.Colorize("Active Addons:", 1, 1, 0.5), active .. "/" .. GetNumAddOns(), 1, 1,
                    1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(u.Colorize("Memory Usage:", 1, 1, 0.5), memmb, 1, 1, 1)
                GameTooltip:AddDoubleLine(u.Colorize("Next Memory Cleanup:", 1, 1, 0.5), gcmb, 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(u.Colorize("Network Down:", 1, 1, 0.5), u.Round(nin, 1) .. " KB/s", 1, 1, 1)
                GameTooltip:AddDoubleLine(u.Colorize("Network Up:", 1, 1, 0.5), u.Round(nout, 1) .. " KB/s", 1, 1, 1)
                GameTooltip:AddDoubleLine(u.Colorize("Network Latency:", 1, 1, 0.5), nping .. " ms", 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(u.Colorize("Graphic Renderer:", 1, 1, 0.5), GetCVar("gxApi"), 1, 1, 1)
                GameTooltip:AddDoubleLine(u.Colorize("Screen Resolution:", 1, 1, 0.5), GetCVar("gxResolution"), 1, 1, 1)
                GameTooltip:AddDoubleLine(u.Colorize("UI-Scale:", 1, 1, 0.5), u.Round(UIParent:GetEffectiveScale()), 1, 1,
                    1)

                GameTooltip:Show()

                this.text:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\6.ttf", 14, "OUTLINE")
            end, nil,
            function()
                local lag, fps, laghex, fpshex, _
                if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end

                fps = floor(GetFramerate())
                _, _, lag = GetNetStats()

                _, _, _, fpshex = u.GetColorGradient(fps / 60)
                _, _, _, laghex = u.GetColorGradient(60 / lag)
                fps = fpshex .. fps .. "|r"
                lag = laghex .. lag .. "|r"
                this.text:SetText(fps .. " " .. "FPS" .. " & " .. lag .. " " .. "MS")
            end
        )
        lagWidget:SetPoint("RIGHT", leftPanel, "RIGHT", 0, 10)
        bar.widgets.lag = lagWidget

        local timetoLevelFramWatch = CreateFrame("Frame")
        timetoLevelFramWatch:SetScript("OnUpdate", function()

        end)

        local ranks = {
            { name = "Noob",       range = { 1, 10 },  color = { 1.0, 0.0, 0.0 } }, -- Red
            { name = "Apprentice", range = { 11, 20 }, color = { 1.0, 0.5, 0.0 } }, -- Orange
            { name = "Adept",      range = { 21, 30 }, color = { 1.0, 1.0, 0.0 } }, -- Yellow
            { name = "Veteran",    range = { 31, 40 }, color = { 0.0, 1.0, 0.0 } }, -- Green
            { name = "Master",     range = { 41, 50 }, color = { 0.0, 0.5, 1.0 } }, -- Blue
            { name = "Legend",     range = { 51, 60 }, color = { 0.6, 0.2, 1.0 } }, -- Purple
        }

        local function GetRankInfo(level)
            for _, rank in ipairs(ranks) do
                if level >= rank.range[1] and level <= rank.range[2] then
                    local value = level - rank.range[1] + 1
                    local maxValue = rank.range[2] - rank.range[1] + 1
                    return rank.name, rank.color, value, maxValue
                end
            end
            return nil
        end

        GameTooltipStatusBar:ClearAllPoints()
        GameTooltipStatusBar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 4, -2)
        GameTooltipStatusBar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -4, -2)
        GameTooltipStatusBar:SetHeight(12)

        GameTooltipStatusBar.bg = GameTooltipStatusBar:CreateTexture(nil, "BACKGROUND")
        GameTooltipStatusBar.bg:SetTexture("Interface\\AddOns\\SimpleUI\\Media\\Textures\\SimpleUI-Default.blp")
        GameTooltipStatusBar.bg:SetVertexColor(.1, .1, 0, .8)
        GameTooltipStatusBar.bg:SetAllPoints(true)
        local statusBar = GameTooltipStatusBar

        if statusBar then
            -- Get the number of children and iterate manually
            local numChildren = statusBar:GetNumChildren()
            for i = 1, numChildren do
                local child = statusBar:GetChildren(i) -- Use manual indexing
                if child and child:GetScript("OnUpdate") then
                    -- Disable the OnUpdate script
                    child:SetScript("OnUpdate", nil)
                    DEFAULT_CHAT_FRAME:AddMessage("Removed OnUpdate from child frame.")
                end
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("GameTooltipStatusBar not found.")
        end

        local function RankSystem(level)
            local rankName, rankColor, value, maxValue = GetRankInfo(level)
            if rankName then
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(u.Colorize("Rank:", 1, 1, 0.5), u.Colorize(rankName, unpack(rankColor)), 1, 1,
                    1)

                GameTooltipStatusBar:SetMinMaxValues(0, maxValue)
                GameTooltipStatusBar:SetValue(value)
                GameTooltipStatusBar:SetStatusBarTexture(
                    "Interface\\AddOns\\SimpleUI\\Media\\Textures\\SimpleUI-Default.blp")
                GameTooltipStatusBar:SetStatusBarColor(unpack(rankColor))
                GameTooltipStatusBar:Show()
            end
        end

        local XpToLevel = CreateFrame("Frame", "SimpleXPToLevel")
        local sessionStartExp  = UnitXP("player")
        local sessionStartLvl  = UnitLevel("player")
        local totalExpThisSession = 0
        local totalLvlGained   = 0
        local killsThisSession = 0
        local xpPerKill        = 0
        local sessionStartTime = GetTime()
        local lastExp          = sessionStartExp
        

        local function UpdateExpStats(self)
            local currXP   = UnitXP("player")
            local maxXP    = UnitXPMax("player")
            local currTime = GetTime()
            local lvl      = UnitLevel("player")
        
            -- Accumulate session XP
            if currXP ~= lastExp then
                totalExpThisSession = totalExpThisSession + (currXP - lastExp)
                lastExp = currXP
            end
        
            local timeElapsed = currTime - sessionStartTime
            local expPerHour  = (timeElapsed > 0)
                                and math.floor(totalExpThisSession / timeElapsed * 3600)
                                or 0
        
            local killsToLvl  = 0
            if xpPerKill > 0 then
                killsToLvl = math.ceil((maxXP - currXP) / xpPerKill)
            end
        
            totalLvlGained = lvl - sessionStartLvl
        
            Wonderbar.xpPerHour  = expPerHour
            Wonderbar.killsToLvl = killsToLvl
        end

        local function ResetXPTracker()
            sessionStartExp     = UnitXP("player")
            sessionStartLvl     = UnitLevel("player")
            totalExpThisSession = 0
            totalLvlGained      = 0
            killsThisSession    = 0
            xpPerKill           = 0
            sessionStartTime    = GetTime()
            lastExp             = sessionStartExp
        end

        XpToLevel:SetScript("OnEvent", function()
            if event == "PLAYER_ENTERING_WORLD" then
                -- Reset session stats
                sessionStartExp     = UnitXP("player")
                sessionStartLvl     = UnitLevel("player")
                totalExpThisSession = 0
                totalLvlGained      = 0
                killsThisSession    = 0
                xpPerKill           = 0
                sessionStartTime    = GetTime()
                lastExp             = sessionStartExp
        
            elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
                -- Example: “You gain 147 experience.” or “Plainstrider dies, you gain 85 experience.”
                -- Use parentheses around (%d+) to capture the digits as capture #1.
                local startPos, endPos, gainedStr = string.find(arg1, "(%d+) experience")
                if gainedStr then
                    local gainedNum = tonumber(gainedStr)
                    -- Only if we successfully parsed a number do we proceed
                    if gainedNum then
                        killsThisSession = killsThisSession + 1
                        xpPerKill        = gainedNum  -- store XP from the *most recent kill*
                    end
                end
            end
        end)

        XpToLevel:RegisterEvent("PLAYER_ENTERING_WORLD")
        XpToLevel:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")

        XpToLevel:SetScript("OnUpdate", UpdateExpStats)

        local expWidget = CreateWidget(leftPanel, "SimpleUIWidgetExp", 12, function(widget)
                GameTooltip:SetOwner(widget, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetText("|cff1a9fc0" .. "Experience")
                GameTooltip:AddLine(" ")
                local currXP = UnitXP("player")
                local maxXP = UnitXPMax("player")
                local currLevel = UnitLevel("player")
                local restedXP = GetXPExhaustion()
                local factionName, standingID, barMin, barMax, barValue = GetWatchedFactionInfo()
                if UnitLevel("player") < _G.MAX_PLAYER_LEVEL then
                    GameTooltip:AddDoubleLine(u.Colorize("Level:", 1, 1, 0.5), currLevel, 1, 1, 1)

                    GameTooltip:AddDoubleLine(u.Colorize("Experience:", 1, 1, 0.5),
                        "(|cff1a9fc0" ..
                        floor((currXP / maxXP) * 100) .. "%|r) " .. u.Colorize(currXP .. " / " .. maxXP, 0, 1, 0), 1, 1,
                        1)
                    if restedXP ~= nil then
                        GameTooltip:AddDoubleLine(u.Colorize("Rested:", 1, 1, 0.5),
                            "(|cff1a9fc0" .. floor((restedXP / maxXP) * 100) .. "%|r) " .. u.Colorize(restedXP, 0, 1, 0),
                            1, 1, 1)
                    end
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddDoubleLine(u.Colorize("XP per Hour:", 1, 1, 0.5),
                        "|cff1a9fc0" .. (Wonderbar.xpPerHour or 0), 1, 1, 1)
                    GameTooltip:AddDoubleLine(u.Colorize("Kills to Level:", 1, 1, 0.5),
                        "|cff1a9fc0" .. (Wonderbar.killsToLvl), 1, 1, 1)
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddDoubleLine(u.Colorize("XP This Session:", 1, 1, 0.5),
                        "|cff1a9fc0" .. totalExpThisSession, 1, 1, 1)
                    GameTooltip:AddDoubleLine(u.Colorize("Levels Gained:", 1, 1, 0.5), "|cff1a9fc0" .. totalLvlGained, 1,
                        1, 1)
                else
                    GameTooltip:AddDoubleLine(u.Colorize("Experience:", 1, 1, 0.5), u.Colorize(NOT_APPLICABLE, 0, 1, 0),
                        1, 1, 1)
                end

                if factionName then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddDoubleLine(u.Colorize("Tracked Reputation:", 1, 1, 0.5),
                        u.Colorize(factionName, 0, 1, 0), 1, 1, 1)
                    local standingName = GetText("FACTION_STANDING_LABEL" .. standingID, UnitSex("player"))
                    GameTooltip:AddDoubleLine(u.Colorize("Standing:", 1, 1, 0.5), u.Colorize(standingName, 0, 1, 0), 1, 1,
                        1)
                    GameTooltip:AddDoubleLine(u.Colorize("Current Reputation:", 1, 1, 0.5),
                        u.Colorize(barValue - barMin .. " / " .. barMax - barMin, 0, 1, 0), 1, 1, 1)
                    local percent = floor(((barValue - barMin) / (barMax - barMin)) * 100)
                    GameTooltip:AddDoubleLine(u.Colorize("Progress:", 1, 1, 0.5), u.Colorize(percent .. "%", 0, 1, 0), 1,
                        1, 1)
                    --GameTooltip:AddDoubleLine(u.Colorize("Rep Line2:", 1, 1, 0.5), u.Colorize(f1, 0, 1, 0), 1, 1, 1)
                    --GameTooltip:AddDoubleLine(u.Colorize("Rep Line3:", 1, 1, 0.5), u.Colorize(f2, 0, 1, 0), 1, 1, 1)
                    --GameTooltip:AddDoubleLine(u.Colorize("Rep Line4:", 1, 1, 0.5), u.Colorize(f3, 0, 1, 0), 1, 1, 1)
                    --GameTooltip:AddDoubleLine(u.Colorize("Rep Line5:", 1, 1, 0.5), u.Colorize(f4, 0, 1, 0), 1, 1, 1)
                end

                local level = UnitLevel("player")
                RankSystem(level)

                GameTooltip:Show()
                widget.text:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\6.ttf", 14, "OUTLINE")
            end, function()
                ResetXPTracker()
                SimpleUI_SystemMessage("XP tracker has been reset.")
            end, nil,
            function()
                local curexp, difexp, maxexp, remexp, oldexp, remstring
                if UnitLevel("player") < _G.MAX_PLAYER_LEVEL then
                    curexp = UnitXP("player")
                    if oldexp ~= nil then
                        difexp = curexp - oldexp
                        maxexp = UnitXPMax("player")
                        if difexp > 0 then
                            remexp = floor((maxexp - curexp) / difexp)
                            remstring = "|cff555555 " .. remexp .. "|r"
                        else
                            remstring = nil
                        end
                    end
                    oldexp = curexp

                    local a = UnitXP("player")
                    local b = UnitXPMax("player")
                    local xprested = tonumber(GetXPExhaustion())
                    if remstring == nil then remstring = "" end
                    if xprested ~= nil then
                        this.text:SetText("Exp" .. ": |cffaaaaff" .. floor((a / b) * 100) .. "%" .. remstring)
                    else
                        this.text:SetText("Exp" .. ": " .. floor((a / b) * 100) .. "%" .. remstring)
                    end
                else
                    this.text:SetText("Exp" .. ": " .. NOT_APPLICABLE)
                end
            end)
        expWidget:RegisterEvent("PLAYER_ENTERING_WORLD")
        expWidget:RegisterEvent("PLAYER_XP_UPDATE")
        expWidget:SetPoint("RIGHT", bar.widgets.lag, "LEFT", -50, 0)
        bar.widgets.exp = expWidget

        local friendsWidget = CreateWidget(leftPanel, "SimpleUIWidgetFriends", 12, function(widget)
                local init       = nil
                local all        = GetNumFriends()
                local playerzone = GetRealZoneText()

                for friendIndex = 1, all do
                    local friend_name, friend_level, friend_class, friend_area, friend_connected = GetFriendInfo(
                        friendIndex)
                    if friend_connected and friend_class and friend_level then
                        if not init then
                            GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
                            GameTooltip:SetText("|cff1a9fc0" .. "Friends Online")
                            GameTooltip:AddLine(" ")
                            init = true
                        end
                        local ccolor = RAID_CLASS_COLORS[friend_class] or { 1, 1, 1 }
                        local lcolor = GetDifficultyColor(tonumber(friend_level)) or { 1, 1, 1 }
                        local zcolor = friend_area == playerzone and "|cff33ffcc" or "|cffcccccc"
                        GameTooltip:AddDoubleLine(
                            u.Rgbhex(lcolor) .. "  [" .. friend_level .. "] " .. u.Rgbhex(ccolor) .. friend_name,
                            zcolor .. friend_area, 1, 1, 1)
                    end
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(u.Colorize("Left-Click:", 0, 1, 0.5),
                    u.Colorize("Open Friends List", 0, 1, 0.5), 1, 1, 1)
                GameTooltip:Show()
                widget.text:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\6.ttf", 14, "OUTLINE")
            end,
            function()
                ToggleFriendsFrame(1)
            end,
            nil,
            function()
                local online = 0
                local all = GetNumFriends()
                for friendIndex = 1, all do
                    local friend_name, friend_level, friend_class, friend_area, friend_connected = GetFriendInfo(
                        friendIndex)
                    if (friend_connected) then
                        online = online + 1
                    end
                end

                this.text:SetText(FRIENDS .. ": " .. online)
            end)
        friendsWidget:RegisterEvent("PLAYER_ENTERING_WORLD")
        friendsWidget:RegisterEvent("FRIENDLIST_UPDATE")
        friendsWidget:SetPoint("RIGHT", bar.widgets.exp, "LEFT", -50, 0)
        bar.widgets.friends = friendsWidget

        local guildWidget = CreateWidget(leftPanel, "SimpleUIWidgetsGuild", 12, function(widget)
                if not GetGuildInfo("player") then return end

                local raidparty = {}
                for i = 1, 4 do -- detect people in group
                    if UnitExists("party" .. i) then
                        raidparty[UnitName("party" .. i)] = true
                    end
                end
                for i = 1, 40 do -- detect people in raid
                    if UnitExists("raid" .. i) then
                        raidparty[UnitName("raid" .. i)] = true
                    end
                end

                local all = GetNumGuildMembers()
                local playerzone = GetRealZoneText()
                local off = FauxScrollFrame_GetOffset(GuildListScrollFrame)
                local left, field, init

                for i = 1, all do
                    local name, _, _, level, class, zone, _, _, online = GetGuildRosterInfo(off + i)
                    if online then
                        if not init then
                            GameTooltip:SetOwner(widget, "ANCHOR_BOTTOMRIGHT")
                            GameTooltip:SetText("|cff1a9fc0" .. "Guild Online")
                            GameTooltip:AddLine(" ")
                            init = true
                        end

                        local ccolor = RAID_CLASS_COLORS[class] or { 1, 1, 1 }
                        local lcolor = GetDifficultyColor(tonumber(level)) or { 1, 1, 1 }
                        local level = "|cff555555" .. "  [" .. u.Rgbhex(lcolor) .. level .. "|cff555555]"
                        local raid = raidparty[name] and "|cff555555[|cff33ffccG|cff555555]|r" or ""

                        if not left then
                            left = level .. raid .. " " .. u.Rgbhex(ccolor) .. name
                            GameTooltip:AddLine(left)
                        else
                            field = raid .. level .. " " .. u.Rgbhex(ccolor) .. name
                            GameTooltip:AddLine(field)
                            left = nil
                        end
                    end
                end

                if left then
                    GameTooltip:AddLine(left .. "")
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(u.Colorize("Left-Click:", 0, 1, 0.5), u.Colorize("Open Guild List", 0, 1, 0.5),
                    1, 1, 1)
                GameTooltip:Show()
                widget.text:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\6.ttf", 14, "OUTLINE")
            end,
            function() ToggleFriendsFrame(3) end,
            function()
                if (this.tick or 60) > GetTime() then return else this.tick = GetTime() + 60 end
                if GetGuildInfo("player") then GuildRoster() end
            end,
            function()
                if GetGuildInfo("player") then
                    local count = 0
                    for i = 1, GetNumGuildMembers() do
                        local _, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
                        if online then count = count + 1 end
                    end
                    this.text:SetText(GUILD .. ": " .. count)
                else
                    this.text:SetText(GUILD .. ": " .. NOT_APPLICABLE)
                end
            end)
        guildWidget:RegisterEvent("PLAYER_ENTERING_WORLD")
        guildWidget:RegisterEvent("GUILD_ROSTER_UPDATE")
        guildWidget:RegisterEvent("PLAYER_GUILD_UPDATE")
        guildWidget:SetPoint("RIGHT", bar.widgets.friends, "LEFT", -50, 0)
        bar.widgets.guild = guildWidget

        --#####RIGHT SIDE #######

        local bagsWidget = CreateWidget(rightPanel, "SimpleUIWidgetsBags", 12, function()
            local maxslots = 0
            local usedslots = 0

            local free = 0
            for i = 0, 4 do
                for slot = 1, GetContainerNumSlots(i) do
                    local link = GetContainerItemLink(i, slot)
                    if not (link) then
                        free = free + 1
                    end
                end
            end

            for bag = 0, 4 do
                local bagsize = GetContainerNumSlots(bag)
                maxslots = maxslots + bagsize
                for j = 1, bagsize do
                    local link = GetContainerItemLink(bag, j)
                    if link then
                        usedslots = usedslots + 1
                    end
                end
            end
            local freeslots = maxslots - usedslots

            GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
            GameTooltip:SetText("|cff1a9fc0" .. "Bags")
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(u.Colorize("Free Slots:", 1, 1, 0.5), u.Colorize(freeslots, 0.5, 1, 0.5), 1, 1, 1)
            GameTooltip:AddDoubleLine(u.Colorize("Slots Used:", 1, 1, 0.5), usedslots, 1, 1, 1)
            GameTooltip:AddDoubleLine(u.Colorize("Max Slots:", 1, 1, 0.5), maxslots, 1, 1, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(u.Colorize("Left-Click:", 0, 1, 0.5), u.Colorize("Open Bags", 0, 1, 0.5), 1, 1, 1)
            GameTooltip:Show()

            this.text:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\6.ttf", 14, "OUTLINE")
        end, OpenAllBags, function()
            local maxslots = 0
            local usedslots = 0

            local free = 0
            for i = 0, 4 do
                for slot = 1, GetContainerNumSlots(i) do
                    local link = GetContainerItemLink(i, slot)
                    if not (link) then
                        free = free + 1
                    end
                end
            end

            for bag = 0, 4 do
                local bagsize = GetContainerNumSlots(bag)
                maxslots = maxslots + bagsize
                for j = 1, bagsize do
                    local link = GetContainerItemLink(bag, j)
                    if link then
                        usedslots = usedslots + 1
                    end
                end
            end
            local freeslots = maxslots - usedslots
            this.text:SetText(freeslots .. " (" .. usedslots .. "/" .. maxslots .. ")")
        end)
        bagsWidget:RegisterEvent("PLAYER_ENTERING_WORLD")
        bagsWidget:RegisterEvent("BAG_UPDATE")

        bagsWidget:SetPoint("LEFT", rightPanel, "LEFT", 0, 15)
        bar.widgets.bags = bagsWidget


        local goldWidget = CreateWidget(rightPanel, "SimpleUIWidgetGold", 12, function()
                local dmod = ""
                if this.diffMoney < 0 then
                    dmod = "|cffff8888-"
                elseif this.diffMoney > 0 then
                    dmod = "|cff88ff88+"
                end

                GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")

                GameTooltip:SetText("|cff1a9fc0" .. "Money")
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(u.Colorize("Login:", 1, 1, 0.5), u.CreateGoldString(this.initMoney), 0, 0, 0)
                GameTooltip:AddDoubleLine(u.Colorize("Now:", 1, 1, 0.5), u.CreateGoldString(GetMoney()), 0, 0, 0)
                GameTooltip:AddLine(" ")
                local totalgold = 0
                for name, gold in pairs(SimpleUI_cache["gold"][GetRealmName()]) do
                    totalgold = totalgold + gold
                    if name ~= UnitName("player") then
                        GameTooltip:AddDoubleLine(u.Colorize(name, 1, 1, 0.5), u.CreateGoldString(gold), 1, 1, 1)
                    end
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(u.Colorize("This Session:", 1, 1, 0.5),
                    dmod .. u.CreateGoldString(math.abs(this.diffMoney)), 1, 1, 1)
                GameTooltip:AddDoubleLine(u.Colorize("Total Gold:", 1, 1, 0.5), u.CreateGoldString(totalgold), 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(u.Colorize("Left-Click:", 0, 1, 0.5), u.Colorize("Open Bags", 0, 1, 0.5), 1, 1,
                    1)
                GameTooltip:Show()

                this.text:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\6.ttf", 14, "OUTLINE")
            end,
            OpenAllBags,
            nil,
            function()
                local realm                         = GetRealmName()
                local unit                          = UnitName("player")
                local money                         = GetMoney()
                local goldstr                       = u.CreateGoldString(GetMoney())

                this.initMoney                      = this.initMoney or money
                this.diffMoney                      = money - this.initMoney

                SimpleUI_cache["gold"][realm]       = SimpleUI_cache["gold"][realm] or {}
                SimpleUI_cache["gold"][realm][unit] = money

                this.text:SetText(goldstr)
            end)
        goldWidget:RegisterEvent("PLAYER_ENTERING_WORLD")
        goldWidget:RegisterEvent("PLAYER_MONEY")
        goldWidget:SetPoint("LEFT", bar.widgets.bags, "RIGHT", 50, 0)
        bar.widgets.gold = goldWidget


        local durabilityWidget = CreateWidget(rightPanel, "SimpleUIWidgetsDurability", 12, function(widget)
                if widget.totalRep > 0 then
                    GameTooltip:SetOwner(widget, "ANCHOR_BOTTOMLEFT")
                    GameTooltip:SetText("|cff1a9fc0" .. (string.gsub(REPAIR_COST, ":", "")) .. "|r")
                    SetTooltipMoney(GameTooltip, widget.totalRep)
                    GameTooltip:AddLine(" ")
                    for _, line in ipairs(widget.itemLines) do
                        GameTooltip:AddDoubleLine(line[1], line[2], 1, 1, 1)
                    end
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddDoubleLine(u.Colorize("Left-Click:", 0, 1, 0.5),
                        u.Colorize("Open Character Panel", 0, 1, 0.5), 1, 1, 1)
                    GameTooltip:Show()
                end
                this.text:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\6.ttf", 14, "OUTLINE")
            end,
            function()
                ToggleCharacter("PaperDollFrame")
            end,
            nil,
            function()
                if event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then return end

                local repPercent = 100
                local lowestPercent = 100
                this.totalRep = 0
                u.Wipe(this.itemLines)
                for _, id in pairs(this.durability_slots) do
                    local hasItem, _, repCost = this.scantip:SetInventoryItem("player", id)
                    if (hasItem) then
                        this.totalRep = this.totalRep + repCost
                        local line, lval, rval = this.scantip:Find(this.duracapture)
                        if (lval and rval) then
                            repPercent = math.floor(lval / rval * 100)
                            if repPercent < 100 then
                                local link = GetInventoryItemLink("player", id)
                                local r, g, b, hex = u.GetColorGradient(repPercent / 100)
                                local cPercent = string.format("%s%s%%|r", hex, repPercent)
                                this.itemLines[table.getn(this.itemLines) + 1] = { link, cPercent }
                            end
                        end
                    end
                    if repPercent < lowestPercent then
                        lowestPercent = repPercent
                    end
                end

                this.text:SetText(lowestPercent .. "% " .. ARMOR)
            end)
        durabilityWidget.itemLines = {}
        durabilityWidget.durability_slots = { 1, 3, 5, 6, 7, 8, 9, 10, 16, 17, 18 }
        durabilityWidget.totalRep = 0
        durabilityWidget.scantip = u.TipScan:GetScanner("panel")
        durabilityWidget.duracapture = string.gsub(DURABILITY_TEMPLATE, "%%[^%s]+", "(.+)")
        durabilityWidget:RegisterEvent("PLAYER_ENTERING_WORLD")
        durabilityWidget:RegisterEvent("PLAYER_MONEY")
        durabilityWidget:RegisterEvent("PLAYER_REGEN_ENABLED")
        durabilityWidget:RegisterEvent("PLAYER_DEAD")
        durabilityWidget:RegisterEvent("PLAYER_UNGHOST")
        durabilityWidget:RegisterEvent("UNIT_INVENTORY_CHANGED")
        durabilityWidget:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
        durabilityWidget:SetPoint("LEFT", bar.widgets.gold, "RIGHT", 50, 0)
        bar.widgets.durability = durabilityWidget

        this.bar = bar
    end

    local login = CreateFrame("Frame")
    login:SetScript("OnEvent", function()
        ConsctructBar()
    end)
    login:RegisterEvent("VARIABLES_LOADED")
end)
