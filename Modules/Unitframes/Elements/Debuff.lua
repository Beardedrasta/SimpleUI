local e = SimpleUI.Element
local u = SUI_Util
local PLAYER_BUFF_START_ID = -1
local maxdurations = {}
-----------------------------------------------
-- Debuff Functions
-----------------------------------------------
function e.Debuff_OnUpdate()
    if (this.tick or 1) > GetTime() then return end
    this.tick = GetTime() + 0.2

    local timeLeft = GetPlayerBuffTimeLeft(GetPlayerBuff(PLAYER_BUFF_START_ID + this.id, "HARMFUL"))
    local texture = GetPlayerBuffTexture(GetPlayerBuff(PLAYER_BUFF_START_ID + this.id, "HARMFUL"))
    local start = 0
    if timeLeft > 0 then
        if not maxdurations[texture] then
            maxdurations[texture] = timeLeft
        elseif maxdurations[texture] and maxdurations[texture] < timeLeft then
            maxdurations[texture] = timeLeft
        end
        start = GetTime() + timeLeft - maxdurations[texture]
    end
    CooldownFrame_SetTimer(this.cd, start, maxdurations[texture], timeLeft > 0 and 1 or 0)
end

function e.Debuff_OnEnter()
    local parent = this:GetParent()
    if not parent.label then return end

    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
    if parent.label == "player" then
        GameTooltip:SetPlayerBuff(GetPlayerBuff(PLAYER_BUFF_START_ID + this.id, "HARMFUL"))
    else
        GameTooltip:SetUnitDebuff(parent.label .. parent.id, this.id)
    end
    u.SetSize(this, parent.config.debuffsize + 2, parent.config.debuffsize + 2)
end

function e.Debuff_OnLeave()
    local parent = this:GetParent()
    GameTooltip:Hide()
    u.SetSize(this, parent.config.debuffsize, parent.config.debuffsize)
end


function e.Debuff_OnClick()
    if this:GetParent().label == "player" then
        CancelPlayerBuff(GetPlayerBuff(PLAYER_BUFF_START_ID + this.id, "HARMFUL"))
    end
end
