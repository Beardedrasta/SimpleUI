-- ##############################
-- ## SimpleUI Configuration UI ##
-- ##############################

SimpleUIConfig = nil    -- Main config frame reference
SimpleUIEditFrames = {} -- Holds all edit frames (profile, actionbar, micromenu)
local grid


-- ########################################
-- ## Main Config Window Toggle Function ##
-- ########################################
function SimpleUI_Config_Window_Toggle()
    if not SimpleUIConfig then
        SimpleUI_Config_CreateWindow()
    else
        local handle = SimpleUIConfig.Handle
        if handle:IsShown() then
            handle:Hide()
        else
            if not SimpleUIConfig.Open == nil then
                SimpleUIConfig.Open.texture:SetTexture(0.102, 0.624, 0.753, 0.6)
                SimpleUIConfig.Open = nil
            end
            SimpleUIConfig.Handle:Show()
        end
    end
end

-- ##############################
-- ## Window Initialization ##
-- ##############################
function SimpleUI_Config_CreateWindow()
    SimpleUI_Config_MainFrame_Create()
    SimpleUI_Config_EditProfile_Create()
    if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Actionbar then
        SimpleUI_Config_EditActionbar_Create()
    end
    if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Micromenu then
        SimpleUI_Config_EditMicromenu_Create()
    end
    if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Unitframes then
        SimpleUI_Config_EditUnitFrame_Create()
        SimpleUIEditFrames["Unitframes"].ChildHandle.General:Show()
        SimpleUIConfig.Tab = SimpleUIEditFrames["Unitframes"].ChildHandle.General
        SimpleUIConfig.Tab.texture:SetTexture(0.5, 0.5, 0.5, 1)
    end
    if not SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.PallyPower then
        SimpleUI_Config_EditPallyPower_Create()
    end
    SimpleUI_Config_EditModules_Create()

    local button = CreateFrame("Button", nil, SimpleUIConfig.Handle)
    button:SetPoint("TOPLEFT", SimpleUIConfig.selectionBG, "TOPLEFT", 7, -18 * SimpleUIConfig.btnMade - 7)
    button:SetWidth(98)
    button:SetHeight(15)

    local texture = button:CreateTexture(nil, "OVERLAY")
    texture:SetTexture(0.50, 0.50, 0.80, 0.9)
    texture:SetAlpha(0.6)
    texture:SetAllPoints(button)

    local txt = button:CreateFontString(nil, "OVERLAY")
    txt:SetFont(SimpleUIFonts["SimpleUI"], 12)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText("Show Grid")
    txt:SetPoint("LEFT", button, "LEFT", 1, 0)

    button:SetScript("OnClick", function()
        local isShown = grid:IsShown()
        SimpleUI_ToggleCastbarOverlay(isShown)
        if isShown then
            grid:Hide()
            txt:SetText("Show Grid")
        else
            grid:Show()
            txt:SetText("Hide Grid")
        end
    end)
    button:SetScript("OnEnter", function()
        texture:SetAlpha(0.9)
    end)
    button:SetScript("OnLeave", function()
        texture:SetAlpha(0.6)
    end)

    SimpleUIConfig.btnMade = SimpleUIConfig.btnMade + 1

    SimpleUIEditFrames["Profile"].Handle:Show()
    SimpleUIConfig.Open = SimpleUIEditFrames["Profile"].Handle
    SimpleUIConfig.Open.texture:SetTexture(0.102, 0.624, 0.753, 1)
end

local Config = {
    TitleFont = SimpleUIFonts["SimpleUI"],
    NormalFont = SimpleUIFonts["SimpleUISmall"],
    NormSize = 12,
    TitleBarHeight = 14,
    BorderTexture = SimpleUI_GetTexture("ThickBorder"),
    BackgroundTexture = SimpleUI_GetTexture("RockBg"),
    StatusbarTexture = SimpleUI_GetTexture("StatusbarDefault"),
    Colors = {
        Gold = { 1, 0.843, 0, 1 },
        Teal = { 0.102, 0.624, 0.753, 0.6 },
        Background = { 0.1, 0.1, 0.1, 0.8 },
    },
}

-- ########################################
-- ## Helper: General Frame Creation ##
-- ########################################
local function SimpleUI_CreateFrame(name, parent, width, height, point)
    local frame = CreateFrame("Frame", name, parent)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetPoint(unpack(point))
    return frame
end

function DrawGrid()
    local grid = CreateFrame("Frame", "SUIGrid", WorldFrame)
    grid:SetAllPoints(WorldFrame)

    local size = 1
    local line = {}

    local width = GetScreenWidth()
    local height = GetScreenHeight()

    local ratio = width / GetScreenHeight()
    local rheight = GetScreenHeight() * ratio

    local wStep = width / 128
    local hStep = rheight / 128

    for i = 0, 128 do
        if i == 128 / 2 then
            line = grid:CreateTexture(nil, "BORDER")
            line:SetTexture(0.1, 0.5, 0.7)
        else
            line = grid:CreateTexture(nil, "BACKGROUND")
            line:SetTexture(0, 0, 0, 0.5)
        end
        line:SetPoint("TOPLEFT", grid, "TOPLEFT", i * wStep - (size / 2), 0)
        line:SetPoint("BOTTOMRIGHT", grid, "BOTTOMLEFT", i * wStep + (size / 2), 0)
    end

    for i = 1, math.floor(height / hStep) do
        if i == math.floor(height / hStep / 2) then
            line = grid:CreateTexture(nil, 'BORDER')
            line:SetTexture(.1, .5, .4)
        else
            line = grid:CreateTexture(nil, 'BACKGROUND')
            line:SetTexture(0, 0, 0)
        end

        line:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -(i * hStep) + (size / 2))
        line:SetPoint('BOTTOMRIGHT', grid, 'TOPRIGHT', 0, -(i * hStep + size / 2))
    end
    grid:Hide()

    return grid
end

grid = DrawGrid()



