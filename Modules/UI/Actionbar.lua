--[[
SimpleUI Actionbar Module for WoW Vanilla 1.12 - Turtle WoW
Author: BeardedRasta
Description: Custom action bar management, enhancing functionality for stances, pets, and shapeshifts.
--]]

SimpleUI:AddModule("Actionbar", function()
    if SimpleUI:IsDisabled("Actionbar") then return end

    ----------------------------------------------------------------
    -- 1) MODULE TABLE & BASIC SETUP
    ----------------------------------------------------------------
    local Actionbar = CreateFrame("Frame")

    -- Utility Functions --------------------------------------------

    local function SetSize(frame, height, width)
        frame:SetHeight(height)
        frame:SetWidth(width)
    end

    -- Remove a frame by unregistering events, clearing points, and hiding it
    function SimpleUI_RemoveFrame(frame)
        if (frame:GetObjectType() ~= "Texture") then
            frame:SetScript("OnEvent", nil)
            frame:UnregisterAllEvents()
        end
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMRIGHT", UIParent, "TOPLEFT", -100, 100)
        frame:SetParent(nil)
        frame:Hide()
    end

    local function ConfigureStatusbar(bar)
        if not bar or not bar.GetChildren then
            return
        end

        if bar:IsObjectType("StatusBar") then
            bar:SetStatusBarTexture(SimpleUITextures["StatusbarShadow"])
        end
        for _, child in ipairs({ bar:GetChildren() }) do
            ConfigureStatusbar(child)
        end
    end


    -- Set up a button with specified settings
    function SimpleUI_SetupButton(button, parent, size, normalTexture, textureSize, position)
        if parent then
            button:SetParent(parent)
        end
        if size then
            SetSize(button, size, size)
        end

        button:ClearAllPoints()
        button:SetNormalTexture(normalTexture)
        button:SetFrameLevel(5)

        local btnNormal = button:GetNormalTexture()
        SetSize(btnNormal, textureSize, textureSize)
        btnNormal:SetDrawLayer("OVERLAY")

        button:GetPushedTexture():SetDrawLayer("OVERLAY")
        button:GetCheckedTexture():SetDrawLayer("ARTWORK")

        getglobal(button:GetName() .. "HotKey"):SetDrawLayer("OVERLAY")
        getglobal(button:GetName() .. "Cooldown"):SetFrameLevel(5)

        if position then
            button:SetPoint(unpack(position))
        else
            button:SetPoint("TOPLEFT", 0, 0)
        end

        if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI then
            btnNormal:SetVertexColor(0.3, 0.3, 0.3, 1)
        else
            btnNormal:SetVertexColor(1, 1, 1, 1)
        end
    end

    -- Module Initialization ----------------------------------------

    -- Default settings for stance pages and multi-action pages
    function SimpleUI_Defaults()
        return {
            stancePages = {
                [0] = 3, -- Humanoid form
                [1] = 5, -- Battle stance, bear, stealth
                [2] = 5, -- Defensive stance, seal
                [3] = 6, -- Cat
                [4] = 7, -- Travel
                [5] = 8  -- Mind controlled
            },
            multiPages = {
                [1] = 11, -- Multi-action left
                [2] = 12  -- Multi-action right
            }
        }
    end

    ----------------------------------------------------------------
    -- 2) MAIN ACTION BAR REPLACEMENT FUNCTION
    ----------------------------------------------------------------

    -- Main replacement logic for the action bars
    function SimpleUI_Replace(config)
        -- config = Actionbar

        ----------------------------------------------------------------
        -- 2A) HELPER SUB-FUNCTIONS
        ----------------------------------------------------------------

        local function configureBar(bar, parent)
            bar:ClearAllPoints()
            bar:SetParent(parent)
            SetSize(bar, 13, 590)
            bar:SetPoint("BOTTOM", 0, 2)
            ConfigureStatusbar(bar)
        end


        local function configureStanceButton(frame, parent)
            local prev = nil
            if parent then
                prev = { "LEFT", parent, "RIGHT", 6, 0 }
            end
            SimpleUI_SetupButton(frame, config.stanceBar, nil, config.texturePath.slotBG, 54, prev)
        end

        ----------------------------------------------------------------
        -- 2B) PREPARE & CLEANUP
        ----------------------------------------------------------------

        UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomLeft"] = nil

        NUM_MULTIBAR_BUTTONS   = 10
        NUM_ACTIONBAR_BUTTONS  = 10
        NUM_BONUS_ACTION_SLOTS = NUM_ACTIONBAR_BUTTONS
        BONUSACTIONBAR_XPOS    = 0
        BONUSACTIONBAR_YPOS    = 37
        NUM_ACTIONBAR_PAGES    = 1

        LEFT_ACTIONBAR_PAGE  = config.settings.multiPages[1]
        RIGHT_ACTIONBAR_PAGE = config.settings.multiPages[2]

        local framesToHide = {
            "MainMenuXPBarTexture0",
            "MainMenuXPBarTexture1",
            "MainMenuXPBarTexture2",
            "MainMenuXPBarTexture3",
            "BonusActionBarTexture0",
            "BonusActionBarTexture1",
            "MainMenuBarMaxLevelBar",
            "MultiBarRightButton11",
            "MultiBarRightButton12",
            "MultiBarBottomLeftButton11",
            "MultiBarBottomLeftButton12",
            "MultiBarBottomRightButton11",
            "MultiBarBottomRightButton12",
            "MultiBarLeftButton11",
            "MultiBarLeftButton12",
            "BonusActionButton11",
            "BonusActionButton12",
            "MainMenuBar",
        }
        for _, fName in ipairs(framesToHide) do
            SimpleUI_RemoveFrame(getglobal(fName))
        end

        ----------------------------------------------------------------
        -- 2C) CONFIGURE XP/REP BARS
        ----------------------------------------------------------------

        configureBar(MainMenuExpBar, config.xpBar)
        configureBar(ReputationWatchBar, config.xpBar)


        ExhaustionTick:SetParent(MainMenuExpBar)
        MainMenuBarOverlayFrame:SetFrameStrata("MEDIUM")
        MainMenuBarOverlayFrame:SetFrameLevel(3)

        ReputationWatchBar:SetFrameLevel(5)
        MainMenuExpBar:SetFrameLevel(2)

        ReputationWatchStatusBar:ClearAllPoints()
        ReputationWatchStatusBar:SetAllPoints()

        MainMenuExpBar:SetScript('OnEnter', function()
            local factionName, _, _, _, _ = GetWatchedFactionInfo()
--[[             local lvl = UnitLevel('player')
            local restedStr
            if GetXPExhaustion and GetXPExhaustion() ~= nil then
                rest = string.format("Rested: |cff90ee90%d|r - (|cff1a9fc0%.0f%%|r)", GetXPExhaustion(),
                    GetXPExhaustion() / UnitXPMax("player") * 100)
            else
                rest = "Rested: |cff90ee900|r"
            end ]]
            if (factionName) then
                ReputationWatchBar:Show()
                MainMenuExpBar:Hide()
            else
                TextStatusBar_UpdateTextString()
                ShowTextStatusBarText(this)
                ExhaustionTick.timer = 1
            end
        end)

        MainMenuExpBar:SetScript("OnLeave", function()
            HideTextStatusBarText(this)
        end)

        ReputationWatchBar:SetScript('OnLeave', function()
            ReputationWatchBar:Hide()
            MainMenuExpBar:Show()
        end)

        ----------------------------------------------------------------
        -- 2D) BONUS ACTION BAR, MULTI-BARS
        ----------------------------------------------------------------

        BonusActionBarFrame:SetParent(config.actionBar)
        BonusActionBarFrame:ClearAllPoints()
        BonusActionBarFrame:SetAllPoints()

        MultiBarRight:ClearAllPoints()
        MultiBarRight:SetPoint('BOTTOMRIGHT', -3, 45)

        MultiBarLeft:ClearAllPoints()
        MultiBarLeft:SetPoint('TOPRIGHT', MultiBarRight, 'TOPLEFT', -4, 0)

        MultiBarBottomLeft:UnregisterAllEvents()
        SetSize(MultiBarBottomLeft, 37, 406)

        MultiBarBottomRight:UnregisterAllEvents()
        SetSize(MultiBarBottomRight, 37, 406)

        ----------------------------------------------------------------
        -- 2E) SETUP ACTION BUTTONS
        ----------------------------------------------------------------

        -- Set up action buttons
        local ab, bab, mblb, mbrb, abTop, abOut = {}, {}, {}, {}, {}, {}
        for i = 1, NUM_ACTIONBAR_BUTTONS do
            ab[i] = getglobal('ActionButton' .. i)
            bab[i] = getglobal('BonusActionButton' .. i)
            mblb[i] = getglobal('MultiBarLeftButton' .. i)
            mbrb[i] = getglobal('MultiBarRightButton' .. i)
            abTop[i] = getglobal('MultiBarBottomLeftButton' .. i)
            abOut[i] = getglobal('MultiBarBottomRightButton' .. i)

            local prevPositions = { nil, nil, nil, nil }
            if i > 1 then
                prevPositions[1] = { 'LEFT', ab[i - 1], 'RIGHT', 4, 0 }
                prevPositions[2] = { 'LEFT', bab[i - 1], 'RIGHT', 4, 0 }
                prevPositions[3] = { 'TOP', mblb[i - 1], 'BOTTOM', 0, -4 }
                prevPositions[4] = { 'TOP', mbrb[i - 1], 'BOTTOM', 0, -4 }
                prevPositions[5] = { 'LEFT', abTop[i - 1], 'RIGHT', 4, 0 }
                prevPositions[6] = { 'LEFT', abOut[i - 1], 'RIGHT', 4, 0 }
            end

            SimpleUI_SetupButton(ab[i],    config.actionBar.default, 37, config.texturePath.slot, 64, prevPositions[1])
            SimpleUI_SetupButton(bab[i],   nil,                      37, config.texturePath.slot, 64, prevPositions[2])
            SimpleUI_SetupButton(mblb[i],  nil,                      37, config.texturePath.slot, 64, prevPositions[3])
            SimpleUI_SetupButton(mbrb[i],  nil,                      37, config.texturePath.slot, 64, prevPositions[4])
            SimpleUI_SetupButton(abTop[i], nil,                      37, config.texturePath.slot, 64, prevPositions[5])
            SimpleUI_SetupButton(abOut[i], nil,                      37, config.texturePath.slot, 64, prevPositions[6])
        end

        MultiBarBottomLeft:ClearAllPoints()
        MultiBarBottomLeft:SetPoint("CENTER", config.actionBarTop, "CENTER", 0, 0)
        MultiBarBottomLeft:SetScale(1)

        MultiBarBottomRight:ClearAllPoints()
        MultiBarBottomRight:SetPoint("BOTTOM", config.actionBarTop, "TOP", 0, 5)
        MultiBarBottomRight:SetScale(1)

        ----------------------------------------------------------------
        -- 2F) PET & STANCE BUTTONS
        ----------------------------------------------------------------

        local pab, sb = {}, {}
        for i = 1, NUM_PET_ACTION_SLOTS do
            pab[i] = getglobal('PetActionButton' .. i)
            configureStanceButton(pab[i], pab[i - 1])
            getglobal('PetActionButton' .. i .. 'AutoCast'):SetFrameLevel(5)
        end

        for i = 1, NUM_SHAPESHIFT_SLOTS do
            sb[i] = getglobal('ShapeshiftButton' .. i)
            configureStanceButton(sb[i], sb[i - 1])
        end

        ----------------------------------------------------------------
        -- 2G) FORCE THE MAIN BAR’S SHOWGRID
        ----------------------------------------------------------------

        for i = 1, NUM_ACTIONBAR_BUTTONS do
            local btn = getglobal("ActionButton" .. i)
            if btn then
                btn.showgrid = (btn.showgrid or 0) + 1
                ActionButton_ShowGrid(btn)
            end
        end
    end

    ----------------------------------------------------------------
    -- 3) ACTIONBAR CONFIG & FRAMES
    ----------------------------------------------------------------

    Actionbar.settings = SimpleUI_Defaults()
    Actionbar.texturePath = {
        xp = SimpleUI_GetTexture("StatusbarDefault"),
        slot = SimpleUI_GetTexture("SlotBg"),
        slotBG = SimpleUI_GetTexture("SlotBorder"),
        stanceBar = SimpleUI_GetTexture("Stancebar")
    }

    Actionbar.xpBar = CreateFrame("Frame", nil, UIParent)
    Actionbar.xpBar:SetFrameLevel(5)
    SetSize(Actionbar.xpBar, 25, 604)
    Actionbar.xpBar:SetPoint('BOTTOM', UIParent)

    Actionbar.xpBar.Bg = MainMenuExpBar:CreateTexture(nil, "BACKGROUND")
    Actionbar.xpBar.Bg:SetAllPoints()
    Actionbar.xpBar.Bg:SetTexture(SimpleUI_GetTexture("StatusbarShadow"))
    Actionbar.xpBar.Bg:SetVertexColor(0.15, 0.15, 0.15, 1)

    Actionbar.RepHolder = CreateFrame("Frame", nil, ReputationWatchBar)
    Actionbar.RepHolder:SetAllPoints(ReputationWatchBar)
    Actionbar.RepHolder:SetFrameLevel(1)

    Actionbar.xpBar.repBg = Actionbar.RepHolder:CreateTexture(nil, "BACKGROUND")
    Actionbar.xpBar.repBg:SetAllPoints()
    Actionbar.xpBar.repBg:SetTexture(SimpleUI_GetTexture("StatusbarDefault"))
    Actionbar.xpBar.repBg:SetVertexColor(0.3, 0.3, 0.3, 1)

    Actionbar.xpBar.textureMiddle = Actionbar.xpBar:CreateTexture(nil, 'ARTWORK')
    Actionbar.xpBar.textureMiddle:SetWidth(606)
    Actionbar.xpBar.textureMiddle:SetHeight(32)
    Actionbar.xpBar.textureMiddle:SetTexture(SimpleUI_GetTexture("ExpFull"))

    Actionbar.ArtFrame = CreateFrame("Frame", nil, UIParent)
    Actionbar.ArtFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 15)
    Actionbar.ArtFrame:SetWidth(400)
    Actionbar.ArtFrame:SetHeight(100)
    Actionbar.ArtFrame:Show()

    Actionbar.ArtFrame.leftTop = Actionbar.ArtFrame:CreateTexture(nil, "ARTWORK")
    Actionbar.ArtFrame.leftTop:SetWidth(430)
    Actionbar.ArtFrame.leftTop:SetHeight(52)
    Actionbar.ArtFrame.leftTop:SetPoint("BOTTOM", Actionbar.ArtFrame)
    Actionbar.ArtFrame.leftTop:SetTexture(SimpleUI_GetTexture("BarBgArt"))

    Actionbar.ArtFrame.leftCap = Actionbar.ArtFrame:CreateTexture(nil, "ARTWORK")
    Actionbar.ArtFrame.leftCap:SetTexCoord(1 / 256, 189 / 256, 1 / 128, 125 / 128)
    Actionbar.ArtFrame.leftCap:SetPoint("BOTTOMRIGHT", Actionbar.ArtFrame, "BOTTOMLEFT", 7, 0)
    Actionbar.ArtFrame.leftCap:SetWidth(94)
    Actionbar.ArtFrame.leftCap:SetHeight(72)
    Actionbar.ArtFrame.leftCap:SetTexture(SimpleUI_GetTexture("Gryphon"))

    Actionbar.ArtFrame.rightCap = Actionbar.ArtFrame:CreateTexture(nil, "ARTWORK")
    Actionbar.ArtFrame.rightCap:SetTexCoord(189 / 256, 1 / 256, 1 / 128, 125 / 128)
    Actionbar.ArtFrame.rightCap:SetPoint("BOTTOMLEFT", Actionbar.ArtFrame, "BOTTOMRIGHT", -7, 0)
    Actionbar.ArtFrame.rightCap:SetWidth(94)
    Actionbar.ArtFrame.rightCap:SetHeight(72)
    Actionbar.ArtFrame.rightCap:SetTexture(SimpleUI_GetTexture("Gryphon"))

    Actionbar.stanceBar = CreateFrame('Frame', nil, UIParent)
    Actionbar.stanceBar:SetPoint('BOTTOMRIGHT', Actionbar.xpBar, 'BOTTOMLEFT', -100, 0)
    Actionbar.stanceBar:SetHeight(38)
    Actionbar.stanceBar:Hide()

    Actionbar.stanceBar.textureLeft = Actionbar.stanceBar:CreateTexture(nil, 'ARTWORK')
    SetSize(Actionbar.stanceBar.textureLeft, 16, 48)
    Actionbar.stanceBar.textureLeft:SetTexCoord(0.03125, 0.125, 0.5, 1)
    Actionbar.stanceBar.textureLeft:SetPoint('BOTTOMRIGHT', Actionbar.stanceBar, 'BOTTOMLEFT', 11, 0)
    Actionbar.stanceBar.textureLeft:SetTexture(Actionbar.texturePath.stanceBar)

    Actionbar.stanceBar.textureRight = Actionbar.stanceBar:CreateTexture(nil, 'ARTWORK')
    SetSize(Actionbar.stanceBar.textureRight, 16, 48)
    Actionbar.stanceBar.textureRight:SetTexCoord(0.875, 0.96875, 0.5, 1)
    Actionbar.stanceBar.textureRight:SetPoint('BOTTOMLEFT', Actionbar.stanceBar, 'BOTTOMRIGHT', -11, 0)
    Actionbar.stanceBar.textureRight:SetTexture(Actionbar.texturePath.stanceBar)

    Actionbar.stanceBar.textureMiddle = Actionbar.stanceBar:CreateTexture(nil, 'ARTWORK')
    Actionbar.stanceBar.textureMiddle:SetHeight(16)
    Actionbar.stanceBar.textureMiddle:SetTexCoord(0.25, 0.55, 0.5, 1)
    Actionbar.stanceBar.textureMiddle:SetPoint('BOTTOMLEFT', Actionbar.stanceBar, 11, 0)
    Actionbar.stanceBar.textureMiddle:SetPoint('BOTTOMRIGHT', Actionbar.stanceBar, -11, 0)
    Actionbar.stanceBar.textureMiddle:SetTexture(Actionbar.texturePath.stanceBar)

    Actionbar.stanceBar.textureMark = {}
    for i = 2, NUM_SHAPESHIFT_SLOTS do
        Actionbar.stanceBar.textureMark[i] = Actionbar.stanceBar:CreateTexture(nil, 'OVERLAY')
        SetSize(Actionbar.stanceBar.textureMark[i], 16, 16)
        Actionbar.stanceBar.textureMark[i]:SetTexCoord(0, 0.03125, 0, 0.5)
        if i < 3 then
            Actionbar.stanceBar.textureMark[i]:SetPoint('BOTTOMRIGHT', -25, -6)
        else
            Actionbar.stanceBar.textureMark[i]:SetPoint('RIGHT', Actionbar.stanceBar.textureMark[i - 1], 'LEFT', -20, 0)
        end
        Actionbar.stanceBar.textureMark[i]:SetTexture(Actionbar.texturePath.stanceBar)
        Actionbar.stanceBar.textureMark[i]:Hide()
    end

    Actionbar.actionBar = CreateFrame('Frame', nil, UIParent)
    SetSize(Actionbar.actionBar, 37, 406)
    Actionbar.actionBar:SetPoint('BOTTOM', 0, 20)

    Actionbar.actionBar.default = CreateFrame('Frame', nil, Actionbar.actionBar)
    Actionbar.actionBar.default:SetAllPoints()

    Actionbar.actionBarTop = CreateFrame('Frame', nil, UIParent)
    SetSize(Actionbar.actionBarTop, 37, 406)
    Actionbar.actionBarTop:SetPoint('BOTTOM', 0, 62)

    ----------------------------------------------------------------
    -- 4) ACTIONBAR UPDATE LOGIC
    ----------------------------------------------------------------

    function SimpleUI_Update_Actionbar()
        local DB = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"]
        if DB.ActionbarArt then
            SetSize(Actionbar.xpBar.textureMiddle, 32, 606)
            SetSize(MainMenuExpBar, 13, 590)
            SetSize(ReputationWatchBar, 13, 590)
            Actionbar.xpBar.textureMiddle:ClearAllPoints()
            Actionbar.xpBar.textureMiddle:SetPoint('BOTTOM', Actionbar.xpBar, 0, -2)
            Actionbar.xpBar.textureMiddle:SetTexture(SimpleUI_GetTexture("ExpFull"))
            Actionbar.ArtFrame:Show()
            Actionbar.ArtFrame.leftCap:Show()
            Actionbar.ArtFrame.rightCap:Show()
        else
            SetSize(Actionbar.xpBar.textureMiddle, 32, 512)
            SetSize(MainMenuExpBar, 13, 418)
            SetSize(ReputationWatchBar, 13, 418)
            Actionbar.xpBar.textureMiddle:ClearAllPoints()
            Actionbar.xpBar.textureMiddle:SetPoint('BOTTOM', Actionbar.xpBar, 0, 0)
            Actionbar.xpBar.textureMiddle:SetTexture(SimpleUI_GetTexture("ExpMinimal"))
            Actionbar.ArtFrame:Hide()
            Actionbar.ArtFrame.leftCap:Hide()
            Actionbar.ArtFrame.rightCap:Hide()
        end

        local useDarkUI = not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI
        if useDarkUI then
            Actionbar.xpBar.textureMiddle:SetVertexColor(0.3, 0.3, 0.3, 0.9)
            Actionbar.ArtFrame.leftCap:SetVertexColor(0.4, 0.4, 0.4, 0.9)
            Actionbar.ArtFrame.rightCap:SetVertexColor(0.4, 0.4, 0.4, 0.9)
            Actionbar.stanceBar.textureLeft:SetVertexColor(0.3, 0.3, 0.3, 0.9)
            Actionbar.stanceBar.textureRight:SetVertexColor(0.3, 0.3, 0.3, 0.9)
            Actionbar.stanceBar.textureMiddle:SetVertexColor(0.3, 0.3, 0.3, 0.9)
            Actionbar.ArtFrame.leftTop:SetVertexColor(0.3, 0.3, 0.3, 0.9)
        else
            Actionbar.xpBar.textureMiddle:SetVertexColor(1, 1, 1, 1)
            Actionbar.ArtFrame.leftCap:SetVertexColor(1, 1, 1, 1)
            Actionbar.ArtFrame.rightCap:SetVertexColor(1, 1, 1, 1)
            Actionbar.stanceBar.textureLeft:SetVertexColor(1, 1, 1, 1)
            Actionbar.stanceBar.textureRight:SetVertexColor(1, 1, 1, 1)
            Actionbar.stanceBar.textureMiddle:SetVertexColor(1, 1, 1, 1)
            Actionbar.ArtFrame.leftTop:SetVertexColor(1, 1, 1, 1)
        end
    end

    ----------------------------------------------------------------
    -- 5) OVERRIDE/HOOK BLIZZARD FUNCTIONS
    ----------------------------------------------------------------

    local OLD_PetActionBar_Update = PetActionBar_Update
    PetActionBar_Update = function()
        OLD_PetActionBar_Update()


        if PetHasActionBar() then
            Actionbar.stanceBar:SetWidth((NUM_PET_ACTION_SLOTS - 1) * 36 + 30)
            for i = 2, NUM_PET_ACTION_SLOTS do
                Actionbar.stanceBar.textureMark[i]:Show()
            end
        end

        for i = 1, NUM_PET_ACTION_SLOTS do
            local btn = getglobal("PetActionButton" .. i)
            local _, _, auto = GetPetActionInfo(i)
            if auto then
                btn:SetNormalTexture(Actionbar.texturePath.slotBg)
            else
                btn:SetNormalTexture(Actionbar.texturePath.slot)
            end
        end
    end

    local OLD_ShowPetActionBar = ShowPetActionBar
    ShowPetActionBar = function()
        OLD_ShowPetActionBar()

        if PetHasActionBar() and PetActionBarFrame.showgrid == 0
           and (PetActionBarFrame.mode ~= "show")
           and not PetActionBarFrame.locked
           and not PetActionBarFrame.ctrlPressed
        then
            Actionbar.stanceBar:Show()
        end
    end

    local OLD_ReputationWatchBar_Update = ReputationWatchBar_Update
    ReputationWatchBar_Update = function(newLevel)
        if (not newLevel) then
            newLevel = UnitLevel("player");
        end
        OLD_ReputationWatchBar_Update(newLevel)

        if (newLevel < MAX_PLAYER_LEVEL) then
            ReputationWatchStatusBar:SetHeight(13)
            ReputationWatchBar:ClearAllPoints()
            ReputationWatchBar:SetPoint("BOTTOM", Actionbar.xpBar, 0, 2)
            ReputationWatchStatusBarText:SetPoint("CENTER", ReputationWatchBarOverlayFrame, "CENTER", 0, 1)
            ReputationWatchBarTexture0:Hide()
            ReputationWatchBarTexture1:Hide()
            ReputationWatchBarTexture2:Hide()
            ReputationWatchBarTexture3:Hide()
            ReputationWatchBar:Hide()
            MainMenuExpBar:Show()
        else
            Actionbar.xpBar:SetPoint('BOTTOM', UIParent)
            ReputationWatchBar:Show()
            ReputationWatchStatusBar:SetHeight(13)
            ReputationWatchBar:ClearAllPoints()
            ReputationWatchBar:SetPoint("BOTTOM", Actionbar.xpBar, 0, 2)
            ReputationWatchStatusBarText:SetPoint("CENTER", ReputationWatchBarOverlayFrame, "CENTER", 0, 1)
            ReputationXPBarTexture0:Hide()
            ReputationXPBarTexture1:Hide()
            ReputationXPBarTexture2:Hide()
            ReputationXPBarTexture3:Hide()
            ExhaustionTick:Hide()
            MainMenuExpBar:Hide()
        end
    end

    local OLD_ActionButton_ShowGrid = ActionButton_ShowGrid
    ActionButton_ShowGrid = function(button)
        if (not button) then
            button = this
        end

        for i = 1, NUM_ACTIONBAR_BUTTONS do
            local actBtn = getglobal("ActionButton" .. i)
            OLD_ActionButton_ShowGrid(actBtn)

            local normalTex = getglobal(actBtn:GetName() .. "NormalTexture")
            if normalTex then
                if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI then
                    normalTex:SetVertexColor(0.4, 0.4, 0.4, 1)
                else
                    normalTex:SetVertexColor(1, 1, 1, 1)
                end
            end
        end

        for i = 1, NUM_SHAPESHIFT_SLOTS do
            local shiftBtn = getglobal("BonusActionButton" .. i)
            OLD_ActionButton_ShowGrid(shiftBtn)

            local shiftTex = getglobal(shiftBtn:GetName() .. "NormalTexture")
            if shiftTex then
                if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI then
                    shiftTex:SetVertexColor(0.4, 0.4, 0.4, 1)
                else
                    shiftTex:SetVertexColor(1, 1, 1, 1)
                end
            end
        end

        OLD_ActionButton_ShowGrid(button)
        local tex = getglobal(button:GetName() .. "NormalTexture")
        if tex then
            if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI then
                tex:SetVertexColor(0.4, 0.4, 0.4, 1)
            else
                tex:SetVertexColor(1, 1, 1, 1)
            end
        end
    end

    local OLD_ActionButton_HideGrid = ActionButton_HideGrid
    ActionButton_HideGrid = function(button)
        if (not button) then
            button = this
        end
        for i = 1, NUM_ACTIONBAR_BUTTONS do
            local ActButton = getglobal('ActionButton' .. i)
            OLD_ActionButton_HideGrid(ActButton)
        end
        for i = 1, NUM_SHAPESHIFT_SLOTS do
            local ShiftButton = getglobal('BonusActionButton' .. i)
            OLD_ActionButton_HideGrid(ShiftButton)
        end
        OLD_ActionButton_HideGrid(button)
    end

    local OLD_ActionButton_Update = ActionButton_Update
    ActionButton_Update = function()
        OLD_ActionButton_Update()
        local texture = GetActionTexture(ActionButton_GetPagedID(this))
        if texture then
            this:SetNormalTexture(SimpleUI_GetTexture("SlotBorder"))
            if (this.isBonus) then
                this.texture = texture
            end
        else
            this:SetNormalTexture(SimpleUI_GetTexture("SlotBg"))
        end
    end

    local OLD_ShapeshiftBar_Update = ShapeshiftBar_Update
    ShapeshiftBar_Update = function()
        OLD_ShapeshiftBar_Update()
        local forms = GetNumShapeshiftForms()
        if forms > 0 then
            Actionbar.stanceBar:SetWidth((forms - 1) * 36 + 30)
            for i = 2, forms do
                Actionbar.stanceBar.textureMark[i]:Show()
            end
            Actionbar.stanceBar:Show()
        elseif not PetHasActionBar() then
            Actionbar.stanceBar:Hide()
        end
    end

    --[[ local OLD_ShowBonusActionBar = ShowBonusActionBar
    ShowBonusActionBar = function()
        if BonusActionBarFrame.mode ~= "show" and BonusActionBarFrame.state ~= "top" then
            if Actionbar.actionBar.default:IsShown() then
                Actionbar.actionBar.default:Hide()
            end
        end
        OLD_ShowBonusActionBar()
    end ]]

    local OLD_HideBonusActionBar = HideBonusActionBar
    HideBonusActionBar = function()
        if (BonusActionBarFrame:IsShown()) then
            if not Actionbar.actionBar.default:IsShown() then
                Actionbar.actionBar.default:Show()
            end
        end
        OLD_HideBonusActionBar()
    end

    local function SimpleUI_BarUpdate(num)
        if (IsShiftKeyDown()) then
            if (CURRENT_ACTIONBAR_PAGE == 1 or num) then
                CURRENT_ACTIONBAR_PAGE = Actionbar.settings.stancePages[GetBonusBarOffset()]
                ChangeActionBarPage()
            end
        else
            if (CURRENT_ACTIONBAR_PAGE ~= 1) then
                CURRENT_ACTIONBAR_PAGE = 1
                ChangeActionBarPage()
            end
        end
    end


    -- Event Handlers -----------------------------------------------
    local ActionbarWatcher = CreateFrame("Frame", nil)
    ActionbarWatcher:RegisterEvent("ADDON_LOADED")
    ActionbarWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    ActionbarWatcher:RegisterEvent('VARIABLES_LOADED')

    ActionbarWatcher:SetScript("OnEvent", function()
        if event == 'UPDATE_BONUS_ACTIONBAR' then
            SimpleUI_BarUpdate(1)
        elseif event == 'UPDATE_SHAPESHIFT_FORMS' then
            ShapeshiftBar_Update()
        elseif (event == 'PET_BAR_UPDATE' or (event == 'UNIT_PET' and arg1 == 'player')) then
            if PetHasActionBar() then
                Actionbar.stanceBar:Show()
            elseif GetNumShapeshiftForms() < 1 then
                Actionbar.stanceBar:Hide()
            end
        elseif event == "ADDON_LOADED" then
            this:UnregisterEvent('ADDON_LOADED')
            this:RegisterEvent('UPDATE_BONUS_ACTIONBAR')
            this:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
            this:RegisterEvent('PET_BAR_UPDATE')
            this:RegisterEvent('UNIT_PET')
            SimpleUI_Replace(Actionbar)
            SimpleUI_Update_Actionbar()
        elseif event == "PLAYER_ENTERING_WORLD" then
            SimpleUI_Update_Actionbar()
        end
    end)


    UIParent_ManageFramePositions = function()
        local yOffsetFrames = {};
        local xOffsetFrames = {};

        if (SHOW_MULTI_SimpleUI_1) then
            tinsert(yOffsetFrames, "bottomLeft");
        end

        if (MultiBarLeft:IsShown()) then
            tinsert(xOffsetFrames, "rightLeft");
        elseif (MultiBarRight:IsShown()) then
            tinsert(xOffsetFrames, "rightRight");
        end

        if ((PetActionBarFrame and PetActionBarFrame:IsShown()) or (ShapeshiftBarFrame and ShapeshiftBarFrame:IsShown())) then
            tinsert(yOffsetFrames, "pet");
        end

        if (MainMenuBarMaxLevelBar:IsShown()) then
            tinsert(yOffsetFrames, "maxLevel");
        end

        local frame, xOffset, yOffset, anchorTo, point, rpoint;
        for index, value in UIPARENT_MANAGED_FRAME_POSITIONS do
            frame = getglobal(index);
            if (frame) then
                xOffset = 0;
                if (value["baseX"]) then
                    xOffset = value["baseX"];
                elseif (value["xOffset"]) then
                    xOffset = value["xOffset"];
                end
                yOffset = 0;
                if (value["baseY"]) then
                    yOffset = value["baseY"];
                end
                local hasBottomLeft, hasPetBar;
                for flag, flagValue in yOffsetFrames do
                    if (value[flagValue]) then
                        if (flagValue == "bottomLeft") then
                            hasBottomLeft = 1;
                        elseif (flagValue == "pet") then
                            hasPetBar = 1;
                        elseif (flagValue == "bottomRight") then
                            hasBottomRight = 1;
                        end
                        yOffset = yOffset + value[flagValue];
                    end
                end
                if (hasBottomLeft and hasPetBar) then
                    yOffset = yOffset + 23;
                end
                for flag, flagValue in xOffsetFrames do
                    if (value[flagValue]) then
                        xOffset = xOffset + value[flagValue];
                    end
                end
                anchorTo = value["anchorTo"];
                point = value["point"];
                rpoint = value["rpoint"];
                if (not anchorTo) then
                    anchorTo = "UIParent";
                end
                if (not point) then
                    point = "BOTTOM";
                end
                if (not rpoint) then
                    rpoint = "BOTTOM";
                end
                if (value["isVar"]) then
                    if (value["isVar"] == "xAxis") then
                        setglobal(index, xOffset);
                    else
                        setglobal(index, yOffset);
                    end
                else
                    if ((frame == ChatFrame1 or frame == ChatFrame2) and SIMPLE_CHAT == "1") then
                        frame:SetPoint(point, anchorTo, rpoint, xOffset, yOffset);
                    elseif (not (frame:IsObjectType("frame") and frame:IsUserPlaced())) then
                        frame:SetPoint(point, anchorTo, rpoint, xOffset, yOffset);
                    end
                end
            end
        end
        if (BattlefieldMinimapTab and not BattlefieldMinimapTab:IsUserPlaced()) then
            BattlefieldMinimapTab:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMRIGHT", -225 - CONTAINER_OFFSET_X,
                BATTLEFIELD_TAB_OFFSET_Y);
        end
        if (PetActionBarFrame:IsShown()) then
            PetActionBarFrame:SetPoint("TOPLEFT", MainMenuBar, "BOTTOMLEFT", PETSimpleUI_XPOS, PETSimpleUI_YPOS);
        end
        local anchorY = 0;
        if (NUM_EXTENDED_UI_FRAMES) then
            local captureBar;
            local numCaptureBars = 0;
            for i = 1, NUM_EXTENDED_UI_FRAMES do
                captureBar = getglobal("WorldStateCaptureBar" .. i);
                if (captureBar and captureBar:IsShown()) then
                    captureBar:SetPoint("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", -CONTAINER_OFFSET_X, anchorY);
                    anchorY = anchorY - captureBar:GetHeight();
                end
            end
        end
        QuestTimerFrame:SetPoint("TOPRIGHT", "MinimapCluster", "BOTTOMRIGHT", -CONTAINER_OFFSET_X, anchorY);
        if (QuestTimerFrame:IsShown()) then
            anchorY = anchorY - QuestTimerFrame:GetHeight();
        end
        if (DurabilityFrame) then
            local durabilityOffset = 0;
            if (DurabilityShield:IsShown() or DurabilityOffWeapon:IsShown() or DurabilityRanged:IsShown()) then
                durabilityOffset = 20;
            end
            DurabilityFrame:SetPoint("TOPRIGHT", "MinimapCluster", "BOTTOMRIGHT", -CONTAINER_OFFSET_X - durabilityOffset,
                anchorY);
            if (DurabilityFrame:IsShown()) then
                anchorY = anchorY - DurabilityFrame:GetHeight();
            end
        end
        QuestWatchFrame:SetPoint("TOPRIGHT", "MinimapCluster", "BOTTOMRIGHT", -CONTAINER_OFFSET_X, anchorY);
        FCF_DockUpdate();
        updateContainerFrameAnchors();
    end
end)
