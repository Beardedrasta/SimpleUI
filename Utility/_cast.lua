local _G = getfenv(0);
local u = SUI_Util

if u.cast then return end

local lastCastTex
local lastRank
local _
local scanner = u.TipScan:GetScanner("cast")
local casting = CreateFrame("Frame", "SimpleUIHostileCast")
local p = UnitName("player")

UnitChannelInfo = _G.UnitChannelInfo or function(unit)
    unit = u.SimpleUIValidUnits[unit] and UnitName(unit) or unit

    local cast
    local nameSubtext
    local text
    local texture
    local startTime
    local endTime
    local isTradeSkill
    local DB = casting.db[unit]

    if DB and DB.cast and DB.start + DB.casttime / 1000 > GetTime() then
        if not DB.channel then return end
        cast = DB.cast
        nameSubtext = DB.rank
        text = ""
        texture = DB.icon
        startTime = DB.start * 1000
        endTime = startTime + DB.casttime
        isTradeSkill = nil
    elseif DB then
        DB.cast = nil
        DB.rank = nil
        DB.start = nil
        DB.casttime = nil
        DB.icon = nil
        DB.channel = nil
    end
    return cast, nameSubtext, text, texture, startTime, endTime, isTradeSkill
end

UnitCastingInfo = _G.UnitCastingInfo or function(unit)
    unit = u.SimpleUIValidUnits[unit] and UnitName(unit) or unit

    local cast
    local nameSubtext
    local text
    local texture
    local startTime
    local endTime
    local isTradeSkill
    local DB = casting.db[unit]

    -- clean legacy values
    if DB and DB.cast and DB.start + DB.casttime / 1000 > GetTime() then
        if DB.channel then return end
        cast = DB.cast
        nameSubtext = DB.rank or ""
        text = ""
        texture = DB.icon
        startTime = DB.start * 1000
        endTime = startTime + DB.casttime
        isTradeSkill = nil
    elseif DB then
        DB.cast = nil
        DB.rank = nil
        DB.start = nil
        DB.casttime = nil
        DB.icon = nil
        DB.channel = nil
    end
    return cast, nameSubtext, text, texture, startTime, endTime, isTradeSkill
end

function casting:AddAction(mob, spell, channel)
    if not mob or not spell then return nil end

    if SimpleUI_Spells["spells"][spell] ~= nil then
        local casttime = SimpleUI_Spells["spells"][spell].t
        local icon = SimpleUI_Spells["spells"][spell].icon and
            string.format("%s%s", "Interface\\Icons\\", SimpleUI_Spells["spells"][spell].icon) or
            nil

        if not self.db[mob] then self.db[mob] = {} end
        self.db[mob].cast = spell
        self.db[mob].rank = nil
        self.db[mob].start = GetTime()
        self.db[mob].casttime = casttime
        self.db[mob].icon = icon
        self.db[mob].channel = channel

        return true
    end
    return nil
end

function casting:RemoveAction(mob, spell)
    if self.db[mob] and (SimpleUI_Interupts["interrupts"][spell] ~= nil or spell == "INTERRUPT") then
        self.db[mob].cast = nil
        self.db[mob].rank = nil
        self.db[mob].start = nil
        self.db[mob].casttime = nil
        self.db[mob].icon = nil
        self.db[mob].channel = nil
    end
end

casting.db = { [p] = {} }

casting:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
casting:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
casting:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
casting:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")
casting:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
casting:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")
casting:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")
casting:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
casting:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE")
casting:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
casting:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE")
casting:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
casting:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE")
casting:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS")
casting:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
casting:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS")
casting:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
casting:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF")
casting:RegisterEvent("SPELLCAST_START")
casting:RegisterEvent("SPELLCAST_STOP")
casting:RegisterEvent("SPELLCAST_FAILED")
casting:RegisterEvent("SPELLCAST_INTERRUPTED")
casting:RegisterEvent("SPELLCAST_DELAYED")
casting:RegisterEvent("SPELLCAST_CHANNEL_START")
casting:RegisterEvent("SPELLCAST_CHANNEL_STOP")
casting:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")