-- #############################
-- ## Main Config Window UI ##
-- #############################
function SimpleUI_Config_MainFrame_Create()
    SimpleUIConfig = {}

    -- Main Handle Frame
    SimpleUIConfig.Handle = SimpleUI_CreateFrame(nil, UIParent, 542, 400, { "CENTER", UIParent, "CENTER", 0, 0 })
    SimpleUIConfig.Handle:SetFrameStrata("BACKGROUND")
    SimpleUIConfig.Handle:SetMovable(true)


    SimpleUIConfig.Border = CreateFrame("Frame", nil, SimpleUIConfig.Handle)
    SimpleUIConfig.Border:SetBackdrop({
        edgeFile = SimpleUI_GetTexture("ThickBorder"),
        edgeSize = 14,
    })
    SimpleUIConfig.Border:SetPoint("TOPLEFT", SimpleUIConfig.Handle, "TOPLEFT", -7, 7)
    SimpleUIConfig.Border:SetPoint("BOTTOMRIGHT", SimpleUIConfig.Handle, "BOTTOMRIGHT", 7, -7)

    -- Background Texture
    SimpleUIConfig.BG = SimpleUIConfig.Handle:CreateTexture(nil, "BACKGROUND")
    SimpleUIConfig.BG:SetTexture(0.1, 0.1, 0.1, 0.8)
    SimpleUIConfig.BG:SetAllPoints(SimpleUIConfig.Handle)

    SimpleUIConfig.TitleBar = CreateFrame("Frame", nil, SimpleUIConfig.Handle)
    SimpleUIConfig.TitleBar:SetPoint("TOPLEFT", SimpleUIConfig.Handle)
    SimpleUIConfig.TitleBar:SetPoint("BOTTOM", SimpleUIConfig.Handle, "TOP", 0, -14)
    SimpleUIConfig.TitleBar:SetPoint("RIGHT", SimpleUIConfig.Handle, "RIGHT", -14, 0)
    SimpleUIConfig.TitleBar:SetFrameLevel(SimpleUIConfig.Handle:GetFrameLevel() + 1)

    SimpleUIConfig.Title = SimpleUIConfig.TitleBar:CreateFontString(nil, "OVERLAY")
    SimpleUIConfig.Title:SetFont(Config.TitleFont, 14)
    SimpleUIConfig.Title:SetShadowColor(0, 0, 0, 1)
    SimpleUIConfig.Title:SetShadowOffset(0.8, -0.8)
    SimpleUIConfig.Title:SetText("|cffffd700Simple:|r|cff1a9fc0UI|r |cffffd700v|r|cff1a9fc0" .. SimpleUIVersion .. "|r")
    SimpleUIConfig.Title:SetPoint("TOP", SimpleUIConfig.Handle, "TOP", 0, -1)

    SimpleUIConfig.TitleBarBorder = CreateFrame("Frame", nil, SimpleUIConfig.Handle)
    SimpleUIConfig.TitleBarBorder:SetBackdrop({
        bgFile = SimpleUI_GetTexture("StatusbarDefault"),
        tile = false,
        tileSize = 0,
        edgeFile = SimpleUI_GetTexture("ThickBorder"),
        edgeSize = 14,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    SimpleUIConfig.TitleBarBorder:SetBackdropColor(0.25, 0.25, 0.25, 1)
    SimpleUIConfig.TitleBarBorder:SetPoint("TOPLEFT", SimpleUIConfig.TitleBar, "TOPLEFT", -7, 7)
    SimpleUIConfig.TitleBarBorder:SetPoint("BOTTOMRIGHT", SimpleUIConfig.TitleBar, "BOTTOMRIGHT", 21, -7)
    SimpleUIConfig.TitleBarBorder:SetFrameLevel(SimpleUIConfig.TitleBar:GetFrameLevel())

    SimpleUIConfig.BtnClose = CreateFrame("Button", nil, SimpleUIConfig.Handle, "UIPanelCloseButton")
    SimpleUIConfig.BtnClose:SetWidth(12)
    SimpleUIConfig.BtnClose:SetHeight(12)
    SimpleUIConfig.BtnClose:SetPoint("TOPRIGHT", SimpleUIConfig.Handle, "TOPRIGHT", -2, -1)
    SimpleUIConfig.BtnClose:GetNormalTexture():SetTexCoord(0.2, 0.75, 0.25, 0.75)
    SimpleUIConfig.BtnClose:GetHighlightTexture():SetTexCoord(0.2, 0.75, 0.25, 0.75)
    SimpleUIConfig.BtnClose:GetPushedTexture():SetTexCoord(0.2, 0.75, 0.25, 0.75)

    SimpleUIConfig.selectionBG = SimpleUIConfig.Handle:CreateTexture(nil, "BORDER")
    --SimpleUIConfig.selectionBG:SetVertexColor(0.73,0.64,0.8,0.8)
    SimpleUIConfig.selectionBG:SetTexture(SimpleUI_GetTexture("RockBgLight"))
    SimpleUIConfig.selectionBG:SetPoint("BOTTOMRIGHT", SimpleUIConfig.Handle, "BOTTOMRIGHT", -1, 1)
    SimpleUIConfig.selectionBG:SetPoint("TOPLEFT", SimpleUIConfig.Handle, "TOPLEFT", 1, -15)

    SimpleUIConfig.Noise = SimpleUIConfig.Handle:CreateTexture(nil, "ARTWORK")
    SimpleUIConfig.Noise:SetTexture("Interface\\AddOns\\SimpleUI\\Media\\Textures\\NoiseInner.blp")
    SimpleUIConfig.Noise:SetAlpha(0.5)
    SimpleUIConfig.Noise:SetAllPoints(SimpleUIConfig.Handle)

    SimpleUIConfig.Shadow = SimpleUIConfig.Handle:CreateTexture(nil, "ARTWORK")
    SimpleUIConfig.Shadow:SetTexture("Interface\\AddOns\\SimpleUI\\Media\\Textures\\ShadowInner.blp")
    SimpleUIConfig.Shadow:SetAllPoints(SimpleUIConfig.Handle)

    local cropAmount = 0.2 -- Adjust this value to control the zoom
    SimpleUIConfig.Shadow:SetTexCoord(
        cropAmount,        -- Left crop
        1 - cropAmount,    -- Right crop
        cropAmount,        -- Top crop
        1 - cropAmount     -- Bottom crop
    )

    SimpleUIConfig.btnMade = 0
    SimpleUIConfig.Open = nil
    SimpleUIConfig.tabMade = 0
    SimpleUIConfig.Tab = nil

    SimpleUIConfig.Handle:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    SimpleUIConfig.Handle:SetMovable(true)
    SimpleUIConfig.TitleBar:EnableMouse(true)
    SimpleUIConfig.TitleBar:SetScript("OnMouseDown", SimpleUI_Config_MainFrame_StartMove)
    SimpleUIConfig.TitleBar:SetScript("OnMouseUp", SimpleUI_Config_MainFrame_StopMove)
    SimpleUIConfig.TitleBar:SetScript("OnHide", SimpleUI_Config_MainFrame_StopMove)
end

function SimpleUI_Config_MainFrame_StartMove(self)
    SimpleUIConfig.Handle.IsMovingOrSizing = 1
    SimpleUIConfig.Handle:StartMoving()
end

function SimpleUI_Config_MainFrame_StopMove(self)
    if SimpleUIConfig.Handle.IsMovingOrSizing then
        SimpleUIConfig.Handle:StopMovingOrSizing()
        SimpleUIConfig.Handle.IsMovingOrSizing = nil
    end
end

function SimpleUI_Config_EditFrame_Create(name)
    local handle = CreateFrame("Frame", nil, SimpleUIConfig.Handle)
    handle:SetPoint("BOTTOMRIGHT", SimpleUIConfig.Handle, "BOTTOMRIGHT", 0, 0)
    handle:SetPoint("TOPLEFT", SimpleUIConfig.selectionBG, "TOPLEFT", 0, -0.5)

    local scrollhandle, childhandle, normalhandle
    scrollhandle = CreateFrame("ScrollFrame", nil, handle)
    scrollhandle:SetPoint("TOPLEFT", handle, 115, 0)
    scrollhandle:SetPoint("BOTTOMRIGHT", handle)
    scrollhandle:EnableMouseWheel(true)

    scrollhandle:SetScript("OnMouseWheel", function()
        local maxScroll = this:GetVerticalScrollRange()
        local Scroll = this:GetVerticalScroll()
        local toScroll = (Scroll - (20 * arg1))
        if toScroll < 0 then
            this:SetVerticalScroll(0)
        elseif toScroll > maxScroll then
            this:SetVerticalScroll(maxScroll)
        else
            this:SetVerticalScroll(toScroll)
        end
    end)

    childhandle = CreateFrame("Frame", nil, scrollhandle)
    childhandle:SetWidth(480)
    childhandle:SetHeight(384)
    childhandle.num = 0
    childhandle.o = {}
    childhandle.noUpdate = {}

    scrollhandle:SetScrollChild(childhandle)


    local categories = CreateFrame("Frame", nil, SimpleUIConfig.Handle)
    categories:SetPoint("TOPLEFT", SimpleUIConfig.selectionBG, "TOPLEFT", 5, -5)
    categories:SetWidth(102)
    categories:SetHeight(375)

    categories.Bg = categories:CreateTexture(nil, "BACKGROUND")
    categories.Bg:SetAllPoints()
    categories.Bg:SetTexture(SimpleUI_GetTexture("StatusbarShadow"))
    categories.Bg:SetVertexColor(0.2, 0.2, 0.2)

    categories.btn = CreateFrame("Button", nil, SimpleUIConfig.Handle)
    categories.btn:SetPoint("TOPLEFT", categories, "TOPLEFT", 2, -18 * SimpleUIConfig.btnMade - 2)

    categories.btn:SetWidth(98)
    categories.btn:SetHeight(15)

    handle.texture = categories.btn:CreateTexture(nil, "ARTWORK")
    handle.texture:SetTexture(0.102, 0.624, 0.753, 0.6)
    handle.texture:SetAlpha(0.6)
    handle.texture:SetAllPoints(categories.btn)

    local txt = categories.btn:CreateFontString(nil, "OVERLAY")
    txt:SetFont(Config.TitleFont, 12)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText(name)
    txt:SetVertexColor(1, 0.843, 0, 1)
    txt:SetPoint("LEFT", categories.btn, "LEFT", 1, 0)

    categories.btn:SetScript("OnClick", function()
        if SimpleUIConfig.Open ~= nil then
            SimpleUIConfig.Open.texture:SetTexture(0.102, 0.624, 0.753, 0.6)
            SimpleUIConfig.Open:Hide()
        end
        handle.texture:SetTexture(0.102, 0.624, 0.753, 1)
        SimpleUIConfig.Open = handle
        handle:Show()
    end)
    categories.btn:SetScript("OnEnter", function()
        handle.texture:SetAlpha(0.9)
    end)
    categories.btn:SetScript("OnLeave", function()
        handle.texture:SetAlpha(0.6)
    end)

    SimpleUIConfig.btnMade = SimpleUIConfig.btnMade + 1

    return handle, childhandle
end

function SimpleUI_Config_EditFrame_Create_NoScroll(name)
    local handle = CreateFrame("Frame", nil, SimpleUIConfig.Handle)
    handle:SetPoint("BOTTOMRIGHT", SimpleUIConfig.Handle, "BOTTOMRIGHT", 0, 0)
    handle:SetPoint("TOPLEFT", SimpleUIConfig.selectionBG, "TOPLEFT", 0, -0.5)

    local normalhandle = CreateFrame("Frame", nil, handle)
    normalhandle:SetPoint("TOPLEFT", handle, 115, 0)
    normalhandle:SetPoint("BOTTOMRIGHT", handle)

    local childhandle = CreateFrame("Frame", nil, normalhandle)
    childhandle:SetAllPoints(normalhandle)
    childhandle.num = 0
    childhandle.o = {}

    local categories = CreateFrame("Frame", nil, SimpleUIConfig.Handle)
    categories:SetPoint("TOPLEFT", SimpleUIConfig.selectionBG, "TOPLEFT", 5, -5)
    categories:SetWidth(102)
    categories:SetHeight(375)

    categories.Bg = categories:CreateTexture(nil, "BACKGROUND")
    categories.Bg:SetAllPoints()
    categories.Bg:SetTexture(SimpleUI_GetTexture("StatusbarShadow"))
    categories.Bg:SetVertexColor(0.2, 0.2, 0.2)

    categories.btn = CreateFrame("Button", nil, SimpleUIConfig.Handle)
    categories.btn:SetPoint("TOPLEFT", categories, "TOPLEFT", 2, -18 * SimpleUIConfig.btnMade - 2)

    categories.btn:SetWidth(98)
    categories.btn:SetHeight(15)

    handle.texture = categories.btn:CreateTexture(nil, "ARTWORK")
    handle.texture:SetTexture(0.102, 0.624, 0.753, 0.6)
    handle.texture:SetAlpha(0.6)
    handle.texture:SetAllPoints(categories.btn)

    local txt = categories.btn:CreateFontString(nil, "OVERLAY")
    txt:SetFont(Config.TitleFont, 12)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText(name)
    txt:SetVertexColor(1, 0.843, 0, 1)
    txt:SetPoint("LEFT", categories.btn, "LEFT", 1, 0)

    categories.btn:SetScript("OnClick", function()
        if SimpleUIConfig.Open ~= nil then
            SimpleUIConfig.Open.texture:SetTexture(0.102, 0.624, 0.753, 0.6)
            SimpleUIConfig.Open:Hide()
        end
        handle.texture:SetTexture(0.102, 0.624, 0.753, 1)
        SimpleUIConfig.Open = handle
        handle:Show()
    end)
    categories.btn:SetScript("OnEnter", function()
        handle.texture:SetAlpha(0.9)
    end)
    categories.btn:SetScript("OnLeave", function()
        handle.texture:SetAlpha(0.6)
    end)

    SimpleUIConfig.btnMade = SimpleUIConfig.btnMade + 1

    return handle, childhandle
end

function SimpleUI_Config_EditUnitFrame_CreateTabs(name)
    -- Reference the Unitframes child handle
    local e = SimpleUIEditFrames["Unitframes"].ChildHandle

    local handle = CreateFrame("Frame", nil, e)
    handle:SetPoint("TOPLEFT", e, "TOPLEFT", 0, 0)
    handle:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", 0, -0.5)
    handle:Hide()

    local tabBar = CreateFrame("Frame", nil, e)
    tabBar:SetPoint("TOPLEFT", e, "TOPLEFT", 5, -5)
    tabBar:SetPoint("TOPRIGHT", e, "TOPRIGHT", -15, 0)
    tabBar:SetHeight(20)

    tabBar.Bg = tabBar:CreateTexture(nil, "BACKGROUND")
    tabBar.Bg:SetPoint("TOPLEFT", tabBar, "TOPLEFT", -2, 0)
    tabBar.Bg:SetPoint("TOPRIGHT", tabBar, "TOPRIGHT", 3, 0)
    tabBar.Bg:SetHeight(20)
    tabBar.Bg:SetTexture(SimpleUI_GetTexture("StatusbarShadow"))
    tabBar.Bg:SetVertexColor(0.2, 0.2, 0.2)

    local categories = CreateFrame("Frame", nil, e)
    categories:SetAllPoints(tabBar.Bg)

    --(SimpleUIConfig.tabMade - 1) * 83 - 1, 0
    categories.btn = CreateFrame("Button", nil, e)
    categories.btn:SetPoint("LEFT", categories, "LEFT", 2 + (SimpleUIConfig.tabMade * 68) + 1, 0)
    categories.btn:SetWidth(65)
    categories.btn:SetHeight(15)

    handle.texture = categories.btn:CreateTexture(nil, "ARTWORK")
    handle.texture:SetTexture(0.3, 0.3, 0.3, 0.6)
    handle.texture:SetAlpha(0.6)
    handle.texture:SetAllPoints(categories.btn)

    local txt = categories.btn:CreateFontString(nil, "OVERLAY")
    txt:SetFont(Config.TitleFont, 12)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText(name)
    txt:SetVertexColor(1, 0.843, 0, 1)
    txt:SetPoint("LEFT", categories.btn, "LEFT", 1, 0)

    local scrollhandle = CreateFrame("ScrollFrame", nil, handle)
    scrollhandle:SetPoint("TOPLEFT", tabBar.Bg, "BOTTOMLEFT", 0, -5)
    scrollhandle:SetPoint("BOTTOMRIGHT", handle)
    scrollhandle:EnableMouseWheel(true)

    scrollhandle:SetScript("OnMouseWheel", function()
        local maxScroll = this:GetVerticalScrollRange()
        local Scroll = this:GetVerticalScroll()
        local toScroll = (Scroll - (20 * arg1))
        if toScroll < 0 then
            this:SetVerticalScroll(0)
        elseif toScroll > maxScroll then
            this:SetVerticalScroll(maxScroll)
        else
            this:SetVerticalScroll(toScroll)
        end
    end)

    local childhandle = CreateFrame("Frame", nil, scrollhandle)
    childhandle:SetWidth(480)
    childhandle:SetHeight(384)
    childhandle.num = 0
    childhandle.o = {}

    scrollhandle:SetScrollChild(childhandle)

    categories.btn:SetScript("OnClick", function()
        if SimpleUIConfig.Tab ~= nil then
            SimpleUIConfig.Tab.texture:SetTexture(0.3, 0.3, 0.3, 0.6)
            SimpleUIConfig.Tab:Hide()
        end
        handle.texture:SetTexture(0.5, 0.5, 0.5, 1)
        SimpleUIConfig.Tab = handle
        handle:Show()
        scrollhandle:SetScrollChild(childhandle)
    end)

    categories.btn:SetScript("OnEnter", function()
        handle.texture:SetAlpha(0.9)
    end)
    categories.btn:SetScript("OnLeave", function()
        handle.texture:SetAlpha(0.6)
    end)

    SimpleUIConfig.tabMade = SimpleUIConfig.tabMade + 1

    return handle, childhandle
end

function SimpleUI_Config_EditFrame_CreateHeaderOption(parent, Text)
    parent.num = parent.num + 1
    local txt = parent:CreateFontString(nil, "OVERLAY")
    txt:SetFont(Config.TitleFont, Config.NormSize + 2)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText("            |cff1a9fc0" .. Text .. "|r")
    txt:SetHeight(13)
    txt:SetJustifyH("LEFT")
    txt:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -parent.num * 23 - 15)
    txt:SetPoint("RIGHT", parent)

    parent.num = parent.num + 1
end

SimpleUI_Config_EditFrame_DropDownMenuCount = 0
function SimpleUI_Config_EditConfig_CreateDropDownOption(parent, optionText)
    local txt = parent:CreateFontString(nil, "OVERLAY")
    txt:SetFont(Config.TitleFont, Config.NormSize)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText(optionText)
    txt:SetVertexColor(1, 0.843, 0, 1)
    txt:SetHeight(13)
    txt:SetJustifyH("LEFT")
    txt:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -parent.num * 23 - 15)
    txt:SetPoint("RIGHT", parent, "LEFT", 255, 0)

    local fn = "SimpleUIDropDown" .. SimpleUI_Config_EditFrame_DropDownMenuCount
    SimpleUI_Config_EditFrame_DropDownMenuCount = SimpleUI_Config_EditFrame_DropDownMenuCount + 1

    local dropmenu = CreateFrame("Frame", fn, parent, "UIDropDownMenuTemplate")
    dropmenu:SetPoint("TOPLEFT", parent, "TOPLEFT", 110, -parent.num * 23 + 15)
    dropmenu:EnableMouse(true)

    getglobal(fn .. "Left"):Hide()
    getglobal(fn .. "Right"):Hide()
    getglobal(fn .. "Middle"):SetTexture(0.1, 0.1, 0.1, 0.6)
    getglobal(fn .. "Middle"):SetHeight(13)
    getglobal(fn .. "Middle"):SetPoint("TOPLEFT", parent, "TOPLEFT", 227, -parent.num * 23 - 15)
    getglobal(fn .. "Middle"):SetPoint("RIGHT", parent, "RIGHT", -55, 0)
    getglobal(fn .. "Button"):ClearAllPoints()
    getglobal(fn .. "Button"):SetAllPoints(getglobal(fn .. "Middle"))
    getglobal(fn .. "Button"):SetParent(getglobal(fn))
    getglobal(fn .. "Text"):SetPoint("LEFT", getglobal(fn .. "Button"), "LEFT", 5, 0)
    getglobal(fn .. "Text"):SetJustifyH("LEFT")
    getglobal(fn .. "Text"):SetFont(Config.TitleFont, Config.NormSize)
    getglobal(fn .. "ButtonNormalTexture"):SetAllPoints(getglobal(fn .. "Button"))
    getglobal(fn .. "ButtonPushedTexture"):SetAllPoints(getglobal(fn .. "Button"))
    getglobal(fn .. "ButtonHighlightTexture"):SetAllPoints(getglobal(fn .. "Button"))
    getglobal(fn .. "ButtonNormalTexture"):SetTexture("")
    getglobal(fn .. "ButtonPushedTexture"):SetTexture(0.102, 0.624, 0.753, 0.7)
    getglobal(fn .. "ButtonHighlightTexture"):SetTexture(0.102, 0.624, 0.753, 0.5)


    parent.num = parent.num + 1
    return dropmenu
