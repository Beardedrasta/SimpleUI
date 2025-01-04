--[[ 
SimpleUI Tooltip Scanner for WoW Vanilla 1.12 - Turtle WoW
Author: BeardedRasta
Description: A tooltip scanning utility for extracting and analyzing tooltip text and attributes.
--]]

-- Setup Environments
local U = SimpleUI.Util;
local _G = getfenv(0)
local u = SUI_Util

-- Ensure only a single instance of the scanner is created
if u.TipScan then
    return
end

-- Tooltip Scanner Initialization ----------------------------------------------------------------------------------
local TipScan = {};
local scannerName = "SimpleUI_Scanner";

-- Tooltip Methods
local tooltipMethods = {
    "SetBagItem", "SetAction", "SetAuctionItem", "SetAuctionSellItem", "SetBuybackItem",
    "SetCraftItem", "SetCraftSpell", "SetHyperlink", "SetInboxItem", "SetInventoryItem",
    "SetLootItem", "SetLootRollItem", "SetMerchantItem", "SetPetAction", "SetPlayerBuff",
    "SetQuestItem", "SetQuestLogItem", "SetQuestRewardSpell", "SetSendMailItem", "SetShapeshift",
    "SetSpell", "SetTalent", "SetTrackingSpell", "SetTradePlayerItem", "SetTradeSkillItem", "SetTradeTargetItem",
    "SetTrainerService", "SetUnit", "SetUnitBuff", "SetUnitDebuff",
}

-- Extra Methods for Text Analysis
local extraMethods = {
    "Find", "Line", "Text", "List",
};

-- Utility Functions ------------------------------------------------------------------------------------------------

--local round = U.round;
--local rgbhex = U.rgbhex;

-- Extracts all visible text from a tooltip and returns it as a formatted string
local getFontString = function(obj)
    local name = obj:GetName()
    local text
--[[     local r, g, b, color, a
    local text, segment ]]

    for i = 1, obj:NumLines() do
        local left = _G[string.format("%sTextLeft%d", name, i)]
        if left and left:IsVisible() then
            local r, g, b = left:GetTextColor()
            local segment = left:GetText()
            if segment and segment ~= "" then
                segment = U.rgbhex(r, g, b) .. segment .. "|r"
                text = text and text .. "\n" .. segment or segment
            end
        end
    end
    return text
end

-- Extracts raw text from tooltip lines and returns a table of left/right text pairs
local getText = function(obj)
    local name = obj:GetName()
    local text = {}
    for i = 1, obj:NumLines() do
        local left = _G[string.format("%sTextLeft%d", name, i)]
        local right = _G[string.format("%sTextRight%d", name, i)]
        text[i] = {
            left and left:IsVisible() and left:GetText() or nil,
            right and right:IsVisible() and right:GetText() or nil,
        }
    end
    return text
end

-- Searches for specific text within the tooltip
local findText = function(obj, searchText, exact)
    local name = obj:GetName()
    for i = 1, obj:NumLines() do
        local left, right = _G[string.format("%sTextLeft%d", name, i)], _G[string.format("%sTextRight%d", name, i)]
        left = left and left:IsVisible() and left:GetText()
        right = right and right:IsVisible() and right:GetText()
        if exact then
            if (left and left == searchText) or (right and right == searchText) then
                return i, searchText
            end
        else
            if left then
                local found, _, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10 = string.find(left, searchText)
                if found then
                    return i, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10
                end
            end
            if right then
                local found, _, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10 = string.find(right, searchText)
                if found then
                    return i, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10
                end
            end
        end
    end
end

-- Retrieves the text of a specific tooltip line
local lineText = function(obj, line)
    local name = obj:GetName()
    if line <= obj:NumLines() then
        local left = _G[string.format("%sTextLeft%d", name, line)]
        local right = _G[string.format("%sTextRight%d", name, line)]
        return left and left:GetText(), right and right:GetText()
    end
end

-- Finds a line by text color in the tooltip
local findColor = function(obj, r, g, b)
    if type(r) == "table" then
        r, g, b = r[1], r[2], r[3]
    end
    local name = obj:GetName()
    for i = 1, obj:NumLines() do
        for _, field in ipairs({
            _G[string.format("%sTextLeft%d", name, i)],
            _G[string.format("%sTextRight%d", name, i)],
        }) do
            if field and field:IsVisible() then
                local tr, tg, tb = field:GetTextColor()
                if math.abs(tr - r) < 0.01 and math.abs(tg - g) < 0.01 and math.abs(tb - b) < 0.01 then
                    return i
                end
            end
        end
    end
end

-- Tooltip Scanner Methods ------------------------------------------------------------------------------------------------

-- Registers and initializes tooltip scanners dynamically
TipScan._registry = setmetatable({}, {
    __index = function(t, k)
        local tooltip = CreateFrame("GameTooltip", string.format("%s%s", scannerName, k), nil, "GameTooltipTemplate")
        tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

        -- Attach utility methods
        function tooltip:Text() return getText(self) end
        function tooltip:FontString() return getFontString(self) end
        function tooltip:Find(text, exact) return findText(self, text, exact) end
        function tooltip:Color(r, g, b) return findColor(self, r, g, b) end
        function tooltip:Line(line) return lineText(self, line) end
        function tooltip:List()
            for _, method in ipairs(tooltipMethods) do print(method) end
            for _, method in ipairs(extraMethods) do print(method) end
        end

        -- Override existing tooltip methods to reset before use
        for _, method in ipairs(tooltipMethods) do
            local old = tooltip[method]
            tooltip[method] = function(self, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
                self:ClearLines()
                self:SetOwner(WorldFrame, "ANCHOR_NONE")
                return old(self, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            end
        end

        rawset(t, k, tooltip)
        return tooltip
    end
})

-- Returns a scanner by type and clears its lines for fresh usage
function TipScan:GetScanner(type)
    local scanner = self._registry[type]
    scanner:ClearLines()
    return scanner
end

function TipScan:List()
    for name in pairs(self._registry) do
        print(name)
    end
end

u.TipScan = TipScan
