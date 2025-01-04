local DarkUI = CreateFrame("Frame")
local _G = getfenv(0)
local U = SimpleUI.Util
local u = SUI_Util

-- Code from ShaguTweaks for UI Elements

SimpleUI:AddModule("DarkUI", function()
    if SimpleUI:IsDisabled("DarkUI") then return end

    local _G = getfenv(0);
    local insert = table.insert;
    local find = string.find;
    local pairs = pairs;
    local color = { r = .3, g = .3, b = .3, a = .9 };
    local blacklist = {
        ["Solid Texture"] = true,
        ["WHITE8X8"] = true,
        ["StatusBar"] = true,
        ["BarFill"] = true,
        ["Portrait"] = true,
        ["Button"] = true,
        ["Icon"] = true,
        ["AddOns"] = true,
        ["StationeryTest"] = true,
        ["TargetDead"] = true,
        ["^KeyRing"] = true,
        ["GossipIcon"] = true,
        ["WorldMap\\(.+)\\"] = true,
        ["PetHappiness"] = true,
        ["Elite"] = true,
        ["Rare"] = true,
        ["ColorPickerWheel"] = true,
        ["ComboPoint"] = true,
        ["Skull"] = true,

        -- LFT:
        ["battlenetworking0"] = true,
        ["damage"] = true,
        ["tank"] = true,
        ["healer"] = true,
    };
    local regionSkips = {
        ["ColorPickerFrame"] = { [15] = true }
    };
    local backgrounds = {
        ["^SpellBookFrame$"] = { 325, 355, 17, -74 },
        ["^ItemTextFrame$"] = { 300, 355, 24, -74 },
        ["^QuestLogDetailScrollFrame$"] = { QuestLogDetailScrollChildFrame:GetWidth(), QuestLogDetailScrollChildFrame:GetHeight(), 0, 0 },
        ["^QuestFrame(.+)Panel$"] = { 300, 330, 24, -82 },
        ["^GossipFrameGreetingPanel$"] = { 300, 330, 24, -82 },
    };
    local borders = {
        ["ShapeshiftButton"] = 2,
        ["BuffButton"] = 2,
        ["TargetFrameBuff"] = 2,
        ["TempEnchant"] = 2,
        ["SpellButton"] = 2,
        ["SpellBookSkillLineTab"] = 2,
        ["ActionButton%d+$"] = 2,
        ["MultiBar(.+)Button%d+$"] = 2,
        ["Character(.+)Slot$"] = 2,
        ["Inspect(.+)Slot$"] = 2,
        ["ContainerFrame(.+)Item"] = 2,
        ["MainMenuBarBackpackButton$"] = 2,
        ["CharacterBag(.+)Slot$"] = 2,
        ["ChatFrame(.+)Button"] = -3,
        ["PetFrameHappiness"] = 1,
        ["MicroButton"] = { -21, 0, 0, 0 },
    };
    local addonframes = {
        ["Blizzard_TalentUI"] = { "TalentFrame" },
        ["Blizzard_AuctionUI"] = { "AuctionFrame", "AuctionDressUpFrame" },
        ["Blizzard_CraftUI"] = { "CraftFrame" },
        ["Blizzard_InspectUI"] = { "InspectPaperDollFrame", "InspectHonorFrame", "InspectFrameTab1", "InspectFrameTab2" },
        ["Blizzard_MacroUI"] = { "MacroFrame", "MacroPopupFrame" },
        ["Blizzard_RaidUI"] = { "ReadyCheckFrame" },
        ["Blizzard_TalentUI"] = { "TalentFrame" },
        ["Blizzard_TradeSkillUI"] = { "TradeSkillFrame" },
        ["Blizzard_TrainerUI"] = { "ClassTrainerFrame" },
    };

    local function IsBlacklisted(texture)
        local name = texture:GetName();
        local texture = texture:GetTexture();
        if not texture then return true end

        if name then
            for entry in pairs(blacklist) do
                if find(name, entry, 1) then return true end
            end
        end

        for entry in pairs(blacklist) do
            if find(texture, entry, 1) then return true end
        end

        return nil
    end

    local function AddSpecialBackground(frame, w, h, x, y)
        frame.Material = frame.Material or frame:CreateTexture(nil, "OVERLAY")
        frame.Material:SetTexture("Interface\\Stationery\\StationeryTest1")
        frame.Material:SetWidth(w)
        frame.Material:SetHeight(h)
        frame.Material:SetPoint("TOPLEFT", frame, x, y)
        frame.Material:SetVertexColor(.8, .8, .8)
    end

    local function DarkenFrame(frame, r, g, b, a)
        -- set defaults
        if not r and not g and not b then
            r, g, b, a = unpack(color)
        end

        -- iterate through all subframes
        if frame and frame.GetChildren then
            for _, frame in pairs({ frame:GetChildren() }) do
                DarkenFrame(frame, r, g, b, a)
            end
        end

        -- set vertex on all regions
        if frame and frame.GetRegions then
            -- read name
            local name = frame.GetName and frame:GetName()

            -- set a dark backdrop border color everywhere
            frame:SetBackdropBorderColor(unpack(color))

            -- add special backgrounds to quests and such
            for pattern, inset in pairs(backgrounds) do
                if name and find(name, pattern) then
                    AddSpecialBackground(frame, inset[1], inset[2], inset[3],
                        inset[4])
                end
            end

            -- add black borders around specified buttons
            for pattern, inset in pairs(borders) do
                if name and find(name, pattern) then
                    --AddBorder(frame, inset, module.color)
                end
            end

            -- scan through all regions (textures)
            for id, region in pairs({ frame:GetRegions() }) do
                if region.SetVertexColor and region:GetObjectType() == "Texture" then
                    if region:GetTexture() and find(region:GetTexture(), "UI%-Panel%-Button%-Up") then
                        -- monochrome buttons
                        -- region:SetDesaturated(true)
                    elseif name and id and regionSkips[name] and regionSkips[name][id] then
                        -- skip special regions
                    elseif IsBlacklisted(region) then
                        -- skip blacklisted texture names
                    else
                        region:SetVertexColor(r, g, b, a)
                    end
                end
            end
        end
    end

    DarkUI:RegisterEvent("PLAYER_ENTERING_WORLD")
    DarkUI:SetScript("OnEvent", function()
        local name
        local original
        local r
        local g
        local b
        local hookBuffButton_Update = BuffButton_Update
        function BuffButton_Update(buttonName, index, filter)
            hookBuffButton_Update(buttonName, index, filter)

            name = this:GetName()
            original = _G[name .. "Border"]
            if original then
                r, g, b = original:GetVertexColor()
                original:SetAlpha(0)
            elseif not original and _G[name] then
                --AddBorder(_G[name], 2, self.color)
            end
        end

        TOOLTIP_DEFAULT_COLOR.r = color.r
        TOOLTIP_DEFAULT_COLOR.g = color.g
        TOOLTIP_DEFAULT_COLOR.b = color.b

        TOOLTIP_DEFAULT_BACKGROUND_COLOR.r = color.r
        TOOLTIP_DEFAULT_BACKGROUND_COLOR.g = color.g
        TOOLTIP_DEFAULT_BACKGROUND_COLOR.b = color.b

        DarkenFrame(UIParent)
        DarkenFrame(WorldMapFrame)
        DarkenFrame(DropDownList1)
        DarkenFrame(DropDownList2)
        DarkenFrame(DropDownList3)

        for _, button in pairs({ MinimapZoomOut, MinimapZoomIn }) do
            for _, func in pairs({ "GetNormalTexture", "GetDisabledTexture", "GetPushedTexture" }) do
                if button[func] then
                    local tex = button[func](button)
                    if tex then
                        tex:SetVertexColor(color.r + .2, color.g + .2, color.b + .2, 1)
                    end
                end
            end
        end

        local function HookAddonOrVariable(addon, func)
            local l = CreateFrame("Frame", nil)
            l.func = func
            l:RegisterEvent("ADDON_LOADED")
            l:RegisterEvent("VARIABLES_LOADED")
            l:RegisterEvent("PLAYER_ENTERING_WORLD")
            l:SetScript("OnEvent", function()
                if IsAddOnLoaded(addon) or _G[addon] then
                    this:func()
                    this:UnregisterAllEvents()
                end
            end)
        end

        HookAddonOrVariable("Blizzard_AuctionUI", function()
            for i = 1, 15 do
                local tex = _G["AuctionFilterButton" .. i]:GetNormalTexture()
                tex:SetVertexColor(color.r, color.g, color.b, 1)
            end

            for i = 1, 8 do
                _G["BrowseButton" .. i .. "Left"]:SetVertexColor(color.r, color.g, color.b, 1)
                _G["BrowseButton" .. i .. "Right"]:SetVertexColor(color.r, color.g, color.b, 1)
            end
        end)

        for addon, data in pairs(addonframes) do
            for _, frame in pairs(data) do
                local frame = frame
                HookAddonOrVariable(frame, function()
                    DarkenFrame(_G[frame])
                end)
            end
        end

        HookAddonOrVariable("Blizzard_TimeManager", function()
            DarkenFrame(TimeManagerClockButton)
        end)

        HookAddonOrVariable("GameTooltipStatusBarBackdrop", function()
            DarkenFrame(_G["GameTooltipStatusBarBackdrop"])
        end)
    end)
end)