local mob, spell, icon, _
casting:SetScript("OnEvent", function()
    if event == "SPELLCAST_START" then
        icon = SimpleUI_Spells["spells"][arg1] and SimpleUI_Spells["spells"][arg1].icon and
            string.format("%s%s", "Interface\\Icons\\", SimpleUI_Spells["spells"][arg1].icon) or lastCastTex
        this.db[p].cast = arg1
        this.db[p].rank = lastRank
        this.db[p].start = GetTime()
        this.db[p].casttime = arg2
        this.db[p].icon = icon
        this.db[p].channel = nil
        if not SimpleUI_Spells["spells"][arg1] or not SimpleUI_Spells["spells"][arg1].icon or not SimpleUI_Spells["spells"][arg1].t then
            SimpleUI_Spells["spells"][arg1] = SimpleUI_Spells["spells"][arg1] or {}
            SimpleUI_Spells["spells"][arg1].icon = SimpleUI_Spells["spells"][arg1].icon or icon
            SimpleUI_Spells["spells"][arg1].t = SimpleUI_Spells["spells"][arg1].t or arg2
        end
        lastCastTex, lastRank = nil, nil
    elseif event == "SPELLCAST_STOP" or event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
        if this.db[p] and not this.db[p].channel then
            this.db[p].cast = nil
            this.db[p].rank = nil
            this.db[p].rank = nil
            this.db[p].start = nil
            this.db[p].casttime = nil
            this.db[p].icon = nil
            this.db[p].channel = nil
        else
            lastCastTex, lastRank = nil, nil
        end
    elseif event == "SPELLCAST_DELAYED" then
        if this.db[p].cast then
            this.db[p].start = this.db[p].start + arg1 / 1000
        end
    elseif event == "SPELLCAST_CHANNEL_START" then
        this.db[p].cast = arg2
        this.db[p].rank = lastRank
        this.db[p].start = GetTime()
        this.db[p].casttime = arg1
        this.db[p].icon = SimpleUI_Spells["spells"][arg2] and SimpleUI_Spells["spells"][arg2].icon and
            string.format("%s%s", "Interface\\Icons\\", SimpleUI_Spells["spells"][arg2].icon) or lastCastTex
        this.db[p].channel = true
        lastCastTex, lastRank = nil, nil
    elseif event == "SPELLCAST_CHANNEL_STOP" then
        if this.db[p] and this.db[p].channel then
            this.db[p].cast = nil
            this.db[p].rank = nil
            this.db[p].start = nil
            this.db[p].casttime = nil
            this.db[p].icon = nil
            this.db[p].channel = nil
        end
    elseif event == "SPELLCAST_CHANNEL_UPDATE" then
        if this.db[p].cast then
            this.db[p].start = -this.db[p].casttime / 1000 + GetTime() + arg1 / 1000
        end
    elseif arg1 then
        mob, spell = u.Cmatch(arg1, SPELLCASTOTHERSTART)
        if casting:AddAction(mob, spell) then return end

        mob, spell = u.Cmatch(arg1, SPELLPERFORMOTHERSTART)
        if casting:AddAction(mob, spell) then return end

        mob, spell = u.Cmatch(arg1, AURAADDEDOTHERHELPFUL)
        if casting:RemoveAction(mob, spell) then return end

        mob, spell = u.Cmatch(arg1, AURAADDEDOTHERHARMFUL)
        if casting:RemoveAction(mob, spell) then return end

        spell, mob = u.Cmatch(arg1, SPELLLOGSELFOTHER)
        if casting:RemoveAction(mob, spell) then return end

        spell, mob = u.Cmatch(arg1, SPELLLOGCRITSELFOTHER)
        if casting:RemoveAction(mob, spell) then return end

        _, spell, mob = u.Cmatch(arg1, SPELLLOGOTHEROTHER)
        if casting:RemoveAction(mob, spell) then return end

        _, spell, mob = u.Cmatch(arg1, SPELLLOGCRITOTHEROTHER)
        if casting:RemoveAction(mob, spell) then return end

        mob, _ = u.Cmatch(arg1, SPELLINTERRUPTSELFOTHER)
        if casting:RemoveAction(mob, "INTERRUPT") then return end

        _, mob, _ = u.Cmatch(arg1, SPELLINTERRUPTOTHEROTHER)
        if casting:RemoveAction(mob, "INTERRUPT") then return end
    end
end)


local as = "Aimed Shot"
local ms = "Multi-Shot"

