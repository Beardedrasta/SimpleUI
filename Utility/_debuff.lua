local E = SimpleUI.Element
local _G = getfenv(0)
local u = SUI_Util
if E.libdebuff then return end

local libdebuff = _G["SimpleUIdebuffsScanner"]
local scanner = u.TipScan:GetScanner("libdebuff")
local _, class = UnitClass("player")
local lastspell

function libdebuff:GetDuration(effect, rank)
  if SimpleUI_AuraList.debuffs[effect] then
    local rank = rank and tonumber((string.gsub(rank, RANK, ""))) or 0
    local rank = SimpleUI_AuraList.debuffs[effect][rank] and rank or libdebuff:GetMaxRank(effect)
    local duration = SimpleUI_AuraList.debuffs[effect][rank]

    if effect == SimpleUI_AuraList.dyndebuffs["Rupture"] then
      -- Rupture: +2 sec per combo point
      duration = duration + GetComboPoints()*2
    elseif effect == SimpleUI_AuraList.dyndebuffs["Kidney Shot"] then
      -- Kidney Shot: +1 sec per combo point
      duration = duration + GetComboPoints()*1
    elseif effect == SimpleUI_AuraList.dyndebuffs["Demoralizing Shout"] then
      -- Booming Voice: 10% per talent
      local _,_,_,_,count = GetTalentInfo(2,1)
      if count and count > 0 then duration = duration + ( duration / 100 * (count*10)) end
    elseif effect == SimpleUI_AuraList.dyndebuffs["Shadow Word: Pain"] then
      -- Improved Shadow Word: Pain: +3s per talent
      local _,_,_,_,count = GetTalentInfo(3,4)
      if count and count > 0 then duration = duration + count * 3 end
    elseif effect == SimpleUI_AuraList.dyndebuffs["Frostbolt"] then
      -- Permafrost: +1s per talent
      local _,_,_,_,count = GetTalentInfo(3,7)
      if count and count > 0 then duration = duration + count end
    elseif effect == SimpleUI_AuraList.dyndebuffs["Gouge"] then
      -- Improved Gouge: +.5s per talent
      local _,_,_,_,count = GetTalentInfo(2,1)
      if count and count > 0 then duration = duration + (count*.5) end
    end
    return duration
  else
    return 0
  end
end

function libdebuff:UpdateDuration(unit, unitlevel, effect, duration)
  if not unit or not effect or not duration then return end
  unitlevel = unitlevel or 0

  if libdebuff.objects[unit] and libdebuff.objects[unit][unitlevel] and libdebuff.objects[unit][unitlevel][effect] then
    libdebuff.objects[unit][unitlevel][effect].duration = duration
  end
end

function libdebuff:GetMaxRank(effect)
  local max = 0
  for id in pairs(SimpleUI_AuraList.debuffs[effect]) do
    if id > max then max = id end
  end
  return max
end

function libdebuff:UpdateUnits()
    if not SimpleUI.Unitframe or not SimpleUI.Unitframe.target then return end
    SimpleUI.Unitframe:RefreshUnits(SimpleUI.Unitframe.target, "aura")
end

function libdebuff:AddPending(unit, unitlevel, effect, duration)
  if not unit or duration <= 0 then return end
  if not SimpleUI_AuraList.debuffs[effect] or libdebuff.pending[3] == effect then return end

  libdebuff.pending[1] = unit
  libdebuff.pending[2] = unitlevel or 0
  libdebuff.pending[3] = effect
  libdebuff.pending[4] = duration -- or libdebuff:GetDuration(effect)
end

function libdebuff:RemovePending()
  libdebuff.pending[1] = nil
  libdebuff.pending[2] = nil
  libdebuff.pending[3] = nil
  libdebuff.pending[4] = nil
end

function libdebuff:PersistPending(effect)
  if not libdebuff.pending[3] then return end
  if libdebuff.pending[3] == effect or ( effect == nil and libdebuff.pending[3] ) then
    libdebuff:AddEffect(libdebuff.pending[1], libdebuff.pending[2], libdebuff.pending[3], libdebuff.pending[4])
    libdebuff:RemovePending()
  end
end

function libdebuff:RevertLastAction()
  lastspell.start = lastspell.start_old
  lastspell.start_old = nil
  libdebuff:UpdateUnits()
end

function libdebuff:AddEffect(unit, unitlevel, effect, duration)
  if not unit or not effect then return end
  unitlevel = unitlevel or 0
  if not libdebuff.objects[unit] then libdebuff.objects[unit] = {} end
  if not libdebuff.objects[unit][unitlevel] then libdebuff.objects[unit][unitlevel] = {} end
  if not libdebuff.objects[unit][unitlevel][effect] then libdebuff.objects[unit][unitlevel][effect] = {} end

  -- save current effect as lastspell
  lastspell = libdebuff.objects[unit][unitlevel][effect]

  libdebuff.objects[unit][unitlevel][effect].effect = effect
  libdebuff.objects[unit][unitlevel][effect].start_old = libdebuff.objects[unit][unitlevel][effect].start
  libdebuff.objects[unit][unitlevel][effect].start = GetTime()
  libdebuff.objects[unit][unitlevel][effect].duration = duration or libdebuff:GetDuration(effect)

  libdebuff:UpdateUnits()
end


-- Remove Pending
libdebuff.rp = { SPELLIMMUNESELFOTHER, IMMUNEDAMAGECLASSSELFOTHER,
  SPELLMISSSELFOTHER, SPELLRESISTSELFOTHER, SPELLEVADEDSELFOTHER,
  SPELLDODGEDSELFOTHER, SPELLDEFLECTEDSELFOTHER, SPELLREFLECTSELFOTHER,
  SPELLPARRIEDSELFOTHER, SPELLLOGABSORBSELFOTHER }