end

function SimpleUI_Config_EditFrame_UpdateAll()
    for _, f in pairs(SimpleUIEditFrames) do
        f.update()
    end
end

SimpleUI_Config_EditFrame_UpdateAll()

function SimpleUI_Config_EditFrame_CreateEditTextOption(parent, optionText, getter, setter)
    local txt = parent:CreateFontString(nil, "OVERLAY")
    txt:SetFont(Config.TitleFont, Config.NormSize)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText(optionText)
    txt:SetVertexColor(1, 0.843, 0, 1)
    txt:SetHeight(13)
    txt:SetJustifyH("LEFT")
    txt:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -parent.num * 23 - 15)
    txt:SetPoint("RIGHT", parent, "LEFT", 255, 0)

    local editbox = CreateFrame("EditBox", nil, parent)
    editbox:SetHeight(13)
    editbox:SetFont(Config.TitleFont, Config.NormSize)

    editbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 227, -parent.num * 23 - 15)
    editbox:SetPoint("RIGHT", parent, "RIGHT", -55, 0)
    editbox:SetAutoFocus(false)

    local inFocusChange = false
    local onEnter = function()
        if inFocusChange then return end
        inFocusChange = true
        editbox:ClearFocus()
        setter(editbox:GetText())
        inFocusChange = false
    end

    local updateOption = function()
        local v = getter()
        editbox:SetText(v)
        editbox:ClearFocus()
    end

    editbox:SetScript("OnEnterPressed", onEnter)
    editbox:SetScript("OnEditFocusLost", onEnter)
    editbox:SetScript("OnEscapePressed", updateOption)

    local editboxbg = parent:CreateTexture(nil, "BACKGROUND")
    editboxbg:SetTexture(0.1, 0.1, 0.1, 0.6)
    editboxbg:SetAllPoints(editbox)
    parent.num = parent.num + 1
    return updateOption, editbox, txt
end

function SimpleUI_Config_EditFrame_CreateCheckBoxOption(parent, optionText, getter, setter, headerTxt, descTxt)
    local txt = parent:CreateFontString(nil, "OVERLAY")
    txt:SetFont(Config.TitleFont, Config.NormSize)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText(optionText)
    txt:SetVertexColor(1, 0.843, 0, 1)
    txt:SetHeight(13)
    txt:SetJustifyH("LEFT")
    txt:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -parent.num * 23 - 15)
    txt:SetPoint("RIGHT", parent, "LEFT", 255, 0)

    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetHeight(13)
    checkbox:SetWidth(14)
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 227, -parent.num * 23 - 15)
    checkbox:GetNormalTexture():SetTexCoord(0.3, 0.6, 0.3, 0.6)
    checkbox:GetHighlightTexture():SetTexCoord(0.3, 0.6, 0.3, 0.6)
    checkbox:GetPushedTexture():SetTexCoord(0.3, 0.6, 0.3, 0.6)

    checkbox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(SimpleUIConfig.Handle, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText(headerTxt, 0.102, 0.624, 0.753, 1)
        GameTooltip:AddLine(descTxt)
        GameTooltip:Show()
    end)

    checkbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    checkbox:SetScript("OnClick", function()
        setter(checkbox:GetChecked())
    end)

    local updateOption = function()
        local v = getter()
        if v then
            checkbox:SetChecked(v)
        else
            checkbox:SetChecked(false)
        end
    end

    parent.num = parent.num + 1
    return updateOption
end