casting.customCast = {}
casting.customCast[strlower(as)] = function(begin, duration)
    if begin then
        local d = duration or 3000
        for i = 1, 32 do
            if UnitBuff("player", i) == "Interface\\Icons\\Racial_Troll_Berserk" then
                local b = 0.3
                if ((UnitHealth("player") / UnitHealthMax("player")) >= 0.40) then
                    b = (1.30 - (UnitHealth("player") / UnitHealthMax("player"))) / 3
                end
                d = d / (1 + b)
            elseif UnitBuff("player", i) == "Interface\\Icons\\Ability_Hunter_RunningShot" then
                d = d / 1.4
            elseif UnitBuff("player", i) == "Interface\\Icons\\Ability_Warrior_InnerRage" then
                d = d / 1.3
            elseif UnitBuff("player", i) == "Interface\\Icons\\Inv_Trinket_Naxxramas04" then
                d = d / 1.2
            end
        end

        local _, _, lag = GetNetStats()
        local start = GetTime() + lag / 1000

        casting.db[p].cast = as
        casting.db[p].rank = lastRank
        casting.db[p].start = start
        casting.db[p].casttime = d
        casting.db[p].icon = "Interface\\Icons\\Inv_spear_07"
        casting.db[p].channel = nil
    else
        casting.db[p].cast = nil
        casting.db[p].rank = nil
        casting.db[p].start = nil
        casting.db[p].casttime = nil
        casting.db[p].icon = nil
        casting.db[p].channel = nil
    end
end

casting.customCast[strlower(ms)] = function(begin, duration)
    if begin then
        local d = duration or 500

        for i = 1, 32 do
            if UnitBuff("player", i) == "Interface\\Icons\\Racial_Troll_Berserk" then
                local b = 0.3
                if ((UnitHealth("player") / UnitHealthMax("player")) >= 0.40) then
                    b = (1.30 - (UnitHealth("player") / UnitHealthMax("player"))) / 3
                end
                d = d / (1 + b)
            elseif UnitBuff("player", i) == "Interface\\Icons\\Ability_Hunter_RunningShot" then
                d = d / 1.4
            elseif UnitBuff("player", i) == "Interface\\Icons\\Ability_Warrior_InnerRage" then
                d = d / 1.3
            elseif UnitBuff("player", i) == "Interface\\Icons\\Inv_Trinket_Naxxramas04" then
                d = d / 1.2
            end
        end

        local _, _, lag = GetNetStats()
        local start = GetTime() + lag / 1000

        casting.db[p].cast = ms
        casting.db[p].rank = lastRank
        casting.db[p].start = start
        casting.db[p].casttime = d
        casting.db[p].icon = "Interface\\Icons\\Ability_upgrademoonglaive"
        casting.db[p].channel = nil
    else
        casting.db[p].cast = nil
        casting.db[p].rank = nil
        casting.db[p].start = nil
        casting.db[p].casttime = nil
        casting.db[p].icon = nil
        casting.db[p].channel = nil
    end
end

local function CastCustom(id, bookType, rawSpellName, rank, texture, castingTime)
    if not id or not rawSpellName or not castingTime then
        return
    end
    lastRank = rank
    lastCastTex = texture
    local func = cast.customCast[strlower(rawSpellName)]
    if not func then
        return
    end
    if GetSpellCooldown(id, bookType) == 0 or UnitCastingInfo(p) then
        return
    end
    func(true)
end

u.Hooksecurefunc("UseContainerItem", function(id, index)
    lastCastTex = GetContainerItemInfo(id, index)
end)

u.Hooksecurefunc("CastSpell", function(id, bookType)
    --[[     local cachedRawSpellName, cachedRank, cachedTexture, cachedCastingTime, _, _, cachedSpellId, cachedBookType =
    U.spell.GetSpellInfo(id, bookType)

    CastCustom(cachedSpellId, cachedBookType, cachedRawSpellName, cachedRank, cachedTexture, cachedCastingTime) ]]
end, true)

u.Hooksecurefunc("CastSpellByName", function(spellCasted, target)
    --[[     local cachedRawSpellName, cachedRank, cachedTexture, cachedCastingTime, _, _, cachedSpellId, cachedBookType =
    U.spell.GetSpellInfo(spellCasted)

    CastCustom(cachedSpellId, cachedBookType, cachedRawSpellName, cachedRank, cachedTexture, cachedCastingTime) ]]
end, true)

u.Hooksecurefunc("UseAction", function(slot, target, button)
    if GetActionText(slot) or not IsCurrentAction(slot) then return end

    scanner:SetAction(slot)
    local rawSpellName, rank = scanner:Line(1)
    if not rawSpellName then return end -- ignore if the spell is not found

--[[     local cachedRawSpellName, cachedRank, cachedTexture, cachedCastingTime, _, _, cachedSpellId, cachedBookType =
    libspell.GetSpellInfo(rawSpellName .. (rank and ("(" .. rank .. ")") or ""))

    CastCustom(cachedSpellId, cachedBookType, cachedRawSpellName, cachedRank, cachedTexture, cachedCastingTime) ]]
end, true)

u.cast = casting