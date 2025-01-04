local MM = CreateFrame("Frame")
local U = SimpleUI.Util

SimpleUI:AddModule("Minimap", function()
    if SimpleUI:IsDisabled("Minimap") then return end

    local select = select;
    local pairs = pairs;
    local ipairs = ipairs;
    local UnitName = UnitName;
    local UnitClass = UnitClass;
    local find = string.find;
    local len = string.len;
    local sub = string.sub;
    local ceil = math.ceil;
    local floor = math.floor;
    local tinsert = table.insert;
    local _G = getfenv(0)

    local LockButton
    local UnlockButton
    local CheckVisibility
    local GrabMinimapButtons
    local SkinMinimapButtons
    local UpdateLayout

    local UIFrameFlash = UIFrameFlash
    local ToggleCharacter = ToggleCharacter
    local ToggleFriendsFrame = ToggleFriendsFrame
    local ToggleHelpFrame = ToggleHelpFrame
    local ToggleFrame = ToggleFrame

    local PLAYER_ENTERING_WORLD, Minimap_GrabButtons

    MM.map = CreateFrame("Frame", "SimpleUI_minimap", UIParent)
    MM.map:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
    MM.map:SetWidth(Minimap:GetWidth())
    MM.map:SetHeight(Minimap:GetHeight())

    MM.MinimapButtonBar = CreateFrame("Button", "SimpleUI_MMB", Minimap)
    MM.MinimapButtonBar:EnableMouse(true)
    MM.MinimapButtonBar:RegisterForClicks("LeftButtonDown", "RightButtonDown")
    MM.MinimapButtonBar:SetWidth(33)
    MM.MinimapButtonBar:SetHeight(33)
    MM.MinimapButtonBar:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)

    MM.Buttons = {};
    MM.Exclude = {};
    MM.DefaultOptions = {
        ["ButtonPos"] = { 0, 0 },
        ["AttachToMinimap"] = 1,
        ["CollapseTimeout"] = 1,
        ["ExpandDirection"] = 1,
        ["MaxButtonsPerLine"] = 5,
        ["AltExpandDirection"] = 4,
        ["Scale"] = 100,
    }

    MM.Include = {
        [1] = "DPSMate_MiniMap"
    }

    TW_Include = {};

    if TWMinimapShopFrame ~= nil then
        TWMinimapShopFrame:ClearAllPoints()
        TWMinimapShopFrame:SetParent(Minimap)
        TWMinimapShopFrame:SetPoint("LEFT", Minimap, "RIGHT", -1, -1)
        table.insert(TW_Include, "Turtle WoW Shop");
    end

    if (TWMiniMapBattlefieldFrame ~= nil) then
        TWMiniMapBattlefieldFrame:ClearAllPoints()
        TWMiniMapBattlefieldFrame:SetParent(Minimap)
        TWMiniMapBattlefieldFrame:SetPoint("LEFT", Minimap, "RIGHT", -1, -1)
        table.insert(TW_Include, "Turtle WoW Battleground Finder");
    end
    if (LFT_Minimap ~= nil) then
        LFT_Minimap:ClearAllPoints()
        LFT_Minimap:SetParent(Minimap)
        LFT_Minimap:SetPoint("LEFT", Minimap, "RIGHT", -1, -1)
        table.insert(TW_Include, "LookingForTurtles");
    end

    MM.Ignore = {
        [1] = "MiniMapTrackingFrame",
        [2] = "MiniMapMeetingStoneFrame",
        [3] = "MiniMapMailFrame",
        [4] = "MiniMapBattlefieldFrame",
        [5] = "MiniMapPing",
        [6] = "MinimapBackdrop",
        [7] = "MinimapZoomIn",
        [8] = "MinimapZoomOut",
        [9] = "BookOfTracksFrame",
        [10] = "GatherNote",
        [11] = "FishingExtravaganzaMini",
        [12] = "MiniNotePOI",
        [13] = "RecipeRadarMinimapIcon",
        [14] = "FWGMinimapPOI",
        [15] = "SimpleUI_MMB",
        [16] = "QuestieNote",
        [17] = "MetaMap",
        [18] = "LootLinkMinimapButton",
        [19] = "TimeManagerClockButton",
        [20] = "pfMiniMapPin",
        [21] = "Clock",
        [22] = "Timer"
    }

    MM.IgnoreSize = {
        [1] = "AM_MinimapButton",
        [2] = "STC_HealthstoneButton",
        [3] = "STC_ShardButton",
        [4] = "STC_SoulstoneButton",
        [5] = "STC_SpellstoneButton",
        [6] = "STC_FirestoneButton",
        [7] = "TurtleCount",
    }

    MM.ExtraSize = {
        ["GathererMinimapButton"] = function()
            GathererMinimapButton.mask:SetHeight(31);
            GathererMinimapButton.mask:SetWidth(31);
        end,
        ["WIM_IconFrame"] = function()
            WIM_IconFrameButton:SetScale(1);
        end,
        ["MonkeyBuddyIconButton"] = function()
            MonkeyBuddyIconButton:SetHeight(33);
            MonkeyBuddyIconButton:SetWidth(33);
        end,
        ["DPSMate_MiniMap"] = function()
            DPSMate_MiniMap:SetScale(MM.DefaultOptions.Scale / 100);
        end,
        ["AtlasLootMinimapButton"] = function()
            AtlasLootMinimapButton:SetWidth(28)
            AtlasLootMinimapButton:SetHeight(28)
        end,
        ["LibDBIcon10_VoiceOver"] = function()
            LibDBIcon10_VoiceOver:SetWidth(28)
            LibDBIcon10_VoiceOver:SetHeight(28)
        end,
        ["FuBarPluginTourGuideFrameMinimapButton"] = function()
            FuBarPluginTourGuideFrameMinimapButton:SetWidth(28)
            FuBarPluginTourGuideFrameMinimapButton:SetHeight(28)
        end,

    }

    MM.CallBack = {
        ["RecipeRadarMinimapButton"] = function()
            RecipeRadar_MinimapButton_UpdatePosition();
        end
    }

    local rescanned = false;
    local starttime = GetTime();

    function MM.TestFrame(name)
        local hasClick = false;
        local hasMouseUp = false;
        local hasMouseDown = false;
        local hasEnter = false;
        local hasLeave = false;
        local frame = getglobal(name)

        if frame then
            if (frame:HasScript("OnClick")) then
                local test = frame:GetScript("OnClick");
                if (test) then
                    hasClick = true;
                end
            end
            if (frame:HasScript("OnMouseUp")) then
                local test = frame:GetScript("OnMouseUp");
                if (test) then
                    hasMouseUp = true;
                end
            end
            if (frame:HasScript("OnMouseDown")) then
                local test = frame:GetScript("OnMouseDown");
                if (test) then
                    hasMouseDown = true;
                end
            end
            if (frame:HasScript("OnEnter")) then
                local test = frame:GetScript("OnEnter");
                if (test) then
                    hasEnter = true;
                end
            end
            if (frame:HasScript("OnLeave")) then
                local test = frame:GetScript("OnLeave");
                if (test) then
                    hasLeave = true;
                end
            end
        end
        return hasClick, hasMouseUp, hasMouseDown, hasEnter, hasLeave;
    end

    function MM.GatherIcons()
        local children = { Minimap:GetChildren() };
        local additional = { MinimapBackdrop:GetChildren() };
        for _, child in ipairs(additional) do
            tinsert(children, child);
        end
        for _, child in ipairs(MM.Include) do
            local frame = getglobal(child);
            if frame then
                tinsert(children, frame);
            end
        end
        for _, child in ipairs(children) do
            if child:GetName() then
                local ignore = false;
                for _, needle in ipairs(MM.Ignore) do
                    if find(child:GetName(), needle) then
                        ignore = true;
                    end
                end
                for i, needle in ipairs(MM.Ignore) do
                    if find(child:GetName(), "TWMiniMapBattlefieldFrame") then
                        ignore = false;
                    end
                end
                if not ignore then
                    if not child:HasScript("OnClick") then
                        for _, subchild in ipairs({ child:GetChildren() }) do
                            if subchild:HasScript("OnClick") then
                                child = subchild;
                                break;
                            end
                        end
                    end
                    local hasClick, hasMouseUp, hasMouseDown, _, _ = MM.TestFrame(child:GetName());

                    if hasClick or hasMouseUp or hasMouseDown then
                        local name = child:GetName();

                        MM.PrepareButton(name);
                        if not MM.IsExcluded(name) then
                            MM.AddButton(name);
                        end
                    end
                end
            end
        end
        MM.SetPositions();
    end

    function MM.PrepareButton(name)
        local frame = getglobal(name);
        if frame then
            if frame.RegisterForClicks then
                frame:RegisterForClicks("LeftButtonDown", "RightButtonDown");
            end
            if not MM.IsInArray(MM.IgnoreSize, name) then
                frame:SetScale(MM.DefaultOptions.Scale * (1 / Minimap:GetEffectiveScale()) / 100);
            end
            frame.isvisible = frame:IsVisible();
            frame.oshow = frame.Show;
            frame.Show = function(frame)
                frame.isvisible = true;
                if not MM.IsExcluded(frame:GetName()) then
                    MM.SetPositions();
                end
                if MM.IsExcluded(frame:GetName() or (MM.Buttons[1] and MM.Buttons[1] ~= frame:GetName() and getglobal(MM.Buttons[1]:IsVisible()))) then
                    frame.oshow(frame);
                end
            end
            frame.ohide = frame.Hide;
            frame.Hide = function(frame)
                frame.isvisible = false;
                frame.ohide(frame);
                if (not MM.IsExcluded(frame:GetName())) then
                    MM.SetPositions();
                end
            end

            if (frame:HasScript("OnClick")) then
                frame.oclick = frame:GetScript("OnClick");
                frame:SetScript("OnClick", function()
                    if (arg1 and arg1 == "RightButton" and IsControlKeyDown()) then
                        local name = this:GetName();
                        if (MM.IsExcluded(name)) then
                            MM.AddButton(name);
                        else
                            MM.RestoreButton(name);
                        end
                        MM.SetPositions();
                    elseif (this.oclick) then
                        this.oclick();
                    end
                end);
            elseif (frame:HasScript("OnMouseUp")) then
                frame.omouseup = frame:GetScript("OnMouseUp");
                frame:SetScript("OnMouseUp", function()
                    if (arg1 and arg1 == "RightButton" and IsControlKeyDown()) then
                        local name = this:GetName();
                        if (MM.IsExcluded(name)) then
                            MM.AddButton(name);
                        else
                            MM.RestoreButton(name);
                        end
                        MM.SetPositions();
                    elseif (this.omouseup) then
                        this.omouseup();
                    end
                end);
            elseif (frame:HasScript("OnMouseDown")) then
                frame.omousedown = frame:GetScript("OnMouseDown");
                frame:SetScript("OnMouseDown", function()
                    if (arg1 and arg1 == "RightButton" and IsControlKeyDown()) then
                        local name = this:GetName();
                        if (MM.IsExcluded(name)) then
                            MM.AddButton(name);
                        else
                            MM.RestoreButton(name);
                        end
                        MM.SetPositions();
                    elseif (this.omousedown) then
                        this.omousedown();
                    end
                end);
            end
            if (frame:HasScript("OnEnter")) then
                frame.oenter = frame:GetScript("OnEnter");
                frame:SetScript("OnEnter", function()
                    if (not MM.IsExcluded(this:GetName())) then
                        MM.ShowTimeout = -1;
                    end
                    if (this.oenter) then
                        this.oenter();
                    end
                end);
            end
            if (frame:HasScript("OnLeave")) then
                frame.oleave = frame:GetScript("OnLeave");
                frame:SetScript("OnLeave", function()
                    if (not MM.IsExcluded(this:GetName())) then
                        MM.ShowTimeout = 0;
                    end
                    if (this.oleave) then
                        this.oleave();
                    end
                end);
            end
            if MM.CallBack[name] then
                local func = MM.CallBack[name];
                func();
            end
        end
    end

    function MM.AddButton(name)
        local show = false;
        local child = getglobal(name);
        if not child then return end
        if MM.Buttons[1] and MM.Buttons[1] ~= name and getglobal(MM.Buttons[1]):IsVisible() then
            show = true;
        end
        child.opoint = { child:GetPoint() };
        if not child.opoint[1] then
            child.opoint = { "TOP", Minimap, "BOTTOM", 0, 0 }
        end
        child.osize = { child:GetHeight(), child:GetWidth() };
        child.oclearallpoints = child.ClearAllPoints;
        child.ClearAllPoints = function() end;
        child.osetpoint = child.SetPoint;
        child.SetPoint = function() end;
        if not show then
            child.ohide(child);
        end
        tinsert(MM.Buttons, name)
        local i = MM.IsInArray(MM.Exclude, name)
        if i then
            tinsert(MM.Exclude, i);
        end
    end

    function MM.IsExcluded(name)
        for _, needle in ipairs(MM.Exclude) do
            if needle == name then
                return true;
            end
        end
        return false;
    end

    function MM.RestoreButton(name)
        local button = getglobal(name)
        button.oclearallpoints(button);
        button.osetpoint(button, button.opoint[1], button.opoint[2], button.opoint[3], button.opoint[4], button.opoint
            [5]);
        button:SetHeight(button.osize[1])
        button:SetWidth(button.osize[1])
        button.ClearAllPoints = button.oclearallpoints;
        button.SetPoint = button.osetpoint;
        if button.isvisible then
            button.oshow(button);
        else
            button.ohide(button);
        end

        tinsert(MM.Exclude, name)
        local i = MM.IsInArray(MM.Buttons, button:GetName());
        if i then
            tinsert(MM.Buttons, i);
        end
    end

    local function ResizeButton(frame)
        frame:SetHeight(31);
        frame:SetWidth(31);
        --frame:SetScale(MM.DefaultOptions.Scale * (Minimap:GetEffectiveScale()) / 100)
    end

    function MM.SetPositions()
        local directions = {
            [1] = { "RIGHT", "LEFT" },
            [2] = { "BOTTOM", "TOP" },
            [3] = { "LEFT", "RIGHT" },
            [4] = { "TOP", "BOTTOM" }
        }
        local offsets = {
            [1] = { "RIGHT", "LEFT" },
            [2] = { "BOTTOM", "TOP" },
            [3] = { "LEFT", "RIGHT" },
            [4] = { "TOP", "BOTTOM" }
        }
        local cols = {};
        local parentId = 0;
        local count = 0;
        for i, name in ipairs(MM.Buttons) do
            local frame = getglobal(name);
            if frame.isvisible then
                count = count + 1;
                local mp1 = MM.DefaultOptions["MaxButtonsPerLine"]
                if MM.DefaultOptions["MaxButtonsPerLine"] == 0 then
                    mp1 = 100
                end
                local row = floor(count / mp1)
                local col = count - row * mp1
                local parent;

                local dirchild, dirparent = directions[MM.DefaultOptions.ExpandDirection][1],
                    directions[MM.DefaultOptions.ExpandDirection][2];
                if count == 1 then
                    -- Special case for the first button
                    frame.oclearallpoints(frame);
                    frame.osetpoint(frame, "CENTER", MM.MinimapButtonBar, "CENTER", 8, -3);
                    parentId = i; -- Set the parent ID for subsequent buttons
                    cols[row] = i;
                else
                    if parentId == 0 then
                        parent = MM.MinimapButtonBar;
                        cols[row] = i;
                    else
                        parent = getglobal(MM.Buttons[parentId]);
                    end

                    if col == 1 and parentId ~= 0 then
                        cols[row] = i;
                        parent = getglobal(MM.Buttons[cols[row - 1]]);
                        dirchild, dirparent = offsets[MM.DefaultOptions.AltExpandDirection][1],
                            offsets[MM.DefaultOptions.AltExpandDirection][2];
                    end

                    if not MM.IsInArray(MM.IgnoreSize, name) then
                        if MM.ExtraSize[name] then
                            local func = MM.ExtraSize[name];
                            func();
                        else
                            ResizeButton(frame);
                        end
                    end

                    frame.oclearallpoints(frame);
                    frame.osetpoint(frame, dirchild, parent, dirparent, 0, 0);
                    parentId = i;
                end
            end
        end
    end

    local function getTableLength(tbl)
        local count = 0
        for _ in pairs(tbl) do
            count = count + 1
        end
        return count
    end


    function SkinMinimapButton(button)
        if not button then
            return
        end

        local name = button:GetName()
        if not name then
            return
        end
        if button:IsObjectType("Button") then
            button:SetPushedTexture(nil)
            button:SetHighlightTexture(nil)
            button:SetDisabledTexture(nil)
        end

        local regions = { button:GetRegions() }
        for i, region in ipairs(regions) do
            if region and region:GetObjectType() == "Texture" then
                local texture = region:GetTexture()
                if texture and (find(texture, "Border") or find(texture, "Background") or find(texture, "AlphaMask")) then
                    region:SetTexture(nil)
                else
                    if name == "BagSync_MinimapButton" then
                        region:SetTexture("Interface\\AddOns\\BagSync\\media\\icon")
                    elseif name == "AtlasLootMinimapButton" then
                        region:SetTexture("")
                        button.newTex = button:CreateTexture(nil, "OVERLAY")
                        button.newTex:SetPoint("CENTER", button, "CENTER", 0, 0)
                        button.newTex:SetVertexColor(1, 1, 1, 1)
                        button.newTex:SetTexture("Interface\\ICONS\\INV_Box_01")
                        local cropAmount = 0.1 -- Adjust this value to control the zoom
                        button.newTex:SetTexCoord(
                            cropAmount,        -- Left crop
                            1 - cropAmount,    -- Right crop
                            cropAmount,        -- Top crop
                            1 - cropAmount     -- Bottom crop
                        )
                        button.newTex:SetWidth(23)
                        button.newTex:SetHeight(23)
                    elseif name == "DBMMinimapButton" then
                        region:SetTexture("Interface\\Icons\\INV_Helmet_87")
                    elseif name == "OutfitterMinimapButton" then
                        if region:GetTexture() == "Interface\\Addons\\Outfitter\\Textures\\MinimapButton" then
                            region:SetTexture(nil)
                        end
                    elseif name == "SmartBuff_MiniMapButton" then
                        region:SetTexture("Interface\\Icons\\Spell_Nature_Purge")
                    elseif name == "VendomaticButtonFrame" then
                        region:SetTexture("Interface\\Icons\\INV_Misc_Rabbit_2")
                    elseif name == "MiniMapTracking" then
                        for m = 1, MiniMapTrackingButton:GetNumRegions() do
                            local trackRegion = select(m, MiniMapTrackingButton:GetRegions())
                            if trackRegion:GetObjectType() == "Texture" then
                                local trackTexture = trackRegion:GetTexture()
                                if trackTexture and (find(trackTexture, "Border") or find(trackTexture, "Background") or find(trackTexture, "AlphaMask")) then
                                    trackRegion:SetTexture(nil)
                                end
                            end
                        end
                    end

                    --region.SetPoint = MM._noop
                end
            end
        end
        button.Bg = button:GetParent():CreateTexture(nil, "BACKGROUND")
        button.Bg:SetTexture("Interface\\AddOns\\SimpleUI\\Media\\Textures\\background-light.tga")
        button.Border = CreateFrame("Frame", nil, button)
        button.Border:SetBackdrop({
            edgeFile = SimpleUI_GetTexture("ThickBorder"),
            edgeSize = 14,
        })
        if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI then
            button.Bg:SetVertexColor(0.3, 0.3, 0.3, 0.9)
            button.Border:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.9)
        else
            button.Bg:SetVertexColor(1, 1, 1, 1)
            button.Border:SetBackdropBorderColor(1, 1, 1, 1)
        end
        if name == "FuBarPluginTourGuideFrameMinimapButton" or name == "AtlasLootMinimapButton" then
            button.Bg:ClearAllPoints()
            button.Bg:SetPoint("TOPLEFT", button, "TOPLEFT", 2.5, -2.5)
            button.Bg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2.5, 2.5)
            button.Border:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 5)
            button.Border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -5)
        else
            button.Bg:ClearAllPoints()
            button.Bg:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
            button.Bg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
            button.Border:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
            button.Border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -4)
        end
    end

    function MM.OnLoad(arg1)
        for i, name in ipairs(MM.Buttons) do
            local frame = getglobal(name);
            if frame.isvisible then
                frame.oshow(frame);
            end
        end
    end

    function MM.OnUpdate(elapsed)
        if not rescanned and (GetTime() - starttime) > 5 then
            rescanned = true;
            MM.GatherIcons();
            MM.SetButtonPosition();
            for i, name in ipairs(MM.Buttons) do
                local frame = getglobal(name);
                if frame.isvisible then
                    frame.oshow(frame);
                    SkinMinimapButton(frame)
                end
            end
            for _, child in ipairs({ MM.MinimapButtonBar:GetChildren() }) do
                if child then
                    SkinMinimapButton(child)
                end
            end
            return;
        end
    end

    function MM.ResetPosition()
        MM.DefaultOptions.ButtonPos[1] = MM.DefaultOptions.ButtonPos[1]
        MM.DefaultOptions.ButtonPos[2] = MM.DefaultOptions.ButtonPos[2]
        MM.DefaultOptions.AttachToMinimap = MM.DefaultOptions.AttachToMinimap;
        MM.SetButtonPosition();
    end

    function MM.SetButtonPosition()
        if not MM.DefaultOptions then
            return
        end
        MM.MinimapButtonBar:SetScale((MM.DefaultOptions.Scale or 100) * (1 / Minimap:GetEffectiveScale()) / 100);
        if MM.DefaultOptions.AttachToMinimap == 1 then
            MM.MinimapButtonBar:ClearAllPoints();
            MM.MinimapButtonBar:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", MM.DefaultOptions.ButtonPos[1],
                MM.DefaultOptions.ButtonPos
                [2])
        else
            MM.MinimapButtonBar:ClearAllPoints();
            MM.MinimapButtonBar:SetPoint("BOTTOMRIGHT", Minimap, "TOPRIGHT", MM.DefaultOptions.ButtonPos[1],
                MM.DefaultOptions.ButtonPos[2]);
        end
    end

    function MM.IsInArray(array, needle)
        if type(array) == "table" then
            for i, element in pairs(array) do
                if type(element) == type(needle) and element == needle then
                    return i;
                end
            end
        end
        return nil;
    end

    do
        local menuFrame


        -- handles mouse wheel action on minimap
        local function Minimap_OnMouseWheel()
            local delta = arg1 -- Use the global 'arg1' to get the mouse wheel delta
            local zoomLevel = Minimap:GetZoom()

            if not zoomLevel then
                zoomLevel = 0 -- Default to 0 if GetZoom returns nil
            end

            if delta > 0 and zoomLevel < 5 then
                Minimap:SetZoom(zoomLevel + 1)
            elseif delta < 0 and zoomLevel > 0 then
                Minimap:SetZoom(zoomLevel - 1)
            end
        end


        -- called once the user enter the world
        function PLAYER_ENTERING_WORLD()

            MinimapBorderTop:Hide()
            MinimapZoomIn:Hide()
            MinimapZoomOut:Hide()
            GameTimeFrame:Hide()
            MinimapZoneTextButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -5, -10)
            MinimapZoneTextButton:SetFrameLevel(Minimap:GetFrameLevel() + 2)
            MinimapZoneText:SetPoint("TOPLEFT", "MinimapZoneTextButton", "TOPLEFT", 8, 5)
            Minimap:EnableMouseWheel(true)

            Minimap:SetScript("OnMouseWheel", Minimap_OnMouseWheel)

            -- Make it square
            MinimapBorder:SetTexture(nil)
            Minimap:SetFrameLevel(2)
            Minimap:SetFrameStrata("BACKGROUND")
            Minimap:SetMaskTexture([[Interface\ChatFrame\ChatFrameBackground]])
            Minimap:SetPoint("CENTER", MinimapCluster, "TOP", 9, -98)
            Minimap:SetBackdropColor(0, 0, 0, 1)
            MinimapCluster:SetScale(1.3)

            local textureParent = CreateFrame("Frame", nil, Minimap)
            textureParent:SetFrameLevel(Minimap:GetFrameLevel() + 1)
            textureParent:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -8, 8)
            textureParent:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 8, -8)
            Minimap.TextureParent = textureParent

            local border = textureParent:CreateTexture(nil, "BORDER")
            border:SetPoint("CENTER", textureParent, "CENTER", 0, 0)
            border:SetTexture("Interface\\AddOns\\SimpleUI\\Media\\Textures\\minimap-square-100.tga")
            border:SetWidth(Minimap:GetWidth() + 10)
            border:SetHeight(Minimap:GetHeight() + 10)
            Minimap.Border = border

            local background = Minimap:CreateTexture(nil, "BACKGROUND")
            background:SetAllPoints(Minimap)
            background:SetTexture("Interface\\AddOns\\SimpleUI\\Media\\Textures\\background-light.tga")
            Minimap.Background = background

            if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI then
                border:SetVertexColor(0.2, 0.2, 0.2, 0.9)
            else
                border:SetVertexColor(1, 1, 1, 1)
            end
        end

        local pinger
        local timer
        local frame = CreateFrame("Frame")
        local player = UnitName("player")
        MM:RegisterEvent("ADDON_LOADED")
        MM:RegisterEvent("PLAYER_ENTERING_WORLD")
        MM:RegisterEvent("MINIMAP_PING")
        MM:SetScript("OnEvent", function(event)
            if event == "ADDON_LOADED" and arg1 == "SimpleUI" then
                MM.SetButtonPosition();
            elseif event == "PLAYER_ENTERING_WORLD" then
                PLAYER_ENTERING_WORLD()
            elseif event == "MINIMAP_PING" then
                if UnitName(arg1) ~= player then
                    if not pinger then
                        pinger = frame:CreateFontString(nil, "OVERLAY")
                        pinger:SetFont("Fonts\\FRIZQT__.ttf", 13, "OUTLINE")
                        pinger:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
                        pinger:SetJustifyH("CENTER")
                    end

                    if not timer or (timer and time() - timer > 1) then
                        local unitName = UnitName(arg1)
                        if unitName then
                            local classColor = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[select(2, UnitClass(arg1))])
                                or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[select(2, UnitClass(arg1))])
                                or { r = 1, g = 1, b = 1 } -- default to white if class color is not available

                            -- Format and display the ping text with class color
                            pinger:SetText(format("|cffff0000*|r %s |cffff0000*|r", unitName))
                            pinger:SetTextColor(classColor.r, classColor.g, classColor.b)

                            -- Flash the pinger text for visibility
                            UIFrameFlash(pinger, 0.2, 2.8, 5, false, 0, 5)

                            -- Update timer to prevent frequent pings
                            timer = time()
                        end
                    end
                end
            end
        end)
        MM.MinimapButtonBar:SetScript("OnUpdate", function()
            MM.OnUpdate(arg1)
        end)
        PLAYER_ENTERING_WORLD()
    end
end)
