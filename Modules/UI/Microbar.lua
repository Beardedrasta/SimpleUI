--[[
SimpleUI Microbar Module for WoW Vanilla 1.12 - Turtle WoW
Author: BeardedRasta
Description: Manages micro-buttons, custom icons, latency indicators, and animations.
--]]

-- Set up the environment and initialize Microbar
local Microbar = CreateFrame("Frame")
local _G = getfenv(0)
local U = SimpleUI.Util

SimpleUI:AddModule("Micromenu", function()
    if SimpleUI:IsDisabled("Micromenu") then return end

    -- Advanced Features: Latency, Animations

    function Microbar:CreateMicroEye(parent, x, y)
        LFT:SetPoint("CENTER", parent, x, y)
        local overlay = CreateFrame("Frame", nil, LFTMinimapButton:GetParent())
        overlay:SetFrameStrata("DIALOG")
        overlay:SetWidth(LFTMinimapButton:GetWidth() + 2)
        overlay:SetHeight(LFTMinimapButton:GetHeight() + 2)
        overlay:SetPoint("CENTER", LFTMinimapButton, "CENTER")
        overlay.texture = overlay:CreateTexture()
        overlay.texture:SetAllPoints()
        overlay.texture:SetTexture(SimpleUI_GetTexture("Eye"))
        overlay.texture:SetTexCoord(10 / 512, 55 / 512, 8 / 256, 55 / 256)

        local texCoords = {
            { 10 / 512,  55 / 512,  8 / 256,   55 / 256 },
            { 74 / 512,  119 / 512, 8 / 256,   55 / 256 },
            { 138 / 512, 183 / 512, 8 / 256,   55 / 256 },
            { 202 / 512, 247 / 512, 8 / 256,   55 / 256 },
            { 266 / 512, 311 / 512, 8 / 256,   55 / 256 },
            { 330 / 512, 375 / 512, 8 / 256,   55 / 256 },
            { 394 / 512, 439 / 512, 8 / 256,   55 / 256 },
            { 458 / 512, 503 / 512, 8 / 256,   55 / 256 },

            { 10 / 512,  55 / 512,  72 / 256,  119 / 256 }, --2nd row
            { 74 / 512,  119 / 512, 72 / 256,  119 / 256 },
            { 138 / 512, 183 / 512, 72 / 256,  119 / 256 },
            { 202 / 512, 247 / 512, 72 / 256,  119 / 256 },
            { 266 / 512, 311 / 512, 72 / 256,  119 / 256 },
            { 330 / 512, 375 / 512, 72 / 256,  119 / 256 },
            { 394 / 512, 439 / 512, 72 / 256,  119 / 256 },
            { 458 / 512, 503 / 512, 72 / 256,  119 / 256 },

            { 10 / 512,  55 / 512,  136 / 256, 183 / 256 }, -- 3rd row
            { 74 / 512,  119 / 512, 136 / 256, 183 / 256 },
            { 138 / 512, 183 / 512, 136 / 256, 183 / 256 },
            { 202 / 512, 247 / 512, 136 / 256, 183 / 256 },
            { 266 / 512, 311 / 512, 136 / 256, 183 / 256 },
            { 330 / 512, 375 / 512, 136 / 256, 183 / 256 },
            { 394 / 512, 439 / 512, 136 / 256, 183 / 256 },
            { 458 / 512, 503 / 512, 136 / 256, 183 / 256 },

            { 10 / 512,  55 / 512,  200 / 256, 247 / 256 }, --4th row
            { 74 / 512,  119 / 512, 200 / 256, 247 / 256 },
            { 138 / 512, 183 / 512, 200 / 256, 247 / 256 },
            { 202 / 512, 247 / 512, 200 / 256, 247 / 256 },
            { 266 / 512, 311 / 512, 200 / 256, 247 / 256 }
        }

        local currentFrame = 1
        local function UpdateTexCoords()
            local coords = texCoords[currentFrame]
            overlay.texture:SetTexCoord(unpack(coords))
            currentFrame = currentFrame + 1
            if currentFrame > table.getn(texCoords) then
                currentFrame = 1
            end
        end

        local timeSinceLastUpdate = 0
        local updateInterval = .1 -- Adjust this to change the speed of the animation
        overlay:SetScript("OnUpdate", function(self, elapsed)
            local elapsed = arg1 or 0
            timeSinceLastUpdate = timeSinceLastUpdate + elapsed
            if timeSinceLastUpdate > updateInterval then
                timeSinceLastUpdate = 0
                UpdateTexCoords()
            end
        end)

        local frame = CreateFrame("Frame")
        frame:RegisterEvent("PARTY_MEMBERS_CHANGED")

        frame:SetScript("OnEvent", function(self, event, ...)
            if GetNumPartyMembers() > 0 then
                overlay:SetScript("OnUpdate", nil)
                overlay.texture:SetTexCoord(10 / 512, 55 / 512, 8 / 256, 55 / 256)
            else
                overlay:SetScript("OnUpdate", function(self)
                    local elapsed = arg1 or 0
                    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
                    if timeSinceLastUpdate > updateInterval then
                        timeSinceLastUpdate = 0
                        UpdateTexCoords()
                    end
                end)
                UpdateTexCoords()
                LFT:Hide()
            end
        end)

        LFTMinimapButton:Hide()
        overlay.texture:Hide()

        return overlay
    end

    function Microbar:ShowEBCMinimapDropdown()
        if EBCMinimapDropdown:IsVisible() then
            EBCMinimapDropdown:Hide()
        else
            EBCMinimapDropdown:Show()
        end
    end

    -- Create Latency indicator
    function Microbar:CreateMicroEyeLatency(wow_latency_button, offset_x, offset_y)
        local latency = wow_latency_button
        latency.texture = latency:CreateTexture(nil, "BACKGROUND")
        latency:SetNormalTexture(SimpleUI_GetTexture("Latency"))
        latency:ClearAllPoints()
        latency:SetPoint("BOTTOMLEFT", Microbar.microbutton, -40, 0)
        latency:SetWidth(20)
        latency:SetHeight(15)
        latency:SetScript("OnUpdate", function(self)
            local _, _, latencyHome = GetNetStats()
            if latencyHome < 200 then
                latency:SetNormalTexture(SimpleUI_GetTexture("LatencyGreen"))
            elseif latencyHome < 300 then
                latency:SetNormalTexture(SimpleUI_GetTexture("LatencyYellow"))
            else
                latency:SetNormalTexture(SimpleUI_GetTexture("LatencyRed"))
            end
        end)

        return latency
    end

    -- Helper Functions -------------------------------------------------------------
    local buttonList = {}
    -- Function to create buttons with custom textures
    local function CreateButton(name, parent, anchor, width, height, normalTexture, pushedTexture, highlightTexture,
                                normalCoords, pushedCoords, highlightCoords, offsetX, offsetY, onEnter, onLeave, onClick)
        local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
        button:SetWidth(width)
        button:SetHeight(height)
        button:SetPoint(anchor, parent, offsetX, offsetY)
        button:SetText("")

        -- Set textures
        if normalCoords then
            button:SetNormalTexture(normalTexture)
            local NormalTexture = button:GetNormalTexture()
            NormalTexture:SetTexCoord(unpack(normalCoords))
        else
            local NormalTexture = button:CreateTexture()
            NormalTexture:SetTexture(normalTexture)
            --NormalTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            --NormalTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
            NormalTexture:SetAllPoints()
            button:SetNormalTexture(NormalTexture)
        end

        if pushedCoords then
            button:SetPushedTexture(pushedTexture)
            local PushedTexture = button:GetPushedTexture()
            PushedTexture:SetTexCoord(unpack(pushedCoords))
        else
            local PushedTexture = button:CreateTexture()
            PushedTexture:SetTexture(pushedTexture)
            PushedTexture:SetAllPoints()
            button:SetPushedTexture(PushedTexture)
        end

        if highlightCoords then
            button:SetHighlightTexture(highlightTexture)
            local HighlightTexture = button:GetHighlightTexture()
            HighlightTexture:SetTexCoord(unpack(highlightCoords))
        else
            local highlight = button:CreateTexture()
            highlight:SetTexture(highlightTexture)
            highlight:SetAllPoints()
            button:SetHighlightTexture(highlight)
        end

        button:SetScript("OnEnter", onEnter)
        button:SetScript("OnLeave", onLeave)
        button:SetScript("OnClick", onClick)
        table.insert(buttonList, button)
        return button
    end

    -- Remove Blizzard's default micro menu buttons
    function Microbar:MicroButton_Remove()
        -- Example elements to hide
        local framesToHide = {
            EBC_Minimap, LFT, MinimapShopFrame, TWMiniMapBattlefieldFrame
        }
        for _, frame in ipairs(framesToHide) do
            frame:SetParent(UIParent)
            frame:ClearAllPoints()
            frame:Hide()
        end
    end

    -- Main Microbar button frame
    Microbar.button = CreateFrame("Frame", "SimpleUIMicroButton", UIParent)
    Microbar.button:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 8)
    Microbar.button:SetHeight(30)
    Microbar.button:SetFrameStrata("MEDIUM")
    Microbar.button:Show()

    -- Data table for textures and coordinates
    Microbar.Data = {
        TexCoord = {
            default = { 0.28125, 0.688, 0.2265625, 0.765625 },
            blizz = { 0.3203125, 0.46484375, 0.73828125, 0.837890625 },
        }
    }

    -- Hide Blizzard's default micro buttons
    local buttons = {
        HelpMicroButton,
        MainMenuMicroButton,
        WorldMapMicroButton,
        SocialsMicroButton,
        QuestLogMicroButton,
        TalentMicroButton,
        SpellbookMicroButton,
        CharacterMicroButton,
    }

    for _, button in pairs(buttons) do
        button:ClearAllPoints()
        button:Hide()
    end


    Microbar:MicroButton_Remove()


    -- Custom Microbar Buttons ------------------------------------------------------------------

    -- Define custom buttons
    local microbarButtons = {
        {
            Name = "simpleHelp",
            NormalTexture = SimpleUI_GetTexture("Question"),
            NormalTextureCoord = Microbar.Data.TexCoord.default,
            PushedTexture = SimpleUI_GetTexture("QuestionPush"),
            PushedTextureCoord = Microbar.Data.TexCoord.default,
            HighlightTexture = SimpleUI_GetTexture("GlowGold"),
            HighlightTextureCoord = Microbar.Data.TexCoord.default,
            f_OnEnter = function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(HelpMicroButton.tooltipText, 1, 1, 1, 1, true)
                GameTooltip:AddLine(HelpMicroButton.newbieText, nil, nil, nil, true)
                GameTooltip:Show()
            end,
            f_OnLeave = function()
                GameTooltip:Hide()
            end,
            f_OnClick = function(self, button, down)
                ToggleHelpFrame()
            end
        },
        {
            Name = "simpleMainMenu",
            NormalTexture = SimpleUI_GetTexture("Store"),
            NormalTextureCoord = Microbar.Data.TexCoord.default,
            PushedTexture = SimpleUI_GetTexture("StorePush"),
            PushedTextureCoord = Microbar.Data.TexCoord.default,
            HighlightTexture = SimpleUI_GetTexture("GlowGold"),
            HighlightTextureCoord = Microbar.Data.TexCoord.default,
            f_OnEnter = function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(MainMenuMicroButton.tooltipText, 1, 1, 1, 1, true)
                GameTooltip:AddLine(MainMenuMicroButton.newbieText, nil, nil, nil, true)
                GameTooltip:Show()
            end,
            f_OnLeave = function()
                GameTooltip:Hide()
            end,
            f_OnClick = function(self, button, down)
                ToggleGameMenu()
            end
        },
        {
            Name = "simplePvP",
            NormalTexture = SimpleUI_GetTexture("Pvp"),
            NormalTextureCoord = Microbar.Data.TexCoord.default,
            PushedTexture = SimpleUI_GetTexture("PvpPush"),
            PushedTextureCoord = Microbar.Data.TexCoord.default,
            HighlightTexture = SimpleUI_GetTexture("GlowGold"),
            HighlightTextureCoord = Microbar.Data.TexCoord.default,
            f_OnEnter = function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("Player vs. Player", 1, 1, 1, 1, true)
                GameTooltip:AddLine("Compete against the enemy faction in the battlegrounds.", nil, nil, nil, true)
                GameTooltip:Show()
            end,
            f_OnLeave = function()
                GameTooltip:Hide()
            end,
            f_OnClick = function(self, button, down)
                if BattlefieldFrame:IsVisible() then
                    ToggleGameMenu()
                else
                    ShowTWBGQueueMenu()
                end
            end
        },
        {
            Name = "simpleShop",
            NormalTexture = SimpleUI_GetTexture("Store"),
            NormalTextureCoord = Microbar.Data.TexCoord.default,
            PushedTexture = SimpleUI_GetTexture("StorePush"),
            PushedTextureCoord = Microbar.Data.TexCoord.default,
            HighlightTexture = SimpleUI_GetTexture("GlowGold"),
            HighlightTextureCoord = Microbar.Data.TexCoord.default,
            f_OnEnter = function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("Donation Rewards", 1, 1, 1, 1, true)
                GameTooltip:AddLine("Thank you for supporting Turtle WoW.", nil, nil, nil, true)
                GameTooltip:Show()
            end,
            f_OnLeave = function()
                GameTooltip:Hide()
            end,
            f_OnClick = function(self, button, down)
                ShopFrame_Toggle()
            end
        },
        {
            Name = "simpleLFT",
            NormalTexture = SimpleUI_GetTexture("Lfg"),
            NormalTextureCoord = Microbar.Data.TexCoord.default,
            PushedTexture = SimpleUI_GetTexture("LfgPush"),
            PushedTextureCoord = Microbar.Data.TexCoord.default,
            HighlightTexture = SimpleUI_GetTexture("GlowGold"),
            HighlightTextureCoord = Microbar.Data.TexCoord.default,
            f_OnEnter = function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("Looking for Turtles", 1, 1, 1, 1, true)
                GameTooltip:AddLine("Find other players to fill your party. Running to the dungeon is required.", nil,
                    nil, nil, true)
                GameTooltip:Show()
            end,
            f_OnLeave = function()
                GameTooltip:Hide()
            end,
            f_OnClick = function(self, button, down)
                LFT_Toggle()
            end
        },
        {
            Name = "simpleEBC",
            NormalTexture = SimpleUI_GetTexture("Broadcast"),
            NormalTextureCoord = Microbar.Data.TexCoord.blizz,
            PushedTexture = SimpleUI_GetTexture("Broadcast"),
            PushedTextureCoord = Microbar.Data.TexCoord.blizz,
            HighlightTexture = SimpleUI_GetTexture("GlowGold"),
            HighlightTextureCoord = Microbar.Data.TexCoord.default,
            f_OnEnter = function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("Everlook Broadcasting Co.", 1, 1, 1, 1, true)
                GameTooltip:AddLine("Listen to some awesome tunes while you play Turtle WoW.", nil, nil, nil, true)
                GameTooltip:Show()
            end,
            f_OnLeave = function()
                GameTooltip:Hide()
            end,
            f_OnClick = function(self, button, down)
                EBCMinimapDropdown:ClearAllPoints()
                EBCMinimapDropdown:SetPoint("CENTER", tDFmicrobutton, 0, 65)
                ShowEBCMinimapDropdown()
            end
        },
        {
            Name = "simpleWorldMap",
            NormalTexture = SimpleUI_GetTexture("Map"),
            NormalTextureCoord = Microbar.Data.TexCoord.default,
            PushedTexture = SimpleUI_GetTexture("MapPush"),
            PushedTextureCoord = Microbar.Data.TexCoord.default,
            HighlightTexture = SimpleUI_GetTexture("GlowGold"),
            HighlightTextureCoord = Microbar.Data.TexCoord.default,
            f_OnEnter = function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(WorldMapMicroButton.tooltipText, 1, 1, 1, 1, true)
                GameTooltip:AddLine(WorldMapMicroButton.newbieText, nil, nil, nil, true)
                GameTooltip:Show()
            end,
            f_OnLeave = function()
                GameTooltip:Hide()
            end,
            f_OnClick = function(self, button, down)
                ToggleWorldMap()
            end
        },
        {
            Name = "simpleSocials",
            NormalTexture = SimpleUI_GetTexture("Social"),
            NormalTextureCoord = Microbar.Data.TexCoord.default,
            PushedTexture = SimpleUI_GetTexture("SocialPush"),
            PushedTextureCoord = Microbar.Data.TexCoord.default,
            HighlightTexture = SimpleUI_GetTexture("GlowGold"),
            HighlightTextureCoord = Microbar.Data.TexCoord.default,
            f_OnEnter = function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(SocialsMicroButton.tooltipText, 1, 1, 1, 1, true)
                GameTooltip:AddLine(SocialsMicroButton.newbieText, nil, nil, nil, true)
                GameTooltip:Show()
            end,
            f_OnLeave = function()
                GameTooltip:Hide()
            end,
            f_OnClick = function(self, button, down)
                ToggleFriendsFrame()
            end
        },
        {
            Name = "simpleQuestLog",
            NormalTexture = SimpleUI_GetTexture("Quest"),
            NormalTextureCoord = Microbar.Data.TexCoord.default,
            PushedTexture = SimpleUI_GetTexture("QuestPush"),
            PushedTextureCoord = Microbar.Data.TexCoord.default,
            HighlightTexture = SimpleUI_GetTexture("GlowGold"),
            HighlightTextureCoord = Microbar.Data.TexCoord.default,
            f_OnEnter = function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(QuestLogMicroButton.tooltipText, 1, 1, 1, 1, true)
                GameTooltip:AddLine(QuestLogMicroButton.newbieText, nil, nil, nil, true)
                GameTooltip:Show()
            end,
            f_OnLeave = function()
                GameTooltip:Hide()
            end,
            f_OnClick = function(self, button, down)
                ToggleQuestLog()
            end
        },
        {
            Name = "simpleTalent",
            NormalTexture = SimpleUI_GetTexture("Talent"),
            NormalTextureCoord = Microbar.Data.TexCoord.default,
            PushedTexture = SimpleUI_GetTexture("TalentPush"),
            PushedTextureCoord = Microbar.Data.TexCoord.default,
            HighlightTexture = SimpleUI_GetTexture("GlowGold"),
            HighlightTextureCoord = Microbar.Data.TexCoord.default,
            f_OnEnter = function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(TalentMicroButton.tooltipText, 1, 1, 1, 1, true)
                GameTooltip:AddLine(TalentMicroButton.newbieText, nil, nil, nil, true)
                GameTooltip:Show()
            end,
            f_OnLeave = function()
                GameTooltip:Hide()
            end,
            f_OnClick = function(self, button, down)
                ToggleTalentFrame()
            end
        },
        {
            Name = "simpleSpellBook",
            NormalTexture = SimpleUI_GetTexture("Spell"),
            NormalTextureCoord = Microbar.Data.TexCoord.default,
            PushedTexture = SimpleUI_GetTexture("SpellPush"),
            PushedTextureCoord = Microbar.Data.TexCoord.default,
            HighlightTexture = SimpleUI_GetTexture("GlowGold"),
            HighlightTextureCoord = Microbar.Data.TexCoord.default,
            f_OnEnter = function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("Spellbook & Abilities", 1, 1, 1, 1, true)
                GameTooltip:AddLine(
                    "All of your spells and abilities. To move a spell or ability to your Action Bar, open the Spellbook & Abilities window, left-click that spell or ability, and drag it down to your Action Bar.",
                    nil, nil, nil, true)
                GameTooltip:Show()
            end,
            f_OnLeave = function()
                GameTooltip:Hide()
            end,
            f_OnClick = function(self, button, down)
                ToggleSpellBook(BOOKTYPE_SPELL)
            end
        },
        {
            Name = "simpleCharacter",
            NormalTexture = SimpleUI_GetTexture("Character"),
            NormalTextureCoord = Microbar.Data.TexCoord.default,
            PushedTexture = SimpleUI_GetTexture("CharacterPush"),
            PushedTextureCoord = Microbar.Data.TexCoord.default,
            HighlightTexture = SimpleUI_GetTexture("GlowGold"),
            HighlightTextureCoord = Microbar.Data.TexCoord.default,
            f_OnEnter = function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(CharacterMicroButton.tooltipText, 1, 1, 1, 1, true)
                GameTooltip:AddLine(CharacterMicroButton.newbieText, nil, nil, nil, true)
                GameTooltip:Show()
            end,
            f_OnLeave = function()
                GameTooltip:Hide()
            end,
            f_OnClick = function(self, button, down)
                ToggleCharacter("PaperDollFrame")
            end
        },
    }

    Microbar.microbutton = CreateFrame("Frame", "SimpleUIMicroButton", UIParent)
    Microbar.microbutton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    Microbar.microbutton:SetHeight(30)
    Microbar.microbutton:SetWidth(200)
    Microbar.microbutton:SetFrameStrata("MEDIUM")
    Microbar.microbutton:Show()

    Microbar.microbutton.texture = Microbar.microbutton:CreateTexture(nil, "BACKGROUND")
    Microbar.microbutton.texture:SetPoint("BOTTOMRIGHT", Microbar.microbutton, "BOTTOMRIGHT", 0, 0)
    Microbar.microbutton.texture:SetWidth(472)
    Microbar.microbutton.texture:SetHeight(102)

    if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI then
        Microbar.microbutton.texture:SetVertexColor(0.15, 0.15, 0.15, 0.9)
    else
        Microbar.microbutton.texture:SetVertexColor(1, 1, 1, 1)
    end


    -- Create buttons on the microbar
    local spacing = 21.5
    local offset = -3
    for _, button in ipairs(microbarButtons) do
        local f = CreateButton(button.Name,
            Microbar.microbutton,
            "BOTTOMRIGHT",
            24,
            30,
            button.NormalTexture,
            button.PushedTexture,
            button.HighlightTexture,
            button.NormalTextureCoord,
            button.PushedTextureCoord,
            button.HighlightTextureCoord,
            offset,
            3,
            button.f_OnEnter,
            button.f_OnLeave,
            button.f_OnClick)
        offset = offset - spacing
    end

    function SimpleUI_Update_Microbar_Art()
        if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"].bags.art then
            Microbar.microbutton.texture:Hide()
            Microbar.microbutton.texture:SetTexture("")
        else
            Microbar.microbutton.texture:Show()
            Microbar.microbutton.texture:SetTexture(SimpleUI_GetTexture("MicroMenuArt"))
        end
    end

    function SimpleUI_Update_Microbar_Color()
        if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"].bags.color then
            for _, b in ipairs(buttonList) do
                b:GetNormalTexture():SetDesaturated(false)
            end
        else
            for _, b in ipairs(buttonList) do
                b:GetNormalTexture():SetDesaturated(true)
            end
        end
    end

    SimpleUI_Update_Microbar_Art()
    SimpleUI_Update_Microbar_Color()

    if ShaguTweaks and ShaguTweaks.HookScript then
        Microbar:CreateMicroEye(Microbar.microbutton, -140, 50)
        Microbar:CreateMicroEyeLatency(MainMenuBarPerformanceBarFrameButton, 1 - 8)
    end

    local b = ContainerFrame1PortraitButton
    b:SetNormalTexture(SimpleUI_GetTexture("BigBag"))
    b:SetPoint("TOPLEFT", ContainerFrame1, -1, 2)
    b:SetWidth(50)
    b:SetHeight(50)

    MainMenuBarBackpackButton:Hide()
    KeyRingButton:ClearAllPoints()
    KeyRingButton:Hide()

    local bTex = SimpleUI_GetTexture("BagIcon")
    local bKeyTex = "Interface\\AddOns\\SimpleUI\\Media\\Microbar\\keyslot.tga"
    local bData = {
        {
            Name = "sUIbag1",
            offset_x = -50,
            f_OnClick = function() ToggleBag(1) end
        },
        {
            Name = "sUIbag2",
            offset_x = -85,
            f_OnClick = function() ToggleBag(2) end
        },
        {
            Name = "sUIbag3",
            offset_x = -120,
            f_OnClick = function() ToggleBag(3) end
        },
        {
            Name = "sUIbag4",
            offset_x = -155,
            f_OnClick = function() ToggleBag(4) end
        },
    }

    local function b_Override(frame, parent_frame)
        frame:SetNormalTexture("")
        frame:SetPushedTexture("")
        frame:SetHighlightTexture("")
        frame:ClearAllPoints()
        frame:SetParent(parent_frame)
        frame:SetWidth(25)
        frame:SetHeight(25)
        frame:SetPoint("CENTER", parent_frame, "CENTER", -0.75, 0.75)
        frame:SetFrameLevel(parent_frame:GetFrameLevel() + 1)
    end

    local function b_MainOnClick()
        if IsShiftKeyDown() then
            ToggleBag(0)
            ToggleBag(1)
            ToggleBag(2)
            ToggleBag(3)
            ToggleBag(4)
        else
            ToggleBag(0)
        end
    end

    local function b_ShowAll()
        sUIbag1:Show()
        sUIbag2:Show()
        sUIbag3:Show()
        sUIbag4:Show()
        CharacterBag0Slot:Show()
        CharacterBag1Slot:Show()
        CharacterBag2Slot:Show()
        CharacterBag3Slot:Show()
    end

    local function b_HideAll()
        sUIbag1:Hide()
        sUIbag2:Hide()
        sUIbag3:Hide()
        sUIbag4:Hide()
        --tDFbagKeys:Hide()
        CharacterBag0Slot:Hide()
        CharacterBag1Slot:Hide()
        CharacterBag2Slot:Hide()
        CharacterBag3Slot:Hide()
    end

    local function b_Toggle()
        local tx = SimplebagArrow:GetNormalTexture()
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"].bags.hide = not SimpleUIDB.Profiles
            [SimpleUIProfile]["Entities"]["Actionbar"].bags.hide
        if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"].bags.hide == false then
            b_ShowAll()
            tx:SetTexCoord(488 / 512, 504 / 512, 38 / 128, 70 / 128)
        else
            b_HideAll()
            tx:SetTexCoord(487 / 512, 503 / 512, 2 / 128, 33 / 128)
        end
    end

    local function freeSlots()
        local free = 0
        for i = 0, 4 do
            for slot = 1, GetContainerNumSlots(i) do
                local link = GetContainerItemLink(i, slot)
                if not (link) then
                    free = free + 1
                end
            end
        end
        if this.text then
            this.text:SetText("(" .. free .. ")")
        end
    end

    local b_Main = _G["SimebagMain"] or CreateButton("SimplebagMain", UIParent, "BOTTOMRIGHT", 56, 49,
        bTex, bTex, bTex,
        nil,
        nil,
        nil,
        4.4, 26.5, nil, nil, b_MainOnClick)

    local SimplebagFreeSlots = CreateFrame("Frame", "SimplebagFreeSlots", b_Main)
    SimplebagFreeSlots:SetWidth(50)
    SimplebagFreeSlots:SetHeight(20)
    SimplebagFreeSlots:SetPoint("CENTER", b_Main, "CENTER", 0, -6)
    SimplebagFreeSlots.text = SimplebagFreeSlots:CreateFontString(nil, "OVERLAY")
    SimplebagFreeSlots.text:SetFontObject(SimpleUIFont)
    SimplebagFreeSlots.text:SetPoint("CENTER", SimplebagFreeSlots, "CENTER", 0, 0)
    SimplebagFreeSlots.text:SetVertexColor(1, 1, 1)
    SimplebagFreeSlots:RegisterEvent("PLAYER_ENTERING_WORLD")
    SimplebagFreeSlots:RegisterEvent("BAG_UPDATE")
    SimplebagFreeSlots:SetScript("OnEvent", freeSlots)

    for i, button in ipairs(bData) do
        local frame = _G[button.Name] or CreateButton(button.Name, b_Main, "CENTER", 45, 45,
            bTex, bTex, bTex,
            nil, nil, nil,
            button.offset_x, 0, nil, nil, button.f_OnClick)

        frame:SetFrameStrata("LOW")
        --frame:SetFrameLevel(3)

        b_Override(_G["CharacterBag" .. (i - 1) .. "Slot"], frame)
    end

    local bags_arrow = _G["SimplebagArrow"] or CreateButton("SimplebagArrow", b_Main, "CENTER", 10, 15,
        SimpleUI_GetTexture("BagSlot"), SimpleUI_GetTexture("BagSlot"),
        SimpleUI_GetTexture("BagSlot"),
        { 488 / 512, 504 / 512, 38 / 128, 70 / 128 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        -28, 0, nil, nil, b_Toggle)

    local timeSinceLastUpdate = 0
    local login = CreateFrame("Frame")
    login:RegisterEvent("PLAYER_ENTERING_WORLD")
    login:SetScript("OnEvent", function()
        local tx = bags_arrow:GetNormalTexture()
        if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"].bags.hide then
            b_HideAll()
            tx:SetTexCoord(487 / 512, 503 / 512, 2 / 128, 33 / 128)
        else
            b_ShowAll()
            tx:SetTexCoord(488 / 512, 504 / 512, 38 / 128, 70 / 128)
        end
        if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI then
            SimplebagMain:GetNormalTexture():SetVertexColor(0.3, 0.3, 0.3, 0.9)
            sUIbag1:GetNormalTexture():SetVertexColor(0.15, 0.15, 0.15, 0.9)
            sUIbag2:GetNormalTexture():SetVertexColor(0.15, 0.15, 0.15, 0.9)
            sUIbag3:GetNormalTexture():SetVertexColor(0.15, 0.15, 0.15, 0.9)
            sUIbag4:GetNormalTexture():SetVertexColor(0.15, 0.15, 0.15, 0.9)
        else
            SimplebagMain:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
            sUIbag1:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
            sUIbag2:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
            sUIbag3:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
            sUIbag4:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
        end
    end)
    login:SetScript("OnUpdate", function()
        timeSinceLastUpdate = timeSinceLastUpdate + arg1
        if timeSinceLastUpdate < 1 then
            return
        end
        timeSinceLastUpdate = 0
        this:SetScript("OnUpdate", nil)

        freeSlots()

        local tx = bags_arrow:GetNormalTexture()
        if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"].bags.hide then
            b_HideAll()
            tx:SetTexCoord(487 / 512, 503 / 512, 2 / 128, 33 / 128)
        else
            b_ShowAll()
            tx:SetTexCoord(488 / 512, 504 / 512, 38 / 128, 70 / 128)
        end
        for bag = 0, 4 do
            -- Get the number of slots in the bag
            local size = GetContainerNumSlots(bag)
            -- Iterate through each slot in the bag
            for slot = 1, size do
                -- Get the frame for the bag slot
                local frame = getglobal("ContainerFrame" .. bag + 1 .. "Item" .. slot)
                if frame then
                    -- Create a texture for the frame
                    local texture = frame:CreateTexture(nil, "BACKGROUND")
                    -- Set the texture to your custom image
                    texture:SetTexture(SimpleUI_GetTexture("BagBg"))
                    -- Set the size of the texture to match the size of the frame
                    texture:SetWidth(frame:GetWidth())
                    texture:SetHeight(frame:GetHeight())
                    -- Position the texture to cover the entire frame
                    texture:SetAllPoints(frame)
                end
            end
        end
    end)
end)
