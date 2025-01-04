local relocator = SimpleUI.movables
local _G = getfenv(0)
local u = SUI_Util

local floor = math.floor;

local groupedFrames = {
    { "SimpleUIraid",  40, 5 },
    { "SimpleUIgroup", 4 },
}

local anchorPoint = {
    "TOPLEFT", "TOP", "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "BOTTOM", "BOTTOMLEFT", "LEFT", "CENTER"
}

local selector = CreateFrame("Frame", "SUIUnlockSelection", UIParent)
selector:Hide()

local function GetFrames()
    local frame = this.frame
    local frames = { frame }

    if IsShiftKeyDown() or IsControlKeyDown() then
        for id, cluster in pairs(groupedFrames) do
            local len = strlen(cluster[1])
            if strsub(frame:GetName(), 0, len) == cluster[1] then
                if IsShiftKeyDown() and cluster[2] then
                    for i = 1, cluster[2] do
                        if _G[cluster[1] .. i] ~= frame then
                            table.insert(frames, _G[cluster[1] .. i])
                        end
                    end
                elseif IsControlKeyDown() and cluster[3] then
                    local id = tonumber(strsub(frame:GetName(), len + 1, len + 2))
                    local b = 1
                    for i = cluster[3] + 1, cluster[2], cluster[3] do
                        b = (id >= i) and i or b
                    end

                    for i = b, b + cluster[3] - 1 do
                        if _G[cluster[1] .. i] ~= frame then
                            table.insert(frame, _G[cluster[1] .. i])
                        end
                    end
                end
            end
        end
    end
    return frames
end

local function DraggerOnUpdate()
    this.text:SetAlpha(this.text:GetAlpha() - 0.05)
    if this.text:GetAlpha() < 0.1 then
        this.text:SetText(strsub(this:GetParent():GetName(), 3))
        this.text:SetAlpha(1)
        this:SetScript("OnUpdate", function() return end)
    end
end

local function SaveScale(frame, scale)
    frame:SetScale(scale)

    if not SimpleUIDB.position[frame:GetName()] then
        SimpleUIDB.position[frame:GetName()] = {}
    end

    SimpleUIDB.position[frame:GetName()]["scale"] = scale
    frame.drag.text:SetText("Scale: " .. scale)
    frame.drag.text:SetAlpha(1)
    frame.drag:SetScript("OnUpdate", DraggerOnUpdate)
end

local function SavePosition(frame)
    u.SaveRelocator(frame)
    u.UpdateMovable(frame)
end

local function DrawGrid()
    local grid = CeateFrame("Frame", this:GetName() .. "Grid", UIParent)
    grid:SetAllPoints(this)

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

    for i = 1, floor(height / hStep) do
        if i == floor(height / hStep / 2) then
            line = grid:CreateTexture(nil, 'BORDER')
            line:SetTexture(.1, .5, .4)
        else
            line = grid:CreateTexture(nil, 'BACKGROUND')
            line:SetTexture(0, 0, 0)
        end

        line:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -(i * hStep) + (size / 2))
        line:SetPoint('BOTTOMRIGHT', grid, 'TOPRIGHT', 0, -(i * hStep + size / 2))
    end

    return grid
end

DrawGrid()
