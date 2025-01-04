--[[
SimpleUI Unitframes Module for WoW Vanilla 1.12 - Turtle WoW
Author: BeardedRasta
Description: Manages unit frame buffs, debuffs, and visibility with clean and efficient logic.
--]]

SimpleUI:AddModule("Unitframes", function()
    if SimpleUI:IsDisabled("Unitframes") then return end

    local Unitframe = CreateFrame("Frame", nil, UIParent)
    local _G = getfenv(0)
    local u = SUI_Util
    local E = SimpleUI.Element
    local startid = 1
    
    -- Module Data
    local frames, delayed = {}, {}
    local scanner

    local PLAYER_BUFF_START_ID = -1
    -----------------------------------------------
    -- Delayed Frame Visibility Update
    -----------------------------------------------

    Unitframe:SetScript("OnUpdate", function()
        if InCombatLockdown and not InCombatLockdown() then
            for frame in pairs(delayed) do
                frame:UpdateVisibility()
                delayed[frame] = nil
            end
        end
    end)

    -----------------------------------------------
    -- Visibility Scan Frame
    -----------------------------------------------

    local visibilityscan = CreateFrame("Frame", "SimpleUIUnitFrameVisibility", UIParent)
    visibilityscan.frames = {}
    visibilityscan:SetScript("OnUpdate", function()
        if (this.limit or 1) > GetTime() then
            return
        else
            this.limit = GetTime() + 0.2
        end
        for frame in pairs(this.frames) do
            frame:UpdateVisibility()
        end
    end)

    local TimerFrame = CreateFrame("Frame")
    TimerFrame.elapsed = 0

    function TimerFrame:Start(frame, delay, callback)
        if self.running == nil then
            self.running = true
        end

        self.delay = delay
        self.callback = callback
        self.elapsed = 0
        if self.running then
            self:SetScript("OnUpdate", function()
                self.elapsed = self.elapsed + arg1
                if self.elapsed >= self.delay then
                    frame:Hide()
                    if self.callback then
                        self.callback()
                        frame:Show()
                    end
                    self:SetScript("OnUpdate", nil)
                    self.running = false
                end
            end)
        else
            self:SetScript("OnUpdate", nil)
        end
    end


    -----------------------------------------------
    -- Buff Detection and Visibility Management
    -----------------------------------------------

    local detect_icon, detect_name
    -----------------------------------------------
    -- Function: DetectBuff
    -- Purpose: Detects and retrieves a buff's texture or name with caching to optimize performance.
    -- Parameters:
    --   name (string): Unit name to check.
    --   id (number): Buff ID for the specified unit.
    -- Returns:
    --   string, number: Texture path and a flag indicating if detected.
    -----------------------------------------------
    function Unitframe:DetectBuff(name, id)
        if not name or not id then return end

        -- Initialize or reset variables
        detect_icon, detect_name = nil, nil
        scanner = scanner or u.TipScan:GetScanner("unitframes")
        SimpleUI_cache.buff_icons = SimpleUI_cache.buff_icons or {}

        detect_icon = UnitBuff(name, id)
        if detect_icon then
            if not SimpleUI_AuraList.icons[detect_name] and not SimpleUI_cache.buff_icons[detect_icon] then
                -- Retrieve buff name and cache it
                scanner:SetUnitBuff(name, id)
                detect_name = scanner:Line(1)
                if detect_name then
                    SimpleUI_cache.buff_icons[detect_icon] = detect_name
                end
            end
            return UnitBuff(name, id)
        end

        -- Tooltip Scanner fallback for name-based icons
        scanner:SetUnitBuff(name, id)
        detect_name = scanner:Line(1)
        if detect_name then
            if SimpleUI_AuraList["icons"][detect_name] then
                return "Interface\\Icons\\" .. SimpleUI_AuraList.icons[detect_name], 1
            end
            for icon, cached_name in pairs(SimpleUI_cache.buff_icons) do
                if cached_name == detect_name then
                    return icon, 1
                end
            end
            return "interface\\icons\\inv_misc_questionmark", 1
        end
        return nil
    end

    -----------------------------------------------
    -- Function: UpdateVisibility
    -- Purpose: Updates the visibility of a unit frame based on combat lockdown, raid status, and other rules.
    -- Returns: None
    -----------------------------------------------
    function Unitframe:UpdateVisibility()
        local frame = self or this
        if not frame then return end

        -- Handle combat lockdown by delaying visibility updates
        if InCombatLockdown and InCombatLockdown() then
            delayed[frame] = true
            return
        end

        if frame.firstLoad == nil then
            frame.firstLoad = true
        end

        -- Determine unit string
        local unitstr = string.format("%s%s", frame.label or "", frame.id or "")

        -- Cache raid frame ID
        if not frame.cache_raid then
            if strsub(self:GetName(), 0, 6) == "SimpleUIraid" then
                frame.cache_raid = tonumber(strsub(self:GetName(), 7, 8))
            else
                frame.cache_raid = 0
            end
        end

        -- Raid/Party Frame Adjustments
        if frame.cache_raid > 0 then
            local id = frame.cache_raid

            -- always show self in raidframes
            if frame.label == "party" or frame.label == "player" then
                frame.id = id
                frame.label = "raid"
            end
        end

        local visibility = string.format("[target=%s,exists] show; hide", unitstr)
        if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].locked and SimpleUI.unlock then
        elseif frame.firstLoad then
            visibility = "hide"     -- Force a hide on the first load to initialize the model
            frame.firstLoad = false -- Mark firstLoad as completed
            self.visible = nil
        elseif self.config.visible == nil then
            visibility = "hide"
            self.visible = nil
        elseif SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].hidepartyraid == 1 and self.label and strsub(self.label, 0, 5) == "party" and UnitInRaid("player") then
            visibility = "hide"
            self.visible = nil
        elseif (self.framename == "Group0" or self.framename == "PartyPet0" or self.framename == "Party0Target") and (GetNumPartyMembers() <= 0 or (SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].hidepartyraid == 1 and UnitInRaid("player"))) then
            visibility = "hide"
            self.visible = nil
        end

        if self.unitname and self.unitname ~= "focus" and self.unitname ~= "focustarget" then
            self:Show()
        elseif visibility == "hide" then
            self:Hide()
        elseif visibility == "show" then
            self:Show()
        else
            if UnitName(unitstr) then
                if self.label == "partypet" then
                    if not UnitIsVisible(unitstr) or not UnitExists("party" .. self.id) then
                        self:Hide()
                        return
                    end
                elseif self.label == "pettarget" then
                    if not UnitIsVisible(unitstr) or not UnitExists("pet") then
                        self.frame:Hide()
                        return
                    end
                end
                if self.config.visible then
                    self:Show()
                end
            else
                --self.lastUnit = nil
                self:Hide()
            end
        end


        --[[ -- Visibility rules based on configuration
        if frame.config and frame.config.visibile == false then
            frame:Hide()
            frame.visible = nil
            return
        end

        -- Determine visibility
        local shouldShow = false
        if UnitExists(unitstr) and UnitName(unitstr) then
            if frame.label == "partypet" then
                shouldShow = UnitExists("party" .. frame.id) and UnitIsVisible(unitstr)
            elseif frame.label == "pettarget" then
                shouldShow = UnitExists("pet") and UnitIsVisible(unitstr)
            else
                shouldShow = frame.config.visible ~= false
            end
        end

        -- Update frame visibility
        if shouldShow then
            frame:Show()
        else
            frame:Hide()
        end ]]
    end

    -----------------------------------------------
    -- Function: UpdateFrameSize
    -- Purpose: Updates the frame dimensions based on configuration settings.
    -- Returns: None
    -----------------------------------------------
    function Unitframe:UpdateFrameSize()
        -- Default Values
        local BORDER_SIZE, spacing = 2, self.config.pspace * u.GetPerfectPixel()
        local width, height = self.config.width, self.config.height
        local pheight, ptwidth, ptheight = self.config.manaheight, self.config.portraitwidth, self.config.portraitheight

        -- Calculate real frame height
        local realHeight = height + spacing + pheight + 2 * BORDER_SIZE
        if spacing < 0 and abs(spacing) > tonumber(pheight) then
            realHeight, spacing = height, 0
        end

        -- Update portrait dimensions
        local portraitOffset = 0
        if self.config.portrait == "left" or self.config.portrait == "right" then
            if ptwidth == -1 and ptheight == -1 then
                -- Align portrait size to frame height
                self.portrait:SetWidth(realHeight)
                self.portrait:SetHeight(realHeight)
                portraitOffset = realHeight + spacing + 2 * BORDER_SIZE
            else
                -- Use custom portrait dimensions
                self.portrait:SetWidth(ptwidth)
                self.portrait:SetHeight(ptwidth)
            end
        end

        -- Set final dimensions
        self:SetWidth(width + portraitOffset)
        self:SetHeight(realHeight)
    end

    -----------------------------------------------
    -- Function: SetIcons
    -- Purpose: Positions master and leader icons on the given frame.
    -- Parameters:
    --   frame (table): The frame to modify.
    --   p1 (string): First anchor point.
    --   p2 (string): Second anchor point.
    --   xOffset1, yOffset1 (number): Master icon offsets.
    --   xOffset2, yOffset2 (number): Leader icon offsets.
    -- Returns: None
    -----------------------------------------------
    local function SetIcons(frame, p1, p2, xOffset1, yOffset1, xOffset2, yOffset2)
        -- Position master icon
        frame.masterIcon:ClearAllPoints()
        frame.masterIcon:SetPoint(p1, frame, p2, xOffset1, yOffset1)

        -- Position leader icon
        frame.leaderIcon:ClearAllPoints()
        frame.leaderIcon:SetPoint(p1, frame, p2, xOffset2, yOffset2)
    end

    function Unitframe:UpdateConfig(f)
        local frame = f or self
        local cfg = frame.config
        local BORDER_SIZE, spacing = 2, cfg.pspace * u.GetPerfectPixel()

        local relative_point = "BOTTOM"
        if frame.config.panchor == "TOPLEFT" then
            relative_point = "BOTTOMLEFT"
        elseif frame.config.panchor == "TOPRIGHT" then
            relative_point = "BOTTOMRIGHT"
        end

        frame.dispellable = nil
        frame.indicators = nil
        frame.indicator_custom = nil

        -- Frame Visibility and Strata
        frame:SetFrameStrata("MEDIUM")
        frame.alpha_visible = cfg.alpha_visible
        frame.alpha_outofrange = cfg.alpha_outofrange
        frame.alpha_offline = cfg.alpha_offline

        -- Background Setup
        if not frame.background then
            frame.background = CreateFrame("Frame", nil, frame)
            u.CreateBackdrop(frame.background, 4.8, nil, nil, true)
            frame.background:SetFrameStrata("BACKGROUND")
            frame.background.backdrop.border:SetFrameLevel(frame.health.bar:GetFrameLevel() + 1)
            frame.background.backdrop.border:SetFrameStrata("MEDIUM")
        end
        Unitframe:ConfigureHealthBar(frame, cfg, BORDER_SIZE)         -- Health Bar Configuration
        Unitframe:ConfigurePowerBar(frame, cfg, BORDER_SIZE, spacing) -- Power Bar Configuration
        Unitframe:ConfigurePortrait(frame, cfg, BORDER_SIZE, spacing) -- Portrait Configuration
        Unitframe:ConfigureTexts(frame, cfg, BORDER_SIZE)             -- Text Configurations
        Unitframe:ConfigureIcons(frame, cfg, BORDER_SIZE)             -- Icons Configuration
        Unitframe:ConfigureLevel(frame, cfg)
        Unitframe:UpdateFrameBackground(frame)

        local buffs = frame.config.buffs
        local debuffs = frame.config.debuffs
        if (buffs == "TOPLEFT" and debuffs == "TOPRIGHT") or (buffs == "TOPRIGHT" and debuffs == "TOPLEFT") then
            frame.masterIcon:ClearAllPoints()
            frame.masterIcon:SetPoint("BOTTOMLEFT", frame.portrait, "TOPLEFT", 16, 4.5)

            frame.leaderIcon:ClearAllPoints()
            frame.leaderIcon:SetPoint("BOTTOMLEFT", frame.portrait, "TOPLEFT", 0, 2)
        elseif buffs == "TOPLEFT" or debuffs == "TOPLEFT" then
            SetIcons(frame, "BOTTOMRIGHT", "TOPRIGHT", -16, 3.5, 0, 1)
        elseif buffs == "TOPRIGHT" or debuffs == "TOPRIGHT" then
            SetIcons(frame, "BOTTOMLEFT", "TOPLEFT", 16, 3.5, 0, 1)
        elseif frame.label == "raid" then
            SetIcons(frame, "BOTTOMRIGHT", "TOPRIGHT", -16, -12.5, -1, -15)
            frame.masterIcon:SetAlpha(0.7)
            frame.leaderIcon:SetAlpha(0.7)
        end

        frame.happinessIcon:SetWidth(20)
        frame.happinessIcon:SetHeight(20)
        frame.happinessIcon:ClearAllPoints()
        frame.happinessIcon:SetPoint("RIGHT", frame.background.backdrop.border, "LEFT", 4, 3)
        frame.happinessIcon.texture:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness")
        frame.happinessIcon.texture:SetAllPoints(frame.happinessIcon)
        frame.happinessIcon.texture:SetTexCoord(0, 0.1875, 0, 0.359375)
        frame.happinessIcon:Hide()

        if frame.config.buffs == "off" then
            for i = 1, 32 do
                if frame.buffs and frame.buffs[i] then
                    frame.buffs[i]:Hide()
                    frame.buffs[i] = nil
                end
            end
            frame.buffs = nil
        else
            frame.buffs = frame.buffs or {}

            for i = 1, 32 do
                if i > frame.config.maxBuffs then
                    break
                end

                local pR = frame.config.buffsPerRow
                local r = floor((i - 1) / pR)
                local bN = "SimpleUI" .. frame.framename .. "Buff" .. i

                frame.buffs[i] = frame.buffs[i] or CreateFrame("Button", bN, frame)
                frame.buffs[i].texture = frame.buffs[i].texture or frame.buffs[i]:CreateTexture()
                frame.buffs[i].texture:SetTexCoord(.08, .92, .08, .92)
                frame.buffs[i].texture:SetAllPoints()

                frame.buffs[i].stacks = frame.buffs[i].stacks or
                    frame.buffs[i]:CreateFontString(nil, "OVERLAY", frame.buffs[i])
                frame.buffs[i].stacks:SetFontObject(SimpleUIAuraFont)
                frame.buffs[i].stacks:SetPoint("BOTTOMRIGHT", frame.buffs[i], 2, -2)
                frame.buffs[i].stacks:SetJustifyH("LEFT")
                frame.buffs[i].stacks:SetShadowColor(0, 0, 0)
                frame.buffs[i].stacks:SetShadowOffset(0.8, -0.8)
                frame.buffs[i].stacks:SetTextColor(1, 1, .5)

                frame.buffs[i].cd = frame.buffs[i].cd or
                    CreateFrame("Model", frame.buffs[i]:GetName() .. "Cooldown", frame.buffs[i], "CooldownFrameTemplate")
                frame.buffs[i].cd.SimpleUI_CooldownType = "ALL"
                frame.buffs[i].cd.SimpleUI_CooldownStyleText = 1
                frame.buffs[i].cd.SimpleUI_CooldownStyleAnimation = 0
                frame.buffs[i].id = i
                frame.buffs[i]:Hide()
                u.CreateBackdrop(frame.buffs[i], 6.8, nil, nil, false)


                frame.buffs[i]:RegisterForClicks("RightButtonUp")
                frame.buffs[i]:ClearAllPoints()


                local invert_h, invert_v, af
                if frame.config.buffs == "TOPLEFT" then
                    invert_h = 1
                    invert_v = 1
                    af = "BOTTOMLEFT"
                elseif frame.config.buffs == "BOTTOMLEFT" then
                    invert_h = -1
                    invert_v = 1
                    af = "TOPLEFT"
                elseif frame.config.buffs == "TOPRIGHT" then
                    invert_h = 1
                    invert_v = -1
                    af = "BOTTOMRIGHT"
                elseif frame.config.buffs == "BOTTOMRIGHT" then
                    invert_h = -1
                    invert_v = -1
                    af = "TOPRIGHT"
                end

                frame.buffs[i]:SetPoint(af, frame, frame.config.buffs,
                    invert_v * (i - 1 - r * pR) * (2 * 2 + frame.config.buffsize + 1),
                    invert_h * (r * (2 * 2 + frame.config.buffsize + 1) + (2 * 2 + 5)))

                u.SetSize(frame.buffs[i], frame.config.buffsize, frame.config.buffsize)

                if frame:GetName() == "SimpleUIplayer" then
                    frame.buffs[i]:SetScript("OnUpdate", E.Buff_OnUpdate)
                end

                frame.buffs[i]:SetScript("OnEnter", E.Buff_OnEnter)
                frame.buffs[i]:SetScript("OnLeave", E.Buff_OnLeave)
                frame.buffs[i]:SetScript("OnClick", E.Buff_OnClick)
            end
        end

        if frame.config.debuffs == "off" then
            for i = 1, 32 do
                if frame.debuffs and frame.debuffs[i] then
                    frame.debuffs[i]:Hide()
                    frame.debuffs[i] = nil
                end
            end
            frame.debuffs = nil
        else
            frame.debuffs = frame.debuffs or {}

            for i = 1, 32 do
                if i > frame.config.maxDebuffs then break end

                local dN = "SimpleUI" .. frame.framename .. "Debuff" .. i

                frame.debuffs[i] = frame.debuffs[i] or CreateFrame("Button", dN, frame)
                frame.debuffs[i].texture = frame.debuffs[i].texture or frame.debuffs[i]:CreateTexture()
                frame.debuffs[i].texture:SetTexCoord(.08, .92, .08, .92)
                frame.debuffs[i].texture:SetAllPoints()

                frame.debuffs[i].stacks = frame.debuffs[i].stacks or
                    frame.debuffs[i]:CreateFontString(nil, "OVERLAY", frame.debuffs[i])
                frame.debuffs[i].stacks:SetFontObject(SimpleUIAuraFont)
                frame.debuffs[i].stacks:SetPoint("BOTTOMRIGHT", frame.debuffs[i], 2, -2)
                frame.debuffs[i].stacks:SetJustifyH("LEFT")
                frame.debuffs[i].stacks:SetShadowColor(0, 0, 0)
                frame.debuffs[i].stacks:SetShadowOffset(0.8, -0.8)
                frame.debuffs[i].stacks:SetTextColor(1, 1, .5)

                frame.debuffs[i].cd = frame.debuffs[i].cd or
                    CreateFrame("Model", frame.debuffs[i]:GetName() .. "Cooldown", frame.debuffs[i],
                        "CooldownFrameTemplate")
                frame.debuffs[i].cd.SimpleUI_CooldownType = "ALL"
                frame.debuffs[i].cd.SimpleUI_CooldownStyleText = 1
                frame.debuffs[i].cd.SimpleUI_CooldownStyleAnimation = 0
                frame.debuffs[i].id = i
                frame.debuffs[i]:Hide()
                u.CreateBackdrop(frame.debuffs[i], 6.8, nil, nil, true)

                frame.debuffs[i]:RegisterForClicks("RightButtonUp")
                frame.debuffs[i]:ClearAllPoints()

                u.SetSize(frame.debuffs[i], frame.config.debuffsize, frame.config.debuffsize)

                frame.debuffs[i]:SetNormalTexture(nil)

                if frame:GetName() == "SimpleUIplayer" then
                    frame.debuffs[i]:SetScript("OnUpdate", E.Debuff_OnUpdate)
                end

                frame.debuffs[i]:SetScript("OnEnter", E.Debuff_OnEnter)
                frame.debuffs[i]:SetScript("OnLeave", E.Debuff_OnLeave)
                frame.debuffs[i]:SetScript("OnClick", E.Debuff_OnClick)
            end
        end
        if cfg.visible then
            SimpleUI_RefreshUnits(frame, "all")
            frame:EnableScripts()
            frame:EnableEvents()
            frame:UpdateFrameSize()
        else
            frame:UnregisterAllEvents()
            frame:Hide()
        end
    end

    function SimpleUI_GlobalConfigUpdate(f)
        Unitframe:UpdateConfig(f)
    end

    -----------------------------------------------
    -- Helper Function: UpdateFrameBackground
    -- Purpose: Configures and updates the frame background anchor points.
    -----------------------------------------------
    function Unitframe:UpdateFrameBackground(frame)
        local cfg = frame.config

        local topAnchor, topX, topY = frame.health, -2, 2
        if cfg.portrait == "left" and frame.portrait:IsShown() then
            topAnchor = frame.portrait
        elseif cfg.portrait == "right" and frame.portrait:IsShown() then
            topAnchor = frame.health
        else
            topAnchor = frame.health
        end

        local bottomAnchor, bottomX, bottomY = frame.health, 2, -2
        if cfg.portrait == "right" and frame.power:IsShown() then
            bottomAnchor = frame.portrait
        elseif cfg.portrait == "left" and frame.power:IsShown() then
            bottomAnchor = frame.power
        elseif cfg.portrait == "left" or cfg.portrait == "right" and not frame.power:IsShown() then
            bottomAnchor = frame.health
        else
            bottomAnchor = frame.power
        end

        frame.background:ClearAllPoints()
        frame.background:SetPoint("TOPLEFT", topAnchor, "TOPLEFT", topX, topY)
        frame.background:SetPoint("BOTTOMRIGHT", bottomAnchor, "BOTTOMRIGHT", bottomX, bottomY)
    end

    -----------------------------------------------
    -- Helper Function: ConfigureHealthBar
    -- Purpose: Sets up health bar dimensions and textures.
    -----------------------------------------------
    function Unitframe:ConfigureHealthBar(frame, cfg, BORDER_SIZE)
        frame.health:ClearAllPoints()
        frame.health:SetPoint("TOP", 0, 0)
        frame.health:SetWidth(cfg.width)
        frame.health:SetHeight(cfg.height)

        if cfg.height < 0.0 then frame.health:Hide() end

        frame.health.bar:SetStatusBarTexture(SimpleUI_GetTexture(cfg.healthTexture))
        frame.health.bar:SetStatusBarBackgroundTexture(SimpleUI_GetTexture(cfg.healthTexture))
        frame.health.bar:SetAllPoints(frame.health)
    end

    function SimpleUI_FixStatusbarTexture(frame, cfg)
        Unitframe:UpdateConfig(frame)
        --Unitframe:ConfigureHealthBar(frame, cfg)
        --Unitframe:ConfigurePowerBar(frame, cfg, 2)
    end

    -----------------------------------------------
    -- Helper Function: ConfigurePowerBar
    -- Purpose: Configures the power bar placement and textures.
    -----------------------------------------------
    function Unitframe:ConfigurePowerBar(frame, cfg, BORDER_SIZE, spacing)
        local relativePoint = cfg.panchor == "TOPLEFT" and "BOTTOMLEFT" or
            cfg.panchor == "TOPRIGHT" and "BOTTOMRIGHT" or "BOTTOM"

        frame.power:ClearAllPoints()
        frame.power:SetPoint(cfg.panchor, frame.health, relativePoint, cfg.poffx,
            -1 * BORDER_SIZE + cfg.poffy * u.GetPerfectPixel())
        frame.power:SetWidth(cfg.pwidth ~= -1 and cfg.pwidth or cfg.width)
        frame.power:SetHeight(cfg.manaheight)
        if tonumber(frame.config.manaheight) < 0.0 then frame.power:Hide() end

        frame.power.bar:SetStatusBarTexture(SimpleUI_GetTexture(cfg.manaTexture))
        frame.power.bar:SetStatusBarBackgroundTexture(SimpleUI_GetTexture(cfg.manaTexture))
        frame.power.bar:SetAllPoints(frame.power)
    end

    -----------------------------------------------
    -- Helper Function: ConfigurePortrait
    -- Purpose: Sets up the portrait appearance and positioning.
    -----------------------------------------------
    function Unitframe:ConfigurePortrait(frame, cfg, BORDER_SIZE, spacing)
        frame.portrait:ClearAllPoints()
        frame.portrait.tex:SetAllPoints(frame.portrait)
        frame.portrait.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        frame.portrait.model:SetAllPoints(frame.portrait)
        frame.portrait.sep.tex:SetTexture(SimpleUI_GetTexture("Seperator"))
        frame.portrait.sep.tex:SetAllPoints(frame.portrait.sep)
        frame.portrait.sep:SetWidth(10)
        frame.portrait.sep:SetHeight(frame:GetHeight())

        if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI then
            frame.portrait.sep.tex:SetVertexColor(0.3, 0.3, 0.3, 0.9)
        else
            frame.portrait.sep.tex:SetVertexColor(1, 1, 1, 1)
        end

        if cfg.portrait == "bar" then
            frame.portrait:SetParent(frame.health.bar)
            frame.portrait:SetAllPoints(frame.health.bar)
            frame.portrait:SetAlpha(frame.config.alpha)
            if frame.portrait.backdrop then
                frame.portrait.backdrop:Hide()
            end
            frame.portrait.model:SetFrameLevel(3)
            frame.portrait:Show()
            frame.portrait.sep:Hide()
        elseif cfg.portrait == "left" then
            frame.portrait:SetParent(frame)
            if cfg.portraitwidth == -1 and cfg.portraitheight == -1 then
                frame.portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            else
                frame.portrait:SetPoint("LEFT", frame, "LEFT", -cfg.portraitwidth - 6 * BORDER_SIZE - spacing, 0)
            end

            frame.health:ClearAllPoints()
            frame.health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

            frame.portrait:SetAlpha(1)
            frame.portrait:SetFrameStrata("BACKGROUND")

            frame.portrait.model:SetFrameStrata("BACKGROUND")
            frame.portrait.model:SetFrameLevel(1)
            frame.portrait:Show()

            frame.portrait.sep:ClearAllPoints()
            frame.portrait.sep:SetPoint("CENTER", frame.portrait, "CENTER", frame.portrait:GetWidth() / 2 + 3, 0)
        elseif cfg.portrait == "right" then
            frame.portrait:SetParent(frame)
            if cfg.portraitwidth == -1 and cfg.portraitheight == -1 then
                frame.portrait:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            else
                frame.portrait:SetPoint("RIGHT", frame, "RIGHT", cfg.portraitwidth + 6 * BORDER_SIZE + spacing, 0)
            end
            frame.health:ClearAllPoints()
            frame.health:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

            frame.portrait:SetAlpha(1)
            frame.portrait:SetFrameStrata("BACKGROUND")

            frame.portrait.model:SetFrameStrata("BACKGROUND")
            frame.portrait.model:SetFrameLevel(1)
            frame.portrait:Show()

            frame.portrait.sep:ClearAllPoints()
            frame.portrait.sep:SetPoint("CENTER", frame.portrait, "CENTER", -frame.portrait:GetWidth() / 2 - 3, 0)
        else
            frame.portrait:Hide()
        end
    end

    function SimpleUI_FixPortrait(cfg)
        local frame = getglobal("SimpleUIplayer")
        local BORDER_SIZE, spacing = 2, cfg.pspace * u.GetPerfectPixel()
        if cfg.portrait == "bar" then
            frame.portrait:SetParent(frame.health.bar)
            frame.portrait:SetAllPoints(frame.health.bar)
            frame.portrait:SetAlpha(cfg.alpha)
            if frame.portrait.backdrop then
                frame.portrait.backdrop:Hide()
            end
            frame.portrait.model:SetFrameLevel(3)
            frame.portrait:Show()
            frame.level:ClearAllPoints()
            frame.level:SetPoint("BOTTOMLEFT", frame.background.backdrop.border, "BOTTOMLEFT", 0, 0)
        elseif cfg.portrait == "left" then
            frame.portrait:SetParent(frame)
            if cfg.portraitwidth == -1 and cfg.portraitheight == -1 then
                frame.portrait:ClearAllPoints()
                frame.portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            else
                frame.portrait:ClearAllPoints()
                frame.portrait:SetPoint("LEFT", frame, "LEFT", -cfg.portraitwidth - 6 * BORDER_SIZE - spacing, 0)
            end

            frame.health:ClearAllPoints()
            frame.health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

            frame.portrait:SetAlpha(1)
            frame.portrait:SetFrameStrata("BACKGROUND")

            frame.portrait.model:SetFrameStrata("BACKGROUND")
            frame.portrait.model:SetFrameLevel(1)
            frame.portrait:Show()
            frame.level:ClearAllPoints()
            frame.level:SetPoint("BOTTOMLEFT", frame.background.backdrop.border, "BOTTOMLEFT", 0, 0)
        elseif cfg.portrait == "right" then
            frame.portrait:SetParent(frame)
            if cfg.portraitwidth == -1 and cfg.portraitheight == -1 then
                frame.portrait:ClearAllPoints()
                frame.portrait:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            else
                frame.portrait:ClearAllPoints()
                frame.portrait:SetPoint("RIGHT", frame, "RIGHT", cfg.portraitwidth + 6 * BORDER_SIZE + spacing, 0)
            end
            frame.health:ClearAllPoints()
            frame.health:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

            frame.portrait:SetAlpha(1)
            frame.portrait:SetFrameStrata("BACKGROUND")

            frame.portrait.model:SetFrameStrata("BACKGROUND")
            frame.portrait.model:SetFrameLevel(1)
            frame.portrait:Show()
            frame.level:ClearAllPoints()
            frame.level:SetPoint("BOTTOMRIGHT", frame.background.backdrop.border, "BOTTOMRIGHT", 0, 0)
        else
            frame.portrait:Hide()
            frame.level:ClearAllPoints()
            frame.level:SetPoint("BOTTOMLEFT", frame.background.backdrop.border, "BOTTOMLEFT", 0, 0)
        end

        Unitframe:UpdateFrameBackground(frame)
    end

    -----------------------------------------------
    -- Helper Function: ConfigureTexts
    -- Purpose: Updates all text regions (e.g., health, power, name).
    -----------------------------------------------
    function Unitframe:ConfigureTexts(frame, cfg, BORDER_SIZE)
        local function configureTextRegion(region, parent, point1, point2, offsetX, offsetY)
            --region:SetFontObject(SimpleUIFont)
            region:SetFont(SimpleUI_GetFont(frame.config.font),
                frame.config.fontSize, "OUTLINE")
            region:SetJustifyH("CENTER")
            region:SetParent(parent)
            region:ClearAllPoints()
            region:SetPoint(point1, parent, point1, offsetX, offsetY)
            region:SetPoint(point2, parent, point2, -offsetX, 0)
        end

        configureTextRegion(frame.healthCenterTextHp, frame.health.bar, "TOPLEFT", "BOTTOMRIGHT", 2 * BORDER_SIZE,
            cfg.txthpcenteroffy)
        configureTextRegion(frame.healthCenterTextName, frame.health.bar, "TOPLEFT", "BOTTOMRIGHT", 2 * BORDER_SIZE,
            cfg.txthpcenteroffy)
        configureTextRegion(frame.powerCenterText, frame.power.bar, "TOPLEFT", "BOTTOMRIGHT", 2 * BORDER_SIZE + cfg
            .poffx, 0)
        frame.healthCenterTextHp:Hide()
        frame.powerCenterText:Hide()
    end

    -----------------------------------------------
    -- Helper Function: ConfigureIcons
    -- Purpose: Updates leader, master looter, and raid icons.
    -----------------------------------------------
    function Unitframe:ConfigureIcons(frame, cfg, BORDER_SIZE)
        u.SetSize(frame.restIcon, 24, 24)
        frame.restIcon:SetPoint("CENTER", frame.level, "CENTER", 0, 0)
        frame.restIcon:SetFrameLevel(frame.level:GetFrameLevel() + 1)
        frame.restIcon.texture:SetTexture(SimpleUITextures.UitframeIcons)
        frame.restIcon.texture:SetTexCoord(0.5195, 0.6445, 0.0039, 0.1289)
        frame.restIcon.texture:SetAllPoints(frame.restIcon)
        frame.restIcon:Hide()

        frame.leaderIcon:SetWidth(16)
        frame.leaderIcon:SetHeight(16)
        frame.leaderIcon.texture:SetTexture("Interface\\AddOns\\SimpleUI\\Media\\Textures\\LeaderIcon.blp") --"Interface\\GroupFrame\\UI-Group-LeaderIcon"
        frame.leaderIcon.texture:SetVertexColor(0.9, 0.743, 0, 1)
        frame.leaderIcon.texture:SetAllPoints(frame.leaderIcon)
        frame.leaderIcon:Hide()


        frame.masterIcon:SetWidth(14)
        frame.masterIcon:SetHeight(12)
        frame.masterIcon.texture:SetTexture("Interface\\AddOns\\SimpleUI\\Media\\Textures\\LooterIcon.blp") -- "Interface\\GroupFrame\\UI-Group-MasterLooter"
        frame.masterIcon.texture:SetVertexColor(0.9, 0.743, 0, 1)
        frame.masterIcon.texture:SetAllPoints(frame.masterIcon)
        frame.masterIcon:Hide()

        u.SetSize(frame.raidIcon, 18, 18)
        frame.raidIcon:SetPoint("TOPLEFT", frame.health.bar, "TOPLEFT", 0, 1)
        frame.raidIcon.texture:SetTexture("Interface\\AddOns\\SimpleUI\\Media\\Textures\\raidicons.blp")
        frame.raidIcon.texture:SetAllPoints(frame.raidIcon)
        frame.raidIcon:Hide()
        if frame.label == "raid" then
            frame.raidIcon:SetAlpha(0.7)
        end
    end

    -----------------------------------------------
    -- Helper Function: ConfigureLevel
    -- Purpose: Update Level Background, Overlay, and Text
    -----------------------------------------------
    function Unitframe:ConfigureLevel(frame, cfg)
        frame.level:SetFrameLevel(frame.background.backdrop.border:GetFrameLevel() + 1)
        frame.level.bg:SetAllPoints(frame.level)
        frame.level.bg:SetTexture(SimpleUITextures.CircleMask)
        frame.level.overlay:SetPoint("CENTER", frame.level, "CENTER", 0, 0)
        frame.level.overlay:SetTexture(SimpleUITextures.CircleBorder)
        frame.level.text:SetJustifyH("CENTER")
        frame.level.text:SetPoint("CENTER", frame.level, "CENTER", 0, 0)

        if (frame.label == "player" and frame.IsPlayerParty == false) or frame.label == "target" then
            frame.level:SetWidth(24)
            frame.level:SetHeight(24)
            frame.level.overlay:SetWidth(26)
            frame.level.overlay:SetHeight(26)
            frame.level.text:SetFont(
                SimpleUI_GetFont(SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].font), 12, "OUTLINE")
        else
            frame.level:SetWidth(16)
            frame.level:SetHeight(16)
            frame.level.overlay:SetWidth(18)
            frame.level.overlay:SetHeight(18)
            frame.level.text:SetFont(
                SimpleUI_GetFont(SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].font), 10, "OUTLINE")
        end

        if cfg.portrait == "bar" or cfg.portrait == "left" then
            frame.level:ClearAllPoints()
            frame.level:SetPoint("BOTTOMLEFT", frame.background.backdrop.border, "BOTTOMLEFT", 0, 0)
        elseif cfg.portrait == "right" then
            frame.level:ClearAllPoints()
            frame.level:SetPoint("BOTTOMRIGHT", frame.background.backdrop.border, "BOTTOMRIGHT", 0, 0)
        else
            frame.level:ClearAllPoints()
            frame.level:SetPoint("BOTTOMLEFT", frame.background.backdrop.border, "BOTTOMLEFT", 0, 0)
        end

        if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI then
            frame.level.bg:SetVertexColor(0.15, 0.15, 0.15, 0.9)
            frame.level.overlay:SetVertexColor(0.3, 0.3, 0.3, 0.9)
        else
            frame.level.bg:SetVertexColor(0.25, 0.25, 0.25, 1)
            frame.level.overlay:SetVertexColor(1, 1, 1, 1)
        end

        if frame.label == "raid" then
            frame.level:Hide()
        end
    end

    -- End Function


    function Unitframe.OnShow()
        SimpleUI_RefreshUnits(this, "all")      -- Refresh all units
        SimpleUI_RefreshUnits(this, "portrait") -- Refresh portrait only

        if this.config and this.config.visible == false then
            this:Hide()
            this.visible = nil
        end

        if this.label == "player" then
            TimerFrame:Start(this, 5, SimpleUI_RefreshUnits(this, "portrait"))
        end
    end

    function Unitframe.OnEvent()
        local frame, evt = this, event

        -- General indicator update events
        if evt == "PARTY_LEADER_CHANGED" or evt == "PARTY_LOOT_METHOD_CHANGED"
            or evt == "PARTY_MEMBERS_CHANGED" or evt == "RAID_ROSTER_UPDATE"
            or evt == "PLAYER_UPDATE_RESTING" then
            frame.indicatorUpdate = true
        end

        -- Exit early if frame label is missing
        if not frame.label then return end

        -- Event handling based on event type
        if evt == "PLAYER_ENTERING_WORLD" then
            Unitframe:UpdateConfig(frame)
            frame.portraitUpdate = true
        elseif evt == "PLAYER_ENTERING_WORLD" or
            (frame.label == "target" and evt == "PLAYER_TARGET_CHANGED") or
            ((frame.label == "party" or frame.label == "raid") and (evt == "PARTY_MEMBERS_CHANGED" or evt == "RAID_ROSTER_UPDATE")) or
            (frame.label == "pet" and evt == "UNIT_PET") then
            frame.fullUpdate = true
        elseif frame.label == "player" and (evt == "PLAYER_AURAS_CHANGED" or evt == "UNIT_INVENTORY_CHANGED") then
            frame.fullUpdate = true
        elseif evt == "UNIT_ENERGY" and (frame.label == "player" or arg1 == frame.label .. frame.id) then
            frame.fullUpdate = true
        elseif evt == "UNIT_RAGE" then
            frame.fullUpdate = true
        elseif evt == "PLAYER_LOGIN" or evt == "UNIT_PORTRAIT_UPDATE" or evt == "UNIT_MODEL_CHANGED" then
            frame.portraitUpdate = true
        elseif evt == "UNIT_AURA" then
            frame.auraUpdate = true
        elseif evt == "UNIT_FACTION" then
            frame.pvpUpdate = true
        else
            frame.fullUpdate = true
        end
    end

    function Unitframe.OnUpdate()
        local frame = this

        -- Update indicators
        if frame.indicatorUpdate then
            Unitframe:RefreshIndicators(frame)
            frame.indicatorUpdate = nil
        end

        -- Full update handling
        if frame.fullUpdate then
            SimpleUI_RefreshUnits(frame, "all")
            frame.fullUpdate = nil
            frame.auraUpdate = nil
            frame.portraitUpdate = nil
            frame.pvpUpdate = nil
        else
            -- Partial updates
            if frame.auraUpdate then
                SimpleUI_RefreshUnits(frame, "aura")
                frame.auraUpdate = nil
            end
            if frame.portraitUpdate then
                SimpleUI_RefreshUnits(frame, "portrait")
                frame.portraitUpdate = nil
            end
            if frame.pvpUpdate then
                SimpleUI_RefreshUnits(frame, "pvp")
                frame.pvpUpdate = nil
            end
        end

        -- Focus handling for unit targeting
        if frame.unitname and frame == SimpleUIfocus then
            Unitframe:HandleFocusUpdate(frame)
        end

        if not frame.label then return end
        -- Portrait model handling
        if frame.portrait and frame.portrait.model and frame.portrait.model.update then
            frame.portrait.model.lastUnit = UnitName(frame.portrait.model.update)
            frame.portrait.model:SetUnit(frame.portrait.model.update)
            frame.portrait.model:SetCamera(0)
            frame.portrait.model.update = nil
        end

        if not frame.lastTick then frame.lastTick = GetTime() + (frame.tick or .2) end
        if frame.lastTick and frame.lastTick < GetTime() then
            local unitstr = frame.label .. frame.id

            frame.lastTick = GetTime() + (frame.tick or .2)

            -- target target has a huge delay, make sure to not tick during range checks
            -- by waiting for a stable name over three ticks otherwise aborting the update.
            if frame.label == "targettarget" then
                local name = UnitName(frame.label)
                if name ~= frame.namebuf1 then
                    frame.namebuf1 = name
                    return
                elseif name ~= frame.namebuf2 then
                    frame.namebuf2 = name
                    return
                end
            end

            Unitframe:RefreshUnitState(frame)
            Unitframe:RefreshIndicators(frame)


            -- update everything on eventless frames (targettarget, etc)
            if frame.tick then
                SimpleUI_RefreshUnits(frame, "all")
            end
        end
    end

    -----------------------------------------------
    -- Helper Function: HandleFocusUpdate
    -- Purpose: Handles focus logic and refreshes units when focus changes.
    -----------------------------------------------
    function Unitframe:HandleFocusUpdate(frame)
        local uN = (frame.label and UnitName(frame.label)) or ""
        if not frame.unitname or frame.unitname == "focus" then return end

        if strlower(uN) ~= frame.unitname then
            for unit in pairs(u.SimpleUIValidUnits) do
                local scan = UnitName(unit) or ""
                if frame.unitname == strlower(scan) then
                    frame.label = unit
                    if frame.portrait then frame.portrait.model.lastUnit = nil end
                    frame.instantRefresh = true
                    SimpleUI_RefreshUnits(frame, "all")
                    return
                end
                frame.label = nil
                frame.instantRefresh = true
                frame.health.bar:SetStatusBarColor(0.2, 0.2, 0.2)
            end
        end
    end

    -----------------------------------------------
    -- Function: UF.HappinessOnEnter
    -- Purpose: Shows a tooltip with pet happiness details when the user hovers over the frame.
    -----------------------------------------------
    function Unitframe.HappinessOnEnter()
        if not this.tooltip then return end

        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText(this.tooltip)

        if this.tooltipDamage then
            GameTooltip:AddLine(this.tooltipDamage, "", 1, 1, 1)
        end

        if this.tooltipLoyalty then
            GameTooltip:AddLine(this.tooltipLoyalty, "", 1, 1, 1)
        end

        GameTooltip:Show()
    end

    -----------------------------------------------
    -- Function: UF.HappinessOnLeave
    -- Purpose: Hides the tooltip for pet happiness.
    -----------------------------------------------
    function Unitframe.HappinessOnLeave()
        GameTooltip:FadeOut()
    end

    -----------------------------------------------
    -- Function: UF.OnEnter
    -- Purpose: Displays unit information in a tooltip when hovering over the unit frame.
    -----------------------------------------------
    function Unitframe.OnEnter()
        if not this.label then return end

        GameTooltip_SetDefaultAnchor(GameTooltip, this)
        GameTooltip:SetUnit(this.label .. this.id)
        GameTooltip:Show()

        -- Toggle visibility of text elements
        this.healthCenterTextHp:Show()
        this.healthCenterTextName:Hide()

        if this.config.ptxton then
            this.powerCenterText:Show()
        end
    end

    -----------------------------------------------
    -- Function: UF.OnLeave
    -- Purpose: Hides the unit tooltip and resets text visibility on leaving the frame.
    -----------------------------------------------
    function Unitframe.OnLeave()
        GameTooltip:FadeOut()

        this.healthCenterTextHp:Hide()
        this.healthCenterTextName:Show()
        this.powerCenterText:Hide()
    end

    -----------------------------------------------
    -- Function: UF.OnClick
    -- Purpose: Handles unit frame clicks to target the unit or perform custom actions.
    -----------------------------------------------
    function Unitframe.OnClick()
        if not this.label and this.unitname then
            TargetByName(this.unitname, true)
        else
            Unitframe:ClickAction(arg1)
        end
    end

    function Unitframe.OnDragStart()
        if IsAltKeyDown() then
            this:StartMoving()
        end
    end

    function Unitframe.OnDragStop()
        this:StopMovingOrSizing()
    end

    -----------------------------------------------
    -- Function: UF:RightClickFunction
    -- Purpose: Displays the dropdown menu for specific unit frames when right-clicked.
    -----------------------------------------------
    function Unitframe:RightClickFunction(unit)
        local dropDownMap = {
            ["player"] = PlayerFrameDropDown,
            ["target"] = TargetFrameDropDown,
            ["pet"] = PetFrameDropDown,
        }

        if dropDownMap[unit] then
            ToggleDropDownMenu(1, nil, dropDownMap[unit], "cursor")
        elseif strfind(unit, "party%d") then
            ToggleDropDownMenu(1, nil, getglobal("PartyMemberFrame" .. this.id .. "DropDown"), "cursor")
        elseif strfind(unit, "raid%d") then
            local unitstr = this.label .. this.id -- this.label = unit, this.id = unit id or nil
            FriendsDropDown.displayMode = "MENU"
            FriendsDropDown.initialize = function()
                UnitPopup_ShowMenu(_G[UIDROPDOWNMENU_OPEN_MENU], "PARTY", unitstr, nil, this.id)
            end
            ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
        end
    end

    -----------------------------------------------
    -- Function: PetFlashFrame
    -- Purpose: Animates the pet happiness frame with a fading flash effect.
    -----------------------------------------------
    local function PetFlashFrame(frame)
        local elapsed, fadeIn = 0, true
        if frame.fading then return end

        frame:SetScript("OnUpdate", function()
            frame.fading = true
            elapsed = elapsed + arg1
            local progress = elapsed / 1.5

            if fadeIn then
                frame:SetAlpha(math.min(progress, 1))
                if progress >= 1 then
                    elapsed = 0
                    fadeIn = false
                end
            else
                frame:SetAlpha(math.max(1 - progress, 0))
                if progress >= 1 then
                    elapsed = 0
                    fadeIn = true
                end
            end
        end)
    end

    -----------------------------------------------
    -- Function: PetFrameFlashStop
    -- Purpose: Stops the pet happiness frame animation and resets its alpha.
    -----------------------------------------------
    local function PetFrameFlashStop(frame)
        frame:SetScript("OnUpdate", nil)
        frame:SetAlpha(1)
        frame.fading = false
    end

    -----------------------------------------------
    -- Function: UF.SetPetHappiness
    -- Purpose: Updates the pet happiness tooltip and applies a visual flash if the pet is unhappy.
    -----------------------------------------------
    function Unitframe.SetPetHappiness()
        local happiness, damagePercentage, loyaltyRate = GetPetHappiness()
        happiness = happiness or 3

        -- Set tooltip texts
        this.tooltip = getglobal("PET_HAPPINESS" .. happiness)
        this.tooltipDamage = format(PET_DAMAGE_PERCENTAGE, damagePercentage or 0)
        this.tooltipLoyalty = loyaltyRate > 0 and getglobal("GAINING_LOYALTY")
            or (loyaltyRate < 0 and getglobal("LOSING_LOYALTY") or nil)

        -- Flash the frame if happiness is less than 3
        if happiness < 3 then
            PetFlashFrame(this)
        else
            PetFrameFlashStop(this)
        end
    end

    -----------------------------------------------
    -- Function: UF:EnableEvents
    -- Purpose: Registers events for the unit frame and related components.
    -----------------------------------------------
    function Unitframe:EnableEvents()
        local frame = self or this
        local events = {
            "PLAYER_ENTERING_WORLD",
            "PLAYER_LOGIN",
            "UNIT_DISPLAYPOWER",
            "UNIT_HEALTH",
            "UNIT_MAXHEALTH",
            "UNIT_MANA",
            "UNIT_MAXMANA",
            "UNIT_RAGE",
            "UNIT_MAXRAGE",
            "UNIT_ENERGY",
            "UNIT_MAXENERGY",
            "UNIT_FOCUS",
            "UNIT_PORTRAIT_UPDATE",
            "UNIT_MODEL_CHANGED",
            "UNIT_FACTION",
            "UNIT_AURA",
            "PLAYER_AURAS_CHANGED",
            "UNIT_INVENTORY_CHANGED",
            "PARTY_MEMBERS_CHANGED",
            "PARTY_LEADER_CHANGED",
            "RAID_ROSTER_UPDATE",
            "PLAYER_UPDATE_RESTING",
            "PLAYER_TARGET_CHANGED",
            "PARTY_LOOT_METHOD_CHANGED",
            "RAID_TARGET_UPDATE",
            "UNIT_PET",
            "UNIT_HAPPINESS"
        }

        for _, event in ipairs(events) do
            frame:RegisterEvent(event)
        end

        frame.happinessIcon:RegisterEvent("UNIT_PET")
        frame.happinessIcon:RegisterEvent("UNIT_HAPPINESS")
        frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
        frame:RegisterForDrag("LeftButton")
        frame:SetMovable(true)
        frame:EnableMouse(true)
    end

    -----------------------------------------------
    -- Function: UF:EnableScripts
    -- Purpose: Assigns scripts (event handlers, click, update) to the unit frame and its components.
    -----------------------------------------------
    function Unitframe:EnableScripts()
        local frame = self

        -- Core frame scripts
        frame:SetScript("OnClick", Unitframe.OnClick)
        frame:SetScript("OnShow", Unitframe.OnShow)
        frame:SetScript("OnEvent", Unitframe.OnEvent)
        frame:SetScript("OnUpdate", Unitframe.OnUpdate)
        frame:SetScript("OnEnter", Unitframe.OnEnter)
        frame:SetScript("OnLeave", Unitframe.OnLeave)
        frame:SetScript("OnDragStart", Unitframe.OnDragStart)
        frame:SetScript("OnDragStop", Unitframe.OnDragStop)

        -- Happiness icon scripts
        frame.happinessIcon:SetScript("OnEnter", Unitframe.HappinessOnEnter)
        frame.happinessIcon:SetScript("OnLeave", Unitframe.HappinessOnLeave)
        frame.happinessIcon:SetScript("OnEvent", Unitframe.SetPetHappiness)


        visibilityscan.frames[frame] = true
    end

    do
        local animations = {}
        local stepsize, val
        local width, height, point
        local animateFrame = CreateFrame("Frame", "SimpleUIStatusBarAnimation", UIParent)
        animateFrame:SetScript("OnUpdate", function()
            if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].stepsize == "Instant" then
                stepsize = 0
            elseif SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].stepsize == "Very Fast" then
                stepsize = 2
            elseif SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].stepsize == "Fast" then
                stepsize = 4
            elseif SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].stepsize == "Normal" then
                stepsize = 6
            elseif SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].stepsize == "Average" then
                stepsize = 8
            elseif SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].stepsize == "Slow" then
                stepsize = 10
            end
            for bar in pairs(animations) do
                if not bar.val_ or abs(bar.val_ - bar.val) < stepsize or bar.instant then
                    bar:DisplayValue(bar.val)
                elseif bar.val ~= bar.val_ then
                    bar:DisplayValue(bar.val_ +
                        min((bar.val - bar.val_) / stepsize, max(bar.val - bar.val_, 30 / GetFramerate())))
                end
            end
        end)

        local handlers = {
            ["DisplayValue"] = function(self, val)
                val = val > self.max and self.max or val
                val = val < self.min and self.min or val

                -- remove animation queue
                if val == self.val_ then
                    animations[self] = nil
                end

                -- set current visible value
                self.val_ = val

                if self.mode == "vertical" then
                    height = self:GetHeight()
                    height = height / self:GetEffectiveScale()
                    point = height / (self.max - self.min) * (val - self.min)

                    -- keep values in limits
                    point = math.min(height, point)
                    point = math.max(0, point)

                    -- set point to zero if value and max is zero
                    if val == 0 then point = 0 end

                    -- set status bar position/size
                    self.bar:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -height + point)
                    self.bar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)

                    -- set background bar position/size
                    self.bg:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
                    self.bg:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, point)
                else
                    width = self:GetWidth()
                    width = width / self:GetEffectiveScale()
                    point = width / (self.max - self.min) * (val - self.min)

                    -- keep values in limits
                    point = math.min(width, point)
                    point = math.max(0, point)

                    -- set point to zero if value and max is zero
                    if val == 0 then point = 0 end

                    -- set status bar position/size
                    self.bar:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
                    self.bar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -width + point, 0)

                    -- set background bar position/size
                    self.bg:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
                    self.bg:SetPoint("TOPLEFT", self, "TOPLEFT", point, 0)
                end
            end,

            ["SetMinMaxValues"] = function(self, smin, smax, smooth)
                -- smoothen the transition by keeping the value at the same percentage as before
                if smooth and self.max and self.max > 0 and smax > 0 and self.max ~= smax then
                    self.val_ = (self.val_ or self.val) / self.max * smax
                end

                self.min, self.max = smin, smax
                self:DisplayValue(self.val_ or self.val)
            end,

            ["SetValue"] = function(self, val)
                self.val = val or 0

                -- start animation on difference
                if self.val_ ~= self.val then
                    animations[self] = true
                end
            end,

            ["SetStatusBarTexture"] = function(self, r, g, b, a)
                self.bar:SetTexture(r, g, b, a)
            end,

            ["SetStatusBarColor"] = function(self, r, g, b, a)
                self.bar:SetVertexColor(r, g, b, a)
            end,

            ["SetStatusBarBackgroundTexture"] = function(self, r, g, b, a)
                self.bg:SetTexture(r, g, b, a)
            end,

            ["SetStatusBarBackgroundColor"] = function(self, r, g, b, a)
                self.bg:SetVertexColor(r, g, b, a)
            end,

            ["SetOrientation"] = function(self, mode)
                self.mode = strlower(mode)
            end,
        }
        function Unitframe.CreateStatusBar(name, parent)
            local f = CreateFrame("Button", name, parent)
            f:EnableMouse(nil)

            f.bar = f:CreateTexture(nil, "ARTWORK")
            f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
            f.bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

            f.bg = f:CreateTexture(nil, "BACKGROUND")
            f.bg:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
            f.bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

            -- set some default values
            f.min, f.max, f.val = 0, 100, 0

            -- add all handler functions to the object
            for name, func in pairs(handlers) do
                f[name] = func
            end

            return f
        end
    end

    -----------------------------------------------
    -- Function: UF:CreateUnitFrame
    -- Purpose: Creates and initializes a unit frame with all associated components and configurations.
    -- Parameters:
    --    unit: The unit type (e.g., "player", "party").
    --    id: The unit ID or index.
    --    config: Configuration table for the frame.
    --    tick: Tick value for energy updates.
    -----------------------------------------------
    function Unitframe:CreateUnitFrame(unit, id, config, tick)
        -- Generate a frame name based on unit and ID
        local framename = ((unit == "party") and "Group" or (unit or "")) .. (id or "")
        unit, id = strlower(unit or ""), strlower(id or "")
        local isPlayerParty = (unit == "party" and id == "0")

        -- Correct specific unit values
        if isPlayerParty then unit, id = "player", "" end
        if unit == "partypet" and id == "0" then unit, id = "pet", "" end
        if unit == "pettarget" and id == "0" then unit, id = "pettarget", "" end
        if unit == "party0target" then unit, id = "target", "" end

        -- Check for existing frame
        if _G["SimpleUI" .. framename] then return end

        -- Create the main frame
        local frame = CreateFrame("Button", "SimpleUI" .. framename, UIParent)
        frame.UpdateFrameSize = Unitframe.UpdateFrameSize
        frame.UpdateVisibility = Unitframe.UpdateVisibility
        frame.UpdateConfig = Unitframe.UpdateConfig
        frame.EnableScripts = Unitframe.EnableScripts
        frame.EnableEvents = Unitframe.EnableEvents
        --frame.EnableClickCast = UF.EnableClickCast
        frame.GetColor = Unitframe.GetColor
        frame.label = unit
        frame.id = id
        frame.config = config
        frame.tick = tick
        frame.framename = framename
        frame.IsPlayerParty = isPlayerParty
        frame.EnergyTime = 0
        frame.EnergyLast = 0
        frame.firstRun = 1

        -- Assign unit name for invalid units
        if not u.SimpleUIValidUnits[unit .. id] then
            frame.unitname, frame.label, frame.id = unit, "", ""
            frame.RegisterEvent = function() end
        end

        -- Initialize core components
        frame.health = CreateFrame("Frame", nil, frame)
        frame.health.bar = Unitframe.CreateStatusBar(nil, frame.health)
        --frame.health.bar:SetParent(frame.health)

        frame.power = CreateFrame("Frame", nil, frame)
        frame.power.bar = Unitframe.CreateStatusBar(nil, frame.power)
        --frame.power.bar:SetParent(frame.health)

        frame.TickerFrame = Unitframe:CreateTickerFrame(frame)

        frame.combat = CreateFrame("Frame", nil, frame.health)
        frame.combat.tex = frame.combat:CreateTexture(nil, "OVERLAY")

        frame.healthCenterTextName = frame:CreateFontString("Status", "OVERLAY", "GameFontNormalSmall")
        frame.healthCenterTextHp = frame:CreateFontString("Status", "OVERLAY", "GameFontNormalSmall")
        frame.powerCenterText = frame:CreateFontString('Status', "OVERLAY", "GameFontNormalSmall")

        frame.level = CreateFrame("Frame", nil, frame)
        frame.level.bg = frame.level:CreateTexture(nil, "BACKGROUND")
        frame.level.overlay = frame.level:CreateTexture(nil, "OVERLAY")
        frame.level.text = frame.level:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")


        frame.combatIcon = Unitframe:CreateIcon(frame)
        frame.leaderIcon = Unitframe:CreateIcon(frame.health.bar)
        frame.masterIcon = Unitframe:CreateIcon(frame.health.bar)
        frame.pvpIcon = Unitframe:CreateIcon(frame.health.bar)
        frame.raidIcon = Unitframe:CreateIcon(frame.health.bar)
        frame.restIcon = Unitframe:CreateIcon(frame.level)
        frame.happinessIcon = Unitframe:CreateIcon(frame.health.bar, "happiness")

        frame.portrait = CreateFrame("Frame", "SimpleUIPortrait" .. frame.label .. frame.id, frame)
        frame.portrait.tex = frame.portrait:CreateTexture("SimpleUIPortraitTexture" .. frame.label .. frame.id, "OVERLAY")
        frame.portrait.model = CreateFrame("PlayerModel", "SimpleUIPortraitModel" .. frame.label .. frame.id,
            frame.portrait)
        frame.portrait.model.next = CreateFrame("PlayerModel", nil, nil)

        frame.portrait.sep = CreateFrame("Frame", nil, frame.health)
        frame.portrait.sep.tex = frame.portrait.sep:CreateTexture(nil, "OVERLAY")

        -- Finalize frame setup
        frame:Hide()
        frame:UpdateConfig()
        frame:UpdateFrameSize()
        frame:EnableScripts()
        frame:EnableEvents()

        -- Visibility handling
        if frame.config.visible then
            SimpleUI_RefreshUnits(frame, "all")
            frame:EnableScripts()
            frame:EnableEvents()
            frame:UpdateFrameSize()
        else
            frame:UnregisterAllEvents()
            frame:Hide()
        end

        table.insert(frames, frame)
        return frame
    end

    function Unitframe:CreateTickerFrame(parent)
        local ticker = CreateFrame("StatusBar", nil, parent.power.bar)
        ticker.Spark = ticker:CreateTexture(nil, "OVERLAY")
        ticker.Spark:SetPoint("CENTER", ticker, "CENTER", 0, 0)
        return ticker
    end

    function Unitframe:CreateIcon(parent, name)
        local icon = CreateFrame("Frame", nil, parent)
        icon.texture = icon:CreateTexture(nil, "BACKGROUND")
        if name == "happiness" then
            icon:EnableMouse(true)
        end
        return icon
    end

    function Unitframe:RefreshUnitState(unit)
        local alpha = unit.alpha_visible
        local unlock = SimpleUI.unlock and SimpleUI.unlock:IsShown() or nil

        if not UnitIsConnected(unit.label .. unit.id) and not unlock then
            alpha = unit.alpha_offline
            unit.health.bar:SetMinMaxValues(0, 100, true)
            unit.power.bar:SetMinMaxValues(0, 100, true)
            unit.health.bar:SetValue(0)
            unit.power.bar:SetValue(0)
        elseif unit.config.faderange == 1 and not u.UnitInRange(unit.label .. unit.id, 4) and not unlock then
            alpha = unit.alpha_outofrange
        end


        if floor(unit:GetAlpha() * 10 + 0.5) == floor(alpha * 10 + 0.5) then
            return
        end

        unit:SetAlpha(alpha)

        if unit.config.portrait == "bar" then
            unit.portrait:SetAlpha(unit.config.alpha)
        end
    end

    function Unitframe:RefreshIndicators(unit)
        if not unit.label or not unit.id then
            return
        end

        local unitstr = unit.label .. unit.id

        if unit.leaderIcon then
            if unit.config.leaderIcon == true and UnitIsPartyLeader(unitstr) and (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0) then
                unit.leaderIcon:Show()
            else
                unit.leaderIcon:Hide()
            end
        end

        if unit.masterIcon then
            if unit.config.masterIcon == false then
                unit.masterIcon:Hide()
            else
                local method, group, raid = GetLootMethod()
                local name = group and UnitName(group == 0 and "player" or "party" .. group) or
                    raid and UnitName("raid" .. raid) or nil

                if name and name == UnitName(unitstr) then
                    unit.masterIcon:Show()
                else
                    unit.masterIcon:Hide()
                end
            end
        end

        if unit.pvpIcon then
            if unit.config.showpvp == true and UnitIsPVP(unitstr) then
                unit.pvpIcon:Show()
            else
                unit.pvpIcon:Hide()
            end
        end

        if unit.restIcon and unit:GetName() == "SimpleUIplayer" then
            if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].player.showrest == true and UnitIsUnit(unitstr, "player") and IsResting() then
                unit.restIcon:Show()
            else
                unit.restIcon:Hide()
            end
        end

        if unit.happinessIcon and unit:GetName() == "SimpleUIpet" then
            if unit.config.happinessIcon == false then
                unit.happinessIcon:Hide()
            else
                if UnitIsVisible("pet") then
                    local happiness, damagePercentage, loyaltyRate = GetPetHappiness()
                    if happiness == 1 then
                        unit.happinessIcon.texture:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness") -- UPDATE TO PET ICON
                        unit.happinessIcon.texture:SetTexCoord(0.375, 0.5625, 0, 0.359375)
                    elseif happiness == 2 then
                        unit.happinessIcon.texture:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness")
                        unit.happinessIcon.texture:SetTexCoord(0.1875, 0.375, 0, 0.359375)
                    else
                        unit.happinessIcon.texture:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness")
                        unit.happinessIcon.texture:SetTexCoord(0, 0.1875, 0, 0.359375)
                    end
                    unit.happinessIcon:Show()
                else
                    unit.happinessIcon:Hide()
                end
            end
        end

        if unit.raidIcon then
            local raidIcon = UnitName(unitstr) and GetRaidTargetIndex(unitstr)
            if unit.config.raidIcon == true and raidIcon then
                SetRaidTargetIconTexture(unit.raidIcon.texture, raidIcon)
                unit.raidIcon:Show()
            else
                unit.raidIcon:Hide()
            end
        end
    end

    local SimpleUIDebuffColors = {
        ["Magic"]   = { 0.1, 0.7, 0.8, 1 },
        ["Poison"]  = { 0.2, 0.7, 0.3, 1 },
        ["Curse"]   = { 0.6, 0.2, 0.6, 1 },
        ["Disease"] = { 0.9, 0.7, 0.2, 1 }
    }

    function SimpleUI_RefreshUnits(unit, element)
        -- Validate unit and frame components
        if not unit.label then return end
        if not unit.health then return end
        if not unit.power then return end
        if not unit.id then unit.id = "" end
        local element = element or ""

        -- Skip scanning targets if scanning is active
        if unit.label == "target" or unit.label == "targettarget" or unit.label == "targettargettarget" then
            if SimpleUIScanActive == true then return end
        end

        unit:UpdateVisibility()
        if not unit:IsShown() and not unit.visible then return end

        local unitstr = unit.label .. unit.id
        local rawBorder, default_border = 2, 2
        unit.namecache = UnitName(unitstr)

        if unit.buffs and (element == "all" or element == "aura") then
            local texture, stacks
            for i = 1, unit.config.maxBuffs do
                if not unit.buffs[i] then
                    break
                end

                if unit.label == "player" then
                    stacks = GetPlayerBuffApplications(GetPlayerBuff(PLAYER_BUFF_START_ID + i, "HELPFUL"))
                    texture = GetPlayerBuffTexture(GetPlayerBuff(PLAYER_BUFF_START_ID + i, "HELPFUL"))
                else
                    texture, stacks = Unitframe:DetectBuff(unitstr, i)
                end

                unit.buffs[i].texture:SetTexture(texture)

                if texture then
                    unit.buffs[i]:Show()
                    if stacks > 1 then
                        unit.buffs[i].stacks:SetText(stacks)
                    else
                        unit.buffs[i].stacks:SetText("")
                    end
                else
                    unit.buffs[i]:Hide()
                end
            end
        end

        if unit.debuffs and (element == "all" or element == "aura") then
            local texture, stacks, dtype
            local pR = unit.config.debuffsPerRow
            local bpR = unit.config.buffsPerRow


            local invert_h, invert_v, af
            if unit.config.debuffs == "TOPLEFT" then
                invert_h = 1
                invert_v = 1
                af = "BOTTOMLEFT"
            elseif unit.config.debuffs == "BOTTOMLEFT" then
                invert_h = -1
                invert_v = 1
                af = "TOPLEFT"
            elseif unit.config.debuffs == "TOPRIGHT" then
                invert_h = 1
                invert_v = -1
                af = "BOTTOMRIGHT"
            elseif unit.config.debuffs == "BOTTOMRIGHT" then
                invert_h = -1
                invert_v = -1
                af = "TOPRIGHT"
            end

            local buffrow, reposition = 0, (element == "all" and true or nil)
            if unit.config.buffs == unit.config.debuffs then
                if unit.buffs[0 * bpR + 1] and unit.buffs[0 * bpR + 1]:IsShown() then buffrow = buffrow + 1 end
                if unit.buffs[1 * bpR + 1] and unit.buffs[1 * bpR + 1]:IsShown() then buffrow = buffrow + 1 end
                if unit.buffs[2 * bpR + 1] and unit.buffs[2 * bpR + 1]:IsShown() then buffrow = buffrow + 1 end
                if unit.buffs[3 * bpR + 1] and unit.buffs[3 * bpR + 1]:IsShown() then buffrow = buffrow + 1 end
            end

            if buffrow ~= unit.lastbuffrow then
                unit.lastbuffrow = buffrow
                reposition = true
            end

            for i = 1, unit.config.maxDebuffs do
                if not unit.debuffs[i] then break end

                local row = floor((i - 1) / unit.config.debuffsPerRow)

                if reposition then
                    unit.debuffs[i]:SetPoint(af, unit, unit.config.debuffs,
                        invert_v * (i - 1 - row * pR) * (2 * 2 + unit.config.debuffsize + 1) + 2,
                        invert_h * ((row + buffrow) * (2 * 2 + unit.config.debuffsize + 1) + (2 * 2 + 6)))
                end

                if unit.label == "player" then
                    texture = GetPlayerBuffTexture(GetPlayerBuff(PLAYER_BUFF_START_ID + i, "HARMFUL"))
                    stacks = GetPlayerBuffApplications(GetPlayerBuff(PLAYER_BUFF_START_ID + i, "HARMFUL"))
                    dtype = GetPlayerBuffDispelType(GetPlayerBuff(PLAYER_BUFF_START_ID + i, "HARMFUL"))
                else
                    texture, stacks, dtype = _G.UnitDebuff(unitstr, i)
                end

                unit.debuffs[i].texture:SetTexture(texture)

                local r, g, b = DebuffTypeColor.none.r, DebuffTypeColor.none.g, DebuffTypeColor.none.b
                if dtype and DebuffTypeColor[dtype] then
                    r, g, b = DebuffTypeColor[dtype].r, DebuffTypeColor[dtype].g, DebuffTypeColor[dtype].b
                end
                unit.debuffs[i].backdrop.border:SetBackdropBorderColor(r, g, b, 1)

                if texture then
                    unit.debuffs[i]:Show()

                    if unit:GetName() == "SimpleUIplayer" then
                        --[[                         local timeleft = GetPlayerBuffTimeLeft(GetPlayerBuff(PLAYER_BUFF_START_ID + unit.debuffs[i].id, "HARMFUL"), "HARMFUL")
                        if timeleft and timeleft > 0 then
                            CooldownFrame_SetTimer(unit.debuffs[i].cd, GetTime(), 10, 1)
                        end ]]
                    elseif E.libdebuff then
                        local name, rank, texture, stacks, dtype, duration, timeleft = E.libdebuff:UnitDebuff(unitstr, i)
                        if duration and timeleft then
                            local startTime = GetTime() + timeleft - duration
                            CooldownFrame_SetTimer(unit.debuffs[i].cd, startTime, duration, 1)
                        end
                    end

                    if stacks > 1 then
                        unit.debuffs[i].stacks:SetText(stacks)
                    else
                        unit.debuffs[i].stacks:SetText("")
                    end
                else
                    unit.debuffs[i]:Hide()
                end
            end
        end

        if unit.portrait and (element == "all" or element == "portrait") then
            if unit.firstLoad == nil then
                -- Hide the model initially and delay the setup to fix first-load rendering issues
                unit.portrait.model:Hide()
                if unit and unit.portrait then
                    unit.portrait.model:Show()
                    unit.firstLoad = true -- Reset the flag after first initialization
                    unit.portrait.model:SetCamera(0)
                    unit.portrait.model:SetUnit(unitstr)
                end
            end
            if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].always2D == true then
                unit.portrait.tex:Show()
                unit.portrait.model:Hide()
                SetPortraitTexture(unit.portrait.tex, unitstr)
            else
                if not UnitIsVisible(unitstr) or not UnitIsConnected(unitstr) then
                    if unit.config.portrait == "bar" then
                        unit.portrait.tex:Hide()
                        unit.portrait.model:Hide()
                    elseif SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].portraittexture == true then
                        unit.portrait.tex:Show()
                        unit.portrait.model:Hide()
                        SetPortraitTexture(unit.portrait.tex, unitstr)
                    else
                        unit.portrait.tex:Hide()
                        unit.portrait.model:Show()
                        unit.portrait.model:SetModelScale(4.25)
                        unit.portrait.model:SetPosition(0, 0, -1)
                        --unit.portrait.model:SetCamera(0)
                        unit.portrait.model:SetModel("Interface\\Button\\talktomequestionmark.mdx")
                    end
                else
                    if unit.config.portrait == "bar" then
                        unit.portrait:SetAlpha(unit.config.alpha)
                    else
                        unit.portrait:SetAlpha(1)
                    end
                    unit.portrait.tex:Hide()
                    unit.portrait.model:Show()
                    unit.portrait.model:SetCamera(0)
                    if element == "portait" then
                        unit.portrait.model.update = unitstr
                    else
                        unit.portrait.model.next:SetUnit(unitstr)
                        if unit.portrait.model.lastUnit ~= UnitName(unitstr) or unit.portrait.model:GetModel() ~= unit.portrait.model.next:GetModel() then
                            unit.portrait.model.update = unitstr
                        end
                    end
                end
            end
        end

        --[[         local health, healthMax = UnitHealth(unitstr), UnitHealthMax(unitstr)
        local power, powerMax = UnitMana(unitstr), UnitManaMax(unitstr)

        if unit.config.invertHealth == true then
            health = healthMax - health
            if power == 0 or power == nil then
                powerMax = 100
                power = powerMax - power
            else
                power = powerMax - power
            end
        end ]]


        -- Refresh Health and Power
        Unitframe:RefreshHealthAndPower(unit, unitstr)


        local baseR, baseG, baseB = 0.2, 0.2, 0.2 -- Default values for r, g, b
        local r, g, b, a = baseR, baseG, baseB, 1
        if UnitIsPlayer(unitstr) then
            local _, class = UnitClass(unitstr)
            local color = RAID_CLASS_COLORS[class]
            if color then
                baseR, baseG, baseB = color.r, color.g, color.b
            end
        elseif unit.label == "pet" then
            local happiness = GetPetHappiness()
            if happiness == 1 then
                baseR, baseG, baseB = 1, 0, 0 -- Unhappy pet
            elseif happiness == 2 then
                baseR, baseG, baseB = 1, 1, 0 -- Neutral pet
            else
                baseR, baseG, baseB = 0, 1, 0 -- Happy pet
            end
        else
            local color = UnitReactionColor[UnitReaction(unitstr, "player")]
            if color then
                baseR, baseG, baseB = color.r, color.g, color.b -- Store reaction color
            end
        end

        if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].pastel then
            r, g, b = (baseR + 0.5) * 0.5, (baseG + 0.5) * 0.5, (baseB + 0.5) * 0.5
        else
            r, g, b = baseR, baseG, baseB -- Use original colors if pastel is off
        end

        if unit.config.invertHealth then
            unit.health.bar:SetStatusBarColor(0.2, 0.2, 0.2, 1)
            unit.health.bar:SetStatusBarBackgroundColor(r, g, b, 1)
        else
            unit.health.bar:SetStatusBarColor(r, g, b, 1)
            unit.health.bar:SetStatusBarBackgroundColor(0.2, 0.2, 0.2, 1)
        end

        local mana = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].manaColor
        local rage = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].rageColor
        local energy = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].energyColor
        local focus = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].focusColor

        local pR, pG, pB, pA = .5, .5, .5, 1
        local utype = UnitPowerType(unitstr)
        if utype == 0 then
            pR, pG, pB, pA = mana.r, mana.g, mana.b, mana.a
        elseif utype == 1 then
            pR, pG, pB, pA = rage.r, rage.g, rage.b, rage.a
        elseif utype == 2 then
            pR, pG, pB, pA = energy.r, energy.g, energy.b, energy.a
        elseif utype == 3 then
            pR, pG, pB, pA = focus.r, focus.g, focus.b, focus.a
        end

        if unit.config.invertHealth then
            unit.power.bar:SetStatusBarColor(0.2, 0.2, 0.2, pA)
            unit.power.bar:SetStatusBarBackgroundColor(pR, pG, pB, pA)
        else
            unit.power.bar:SetStatusBarColor(pR, pG, pB, pA)
            unit.power.bar:SetStatusBarBackgroundColor(0.2, 0.2, 0.2, 1)
        end

        if UnitName(unitstr) then
            unit.healthCenterTextName:SetText(Unitframe:GetStatusValue(unit, "namecenter"))
            unit.healthCenterTextHp:SetText(Unitframe:GetStatusValue(unit, "hpcenter"))
            unit.level.text:SetText(Unitframe:GetStatusValue(unit, "level"))

            unit.powerCenterText:SetText(Unitframe:GetStatusValue(unit, "powercenter"))

            unit.healthCenterTextName:SetFont(
                SimpleUI_GetFont(unit.config.font),
                unit.config.fontSize, "OUTLINE")
            unit.healthCenterTextHp:SetFont(
                SimpleUI_GetFont(unit.config.font),
                unit.config.fontSize, "OUTLINE")
            unit.powerCenterText:SetFont(
                SimpleUI_GetFont(unit.config.font),
                unit.config.fontSize, "OUTLINE")

            if UnitIsTapped(unitstr) and not UnitIsTappedByPlayer(unitstr) then
                unit.health.bar:SetStatusBarColor(0.5, 0.5, 0.5, 0.5)
            end
        end

        if (unit.label == "player" and unit.IsPlayerParty == false) or unit.label == "target" then
            unit.level.text:SetFont(
                SimpleUI_GetFont(unit.config.font), 12, "OUTLINE")
        else
            unit.level.text:SetFont(
                SimpleUI_GetFont(unit.config.font), 10, "OUTLINE")
        end

        Unitframe:RefreshUnitState(unit)
    end

    function Unitframe:RefreshHealthAndPower(unit, unitstr)
        local health, healthMax = UnitHealth(unitstr), UnitHealthMax(unitstr)
        local power, powerMax = UnitMana(unitstr), UnitManaMax(unitstr)

        if unit.config.invertHealth then
            health = healthMax - health
            if power == 0 or power == nil then
                powerMax = 100
                power = powerMax - power
            else
                power = powerMax - power
            end
        end

        unit.health.bar:SetMinMaxValues(0, healthMax)
        unit.health.bar:SetValue(health)
        unit.power.bar:SetMinMaxValues(0, powerMax)
        unit.power.bar:SetValue(power)
    end

    local buttons = {
        [1] = "LeftButton",
        [2] = "RightButton",
        [3] = "MiddleButton",
        [4] = "Button4",
        [5] = "Button5",
    }

    local modifiers = {
        [""] = "",
        ["alt"] = "_alt",
        ["ctrl"] = "_ctrl",
        ["shift"] = "_shift",
    }

    function Unitframe:EnableClickCast()
        --FrameClickCast
    end

    function Unitframe:ClickAction(button)
        local label = this.label or ""
        local id = this.id or ""
        local unitstr = label .. id
        local showmenu = button == "RightButton" and true or nil

        if SpellIsTargeting() then
            if button == "RightButton" then
                SpellStopTargeting()
                return
            elseif button == "LeftButton" and UnitExists(unitstr) then
                SpellTargetUnit(unitstr)
                return
            end
        end

        if CursorHasItem() then
            DropItemOnUnit(unitstr)
            return
        end

        if showmenu then
            Unitframe:RightClickFunction(unitstr)
            return
        end

        if label == "pet" and CursorHasItem() then
            local _, playerClass = UnitClass("player")
            if playerClass == "HUNTER" and UnitExists("pet") then
                DropItemOnUnit("pet")
                return
            end
        end

        local modstring = ""
        modstring = IsAltKeyDown() and modstring .. "alt" or modstring
        modstring = IsControlKeyDown() and modstring .. "ctrl" or modstring
        modstring = IsShiftKeyDown() and modstring .. "shift" or modstring
        modstring = modstring .. button

        if this.clickactions and this.clickactions[modstring] then
            if string.find(this.clickactions[modstring], "^%/(.+)") then
                RunMacroText(this.clickactions[modstring])
                return
            else
                CastSpellByName(this.clickactions[modstring])
                return
            end
        end

        if UnitExists(unitstr) then
            TargetUnit(unitstr)
        end
    end

    local function abbrevname(t)
        return string.sub(t, 1, 1) .. ". "
    end

    function Unitframe:GetNameString(unitstr)
        local name = UnitName(unitstr)
        local abbrev = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].abbrevname == true or nil
        local size = 20

        if abbrev and name and strlen(name) > size then
            name = string.gsub(name, "^(%S+) ", abbrevname)
        end

        if abbrev and name and strlen(name) > size then
            name = string.gsub(name, "(%S+) ", abbrevname)
        end

        return name
    end

    function Unitframe:GetLevelString(unitstr)
        local level = UnitLevel(unitstr)
        if level == -1 then
            level = "?"
        end

        local elite = UnitClassification(unitstr)
        if elite == "worldboss" then
            level = level .. "B"
        elseif elite == "rareelite" then
            level = level .. "R+"
        elseif elite == "elite" then
            level = level .. "+"
        elseif elite == "rare" then
            level = level .. "R"
        end

        return level
    end

    function Unitframe:GetStatusValue(unit, pos)
        if not pos or not unit then
            return
        end

        local config = unit.config["txt" .. pos]
        local unitstr = unit.label .. unit.id
        local frame = unit[pos .. "Text"]

        if pos == "center" and not config then
            config = "unit"
        end

        local unitMana, unitmanaMax = UnitMana(unitstr), UnitManaMax(unitstr)
        local unitHealth, unitHealthMax = UnitHealth(unitstr), UnitHealthMax(unitstr)
        local rhp, rhpmax = unitHealth, unitHealthMax

        --if E.libhealth and E.libhealth.enabled then
        --rhp, rhpmax = E.libhealth:GetUnitHealth(unitstr)
        --elseif unit.label == "target" and (MobHealth3 or MobHealthFrame) and MobHealth_GetTargetCurHP() then
        --rhp, rhpmax = MobHealth_GetTargetCurHP(), MobHealth_GetTargetMaxHP()
        --end

        if config == "unit" then
            local name = unit:GetColor() .. Unitframe:GetNameString(unitstr)
            if UnitIsDead(unitstr) then
                return unit:GetColor("health") .. DEAD
            else
                return name
            end
        elseif config == "unitrev" then
            local name = unit:GetColor("unit") .. Unitframe:GetNameString(unitstr)
            local level = unit:GetColor("level") .. Unitframe:GetLevelString(unitstr)

            return name .. "  " .. level
        elseif config == "name" then
            return unit:GetColor("unit") .. Unitframe:GetNameString(unitstr)
        elseif config == "nameshort" then
            return unit:GetColor("unit") .. strsub(UnitName(unitstr), 0, 3)
        elseif config == "level" then
            return unit:GetColor("level") .. Unitframe:GetLevelString(unitstr)
        elseif config == "class" then
            if UnitIsPlayer(unitstr) then
                return unit:GetColor("class") .. (UnitClass(unitstr) or UNKNOWN)
            else
                return ""
            end

            -- health
        elseif config == "health" then
            return unit:GetColor("health") .. u.Abbreviate(rhp)
        elseif config == "healthmax" then
            return unit:GetColor("health") .. u.Abbreviate(rhpmax)
        elseif config == "healthperc" then
            return unit:GetColor("health") .. ceil(unitHealth / unitHealthMax * 100)
        elseif config == "healthmiss" then
            local health = ceil(rhp - rhpmax)
            if UnitIsDead(unitstr) then
                return unit:GetColor("health") .. DEAD
            elseif health == 0 then
                return unit:GetColor("health") .. "0"
            else
                return unit:GetColor("health") .. u.Abbreviate(health)
            end
        elseif config == "healthdyn" then
            local name = unit:GetColor() .. Unitframe:GetNameString(unitstr)
            if UnitIsDead(unitstr) then
                return name
            elseif unitHealth ~= unitHealthMax then
                return unit:GetColor("health") ..
                    u.Abbreviate(rhp) .. " - " .. ceil(unitHealth / unitHealthMax * 100) .. "%"
            else
                return unit:GetColor("health") .. u.Abbreviate(rhp)
            end
        elseif config == "namehealth" then
            local health = ceil(rhp - rhpmax)
            if UnitIsDead(unitstr) then
                return unit:GetColor("health") .. DEAD
            elseif health == 0 then
                return unit:GetColor("unit") .. Unitframe:GetNameString(unitstr)
            else
                return unit:GetColor("health") .. u.Abbreviate(health)
            end
        elseif config == "namehealthbreak" then
            local health = ceil(rhp - rhpmax)
            if UnitIsDead(unitstr) then
                return unit:GetColor("health") .. DEAD
            elseif health == 0 then
                return unit:GetColor("unit") .. Unitframe:GetNameString(unitstr)
            else
                return unit:GetColor("unit") ..
                    UF:GetNameString(unitstr) .. "\n" .. unit:GetColor("health") .. u.Abbreviate(-health)
            end
        elseif config == "shortnamehealth" then
            local health = ceil(rhp - rhpmax)
            if UnitIsDead(unitstr) then
                return unit:GetColor("health") .. DEAD
            elseif health == 0 then
                return unit:GetColor("unit") .. strsub(UnitName(unitstr), 0, 3)
            else
                return unit:GetColor("health") .. u.Abbreviate(health)
            end
        elseif config == "healthminmax" then
            return unit:GetColor("health") .. u.Abbreviate(rhp) .. "/" .. u.Abbreviate(rhpmax)

            -- mana/power/focus
        elseif config == "power" then
            return unit:GetColor("power") .. u.Abbreviate(unitMana)
        elseif config == "powermax" then
            return unit:GetColor("power") .. u.Abbreviate(unitmanaMax)
        elseif config == "powerperc" then
            local perc = UnitManaMax(unitstr) > 0 and ceil(unitMana / unitmanaMax * 100) or 0
            return unit:GetColor("power") .. perc
        elseif config == "powermiss" then
            local power = ceil(unitMana - unitmanaMax)
            if power == 0 then
                return unit:GetColor("power") .. "0"
            else
                return unit:GetColor("power") .. u.Abbreviate(power)
            end
        elseif config == "powerdyn" then
            -- show percentage when only mana is less than 100%
            if unitMana ~= unitmanaMax and UnitPowerType(unitstr) == 0 then
                return unit:GetColor("power") ..
                    u.Abbreviate(unitMana) .. " - " .. ceil(unitMana / unitmanaMax * 100) .. "%"
            else
                return unit:GetColor("power") .. u.Abbreviate(unitMana)
            end
        elseif config == "powerminmax" then
            return unit:GetColor("power") .. u.Abbreviate(unitMana) .. "/" .. u.Abbreviate(unitmanaMax)
        else
            return ""
        end
    end

    function Unitframe.GetColor(self, preset)
        local config = self.config
        local unitstr = self.label .. self.id
        local r, g, b = 1, 1, 1

        if preset == "unit" then
            if UnitIsPlayer(unitstr) then
                local _, class = UnitClass(unitstr)
                if RAID_CLASS_COLORS[class] then
                    r, g, b = RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b
                end
            elseif self.label == "pet" then
                local happiness = GetPetHappiness()
                if happiness == 1 then
                    r, g, b = 1, 0, 0
                elseif happiness == 2 then
                    r, g, b = 1, 1, 0
                else
                    r, g, b = 0, 1, 0
                end
            else
                local color = UnitReactionColor[UnitReaction(unitstr, "player")]
                if color then r, g, b = color.r, color.g, color.b end
            end
        elseif preset == "class" then
            local _, class = UnitClass(unitstr)
            if RAID_CLASS_COLORS[class] then
                r, g, b = RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b
            end
        elseif preset == "reaction" then
            r = UnitReactionColor[UnitReaction(unitstr, "player")].r
            g = UnitReactionColor[UnitReaction(unitstr, "player")].g
            b = UnitReactionColor[UnitReaction(unitstr, "player")].b
        elseif preset == "health" then
            if UnitHealthMax(unitstr) > 0 then
                r, g, b = u.GetColorGradient(UnitHealth(unitstr) / UnitHealthMax(unitstr))
            else
                r, g, b = 0, 0, 0
            end
        elseif preset == "power" then
            r = ManaBarColor[UnitPowerType(unitstr)].r
            g = ManaBarColor[UnitPowerType(unitstr)].g
            b = ManaBarColor[UnitPowerType(unitstr)].b
        elseif preset == "level" then
            r = GetDifficultyColor(UnitLevel(unitstr)).r
            g = GetDifficultyColor(UnitLevel(unitstr)).g
            b = GetDifficultyColor(UnitLevel(unitstr)).b
        else
            r, g, b = 1.0, 0.8196, 0.0
        end

        if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].pastel == true then
            r = (r + .75) * .5
            g = (g + .75) * .5
            b = (b + .75) * .5
        end

        return u.Rgbhex(r, g, b)
    end

    --Debuff Helpers
    local function GetDebuffTypesForClass(class)
        local debuffTypes = {
            MAGE = { "Curse" },
            DRUID = { "Curse", "Poison" },
            PRIEST = { "Magic", "Disease" },
            WARLOCK = { "Magic" },
            PALADIN = { "Magic", "Poison", "Disease" },
            SHAMAN = { "Poison", "Disease" },
        }
        return debuffTypes[class]
    end


    function Unitframe:CheckDebuffs(unit, frame)
        local c = SimpleUIDB.Profilse[SimpleUIProfile]["Entities"]["Unitframes"]
        local _, class = UnitClass(unit)
        local classColor = RAID_CLASS_COLORS[class]
        local debuffTypes = GetDebuffTypesForClass(class)

        local show
        local Curses = {}
        local debuffCount = 0

        -- Check debuffs on the target
        for i = 1, MAX_TARGET_DEBUFFS do
            local debuff, _, debuffType = _G.UnitDebuff(unit, i)
            if not debuff then break end

            if debuffType then
                Curses[debuffType] = debuffType
                debuffCount = debuffCount + 1
            end
        end

        -- Determine if we should highlight based on debuff type and player class
        if debuffCount > 0 then
            if not c.HighlightDebuffClass then
                show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
            end

            for _, debuffType in ipairs(debuffTypes or {}) do
                if debuffType and Curses[debuffType] then
                    show = debuffType
                    break
                end
            end
        end

        local color = show and DebuffTypeColor[show] or classColor
        if UnitExists(unit) then
            color.a = 1
            frame:SetStatusBarColor(color.r, color.g, color.b, color.a)
        end
    end

    if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].player.enable then
        if not _G["SimpleUIplayer"] then
            PlayerFrame:Hide()
            PlayerFrame:UnregisterAllEvents()

            Unitframe.player = Unitframe:CreateUnitFrame("player", nil,
                SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].player)
            Unitframe.player:ClearAllPoints()
            Unitframe.player:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -75, 200)
            u.UpdateRelocator(Unitframe.player)
        end

        SimpleUI.player = Unitframe.player

        UnitPopupButtons["RESET_INSTANCES_FIX"] = { text = RESET_INSTANCES, dist = 0 }
        for id, text in pairs(UnitPopupMenus["SELF"]) do
            if text == "RESET_INSTANCES" then
                UnitPopupMenus["SELF"][id] = "RESET_INSTANCES_FIX"
            end
        end

        u.Hooksecurefunc("UnitPopup_OnClick", function()
            local button = this.value
            if button == "RESET_INSTANCES_FIX" then
                StaticPopup_Show("CONFIRM_RESET_INSYANCES")
            end
        end)
    end

    if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].target.enable then
        if not _G["SimpleUItarget"] then
            TargetFrame:Hide()
            TargetFrame:UnregisterAllEvents()

            Unitframe.target = Unitframe:CreateUnitFrame("target", nil,
                SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].target)
            Unitframe.target:ClearAllPoints()
            Unitframe.target:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 75, 200)
            Unitframe.target:UpdateFrameSize()
        end

        SimpleUI.target = Unitframe.target
    end

    if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].pet.enable then
        if not _G["SimpleUIpet"] then
            Unitframe.pet = Unitframe:CreateUnitFrame("pet", nil,
                SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].pet)
            Unitframe.pet:ClearAllPoints()
            Unitframe.pet:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -300, 210)
            Unitframe.pet:UpdateFrameSize()
        end
    end

    if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].targettarget.enable then
        if not _G["SimpleUItargettarget"] then
            Unitframe.targettarget = Unitframe:CreateUnitFrame("targettarget", nil,
                SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].targettarget, 0.1)
            Unitframe.targettarget:ClearAllPoints()
            Unitframe.targettarget:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 300, 210)
            Unitframe.targettarget:UpdateFrameSize()
        end
    end

    Unitframe.focus = Unitframe:CreateUnitFrame("focus", nil,
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].focus)
    Unitframe.focus:UpdateFrameSize()
    Unitframe.focus:SetPoint("TOPRIGHT", UIParent, "TOP", -330, -330)
    Unitframe.focus:Hide()

    SLASH_SUIFOCUS1 = "/focus"
    function SlashCmdList.SUIFOCUS(msg)
        if not Unitframe or not Unitframe.focus then return end
        if msg ~= "" then
            Unitframe.focus.unitname = strlower(msg)
        elseif UnitName("target") then
            Unitframe.focus.unitname = strlower(UnitName("target"))
        else
            Unitframe.focus.unitname = nil
            Unitframe.focus.label = nil
        end
    end

    SLASH_SUICLEARFOCUS1 = "/clearfocus"
    function SlashCmdList.SUICLEARFOCUS(msg)
        if Unitframe and Unitframe.focus then
            Unitframe.focus.label = nil
            Unitframe.focus.unitname = nil
        end
    end

    if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].party.enable then
        do
            local f
            for i = 1, 4 do
                f = _G[string.format("PartyMemberFrame%d", i)]
                if f then
                    f:Hide()
                    f:UnregisterAllEvents()
                    f.Show = function() return end
                end
            end
        end
        if IsAddOnLoaded("HealersMate") then
            return
        end
        Unitframe.group = Unitframe.group or {}
        function Unitframe.group:UpdateConfig()
            do
                local f
                for i = 1, 4 do
                    f = _G[string.format("PartyMemberFrame%d", i)]
                    if f then
                        f:Hide()
                        f:UnregisterAllEvents()
                        f.Show = function() return end
                    end
                end
            end
            if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].selfingroup == 1 then
                startid = 0
            end
            local spacing = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].party.pspace
            for i = startid, 4 do
                if not Unitframe.group[i] then
                    Unitframe.group[i] = Unitframe.group[i] or
                        Unitframe:CreateUnitFrame("party", i,
                            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].party)
                    Unitframe.group[i]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 15, -50 - ((i - startid) * 75)) --(i - startid)
                    Unitframe.group[i]:UpdateConfig()
                    if not Unitframe.group[i] then
                        SimpleUI:SystemMessage("Frame not found in M.Party.group for index " .. i)
                    end
                elseif Unitframe.group[i] then
                    Unitframe.group[i]:UpdateConfig()
                end
            end
        end

        Unitframe.group:UpdateConfig()
    end

    if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].raid.enable then
        if IsAddOnLoaded("HealersMate") then
            return
        end
        Unitframe.raid = CreateFrame("Frame", "SimpleUIRaidUpdate", UIParent)

        local maxraid = tonumber(40)
        local rawborder, default_border = 2, 2
        local assignedUnits = {}
        local cluster = CreateFrame("Frame", "SimpleUIRaidCluster", UIParent)
        cluster:SetFrameLevel(20)
        cluster:SetWidth(120)
        cluster:SetHeight(10)
        cluster:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", default_border * 2, 200 + default_border * 5)

        Unitframe.raid.tanksfirst = {
            ["SIMPLE_TANK_TOGGLE"] = { "Toggle as Tank", "toggleTank" }
        }
        Unitframe.raid.tankrole = {}

        function Unitframe.raid:UpdateConfig()
            local rawborder, default_border = 2, 2
            maxraid = tonumber(40)

            for i = 1, maxraid do
                Unitframe.raid[i] = Unitframe.raid[i] or
                    Unitframe:CreateUnitFrame("raid", i,
                        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].raid)
                Unitframe.raid[i]:SetParent(cluster)
                Unitframe.raid[i]:SetFrameLevel(5)
                Unitframe.raid[i]:UpdateConfig()
                Unitframe.raid[i]:UpdateFrameSize()
            end

            local i = 1
            local width = Unitframe.raid[1]:GetWidth() + 2 * default_border
            local height = Unitframe.raid[1]:GetHeight() + 2 * default_border
            local layout = Unitframe.raid[1].config.raidlayout
            local padding = tonumber(Unitframe.raid[1].config.raidpadding) * u.GetPerfectPixel()
            local fill = Unitframe.raid[1].config.raidfill
            local _, _, x, y = string.find(layout, "(.+)x(.+)")
            x, y = tonumber(x), tonumber(y)

            if fill == "VERTICAL" then
                for r = 1, x do
                    for g = 1, y do
                        if Unitframe.raid[i] then
                            Unitframe.raid[i]:ClearAllPoints()
                            Unitframe.raid[i]:SetPoint("BOTTOMLEFT", (r - 1) * (padding + width), (g - 1) *
                                (padding + height))
                        end
                        i = i + 1
                    end
                end
            else
                for g = 1, y do
                    for r = 1, x do
                        if Unitframe.raid[i] then
                            Unitframe.raid[i]:ClearAllPoints()
                            Unitframe.raid[i]:SetPoint("BOTTOMLEFT", (r - 1) * (padding + width), (g - 1) *
                                (padding + height))
                        end
                        i = i + 1
                    end
                end
            end
        end

        Unitframe.raid:UpdateConfig()

        local function SetRaidIndex(frame, id)
            frame.id = id
            frame.label = "raid"
            frame:UpdateVisibility()
        end

        function Unitframe.raid:AddUnitToGroup(index, group)
            if assignedUnits[index] then return end
            for subindex = 1, 5 do
                local ids = subindex + 5 * (group - 1)
                if Unitframe.raid[ids] and Unitframe.raid[ids].id == 0 and Unitframe.raid[ids].config.visible == 1 then
                    SetRaidIndex(Unitframe.raid[ids], index)
                    assignedUnits[index] = true
                    break
                end
            end
        end

        Unitframe.raid:Hide()
        Unitframe.raid:RegisterEvent("RAID_ROSTER_UPDATE")
        Unitframe.raid:RegisterEvent("VARIABLES_LOADED")
        Unitframe.raid:SetScript("OnEvent", function() this:Show() end)
        Unitframe.raid:SetScript("OnUpdate", function()
            -- don't proceed without raid or during combat
            if not UnitInRaid("player") or (InCombatLockdown and InCombatLockdown()) then return end

            assignedUnits = {}

            -- clear all existing frames
            for i = 1, maxraid do SetRaidIndex(Unitframe.raid[i], 0) end

            -- sort tanks into their groups
            for i = 1, GetNumRaidMembers() do
                local name, _, subgroup = GetRaidRosterInfo(i)
                if name and Unitframe.raid.tankrole[name] then
                    Unitframe.raid:AddUnitToGroup(i, subgroup)
                end
            end

            -- sort players into roster
            for i = 1, GetNumRaidMembers() do
                local name, _, subgroup = GetRaidRosterInfo(i)
                if name and not Unitframe.raid.tankrole[name] then
                    Unitframe.raid:AddUnitToGroup(i, subgroup)
                end
            end

            this:Hide()
        end)



        local iupm = table.getn(UnitPopupMenus["RAID"])
        for label, data in pairs(Unitframe.raid.tanksfirst) do
            UnitPopupButtons[label] = { text = TEXT(data[1]), dist = 0 }
            table.insert(UnitPopupMenus["RAID"], iupm - 1, label)
        end

        u.Hooksecurefunc("UnitPopup_OnClick", function()
            local dropdownFrame = _G[UIDROPDOWNMENU_INIT_MENU]
            local button = this.value
            local unit = dropdownFrame.unit
            local name = dropdownFrame.name

            if button and Unitframe.raid.tanksfirst[button] and name then
                Unitframe.raid.tankrole[name] = not Unitframe.raid.tankrole[name]
                Unitframe.raid:Show()
            end
        end)
    end
end)