function SimpleUI_Config_EditFrame_CreateEditNumberOption(parent, optionText, getter, setter, min, max)
    local txt = parent:CreateFontString(nil, "OVERLAY")
    txt:SetFont(Config.TitleFont, Config.NormSize)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText(optionText)
    txt:SetVertexColor(unpack(Config.Colors.Gold))
    txt:SetHeight(13)
    txt:SetJustifyH("LEFT")
    txt:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -parent.num * 23 - 15)
    txt:SetPoint("RIGHT", parent, "LEFT", 255, 0)

    local editbox = CreateFrame("EditBox", nil, parent)
    editbox:SetHeight(13)
    editbox:SetFont(Config.TitleFont, Config.NormSize)
    editbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 227, -parent.num * 23 - 15)
    editbox:SetPoint("RIGHT", parent, "RIGHT", -1.5, 0)
    editbox:SetAutoFocus(false)

    local inFocusChange = false

    local updateOption = function()
        local s = getter()
        local low = min
        local high = max
        if s >= high then
            editbox:SetText(string.format("%.2f", high))
        elseif s <= low then
            editbox:SetText(string.format("%.2f", low))
        elseif s and s > low and s < high then
            editbox:SetText(string.format("%.2f", s))
        end
    end

    local onEnter = function()
        if inFocusChange then return end
        inFocusChange = true
        editbox:ClearFocus()
        local s = tonumber(editbox:GetText())
        local low = tonumber(min)
        local high = tonumber(max)
        if s >= high then
            setter(high)
        elseif s <= low then
            setter(low)
        elseif s and s > low and s < high then
            setter(s)
        end
        updateOption()
        inFocusChange = false
    end

    editbox:SetScript("OnEnterPressed", onEnter)
    editbox:SetScript("OnEditFocusLost", onEnter)
    editbox:SetScript("OnEscapePressed", updateOption)

    local editboxbg = parent:CreateTexture(nil, "BACKGROUND")
    editboxbg:SetTexture(0.1, 0.1, 0.1, 0.6)
    editboxbg:SetAllPoints(editbox)
    parent.num = parent.num + 1
    return updateOption, editbox, txt
end

function SimpleUI_Config_EditFrame_CreateAnchorDropDownOption(parent, optionText, getter, setter)
    local dropmenu = SimpleUI_Config_EditConfig_CreateDropDownOption(parent, optionText)

    UIDropDownMenu_Initialize(dropmenu, function()
        for _, i in pairs({ "TOP", "RIGHT", "BOTTOM", "LEFT", "TOPLEFT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMLEFT", "CENTER" }) do
            local info = {}
            info.text = i
            info.arg1 = i
            info.checked = (i == getter())
            info.func = function(v)
                setter(v)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(getter(), dropmenu)
    return dropmenu
end

function SimpleUI_Config_EditFrame_CreateConfigDropDownOption(parent, optionText, list, getter, setter)
    local dropmenu = SimpleUI_Config_EditConfig_CreateDropDownOption(parent, optionText)

    UIDropDownMenu_Initialize(dropmenu, function()
        for _, i in pairs(list) do
            local info = {}
            info.text = i
            info.arg1 = i
            info.checked = (i == getter())
            info.func = function(v)
                setter(v)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(getter(), dropmenu)
    return dropmenu
end

function SimpleUI_Config_EditFrame_CreateBlessingDropDownOption(
    parent,     -- e.g. your config frame
    optionText, -- label: "Default Buff for Warrior"
    classID,    -- numeric class ID 1..10
    pallyDB     -- your DB table, e.g. SimpleUIDB.Profiles[...]["Entities"]["PallyPower"]
)
    -- We reuse your existing function that sets up a label + a dropdown template
    local dropmenu = SimpleUI_Config_EditConfig_CreateDropDownOption(parent, optionText)

    -- Our local list of blessing names for the dropdown
    local BlessingNames = {
        [0] = "Wisdom",
        [1] = "Might",
        [2] = "Salvation",
        [3] = "Light",
        [4] = "Kings",
        [5] = "Sanctuary",
    }

    -- 'getter' for the current blessing ID from the DB
    local function getCurrentBlessing()
        -- If the DB is missing or no entry, default to 0 (Wisdom, for example)
        local currentID = pallyDB.DefaultBlessings[classID] or 0
        return currentID
    end

    -- 'setter' to store the numeric ID back into the DB
    local function setCurrentBlessing(id)
        pallyDB.DefaultBlessings[classID] = id
    end

    -- Initialize the dropdown
    UIDropDownMenu_Initialize(dropmenu, function()
        -- For each possible blessing
        for blessingID, blessingName in pairs(BlessingNames) do
            local info = {}
            info.text = blessingName
            info.arg1 = blessingID

            -- Mark it checked if it’s the current DB value
            info.checked = (blessingID == getCurrentBlessing())

            -- On click, set that numeric ID into the DB
            info.func = function(arg1)
                setCurrentBlessing(arg1)
                UIDropDownMenu_SetText(BlessingNames[pallyDB.DefaultBlessings[classID]], dropmenu) -- update dropdown text
            end

            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Set the dropdown’s initial text to whatever is stored in the DB
    local currID = getCurrentBlessing()
    UIDropDownMenu_SetText(BlessingNames[currID], dropmenu)

    return dropmenu
end

function SimpleUI_Config_EditFrame_ColorPickerOption(parent, optionText, getter, setter)
    local txt = parent:CreateFontString(nil, "OVERLAY")
    txt:SetFont(Config.TitleFont, Config.NormSize)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText(optionText)
    txt:SetVertexColor(unpack(Config.Colors.Gold))
    txt:SetHeight(13)
    txt:SetJustifyH("LEFT")
    txt:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -parent.num * 23 - 15)
    txt:SetPoint("RIGHT", parent, "LEFT", 255, 0)

    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(13)
    --btn:SetFont(normalFont, normalSize)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 227, -parent.num * 23 - 15)
    btn:SetPoint("RIGHT", parent, "RIGHT", -55, 0)

    local btnbg1 = btn:CreateTexture(nil, "BACKGROUND")
    btnbg1:SetTexture(0, 0, 0, 1)
    btnbg1:SetAllPoints(btn)

    local btnbg2 = btn:CreateTexture(nil, "ARTWORK")
    btnbg2:SetTexture(1, 1, 1, 1)
    btnbg2:SetPoint("TOPLEFT", btnbg1, "TOPLEFT", 1, -1)
    btnbg2:SetPoint("BOTTOMRIGHT", btnbg1, "BOTTOMRIGHT", -1, 1)

    local btnbg3 = btn:CreateTexture(nil, "OVERLAY")
    btnbg3:SetPoint("TOPLEFT", btnbg1, "TOPLEFT", 1, -1)
    btnbg3:SetPoint("BOTTOMRIGHT", btnbg1, "BOTTOMRIGHT", -1, 1)

    local txtR = parent:CreateFontString(nil, "OVERLAY")
    txtR:SetFont(Config.TitleFont, Config.NormSize)
    txtR:SetShadowColor(0, 0, 0, 1)
    txtR:SetShadowOffset(0.8, -0.8)
    txtR:SetText("R")
    txtR:SetHeight(13)
    txtR:SetJustifyH("LEFT")
    txtR:SetPoint("TOPLEFT", parent, "TOPLEFT", 227, -(parent.num + 1) * 23 - 15)
    txtR:SetPoint("RIGHT", parent, "LEFT", 237, 0)

    local editboxR = CreateFrame("EditBox", nil, parent)
    editboxR:SetHeight(13)
    editboxR:SetFont(Config.TitleFont, Config.NormSize, "")
    editboxR:SetPoint("TOPLEFT", txtR, "TOPRIGHT", 3, 0)
    editboxR:SetPoint("RIGHT", txtR, "RIGHT", 35, 0)
    editboxR:SetAutoFocus(false)

    local editboxbgR = parent:CreateTexture(nil, "BACKGROUND")
    editboxbgR:SetTexture(0.1, 0.1, 0.1, 0.6)
    editboxbgR:SetAllPoints(editboxR)

    local txtG = parent:CreateFontString(nil, "OVERLAY")
    txtG:SetFont(Config.TitleFont, Config.NormSize)
    txtG:SetShadowColor(0, 0, 0, 1)
    txtG:SetShadowOffset(0.8, -0.8)
    txtG:SetText("G")
    txtG:SetHeight(13)
    txtG:SetJustifyH("LEFT")
    txtG:SetPoint("TOPLEFT", txtR, "TOPLEFT", 50, 0)
    txtG:SetPoint("RIGHT", txtR, "RIGHT", 52, 0)

    local editboxG = CreateFrame("EditBox", nil, parent)
    editboxG:SetHeight(13)
    editboxG:SetFont(Config.TitleFont, Config.NormSize, "")
    editboxG:SetPoint("TOPLEFT", txtG, "TOPRIGHT", 3, 0)
    editboxG:SetPoint("RIGHT", txtG, "RIGHT", 35, 0)
    editboxG:SetAutoFocus(false)

    local editboxbgG = parent:CreateTexture(nil, "BACKGROUND")
    editboxbgG:SetTexture(0.1, 0.1, 0.1, 0.6)
    editboxbgG:SetAllPoints(editboxG)

    local txtB = parent:CreateFontString(nil, "OVERLAY")
    txtB:SetFont(Config.TitleFont, Config.NormSize)
    txtB:SetShadowColor(0, 0, 0, 1)
    txtB:SetShadowOffset(0.8, -0.8)
    txtB:SetText("B")
    txtB:SetHeight(13)
    txtB:SetJustifyH("LEFT")
    txtB:SetPoint("TOPLEFT", txtG, "TOPLEFT", 50, 0)
    txtB:SetPoint("RIGHT", txtG, "RIGHT", 52, 0)

    local editboxB = CreateFrame("EditBox", nil, parent)
    editboxB:SetHeight(13)
    editboxB:SetFont(Config.TitleFont, Config.NormSize, "")
    editboxB:SetPoint("TOPLEFT", txtB, "TOPRIGHT", 3, 0)
    editboxB:SetPoint("RIGHT", txtB, "RIGHT", 35, 0)
    editboxB:SetAutoFocus(false)

    local editboxbgB = parent:CreateTexture(nil, "BACKGROUND")
    editboxbgB:SetTexture(0.1, 0.1, 0.1, 0.6)
    editboxbgB:SetAllPoints(editboxB)

    local txtA = parent:CreateFontString(nil, "OVERLAY")
    txtA:SetFont(Config.TitleFont, Config.NormSize)
    txtA:SetShadowColor(0, 0, 0, 1)
    txtA:SetShadowOffset(0.8, -0.8)
    txtA:SetText("A")
    txtA:SetHeight(14)
    txtA:SetJustifyH("LEFT")
    txtA:SetPoint("TOPLEFT", txtB, "TOPLEFT", 50, 0)
    txtA:SetPoint("RIGHT", txtB, "RIGHT", 52, 0)

    local editboxA = CreateFrame("EditBox", nil, parent)
    editboxA:SetHeight(13)
    editboxA:SetFont(Config.TitleFont, Config.NormSize, "")
    editboxA:SetPoint("TOPLEFT", txtA, "TOPRIGHT", 3, 0)
    editboxA:SetPoint("RIGHT", txtA, "RIGHT", 35, 0)
    editboxA:SetAutoFocus(false)

    local editboxbgA = parent:CreateTexture(nil, "BACKGROUND")
    editboxbgA:SetTexture(0.1, 0.1, 0.1, 0.6)
    editboxbgA:SetAllPoints(editboxA)

    local updateOption = function()
        local r, g, b, a = getter()
        btnbg3:SetTexture(r, g, b, a)
        editboxR:SetText(string.format("%.2f", r))
        editboxG:SetText(string.format("%.2f", g))
        editboxB:SetText(string.format("%.2f", b))
        editboxA:SetText(string.format("%.2f", a))
    end

    local inFocusChange = false
    local onEnter = function()
        if inFocusChange then return end
        inFocusChange = true
        editboxR:ClearFocus()
        local r, g, b, a = getter()
        local newr = tonumber(editboxR:GetText())
        if not newr then newr = r end
        local newg = tonumber(editboxG:GetText())
        if not newg then newg = g end
        local newb = tonumber(editboxB:GetText())
        if not newb then newb = b end
        local newa = tonumber(editboxA:GetText())
        if not newa then newa = a end
        setter(newr, newg, newb, newa)
        updateOption()
        inFocusChange = false
    end

    editboxR:SetScript("OnEnterPressed", onEnter)
    editboxR:SetScript("OnEditFocusLost", onEnter)
    editboxR:SetScript("OnEscapePressed", updateOption)
    editboxG:SetScript("OnEnterPressed", onEnter)
    editboxG:SetScript("OnEditFocusLost", onEnter)
    editboxG:SetScript("OnEscapePressed", updateOption)
    editboxB:SetScript("OnEnterPressed", onEnter)
    editboxB:SetScript("OnEditFocusLost", onEnter)
    editboxB:SetScript("OnEscapePressed", updateOption)
    editboxA:SetScript("OnEnterPressed", onEnter)
    editboxA:SetScript("OnEditFocusLost", onEnter)
    editboxA:SetScript("OnEscapePressed", updateOption)

    btn:SetScript("OnClick", function()
        if not ColorPickerFrame:IsVisible() then
            ColorPickerFrame.hasOpacity = nil
            ColorPickerFrame.func = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local _, _, _, a = getter()
                setter(r, g, b, a)
                updateOption()
            end
            ColorPickerFrame.cancelFunc = function()
                setter(btnbg3.oldr, btnbg3.oldg, btnbg3.oldb, btnbg3.olda)
                updateOption()
            end
            ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
            ColorPickerFrame:Hide()
            ColorPickerFrame:Show()
            btnbg3.oldr, btnbg3.oldg, btnbg3.oldb, btnbg3.olda = getter()
            ColorPickerFrame:SetColorRGB(btnbg3.oldr, btnbg3.oldg, btnbg3.oldb)
        end
    end)

    parent.num = parent.num + 2
    return updateOption
end

function SimpleUI_Config_EditFrame_CreateEditNumberOption(parent, optionText, getter, setter, min, max)
    local txt = parent:CreateFontString(nil, "OVERLAY")
    txt:SetFont(Config.TitleFont, Config.NormSize)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText(optionText)
    txt:SetVertexColor(unpack(Config.Colors.Gold))
    txt:SetHeight(13)
    txt:SetJustifyH("LEFT")
    txt:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -parent.num * 23 - 15)
    txt:SetPoint("RIGHT", parent, "LEFT", 255, 0)

    local editbox = CreateFrame("EditBox", nil, parent)
    editbox:SetHeight(13)
    editbox:SetFont(Config.TitleFont, Config.NormSize)
    editbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 269, -parent.num * 23 - 15)
    editbox:SetPoint("RIGHT", parent, "RIGHT", -55, 0)
    editbox:SetAutoFocus(false)

    local plusButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    plusButton:GetHighlightTexture():SetTexture(0.102, 0.624, 0.753, 0.5)
    plusButton:GetPushedTexture():SetTexture(0.102, 0.624, 0.753, 0.7)
    plusButton:GetNormalTexture():SetTexture("")
    plusButton:SetFont(Config.TitleFont, 16)
    plusButton:SetWidth(20)
    plusButton:SetHeight(13)
    plusButton:SetText("+")
    plusButton:SetPoint("RIGHT", editbox, "LEFT", -2, 0)
    plusButton:SetScript("OnClick", function()
        local currentValue = tonumber(editbox:GetText())
        if currentValue >= max then
            setter(currentValue)
            editbox:SetText(string.format("%.1f", currentValue))
        else
            setter(currentValue + 1)
            editbox:SetText(string.format("%.1f", currentValue + 1))
        end
    end)

    plusButton.Bg = plusButton:CreateTexture(nil, "BACKGROUND")
    plusButton.Bg:SetAllPoints()
    plusButton.Bg:SetTexture(SimpleUI_GetTexture("StatusbarShadow"))
    plusButton.Bg:SetVertexColor(0.2, 0.2, 0.2)

    local minusButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    minusButton:GetHighlightTexture():SetTexture(0.102, 0.624, 0.753, 0.5)
    minusButton:GetPushedTexture():SetTexture(0.102, 0.624, 0.753, 0.7)
    minusButton:GetNormalTexture():SetTexture("")
    minusButton:SetFont(Config.TitleFont, 16)
    minusButton:SetWidth(20)
    minusButton:SetHeight(13)
    minusButton:SetText("-")
    minusButton:SetPoint("RIGHT", editbox, "LEFT", -22, 0)
    minusButton:SetScript("OnClick", function()
        local currentValue = tonumber(editbox:GetText())
        if currentValue <= min then
            setter(currentValue)
            editbox:SetText(string.format("%.1f", currentValue))
        else
            setter(currentValue - 1)
            editbox:SetText(string.format("%.1f", currentValue - 1))
        end
    end)

    minusButton.Bg = minusButton:CreateTexture(nil, "BACKGROUND")
    minusButton.Bg:SetAllPoints()
    minusButton.Bg:SetTexture(SimpleUI_GetTexture("StatusbarShadow"))
    minusButton.Bg:SetVertexColor(0.2, 0.2, 0.2)

    local updateOption = function()
        local s = getter()
        local low = min
        local high = max
        if s >= high then
            editbox:SetText(string.format("%.1f", high))
        elseif s <= low then
            editbox:SetText(string.format("%.1f", low))
        elseif s and s > low and s < high then
            editbox:SetText(string.format("%.1f", s))
        end
    end


    local onEnter = function()
        local s = tonumber(editbox:GetText())
        local low = tonumber(min)
        local high = tonumber(max)
        if s >= high then
            setter(high)
        elseif s <= low then
            setter(low)
        elseif s and s > low and s < high then
            setter(s)
        end
        updateOption()
    end

    editbox:SetScript("OnEnterPressed", function()
        onEnter()
        this:ClearFocus()
    end)
    editbox:SetScript("OnEditFocusLost", onEnter)
    editbox:SetScript("OnEscapePressed", updateOption)

    local editboxbg = parent:CreateTexture(nil, "BACKGROUND")
    editboxbg:SetTexture(0.1, 0.1, 0.1, 0.6)
    editboxbg:SetAllPoints(editbox)
    parent.num = parent.num + 1
    return updateOption, editbox, txt
