local _G = getfenv(0)
local u = SUI_Util
if u.spell then return end

local scanner = u.TipScan:GetScanner("spell")
local spell = {}


local spellmaxrank = {}
function spell.GetSpellMaxRank(name)
  local cache = spellmaxrank[name]
  if cache then return cache[1], cache[2] end
  local name = string.lower(name)

  local rank = { 0, nil}
  for i = 1, GetNumSpellTabs() do
    local _, _, offset, num = GetSpellTabInfo(i)
    local bookType = BOOKTYPE_SPELL
    for id = offset + 1, offset + num do
      local spellName, spellRank = GetSpellName(id, bookType)
      if name == string.lower(spellName) then
        if not rank[2] then rank[2] = spellRank end

        local _, _, numRank = string.find(spellRank, " (%d+)$")
        if numRank and tonumber(numRank) > rank[1] then
          rank = { tonumber(numRank), spellRank}
        end
      end
    end
  end

  spellmaxrank[name] = { rank[2], rank[1] }
  return rank[2], rank[1]
end


local spellindex = {}
function spell.GetSpellIndex(name, rank)
  name = string.lower(name)
  local cache = spellindex[name..(rank and ("("..rank..")") or "")]
  if cache then return cache[1], cache[2] end

  if not rank then rank = spell.GetSpellMaxRank(name) end

  for i = 1, GetNumSpellTabs() do
    local _, _, offset, num = GetSpellTabInfo(i)
    local bookType = BOOKTYPE_SPELL
    for id = offset + 1, offset + num do
      local spellName, spellRank = GetSpellName(id, bookType)
      if rank and rank == spellRank and name == string.lower(spellName) then
        spellindex[name.."("..rank..")"] = { id, bookType }
        return id, bookType
      elseif not rank and name == string.lower(spellName) then
        spellindex[name] = { id, bookType }
        return id, bookType
      end
    end
  end

  spellindex[name..(rank and ("("..rank..")") or "")] = { nil }
  return nil
end

local spellinfo = {}
function spell.GetSpellInfo(index, bookType)
  local cache = spellinfo[index]
  if cache then return cache[1], cache[2], cache[3], cache[4], cache[5], cache[6], cache[7], cache[8] end

  local name, rank, id
  local icon = ""
  local castingTime = 0
  local minRange = 0
  local maxRange = 0

  if type(index) == "string" then
    local _, _, sname, srank = string.find(index, '(.+)%((.+)%)')
    name = sname or index
    rank = srank or spell.GetSpellMaxRank(name)
    id, bookType = spell.GetSpellIndex(name, rank)

    -- correct name in case of wrong upper/lower cases
    if id and bookType then
      name = GetSpellName(id, bookType)
    end
  else
    name, rank = GetSpellName(index, bookType)
    id, bookType = spell.GetSpellIndex(name, rank)
  end

  if name and id then
    icon = GetSpellTexture(id, bookType)
  end

  if id then
    scanner:SetSpell(id, bookType)
    local _, sec = scanner:Find(gsub(SPELL_CAST_TIME_SEC, "%%.3g", "%(.+%)"), false)
    local _, min = scanner:Find(gsub(SPELL_CAST_TIME_MIN, "%%.3g", "%(.+%)"), false)
    local _, range = scanner:Find(gsub(SPELL_RANGE, "%%s", "%(.+%)"), false)
    
    castingTime = (tonumber(sec) or tonumber(min) or 0) * 1000
    if range then
      local _, _, min, max = string.find(range, "(.+)-(.+)")
      if min and max then
        minRange = tonumber(min)
        maxRange = tonumber(max)
      else
        minRange = 0
        maxRange = tonumber(range)
      end
    end
  end

  spellinfo[index] = { name, rank, icon, castingTime, minRange, maxRange, id, bookType }
  return name, rank, icon, castingTime, minRange, maxRange, id, bookType
end

-- Reset all spell caches whenever new spells are learned/unlearned
local resetcache = CreateFrame("Frame")
resetcache:RegisterEvent("LEARNED_SPELL_IN_TAB")
resetcache:SetScript("OnEvent", function()
  spellmaxrank, spellindex, spellinfo = {}, {}, {}
end)

-- add libspell to pfUI API
u.spell = spell