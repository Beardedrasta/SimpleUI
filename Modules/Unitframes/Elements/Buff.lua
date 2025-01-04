local e = SimpleUI.Element
local u = SUI_Util

-----------------------------------------------
-- Utility: Buff Timer Setup
-----------------------------------------------

local PLAYER_BUFF_START_ID = -1
local maxdurations = {}
function e.Buff_OnUpdate()
    if (this.tick or 1) > GetTime() then return end
    this.tick = GetTime() + 0.2

    local buffId = PLAYER_BUFF_START_ID + this.id
    local timeleft = GetPlayerBuffTimeLeft(GetPlayerBuff(buffId, "HELPFUL"))
    local texture = GetPlayerBuffTexture(GetPlayerBuff(buffId, "HELPFUL"))
    local start = 0

    if timeleft > 0 then
        if not maxdurations[texture] then
            maxdurations[texture] = timeleft
        elseif maxdurations[texture] and maxdurations[texture] < timeleft then
            maxdurations[texture] = timeleft
        end
        start = GetTime() + timeleft - maxdurations[texture]
    end
    CooldownFrame_SetTimer(this.cd, start, maxdurations[texture], timeleft > 0 and 1 or 0)
end

function e.Buff_OnEnter()
    local parent = this:GetParent()
    if not parent.label then return end

    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
    if parent.label == "player" then
        GameTooltip:SetPlayerBuff(GetPlayerBuff(PLAYER_BUFF_START_ID + this.id, "HELPFUL"))
    else
        GameTooltip:SetUnitBuff(parent.label .. parent.id, this.id)
    end

    u.SetSize(this, parent.config.buffsize + 2, parent.config.buffsize + 2)

    if IsShiftKeyDown() then
        local texture = parent.label == "player" and
            GetPlayerBuffTexture(GetPlayerBuff(PLAYER_BUFF_START_ID + this.id, "HELPFUL")) or
            UnitBuff(parent.label .. parent.id, this.id)
        local playerlist = ""
        local first = true

        if UnitInRaid("player") then
            for i = 1, 40 do
                local unitstr = "raid" .. i
                if not u.UnitHasBuff(unitstr, texture) and UnitName(unitstr) then
                    playerlist = playerlist ..
                        (not first and ", " or "") .. GetUnitColor(unitstr) .. UnitName(unitstr) .. "|r"
                    first = false
                end
            end
        else
            if not u.UnitHasBuff("player", texture) then
                playerlist = playerlist ..
                    (not first and ", " or "") .. GetUnitColor("player") .. UnitName("player") .. "|r"
                first = false
            end

            for i = 1, 4 do
                local unitstr = "party" .. i
                if not u.UnitHasBuff(unitstr, texture) and UnitName(unitstr) then
                    playerlist = playerlist ..
                        (not first and ", " or "") .. GetUnitColor(unitstr) .. UnitName(unitstr) .. "|r"
                    first = false
                end
            end
        end

        if strlen(playerlist) > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Unbuffed:", .3, 1, .8)
            GameTooltip:AddLine(playerlist, 1, 1, 1, 1)
            GameTooltip:Show()
        end
    end
end

function e.Buff_OnLeave()
    local parent = this:GetParent()
    GameTooltip:Hide()
    u.SetSize(this, parent.config.buffsize, parent.config.buffsize)
end

function e.Buff_OnClick()
    if this:GetParent().label == "player" then
        CancelPlayerBuff(GetPlayerBuff(PLAYER_BUFF_START_ID + this.id, "HELPFUL"))
    end
end