end

function SimpleUI_Config_Mediapicker_Create()
    local h = CreateFrame("Frame", nil, SimpleUIConfig.Handle)
    h:SetPoint("TOPLEFT", SimpleUIConfig.Handle, "TOPRIGHT", 0, -15)
    h:SetPoint("BOTTOM", SimpleUIConfig.Handle)
    h:SetWidth(200)

    local bg = h:CreateTexture(nil, "BORDER")
    bg:SetTexture(SimpleUI_GetTexture("StatusbarShadow"))
    bg:SetVertexColor(0.25, 0.25, 0.25)
    bg:SetAllPoints(h)

    local scroll = CreateFrame("ScrollFrame", nil, h)
    scroll:SetAllPoints(h)
    scroll:EnableMouseWheel(true)

    scroll:SetScript("OnMouseWheel", function()
        local maxScroll = this:GetVerticalScrollRange()
        local Scroll = this:GetVerticalScroll()
        local toScroll = (Scroll - (20 * arg1))
        if toScroll < 0 then
            this:SetVerticalScroll(0)
        elseif toScroll > maxScroll then
            this:SetVerticalScroll(maxScroll)
        else
            this:SetVerticalScroll(toScroll)
        end
    end)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(200)
    content:SetHeight(350)

    scroll:SetScrollChild(content)
    return h, content
end

function SimpleUI_Config_TextureFrame_Show(getter, setter)
    if not SimpleUI_Config_TextureFrame then
        local h, content = SimpleUI_Config_Mediapicker_Create()
        local num = 0
        local Buttons = {}

        local sortedTextures = {}
        for n in pairs(SimpleUIStatusBars) do table.insert(sortedTextures, n) end
        table.sort(sortedTextures)
        for _, i in ipairs(sortedTextures) do
            local btn = {}
            btn.f = CreateFrame("Button", nil, content)
            btn.f:SetHeight(13)
            btn.f:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -num * 14)
            btn.f:SetPoint("RIGHT", content, "RIGHT", -2, 0)

            btn.bg = btn.f:CreateTexture(nil, "BACKGROUND")
            btn.bg:SetTexture(SimpleUI_GetTexture(i))
            btn.bg:SetAllPoints(btn.f)

            btn.txt = btn.f:CreateFontString(nil, "OVERLAY")
            btn.txt:SetFont(Config.TitleFont, 12)
            btn.txt:SetShadowColor(0, 0, 0, 1)
            btn.txt:SetShadowOffset(0.8, -0.8)
            btn.txt:SetText(i)
            btn.txt:SetPoint("CENTER", btn.f)

            btn.Texture = i

            num = num + 1
            Buttons[i] = btn
        end
        SimpleUI_Config_TextureFrame = {}
        SimpleUI_Config_TextureFrame.h = h
        SimpleUI_Config_TextureFrame.Buttons = Buttons
        SimpleUI_Config_TextureFrame.h:Hide()
    end
    if SimpleUI_Config_TextureFrame.h:IsShown() then
        SimpleUI_Config_TextureFrame.h:Hide()
    else
        for _, b in pairs(SimpleUI_Config_TextureFrame.Buttons) do
            local btn = b
            if btn.Texture == getter() then
                btn.bg:SetVertexColor(0.7, 1, 0.7, 1)
            else
                btn.bg:SetVertexColor(1, 1, 1, 1)
            end
            btn.f:SetScript("OnClick", function()
                setter(btn.Texture)
                SimpleUI_Config_TextureFrame.h:Hide()
            end)
        end
        if SimpleUI_Config_FontFrame then SimpleUI_Config_FontFrame.h:Hide() end
        SimpleUI_Config_TextureFrame.h:Show()
    end