libdebuff.objects = {}
libdebuff.pending = {}

function libdebuff:OnEvent(event)
    if event == "CHAT_MSG_COMBAT_SELF_HITS" then
        local hit = u.Cmatch(arg1, COMBATHITSELFOTHER)
        local crit = u.Cmatch(arg1, COMBATHITCRITSELFOTHER)
        if hit or crit then
          for seal in SimpleUI_AuraList.judgements do
            local name = UnitName("target")
            local level = UnitLevel("target")
            if name and libdebuff.objects[name] then
              if level and libdebuff.objects[name][level] and libdebuff.objects[name][level][seal] then
                libdebuff:AddEffect(name, level, seal)
              elseif libdebuff.objects[name][0] and libdebuff.objects[name][0][seal] then
                libdebuff:AddEffect(name, 0, seal)
              end
            end
          end
        end
        
    
      -- Add Combat Log
      elseif event == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE" or arg1 == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" then
        local unit, effect = u.Cmatch(arg1, AURAADDEDOTHERHARMFUL)
        if unit and effect then
          local unitlevel = UnitName("target") == unit and UnitLevel("target") or 0
          if not libdebuff.objects[unit] or not libdebuff.objects[unit][unitlevel] or not libdebuff.objects[unit][unitlevel][effect] then
            libdebuff:AddEffect(unit, unitlevel, effect)
          end
        end
    
      -- Add Missing Buffs by Iteration
      elseif event == "UNIT_AURA"  or event == "PLAYER_TARGET_CHANGED" then
        for i=1, 16 do
          local effect, rank, texture, stacks, dtype, duration, timeleft = libdebuff:UnitDebuff("target", i)
    
    
          -- abort when no further debuff was found
          if not texture then return end
    
          if texture and effect and effect ~= "" then
            -- don't overwrite existing timers
            local unitlevel = UnitLevel("target") or 0
            local unit = UnitName("target")
            if not libdebuff.objects[unit] or not libdebuff.objects[unit][unitlevel] or not libdebuff.objects[unit][unitlevel][effect] then
              libdebuff:AddEffect(unit, unitlevel, effect)
            end
          end
        end
    
      -- Update Pending Spells
      elseif event == "CHAT_MSG_SPELL_FAILED_LOCALPLAYER" or event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        -- Remove pending spell
        for _, msg in pairs(libdebuff.rp) do
          local effect = u.Cmatch(arg1, msg)
          if effect and libdebuff.pending[3] == effect then
            -- instant removal of the pending spell
            libdebuff:RemovePending()
            return
          elseif effect and lastspell and lastspell.start_old and lastspell.effect == effect then
            -- late removal of debuffs (e.g hunter arrows as they hit late)
            libdebuff:RevertLastAction()
            return
          end
        end
      elseif event == "SPELLCAST_STOP" then
        u.QueueFunction(libdebuff.PersistPending)
      end
end


-- Gather Data by User Actions
u.Hooksecurefunc("CastSpell", function(id, bookType)
  local rawEffect, rank = u.spell.GetSpellInfo(id, bookType)
  local duration = libdebuff:GetDuration(rawEffect, rank)
  libdebuff:AddPending(UnitName("target"), UnitLevel("target"), rawEffect, duration)
end, true)

u.Hooksecurefunc("CastSpellByName", function(effect, target)
  local rawEffect, rank = u.spell.GetSpellInfo(effect)
  local duration = libdebuff:GetDuration(rawEffect, rank)
  libdebuff:AddPending(UnitName("target"), UnitLevel("target"), rawEffect, duration)
end, true)

u.Hooksecurefunc("UseAction", function(slot, target, button)
  if GetActionText(slot) or not IsCurrentAction(slot) then return end
  scanner:SetAction(slot)
  local rawEffect, rank = scanner:Line(1)
  local duration = libdebuff:GetDuration(rawEffect, rank)
  libdebuff:AddPending(UnitName("target"), UnitLevel("target"), rawEffect, duration)
end, true)

function libdebuff:UnitDebuff(unit, id)
  local unitname = UnitName(unit)
  local unitlevel = UnitLevel(unit)
  local texture, stacks, dtype = UnitDebuff(unit, id)
  local duration, timeleft = nil, -1
  local rank = nil -- no backport
  local effect

  if texture then
    scanner:SetUnitDebuff(unit, id)
    effect = scanner:Line(1) or ""
  end


  if self.objects[unitname] and self.objects[unitname][unitlevel] and self.objects[unitname][unitlevel][effect] then
    local debuff = self.objects[unitname][unitlevel][effect]
    if debuff.duration and debuff.duration + debuff.start < GetTime() then
        self.objects[unitname][unitlevel][effect] = nil -- Expired debuff
    else
        duration = debuff.duration
        timeleft = duration + debuff.start - GetTime()
    end
elseif self.objects[unitname] and self.objects[unitname][0] and self.objects[unitname][0][effect] then
    local debuff = self.objects[unitname][0][effect]
    if debuff.duration and debuff.duration + debuff.start < GetTime() then
        self.objects[unitname][0][effect] = nil -- Expired debuff
    else
        duration = debuff.duration
        timeleft = duration + debuff.start - GetTime()
    end
end

  return effect, rank, texture, stacks, dtype, duration, timeleft
end


E.libdebuff = libdebuff