end

function SimpleUI_Config_EditFrame_CreateTexturePickerOption(parent, optionText, getter, setter)
    local txt = parent:CreateFontString(nil, "OVERLAY")
    txt:SetFont(Config.TitleFont, Config.NormSize)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText(optionText)
    txt:SetVertexColor(unpack(Config.Colors.Gold))
    txt:SetHeight(13)
    txt:SetJustifyH("LEFT")
    txt:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -parent.num * 23 - 15)
    txt:SetPoint("RIGHT", parent, "LEFT", 255, 0)

    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(13)
    btn:SetFont(Config.TitleFont, Config.NormSize)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 227, -parent.num * 23 - 15)
    btn:SetPoint("RIGHT", parent, "RIGHT", -55, 0)

    local btnoutline = btn:CreateTexture(nil, "BACKGROUND")
    btnoutline:SetTexture(0, 0, 0, 1)
    btnoutline:SetAllPoints(btn)

    local btnbg = btn:CreateTexture(nil, "OVERLAY")
    btnbg:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    btnbg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)

    local updateOption = function()
        btnbg:SetTexture(SimpleUI_GetTexture(getter()))
    end

    local onClick = function()
        SimpleUI_Config_TextureFrame_Show(getter, setter)
    end

    btn:SetScript("OnClick", onClick)

    parent.num = parent.num + 1
    return updateOption
end

function SimpleUI_Config_FontFrame_Show(getter, setter)
    if not SimpleUI_Config_FontFrame then
        local h, content = SimpleUI_Config_Mediapicker_Create()
        local num = 0
        local Buttons = {}

        local btn = {}
        btn.f = CreateFrame("Button", "SimpleFontButton" .. num, content, "UIPanelButtonTemplate")
        btn.f:SetHeight(13)
        btn.f:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -num * 23)
        btn.f:SetPoint("RIGHT", content, "RIGHT", -2, 0)

        btn.f:GetHighlightTexture():SetTexture(0.102, 0.624, 0.753, 0.5)
        btn.f:GetPushedTexture():SetTexture(0.102, 0.624, 0.753, 0.7)
        btn.f:GetNormalTexture():SetTexture("")

        btn.bg = btn.f:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetTexture(0.1, 0.1, 0.1, 0.6)
        btn.bg:SetAllPoints(btn.f)


        btn.txt = btn.f:CreateFontString(nil, "OVERLAY")
        btn.txt:SetFont(SimpleUI_GetFont(""), 12)
        btn.txt:SetText("Gamefont")
        btn.txt:SetPoint("LEFT", btn.f, 2, 0)

        btn.Font = ""

        num = num + 1
        Buttons["Gamefont"] = btn

        local sortedFonts = {}
        for n in pairs(SimpleUIFonts) do table.insert(sortedFonts, n) end
        table.sort(sortedFonts)
        for _, i in ipairs(sortedFonts) do
            local btn = {}
            btn.f = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
            btn.f:SetHeight(13)
            btn.f:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -num * 14)
            btn.f:SetPoint("RIGHT", content, "RIGHT", 0, 0)

            btn.f:GetHighlightTexture():SetTexture(0.102, 0.624, 0.753, 0.5)
            btn.f:GetPushedTexture():SetTexture(0.102, 0.624, 0.753, 0.7)
            btn.f:GetNormalTexture():SetTexture("")

            btn.bg = btn.f:CreateTexture(nil, "BACKGROUND")
            btn.bg:SetTexture(0.1, 0.1, 0.1, 0.6)
            btn.bg:SetAllPoints(btn.f)

            btn.txt = btn.f:CreateFontString(nil, "OVERLAY")
            btn.txt:SetFont(SimpleUI_GetFont(i), 12)
            btn.txt:SetText(i)
            btn.txt:SetPoint("LEFT", btn.f)

            btn.Font = i

            num = num + 1
            Buttons[i] = btn
        end
        SimpleUI_Config_FontFrame = {}
        SimpleUI_Config_FontFrame.h = h
        SimpleUI_Config_FontFrame.Buttons = Buttons
        SimpleUI_Config_FontFrame.h:Hide()
    end
    if SimpleUI_Config_FontFrame.h:IsShown() then
        SimpleUI_Config_FontFrame.h:Hide()
    else
        for _, b in pairs(SimpleUI_Config_FontFrame.Buttons) do
            local btn = b
            if btn.Font == getter() then
                btn.txt:SetTextColor(0.7, 1, 0.7, 1)
            else
                btn.txt:SetTextColor(1, 1, 1, 1)
            end
            btn.f:SetScript("OnClick", function()
                setter(btn.Font)
                SimpleUI_Config_FontFrame.h:Hide()
            end)
        end
        if SimpleUI_Config_TextureFrame then SimpleUI_Config_TextureFrame.h:Hide() end
        SimpleUI_Config_FontFrame.h:Show()
    end
end

function SimpleUI_Config_EditFrame_CreateFontPickerOption(parent, optionText, getter, setter)
    local txt = parent:CreateFontString(nil, "OVERLAY")
    txt:SetFont(Config.TitleFont, Config.NormSize)
    txt:SetShadowColor(0, 0, 0, 1)
    txt:SetShadowOffset(0.8, -0.8)
    txt:SetText(optionText)
    txt:SetVertexColor(unpack(Config.Colors.Gold))
    txt:SetHeight(13)
    txt:SetJustifyH("LEFT")
    txt:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -parent.num * 23 - 15)
    txt:SetPoint("RIGHT", parent, "LEFT", 255, 0)

    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetHeight(13)
    btn:SetFont(Config.TitleFont, Config.NormSize)
    btn:SetTextColor(1, 1, 1)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 227, -parent.num * 23 - 15)
    btn:SetPoint("RIGHT", parent, "RIGHT", -55, 0)

    btn:GetHighlightTexture():SetTexture(0.102, 0.624, 0.753, 0.5)
    btn:GetPushedTexture():SetTexture(0.102, 0.624, 0.753, 0.7)
    btn:GetNormalTexture():SetTexture("")

    local btnbg = parent:CreateTexture(nil, "BACKGROUND")
    btnbg:SetTexture(0.1, 0.1, 0.1, 0.6)
    btnbg:SetAllPoints(btn)

    local updateOption = function()
        btn:SetText(getter())
        btn:SetFont(SimpleUI_GetFont(getter()), 10)
    end

    local onClick = function()
        SimpleUI_Config_FontFrame_Show(getter, setter)
    end

    btn:SetScript("OnClick", onClick)

    parent.num = parent.num + 1
    return updateOption
end

function SimpleUI_Config_EditProfile_Create()
    SimpleUIEditFrames["Profile"] = {}
    SimpleUIEditFrames["Profile"].Handle, SimpleUIEditFrames["Profile"].ChildHandle = SimpleUI_Config_EditFrame_Create(
        "Profile")
    local e = SimpleUIEditFrames["Profile"].ChildHandle

    local currentp = SimpleUI_Config_EditConfig_CreateDropDownOption(e, "Current Profile")
    UIDropDownMenu_SetText(SimpleUIDB.Profiles[SimpleUIProfile].Name, currentp)
    UIDropDownMenu_Initialize(currentp, function()
        local info = {}
        for i, profile in pairs(SimpleUIDB.Profiles) do
            info.arg1 = i
            info.text = SimpleUIDB.Profiles[i].Name
            info.checked = (i == SimpleUIProfile)
            info.func = function(v)
                SimpleUIProfile = v
                SimpleUI_SystemMessage("Switched to Profile: " .. v)
                SimpleUIEditFrames["Profile"].update()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    e.o[e.num - 1] = function()
        UIDropDownMenu_SetText(SimpleUIDB.Profiles[SimpleUIProfile].Name, currentp)
    end

    local _, namep = SimpleUI_Config_EditFrame_CreateEditTextOption(e, "Profile Name", function()
        return SimpleUIDB.Profiles[SimpleUIProfile].Name
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile].Name = s
        SimpleUI_SystemMessage("Switched to Profile: " .. s)
        SimpleUIEditFrames["Profile"].update()
    end)

    local namedp = e:CreateFontString(nil, "OVERLAY")
    namedp:SetFont(GameFontNormal:GetFont(), 10)
    namedp:SetText("Default")
    namedp:SetHeight(13)
    namedp:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
    namedp:SetJustifyH("LEFT")
    namedp:SetAllPoints(namep)

    e.o[e.num - 1] = function()
        if SimpleUIProfile == "Default" then
            namep:SetText("Default")
            namep:Hide()
            namedp:Show()
        else
            namep:SetText(SimpleUIDB.Profiles[SimpleUIProfile].Name)
            namep:Show()
            namedp:Hide()
        end
    end

    local createp = SimpleUI_Config_EditConfig_CreateDropDownOption(e, "Create new profile")
    UIDropDownMenu_SetText("Select Preset", createp)
    UIDropDownMenu_Initialize(createp, function()
        for i, t in pairs(SimpleUI_Database) do
            local info = {}
            info.text = i
            info.arg1 = i
            info.notCheckable = true
            info.func = function(v)
                local num = 0
                while SimpleUIDB.Profiles["Custom" .. num] do
                    num = num + 1
                end
                SimpleUIDB.Profiles["Custom" .. num] = SimpleUI_Copy(SimpleUI_Database[v], {})

                SimpleUIProfile = "Custom" .. num
                SimpleUIEditFrames["Profile"].update()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local deletep = SimpleUI_Config_EditConfig_CreateDropDownOption(e, "Delete Profile")
    UIDropDownMenu_SetText("Select Profile", deletep)
    UIDropDownMenu_Initialize(deletep, function()
        for i, _ in pairs(SimpleUIDB.Profiles) do
            local info = {}
            info.arg1 = i
            info.text = SimpleUIDB.Profiles[i].Name
            if i == "Default" then
                info.disabled = true
            end
            info.notCheckable = true
            info.func = function(v)
                if SimpleUIProfile == v then
                    SimpleUIProfile = "Default"
                end
                SimpleUIDB.Profiles[v] = nil
                SimpleUIEditFrames["Profile"].update()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "Silence Welcome Message", function()
        return SimpleUIDB.Profiles[SimpleUIProfile].SilenceWelcomeMessage
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile].SilenceWelcomeMessage = s
    end, "Silence Welcome Message", "Removes the login message in the chatbox")

    SimpleUIEditFrames["Profile"].update = function()
        for _, update in pairs(e.o) do
            update()
        end
    end
    e:SetScript("OnShow", SimpleUIEditFrames["Profile"].update)
    SimpleUIEditFrames["Profile"].Handle:Hide()
end

function SimpleUI_Config_EditActionbar_Create()
    SimpleUIEditFrames["Actionbar"] = {}
    SimpleUIEditFrames["Actionbar"].Handle, SimpleUIEditFrames["Actionbar"].ChildHandle =
        SimpleUI_Config_EditFrame_Create(
            "Actionbar")
    local e = SimpleUIEditFrames["Actionbar"].ChildHandle

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "Show Actionbar Art", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"].ActionbarArt
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"].ActionbarArt = s
        SimpleUI_Update_Actionbar()
    end, "Show Actionbar Art", "Toggle between full artwork and minimal")

    SimpleUIEditFrames["Actionbar"].update = function()
        for _, update in pairs(e.o) do
            update()
        end
    end

    e:SetScript("OnShow", SimpleUIEditFrames["Actionbar"].update)
    SimpleUIEditFrames["Actionbar"].Handle:Hide()
end

function SimpleUI_Config_EditMicromenu_Create()
    SimpleUIEditFrames["Micromenu"] = {}
    SimpleUIEditFrames["Micromenu"].Handle, SimpleUIEditFrames["Micromenu"].ChildHandle =
        SimpleUI_Config_EditFrame_Create(
            "Micromenu")
    local e = SimpleUIEditFrames["Micromenu"].ChildHandle


    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "Color Buttons", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"].bags.color
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"].bags.color = s
        SimpleUI_Update_Microbar_Color()
    end, "Color Buttons", "Add / Remove color from the micromenu")

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "Show Micromenu Art", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"].bags.art
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Actionbar"].bags.art = s
        SimpleUI_Update_Microbar_Art()
    end, "Show Micromenu Art", "Toggle micromenu artwork")

    SimpleUIEditFrames["Micromenu"].update = function()
        for _, update in pairs(e.o) do
            update()
        end
    end

    e:SetScript("OnShow", SimpleUIEditFrames["Micromenu"].update)
    SimpleUIEditFrames["Micromenu"].Handle:Hide()
end

function SimpleUI_Config_EditUnitFrame_Create()
    SimpleUIEditFrames["Unitframes"] = {}
    SimpleUIEditFrames["Unitframes"].Handle, SimpleUIEditFrames["Unitframes"].ChildHandle =
        SimpleUI_Config_EditFrame_Create_NoScroll(
            "Unitframes")
    local e = SimpleUIEditFrames["Unitframes"].ChildHandle

    e.General, e.GeneralHandle = SimpleUI_Config_EditUnitFrame_CreateTabs("General")

    local g = e.GeneralHandle
    SimpleUI_Config_EditFrame_CreateHeaderOption(g, "General")
    local speedList = {
        "Instant",
        "Very Fast",
        "Fast",
        "Normal",
        "Average",
        "Slow"
    }
    local speed = SimpleUI_Config_EditFrame_CreateConfigDropDownOption(
        g,
        "Update Speed",
        speedList,
        function()
            return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].stepsize
        end,
        function(s)
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].stepsize = s
            SimpleUIEditFrames["Unitframes"].update()
        end)

    g.o[g.num - 1] = function()
        UIDropDownMenu_SetText(SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].stepsize, speed)
    end

    g.o[g.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(g, "Detach Castbar", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].castbar.anchorToFrame
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].castbar.anchorToFrame = s
        SimpleUI_UpdateCastbarConfig()
    end, "Detach Castbar", "Detach the castbar from the player frame")

    g.o[g.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
        g,
        "Castbar Width",
        function() return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].castbar.width end,
        function(s)
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].castbar.width = s
            SimpleUI_UpdateCastbarConfig()
        end,
        0,
        500
    )

    g.o[g.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
        g,
        "Castbar Height",
        function() return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].castbar.height end,
        function(s)
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].castbar.height = s
            SimpleUI_UpdateCastbarConfig()
        end,
        0,
        100
    )


    SimpleUI_Config_EditFrame_CreateHeaderOption(g, "Group")


    g.o[g.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(g, "Player in Group", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].selfingroup
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].selfingroup = s
    end, "Player in Group", "Show player in group frames")

    g.o[g.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(g, "Hide Group in Raid", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].hidepartyraid
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].hidepartyraid = s
    end, "Hide Group in Raid", "Hides party frames when in a raid group")

    SimpleUI_Config_EditFrame_CreateHeaderOption(g, "Color")

    g.o[g.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(g, "Pastel Colors", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].pastel
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].pastel = s
    end, "Pastel Colors", "Toggle pastel colors on unitframe health")

    g.o[g.num] = SimpleUI_Config_EditFrame_ColorPickerOption(g, "Mana Color", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].manaColor.r,
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].manaColor.g,
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].manaColor.b,
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].manaColor.a
    end, function(r, g, b, a)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].manaColor.r = r
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].manaColor.g = g
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].manaColor.b = b
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].manaColor.a = a
    end)

    g.o[g.num] = SimpleUI_Config_EditFrame_ColorPickerOption(g, "Rage Color", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].rageColor.r,
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].rageColor.g,
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].rageColor.b,
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].rageColor.a
    end, function(r, g, b, a)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].rageColor.r = r
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].rageColor.g = g
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].rageColor.b = b
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].rageColor.a = a
    end)

    g.o[g.num] = SimpleUI_Config_EditFrame_ColorPickerOption(g, "Energy Color", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].energyColor.r,
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].energyColor.g,
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].energyColor.b,
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].energyColor.a
    end, function(r, g, b, a)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].energyColor.r = r
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].energyColor.g = g
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].energyColor.b = b
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].energyColor.a = a
    end)

    local function getPartyFrames()
        local partyFrames = {}
        for i = 1, 4 do -- Assuming max 4 party members
            local frame = getglobal("SimpleUIparty" .. i)
            if frame then
                SimpleUI_SystemMessage(frame)
                table.insert(partyFrames, frame)
            end
        end
        return partyFrames
    end

    local unitFrames = {
        {
            name = "Player",
            config = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].player,
            unit = getglobal("SimpleUIplayer")
        },
        {
            name = "Target",
            config = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].target,
            unit = getglobal("SimpleUItarget")
        },
        {
            name = "ToT",
            config = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].targettarget,
            unit = getglobal("SimpleUItargettarget")
        },
        {
            name = "Pet",
            config = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].pet,
            unit = getglobal("SimpleUIpet")
        },
        {
            name = "Party",
            config = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].party,
            unit = getPartyFrames()
        },
        --{ name = "Raid",    config = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].raid },
    }

    local function createUnitFrameTab(frame, name, configKey, units)
        frame[name], frame[name .. "Handle"] = SimpleUI_Config_EditUnitFrame_CreateTabs(name)

        local f = frame[name .. "Handle"]
        local dbPath = configKey
        local portraitAnchor = { "left", "right", "bar", "none" }
        local bAnchor = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }

        local function globalUpdate()
            if name == "Party" then
                for i = 0, 4 do
                    local partyUnit = getglobal("SimpleUIGroup" .. i)
                    if partyUnit then
                        SimpleUI_GlobalConfigUpdate(partyUnit)
                    end
                end
            else
                if units then
                    SimpleUI_GlobalConfigUpdate(units)
                end
            end
            SimpleUIEditFrames["Unitframes"].update()
        end

        SimpleUI_Config_EditFrame_CreateHeaderOption(f, "Visibility")

        f.o[f.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(
            f,
            "Enable",
            function() return dbPath.visible end,
            function(s) dbPath.visible = s end,
            "Enable",
            "Toggle the " .. name .. " unitframe"
        )

        f.o[f.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
            f,
            "OOR Transparency",
            function() return dbPath.alpha_outofrange end,
            function(s) dbPath.alpha_outofrange = s end,
            0,
            1
        )

        f.o[f.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
            f,
            "Offline Transparency",
            function() return dbPath.alpha_offline end,
            function(s) dbPath.alpha_offline = s end,
            0,
            1
        )

        SimpleUI_Config_EditFrame_CreateHeaderOption(f, "Portrait")
        local portrait = SimpleUI_Config_EditFrame_CreateConfigDropDownOption(
            f,
            "Portrait Position",
            portraitAnchor,
            function() return dbPath.portrait end,
            function(s)
                dbPath.portrait = s
                globalUpdate()
            end)
        f.o[f.num - 1] = function()
            UIDropDownMenu_SetText(dbPath.portrait, portrait)
        end

        SimpleUI_Config_EditFrame_CreateHeaderOption(f, "Health")
        f.o[f.num] = SimpleUI_Config_EditFrame_CreateTexturePickerOption(
            f,
            "Health Texture",
            function() return dbPath.healthTexture end,
            function(s)
                dbPath.healthTexture = s
                globalUpdate()
            end
        )
        f.o[f.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
            f,
            "Health Width",
            function() return dbPath.width end,
            function(s)
                dbPath.width = s
                globalUpdate()
            end,
            5,
            500
        )
        f.o[f.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
            f,
            "Health Height",
            function() return dbPath.height end,
            function(s)
                dbPath.height = s
                globalUpdate()
            end,
            5,
            500
        )

        SimpleUI_Config_EditFrame_CreateHeaderOption(f, "Power")
        f.o[f.num] = SimpleUI_Config_EditFrame_CreateTexturePickerOption(
            f,
            "Mana Texture",
            function() return dbPath.manaTexture end,
            function(s)
                dbPath.manaTexture = s
                globalUpdate()
            end
        )
        f.o[f.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
            f,
            "Mana Height",
            function() return dbPath.manaheight end,
            function(s)
                dbPath.manaheight = s
                globalUpdate()
            end,
            5,
            500
        )

        SimpleUI_Config_EditFrame_CreateHeaderOption(f, "Buffs")
        local pbuffs = SimpleUI_Config_EditFrame_CreateConfigDropDownOption(
            f,
            "Position",
            bAnchor,
            function() return dbPath.buffs end,
            function(s)
                dbPath.buffs = s
                globalUpdate()
            end)
        f.o[f.num - 1] = function()
            UIDropDownMenu_SetText(dbPath.buffs, pbuffs)
        end
        f.o[f.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
            f,
            "Size",
            function()
                return dbPath.buffsize
            end,
            function(s)
                dbPath.buffsize = s
                globalUpdate()
            end, 15, 50)

        f.o[f.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
            f,
            "Max Buff Amount",
            function() return dbPath.maxBuffs end,
            function(s)
                dbPath.maxBuffs = s
                globalUpdate()
            end,
            0,
            32
        )
        f.o[f.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
            f, "Buffs Per Row",
            function() return dbPath.buffsPerRow end,
            function(s)
                dbPath.buffsPerRow = s
                globalUpdate()
            end,
            0, 32
        )

        SimpleUI_Config_EditFrame_CreateHeaderOption(f, "Debuffs")
        local pdebuffs = SimpleUI_Config_EditFrame_CreateConfigDropDownOption(
            f,
            "Position",
            bAnchor,
            function() return dbPath.debuffs end,
            function(s)
                dbPath.debuffs = s
                globalUpdate()
            end)
        f.o[f.num - 1] = function()
            UIDropDownMenu_SetText(dbPath.debuffs, pdebuffs)
        end

        f.o[f.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
            f,
            "Size",
            function() return dbPath.debuffsize end,
            function(s)
                dbPath.debuffsize = s
                globalUpdate()
            end,
            15,
            50
        )

        f.o[f.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
            f,
            "Max Debuff Amount",
            function() return dbPath.maxDebuffs end,
            function(s)
                dbPath.maxDebuffs = s
                globalUpdate()
            end, 0, 32)

        f.o[f.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
            f,
            "Debuffs Per Row",
            function()
                return dbPath.debuffsPerRow
            end,
            function(s)
                dbPath.debuffsPerRow = s
                globalUpdate()
            end,
            0,
            32
        )

        SimpleUI_Config_EditFrame_CreateHeaderOption(f, "Font")

        f.o[f.num] = SimpleUI_Config_EditFrame_CreateFontPickerOption(
            f,
            "Font Select",
            function() return dbPath.font end,
            function(s)
                dbPath.font = s
                SimpleUIEditFrames["Unitframes"].update()
            end
        )

        f.o[f.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
            f,
            "Font Size",
            function() return dbPath.fontSize end,
            function(s)
                dbPath.fontSize = s
            end,
            0,
            28
        )
    end

    for _, unit in ipairs(unitFrames) do
        createUnitFrameTab(e, unit.name, unit.config, unit.unit)
    end

    SimpleUIEditFrames["Unitframes"].update = function()
        for _, update in pairs(g.o) do
            update()
        end
        for _, frame in ipairs(unitFrames) do
            local handle = e[frame.name .. "Handle"]
            for _, update in pairs(handle.o) do
                update()
            end
        end
    end

    e:SetScript("OnShow", SimpleUIEditFrames["Unitframes"].update)
    SimpleUIEditFrames["Unitframes"].Handle:Hide()
    SimpleUIEditFrames["Unitframes"].ChildHandle.General:Hide()
    for _, unit in ipairs(unitFrames) do
        e[unit.name]:Hide()
    end
end

function SimpleUI_Config_EditPallyPower_Create()
    SimpleUIEditFrames["PallyPower"] = {}
    SimpleUIEditFrames["PallyPower"].Handle, SimpleUIEditFrames["PallyPower"].ChildHandle =
        SimpleUI_Config_EditFrame_Create(
            "PallyPower")
    local e = SimpleUIEditFrames["PallyPower"].ChildHandle

    SimpleUI_Config_EditFrame_CreateHeaderOption(e, "Pally Power Options")
    e.o[e.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
        e,
        "Scan Frequency (Seconds)",
        function() return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"].scanfreq end,
        function(s)
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"].scanfreq = s
        end,
        0,
        10
    )

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateEditNumberOption(
        e,
        "Poll Per Frame",
        function() return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"].scanperframe end,
        function(s)
            SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"].scanperframe = s
        end,
        0,
        10
    )

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(
        e,
        "Smart Buffs",
        function() return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"].smartbuffs end,
        function(s) SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"].smartbuffs = s end,
        "Smart Buffs",
        "Restricts buff selection to only allow buffs to be cast on classes that can use it"
    )

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(
        e,
        "10 Min Blessing Only",
        function() return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"].FiveMinBuff end,
        function(s) SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"].FiveMinBuff = s end,
        "10 Min Blessing Only",
        "Sets the casted buff to 10 min version, toggle off to cast greater blessings"
    )

    SimpleUI_Config_EditFrame_CreateHeaderOption(e, "Default Buff Settings")
    e.noUpdate[e.num] = SimpleUI_Config_EditFrame_CreateBlessingDropDownOption(
        e,
        "Warrior",
        1,
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"]
    )

    e.noUpdate[e.num] = SimpleUI_Config_EditFrame_CreateBlessingDropDownOption(
        e,
        "Rogue",
        2,
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"]
    )

    e.noUpdate[e.num] = SimpleUI_Config_EditFrame_CreateBlessingDropDownOption(
        e,
        "Priest",
        3,
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"]
    )

    e.noUpdate[e.num] = SimpleUI_Config_EditFrame_CreateBlessingDropDownOption(
        e,
        "Druid",
        4,
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"]
    )

    e.noUpdate[e.num] = SimpleUI_Config_EditFrame_CreateBlessingDropDownOption(
        e,
        "Paladin",
        5,
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"]
    )

    e.noUpdate[e.num] = SimpleUI_Config_EditFrame_CreateBlessingDropDownOption(
        e,
        "Hunter",
        6,
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"]
    )

    e.noUpdate[e.num] = SimpleUI_Config_EditFrame_CreateBlessingDropDownOption(
        e,
        "Mage",
        7,
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"]
    )

    e.noUpdate[e.num] = SimpleUI_Config_EditFrame_CreateBlessingDropDownOption(
        e,
        "Warlock",
        8,
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"]
    )

    e.noUpdate[e.num] = SimpleUI_Config_EditFrame_CreateBlessingDropDownOption(
        e,
        "Shaman",
        9,
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"]
    )

    e.noUpdate[e.num] = SimpleUI_Config_EditFrame_CreateBlessingDropDownOption(
        e,
        "Pet",
        10,
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"]
    )

    SimpleUIEditFrames["PallyPower"].update = function()
        for _, update in pairs(e.o) do
            update()
        end
    end

    e:SetScript("OnShow", SimpleUIEditFrames["PallyPower"].update)
    SimpleUIEditFrames["PallyPower"].Handle:Hide()
end

function SimpleUI_Config_EditModules_Create()
    SimpleUIEditFrames["Modules"] = {}
    SimpleUIEditFrames["Modules"].Handle, SimpleUIEditFrames["Modules"].ChildHandle =
        SimpleUI_Config_EditFrame_Create(
            "Modules")
    local e = SimpleUIEditFrames["Modules"].ChildHandle

    SimpleUI_Config_EditFrame_CreateHeaderOption(e, "Select the modules that you want to disable")

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "Actionbar", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Actionbar
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Actionbar = s
    end, "Actionbar", "Compact actionbar system")

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "Cooldown", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Cooldown
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Cooldown = s
    end, "Cooldown", "Toggles cooldown numbers on buff / debuff")

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "Unitframes", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Unitframes
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Unitframes = s
    end, "Unitframes", "Toggle the player, target, targettarget, pet, party")

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "Micromenu", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Micromenu
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Micromenu = s
    end, "Micromenu", "Custom Micromenu bar")

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "Minimap", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Minimap
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Minimap = s
    end, "Minimap", "Square Minimap and Button Collection")

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "Wonderbar", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Wonderbar
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Wonderbar = s
    end, "Wonderbar", "Wonderbar info panel")

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "DarkUI", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.DarkUI = s
    end, "DarkUI", "Darkens the elements of the user interface")

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "Castbar", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Castbar
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.Castbar = s
    end, "Castbar", "Player and Target castbars")

    e.o[e.num] = SimpleUI_Config_EditFrame_CreateCheckBoxOption(e, "PallyPower", function()
        return SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.PallyPower
    end, function(s)
        SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled.PallyPower = s
    end, "PallyPower", "Enable SimpleUIs upgraded pallypower.. Credits: Sneakyfoot, Relar")

    SimpleUIEditFrames["Modules"].update = function()
        for _, update in pairs(e.o) do
            update()
        end
    end

    e:SetScript("OnShow", SimpleUIEditFrames["Modules"].update)
    SimpleUIEditFrames["Modules"].Handle:Hide()
end

GameMenuFrame:SetWidth(GameMenuFrame:GetWidth() + 20)
GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 10)
local advanced = CreateFrame("Button", "GameMenuButtonSimpleUI", GameMenuFrame, "GameMenuButtonTemplate")
advanced:SetPoint("TOP", GameMenuButtonContinue, "BOTTOM", 0, -1)
advanced:SetText("Simple:UI" .. "|cffffff00*")
advanced:SetScript("OnClick", function()
    HideUIPanel(GameMenuFrame)
    SimpleUI_Config_Window_Toggle()
end)
--GameMenuButtonKeybindings:ClearAllPoints()
--GameMenuButtonKeybindings:SetPoint("TOP", advanced, "BOTTOM", 0, -1)

GameMenuButtonContinue:ClearAllPoints()
GameMenuButtonContinue:SetPoint("TOP", GameMenuButtonQuit, "BOTTOM", 0, -1)

GameMenuFrame:SetBackdrop({
    bgFile = SimpleUI_GetTexture("RockBg"),
    tile = false,
    tileSize = 0,
    edgeFile = SimpleUI_GetTexture("ThickBorder"),
    edgeSize = 14,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
})

local frame = GameMenuFrame
local a, b, c, d, e, f, g = frame:GetRegions()
for i, v in ipairs({ a, b }) do
    v:Hide()
end

GameMenuFrame.title = CreateFrame("Frame", nil, GameMenuFrame)
GameMenuFrame.title:SetWidth(GameMenuFrame:GetWidth() - 40)
GameMenuFrame.title:SetHeight(40)
GameMenuFrame.title:SetPoint("CENTER", GameMenuFrame, "TOP", 0, 0)
GameMenuFrame.title:SetBackdrop({
    bgFile = SimpleUI_GetTexture("RockBg"),
    tile = false,
    tileSize = 0,
    edgeFile = SimpleUI_GetTexture("ThickBorder"),
    edgeSize = 14,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
})

GameMenuFrame.title.text = GameMenuFrame.title:CreateFontString(nil, "OVERLAY")
GameMenuFrame.title.text:SetFontObject(SimpleUIFont)
GameMenuFrame.title.text:SetPoint("CENTER", GameMenuFrame.title, "CENTER", 0, 0)
GameMenuFrame.title.text:SetText("Game Menu v.2")
