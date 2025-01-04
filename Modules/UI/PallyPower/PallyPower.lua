-- All credits to relar the creator of pallypower addon
-- modified for SimpleUI - Turtle Wow
local PallyPower = CreateFrame("Frame")
local u = SUI_Util
local _G = getfenv(0)

SimpleUI:AddModule("PallyPower", function()
    if SimpleUI:IsDisabled("PallyPower") then return end
    local _, class = UnitClass("player");
    if class ~= "PALADIN" then
        return
    end

    local getn = table.getn;
    local format = string.format;
    local insert = table.insert;
    local remove = table.remove;
    local find = string.find;
    local sub = string.sub;
    local match = string.match;

    local initalized = false;
    local clearTime = 0;

    PaladinList = {};
    SimplePallyPower_Assignments = {};

    SimpleBlessingIcon = {};
    SimpleBBuffIcon = {};
    local db = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"];
    SimplePP_NextScan = db.scanfreq;
    local FiveMinBlessing = db.FiveMinBuff;

    SimpleLastCast = {};
    SimpleLastCastOn = {};
    SimplePP_Symbols = 0;
    SimpleIsPally = 0;

    SimpleTip = CreateFrame("GameTooltip", "PPSimpleTooltip", UIParent, "GameTooltipTemplate")

    local classIconPaths = {
        [1] = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\Warrior",
        [2] = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\Rogue",
        [3] = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\Priest",
        [4] = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\Druid",
        [5] = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\Paladin",
        [6] = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\Hunter",
        [7] = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\Mage",
        [8] = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\Warlock",
        [9] = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\Shaman",
        [10] = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\Pet",
    }

    local defaultBlessings = {
        [1] = 1,  -- Warrior: Might
        [2] = 1,  -- Rogue: Might
        [3] = 0,  -- Priest: Wisdom
        [4] = 0,  -- Druid: Wisdom
        [5] = 0,  -- Paladin: Wisdom
        [6] = 1,  -- Hunter: Might
        [7] = 0,  -- Mage: Wisdom
        [8] = 0,  -- Warlock: Wisdom (or 2=Salvation if you prefer)
        [9] = 0,  -- Shaman: Wisdom
        [10] = 1, -- Pet: Might
    }

    local Assignment = {};
    SimpleCurrentBuffs = {};
    SIMPLEPP_PREFIX = "PLPWR"

    local RestorSelfAutoCastTimeOut = 1;
    local RestorSelfAutoCast = false;

    function SimplePallyPower_OnUpdate(diff)
        if (RestorSelfAutoCast) then
            RestorSelfAutoCastTimeOut = RestorSelfAutoCastTimeOut - diff;
            if (RestorSelfAutoCastTimeOut < 0) then
                RestorSelfAutoCast = false;
                SetCVar("autoSelfCast", "1")
            end
        end

        if (not db.scanfreq) then
            db.scanfrew = 10;
            db.scanperframe = 1;
        end

        SimplePP_NextScan = SimplePP_NextScan - diff
        if SimplePP_NextScan < 0 and SimplePP_IsPally then
            SimplePallyPower_ScanRaid()
            SimplePallyPower_UpdateUI()
        end

        for i, k in SimpleLastCast do
            SimpleLastCast[i] = k - diff
        end
    end

    function SimplePallyPower_AssignDefaultSpells(pname)
        -- If no table yet, make one
        if not SimplePallyPower_Assignments[pname] then
            SimplePallyPower_Assignments[pname] = {}
        end

        local pallyDB = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["PallyPower"]
        local configDefaults = pallyDB["DefaultBlessings"] or {}

        -- Fill in each class with the default
        for classID = 1, 10 do
            local defaultBuff = configDefaults[classID] or 0
            SimplePallyPower_Assignments[pname][classID] = defaultBuff
        end
    end

    function SimplePallyPower_OnEvent()
        if (event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD") then
            if FiveMinBlessing == true then
                SimplePallyPower_SwapIconsForFiveMin()
            else
                SimplePallyPower_SwapIconsForFifteenMin()
            end
            SimplePallyPower_UpdateUI()
            SimplePallyPower_ScanSpells()
        end

        if (event == "PLAYER_ENTERING_WORLD" and (not SimplePallyPower_Assignments[UnitName("player")])) then
            local playerName = UnitName("player")
            if not SimplePallyPower_Assignments[playerName] then
                SimplePallyPower_Assignments[playerName] = {}
                if playerName == "Aznamir" then
                    PP_DebugEnabled = true
                end
                -- Now call your defaults
                SimplePallyPower_AssignDefaultSpells(playerName)
            end
        end

        if event == "CHAT_MSG_ADDON" and arg1 == SIMPLEPP_PREFIX and (arg3 == "PARTY" or arg3 == "RAID") then
            SimplePallyPower_ParseMessage(arg4, arg2)
        end

        if event == "CHAT_MSG_COMBAT_FRIENDLY_DEATH" and SimplePP_NextScan > 1 then
            SimplePP_NextScan = 1
        end

        if event == "PLAYER_LOGIN" then
            SimplePallyPower_UpdateUI()
        end

        if event == "PARTY_MEMBERS_CHANGED" then
            SimplePallyPower_ScanRaid()
            SimplePallyPower_UpdateUI()
        end
    end

    function SimplePallyPower_SwapIconsForFiveMin()
        SimpleBlessingIcon[0] = "Interface\\Icons\\Spell_Holy_SealOfWisdom";
        SimpleBlessingIcon[1] = "Interface\\Icons\\Spell_Holy_FistOfJustice";
        SimpleBlessingIcon[2] = "Interface\\Icons\\Spell_Holy_SealOfSalvation";
        SimpleBlessingIcon[3] = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02";
        SimpleBlessingIcon[4] = "Interface\\Icons\\Spell_Magic_MageArmor";
        SimpleBlessingIcon[5] = "Interface\\Icons\\Spell_Nature_LightningShield";
        SimpleBBuffIcon[0] = "Interface\\Icons\\Spell_Holy_SealOfWisdom";
        SimpleBBuffIcon[1] = "Interface\\Icons\\Spell_Holy_FistOfJustice";
        SimpleBBuffIcon[2] = "Interface\\Icons\\Spell_Holy_SealOfSalvation";
        SimpleBBuffIcon[3] = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02";
        SimpleBBuffIcon[4] = "Interface\\Icons\\Spell_Magic_MageArmor";
        SimpleBBuffIcon[5] = "Interface\\Icons\\Spell_Nature_LightningShield";
    end

    function SimplePallyPower_SwapIconsForFifteenMin()
        SimpleBlessingIcon[0] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom";
        SimpleBlessingIcon[1] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings";
        SimpleBlessingIcon[2] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation";
        SimpleBlessingIcon[3] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight";
        SimpleBlessingIcon[4] = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings";
        SimpleBlessingIcon[5] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary";
        SimpleBBuffIcon[0] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom"
        SimpleBBuffIcon[1] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings"
        SimpleBBuffIcon[2] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation"
        SimpleBBuffIcon[3] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight"
        SimpleBBuffIcon[4] = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings"
        SimpleBBuffIcon[5] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary"
    end

    local function FormatTime(time)
        if not time or time < 0 then
            return "";
        end

        local mins = floor(time / 60)
        local secs = time - (mins * 60)
        return format("%d:%02d", mins, secs);
    end

    function SimplePallyPowerGrid_Update()
        if not initalized then
            SimplePallyPower_ScanSpells()
        end

        local i = 1;
        local NUM_PALLY = 0;
        if PallyPower.Frame:IsVisible() then
            PallyPower.Frame:SetScale(db.scalemain);
            for name, skills in PaladinList do
                _G["SimplePowerFramePlayer" .. i .. "Name"]:SetText(name)
                _G["SimplePowerFramePlayer" .. i .. "Symbols"]:SetText(skills["symbols"])
                _G["SimplePowerFramePlayer" .. i .. "Symbols"]:SetTextColor(1, 1, 0.5)
                if SimplePallyPower_CanControl(name) then
                    _G["SimplePowerFramePlayer" .. i .. "Name"]:SetTextColor(1, 1, 1)
                else
                    if SimplePallyPower_CheckRaidLeader(name) then
                        _G["SimplePowerFramePlayer" .. i .. "Name"]:SetTextColor(0, 1, 0)
                    else
                        _G["SimplePowerFramePlayer" .. i .. "Name"]:SetTextColor(1, 0, 0)
                    end
                end
                for id = 0, 5 do
                    if skills[id] then
                        _G["SimplePowerFramePlayer" .. i .. "Icon" .. id]:Show()
                        _G["SimplePowerFramePlayer" .. i .. "Skill" .. id]:Show()
                        local txt = skills[id]["rank"]
                        if skills[id]["talent"] + 0 > 0 then
                            txt = txt .. "+" .. skills[id]["talent"]
                        end
                        _G["SimplePowerFramePlayer" .. i .. "Skill" .. id]:SetText(txt)
                    else
                        _G["SimplePowerFramePlayer" .. i .. "Icon" .. id]:Hide()
                        _G["SimplePowerFramePlayer" .. i .. "Skill" .. id]:Hide()
                    end
                end
                for id = 1, 10 do
                    if (SimplePallyPower_Assignments[name]) then
                        _G["SimplePowerFramePlayer" .. i .. "Class" .. id .. "Icon"]:SetTexture(SimpleBlessingIcon
                            [SimplePallyPower_Assignments[name][id]])
                    else
                        _G["SimplePowerFramePlayer" .. i .. "Class" .. id .. "Icon"]:SetTexture(nil)
                    end
                end
                i = i + 1
                NUM_PALLY = NUM_PALLY + 1
            end
            PallyPower.Frame:SetHeight(14 + 24 + 56 + (NUM_PALLY * 56) + 22)
            for i = 1, 10 do
                if i <= NUM_PALLY then
                    _G["SimplePowerFramePlayer" .. i]:Show()
                else
                    _G["SimplePowerFramePlayer" .. i]:Hide()
                end
            end
        end
    end

    function SimplePallyPower_UpdateUI()
        if not initalized then
            SimplePallyPower_ScanSpells()
        end

        getglobal("SimplePallyPowerBuffBar"):SetScale(db.scalebar);
        local _, eclass = UnitClass("player")

        if eclass == "PALADIN" then
            SimpleIsPally = 1
        else
            getglobal("SimplePallyPowerBuffBar"):Show()
        end

        if (SimpleIsPally == 1) or (GetNumRaidMembers() > 0 and GetNumPartyMembers() > 0) then
            getglobal("SimplePallyPowerBuffBar"):Show()
            getglobal("SimplePallyPowerBuffBarTitleText"):SetText(format("Paladin Buffs (%d)", SimplePP_Symbols))
            SimpleBuffNum = 1
            if SimplePallyPower_Assignments[UnitName("player")] then
                local assign = SimplePallyPower_Assignments[UnitName("player")]
                for class = 1, 10 do
                    if (assign[class] and assign[class] ~= -1) then
                        getglobal("SimplePallyPowerBuffBarBuff" .. SimpleBuffNum .. "ClassIcon"):SetTexture(
                            classIconPaths
                            [class])
                        getglobal("SimplePallyPowerBuffBarBuff" .. SimpleBuffNum .. "BuffIcon"):SetTexture(
                            SimpleBlessingIcon
                            [assign[class]])

                        local btn = getglobal("SimplePallyPowerBuffBarBuff" .. SimpleBuffNum); --_G["SimplePallyPowerBuffBarBuff" .. SimpleBuffNum];
                        btn.classID = class;
                        btn.buffID = assign[class];
                        btn.need = {};
                        btn.have = {};
                        btn.range = {};
                        btn.dead = {};

                        local nneed = 0;
                        local nhave = 0;
                        local ndead = 0;
                        if SimpleCurrentBuffs[class] then
                            for member, stats in SimpleCurrentBuffs[class] do
                                if stats["visible"] then
                                    if not stats[assign[class]] then
                                        if UnitIsDeadOrGhost(member) then
                                            ndead = ndead + 1;
                                            insert(btn.dead, stats["name"]);
                                        else
                                            nneed = nneed + 1
                                            insert(btn.need, stats["name"]);
                                        end
                                    else
                                        insert(btn.have, stats["name"]);
                                        nhave = nhave + 1
                                    end
                                else
                                    insert(btn.range, stats["name"]);
                                    nhave = nhave + 1
                                end
                            end
                        end
                        if ndead > 0 then
                            getglobal("SimplePallyPowerBuffBarBuff" .. SimpleBuffNum .. "Text"):SetText(nneed ..
                                " (" .. ndead .. ")");
                        else
                            getglobal("SimplePallyPowerBuffBarBuff" .. SimpleBuffNum .. "Text"):SetText(nneed);
                        end
                        getglobal("SimplePallyPowerBuffBarBuff" .. SimpleBuffNum .. "Time"):SetText(FormatTime(
                            SimpleLastCast
                            [assign[class] .. class]));
                        if not (nneed > 0 or nhave > 0) then
                        else
                            SimpleBuffNum = SimpleBuffNum + 1
                            if (nhave == 0) then
                                getglobal(btn:GetName() .. "Background"):SetVertexColor(0.8, 0, 0, 0.6);
                            elseif (nneed > 0) then
                                getglobal(btn:GetName() .. "Background"):SetVertexColor(0.8, 0.64, 0, 0.6);
                            else
                                getglobal(btn:GetName() .. "Background"):SetVertexColor(0.25, 0.25, 0.25, 0.6)
                            end
                            btn:Show()
                        end
                    end
                end
            end
            for rest = SimpleBuffNum, 10 do
                local btn = getglobal("SimplePallyPowerBuffBarBuff" .. rest); --_G["SimplePallyPowerBuffBarBuff" .. rest];
                btn:Hide()
            end
            PallyPower.BuffBar:SetHeight(30 + (34 * (SimpleBuffNum - 1)));
        end
    end

    function SimplePallyPower_ScanSpells()
        local RankInfo = {}
        local i = 1

        while true do
            local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
            local spellTexture = GetSpellTexture(i, BOOKTYPE_SPELL)
            if not spellName then do break end end
            SimplePallyPower_ScanInventory()
            if not spellRank or spellRank == "" then
                spellRank = "Rank 1"
            end

            if FiveMinBlessing == true then
                local _, _, bless = find(spellName, "Blessing of (.*)")
                if bless then
                    local tmp_str, _ = string.find(spellName, "Greater")
                    for id, name in SimplePallyPower_BlessingID do
                        if ((name == bless) and (tmp_str ~= 1)) then
                            local _, _, rank = find(spellRank, "Rank (.*)");
                            if not (RankInfo[id] and spellRank < RankInfo[id]["rank"]) then
                                RankInfo[id] = {};
                                RankInfo[id]["rank"] = rank;
                                RankInfo[id]["id"] = i;
                                RankInfo[id]["name"] = name;
                                RankInfo[id]["talent"] = 0;
                            end
                        end
                    end
                end
            else
                local _, _, bless = find(spellName, "Greater Blessing of (.*)")
                if bless then
                    local tmp_str, _ = find(spellName, "Greater")
                    for id, name in SimplePallyPower_BlessingID do
                        if ((name == bless) and (tmp_str == 1)) then
                            local _, _, rank = find(spellRank, "Rank (.*)");
                            if not (RankInfo[id] and spellRank < RankInfo[id]["rank"]) then
                                RankInfo[id] = {};
                                RankInfo[id]["rank"] = rank;
                                RankInfo[id]["id"] = i;
                                RankInfo[id]["name"] = name;
                                RankInfo[id]["talent"] = 0;
                            end
                        end
                    end
                end
            end
            i = i + 1
        end
        local numTabs = GetNumTalentTabs();
        for t = 1, numTabs do
            local numTalents = GetNumTalents(t);
            for i = 1, numTalents do
                local nameTalent, icon, iconx, icony, currRank, maxRank = GetTalentInfo(t, i);
                if find(nameTalent, "Improved Blessings") then
                    initalized = true;
                    for id = 0, 1 do -- wis, might
                        if (RankInfo[id]) then
                            RankInfo[id]["talent"] = currRank
                        end
                    end
                end
            end
        end
        local _, class = UnitClass("player");
        if class == "PALADIN" then
            PaladinList[UnitName("player")] = RankInfo;
            if initalized then
                SimplePallyPower_SendSelf();
            end
            SimplePP_IsPally = true
        else
            SimplePP_IsPally = nil
            initalized = true;
        end
        SimplePallyPower_ScanInventory()
    end

    function SimplePallyPower_Refresh()
        --ADDED THESE TO FIX THE REFRESH NOT WORKING
        SimplePP_Symbols = 0
        PaladinList = {};
        SimplePP_IsPally = nil
        SimplePallyPower_ScanSpells()
        SimplePallyPowerGrid_Update()

        --This was present before
        SimplePallyPower_SendSelf()
        SimplePallyPower_RequestSend()
        SimplePallyPower_ScanSpells()
        SimplePallyPower_UpdateUI()
    end

    function SimplePallyPower_Clear(fromupdate, who)
        --ButtonClick = PallyPower_Clear() -> then there is no "fromupdate" and no "who"
        --then sends the message at the end to everyone else

        if not who then
            who = UnitName("player")
        end

        for name, skills in SimplePallyPower_Assignments do
            if (SimplePallyPower_CheckRaidLeader(who) or name == who) then
                if name == who then
                else
                    if (clearTime + 5) < GetTime() then
                        clearTime = GetTime()
                    end
                end
                for class, id in SimplePallyPower_Assignments[name] do
                    SimplePallyPower_Assignments[name][class] = -1
                end
            end
        end

        --SimplePallyPower_UpdateUI()
        SimplePallyPower_Refresh()

        if not fromupdate then

        end
    end

    function SimplePallyPower_RequestSend()
        SimpleUI_SystemMessage("REQ")
    end

    function SimplePallyPower_SendSelf()
        if not initalized then
            SimplePallyPower_ScanSpells()
        end
        if not PaladinList[UnitName("player")] then
            return
        end
        local msg = "SELF "
        local RankInfo = PaladinList[UnitName("player")]
        local i
        for id = 0, 5 do
            if (not RankInfo[id]) then
                msg = msg .. "nn";
            else
                msg = msg .. RankInfo[id]["rank"]
                msg = msg .. RankInfo[id]["talent"]
            end
        end
        msg = msg .. "@"
        for id = 0, 9 do
            if (not SimplePallyPower_Assignments[UnitName("player")]) or (not SimplePallyPower_Assignments[UnitName("player")][id]) or SimplePallyPower_Assignments[UnitName("player")][id] == -1 then
                msg = msg .. "n"
            else
                msg = msg .. SimplePallyPower_Assignments[UnitName("player")][id]
            end
        end
    end

    function SimplePallyPower_ParseMessage(sender, msg)
        if not (sender == UnitName("player")) then
            if msg == "REQ" then
                SimplePallyPower_SendSelf()
            end
            if find(msg, "^SELF") then
                SimplePallyPower_Assignments[sender] = {}
                PaladinList[sender] = {}
                _, _, numbers, assign = find(msg, "SELF ([0-9n]*)@?([0-9n]*)")
                for id = 0, 5 do
                    rank = sub(numbers, id * 2 + 1, id * 2 + 1)
                    talent = sub(numbers, id * 2 + 2, id * 2 + 2)
                    if not (rank == "n") then
                        PaladinList[sender][id] = {}
                        PaladinList[sender][id]["rank"] = rank
                        PaladinList[sender][id]["talent"] = talent
                    end
                end
                if assign then
                    for id = 0, 9 do
                        tmp = sub(assign, id + 1, id + 1)
                        if (tmp == "n" or tmp == "") then
                            tmp = -1
                        end
                        SimplePallyPower_Assignments[sender][id] = tmp + 0
                    end
                end
                SimplePallyPower_UpdateUI()
            end
            if find(msg, "^ASSIGN") then
                _, _, name, class, skill = find(msg, "^ASSIGN (.*) (.*) (.*)")
                if (not (name == sender)) and (not SimplePallyPower_CheckRaidLeader(sender)) then
                    return false
                end
                if (not SimplePallyPower_Assignments[name]) then
                    SimplePallyPower_Assignments[name] = {}
                end
                class = class + 0
                skill = skill + 0
                SimplePallyPower_Assignments[name][class] = skill;
                SimplePallyPower_UpdateUI()
            end
            if find(msg, "^MASSIGN") then
                _, _, name, skill = find(msg, "^MASSIGN (.*) (.*)")
                if (not (name == sender)) and (not SimplePallyPower_CheckRaidLeader(sender)) then
                    return false
                end
                if (not SimplePallyPower_Assignments[name]) then
                    SimplePallyPower_Assignments[name] = {}
                end
                skill = skill + 0
                for class = 1, 10 do
                    SimplePallyPower_Assignments[name][class] = skill;
                end
                SimplePallyPower_UpdateUI()
            end
            if find(msg, "^SYMCOUNT ([0-9]*)") then
                _, _, count = find(msg, "^SYMCOUNT ([0-9]*)")
                if PaladinList[sender] then
                    PaladinList[sender]["symbols"] = count;
                else

                end
            end
            if find(msg, "^CLEAR") then
                SimplePallyPower_Clear(true, sender)
            end
        end
    end

    function SimplePallyPower_ShowCredits()
        GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("Simple Pally Power", 1, 1, 1)
        GameTooltip:AddLine("Updates and Fixes: Rake, Xerron, Relar, Eliriss", 1, 1, 1);
        GameTooltip:AddLine("Originally by Sneakyfoot");
        GameTooltip:Show()
    end

    --[[     function SimplePallyPowerFrame_MouseDown(arg1)
        if (((not PallyPower.Frame.isLocked) or (PallyPower.Frame.isLocked == 0)) and (arg1 == "LeftButton")) then
            PallyPower.Frame:StartMoving();
            PallyPower.Frame.isMoving = true;
        end
    end

    function SimplePallyPowerFrame_MouseUp()
        if (PallyPower.Frame.isMoving) then
            PallyPower.Frame:StopMovingOrSizing();
            PallyPower.Frame.isMoving = false;
        end
    end ]]

    function SimplePallyPowerBuffBar_MouseDown(arg1)
        if (((not PallyPower.BuffBar.isLocked) or (PallyPower.BuffBar.isLocked == 0)) and (arg1 == "LeftButton")) then
            PallyPower.BuffBar:StartMoving();
            PallyPower.BuffBar.isMoving = true;
            PallyPower.BuffBar.startPosX = PallyPower.BuffBar:GetLeft();
            PallyPower.BuffBar.startPosY = PallyPower.BuffBar:GetTop();
        end
    end

    function SimplePallyPowerBuffBar_MouseUp()
        if (PallyPower.BuffBar.isMoving) then
            PallyPower.BuffBar:StopMovingOrSizing();
            PallyPower.BuffBar.isMoving = false;
        end
        if abs(PallyPower.BuffBar.startPosX - PallyPower.BuffBar:GetLeft()) < 2 and abs(PallyPower.BuffBar.startPosY - PallyPower.BuffBar:GetTop()) < 2 then
            PallyPower.Frame:Show();
            SimplePallyPower_UpdateUI()
        end
    end

    function SimplePallyPowerGridButton_OnClick(btn, mouseBtn)
        _, _, pnum, class = find(btn:GetName(), "SimplePowerFramePlayer(%d+)Class(%d+)");
        pnum = pnum + 0;
        class = class + 0;
        pname = getglobal("SimplePowerFramePlayer" .. pnum .. "Name"):GetText()
        if not SimplePallyPower_CanControl(pname) then
            return
        end

        if (mouseBtn == "RightButton") then
            SimplePallyPower_Assignments[pname][class] = -1
            SimplePallyPower_UpdateUI()
        else
            SimplePallyPower_PerformCycle(pname, class)
        end
    end

    function PallyPower_PerformCycleBackwards(name, class)
        local shift = IsShiftKeyDown()

        --force pala (all buff possible) when shift wheeling
        if shift then
            class = 4
        end

        if not SimplePallyPower_Assignments[name][class] then
            cur = 6
        else
            cur = SimplePallyPower_Assignments[name][class]
            if cur == 0 then
                cur = 6
            end
        end

        SimplePallyPower_Assignments[name][class] = 0

        for test = cur - 1, -1, -1 do
            cur = test
            if SimplePallyPower_CanBuff(name, test) and (SimplePallyPower_NeedsBuff(class, test) or shift) then
                do
                    break
                end
            end
        end

        if shift then
            for test = 1, 10 do
                SimplePallyPower_Assignments[name][test] = cur
            end
        else
            SimplePallyPower_Assignments[name][class] = cur
        end

        SimplePallyPower_UpdateUI()
    end

    function SimplePallyPower_PerformCycle(name, class)
        local shift = IsShiftKeyDown()

        --force pala (all buff possible) when shift wheeling
        if shift then
            class = 4
        end

        if not SimplePallyPower_Assignments[name][class] then
            cur = 0
        else
            cur = SimplePallyPower_Assignments[name][class]
        end
        SimplePallyPower_Assignments[name][class] = 0
        for test = cur + 1, 6 do
            if SimplePallyPower_CanBuff(name, test) and (SimplePallyPower_NeedsBuff(class, test) or shift) then
                cur = test
                do
                    break
                end
            end
        end

        if (cur == 6) then
            cur = 0
        end

        if shift then
            for test = 1, 10 do
                SimplePallyPower_Assignments[name][test] = cur
            end
        else
            SimplePallyPower_Assignments[name][class] = cur
        end

        SimplePallyPower_UpdateUI()
    end

    function SimplePallyPower_CanBuff(name, test)
        if test == 6 then
            return true
        end
        if (not PaladinList[name][test]) or (PaladinList[name][test]["rank"] == 0) then
            return false
        end
        return true
    end

    function SimplePallyPower_NeedsBuff(class, test)
        if test == 6 then
            return true
        end
        if test == -1 then
            return true
        end
        if db.smartbuffs then
            -- 0 = Wisdom, 1 = Might

            -- No Wisdom for Warrior (1) or Rogue (2)
            if (class == 1 or class == 2) and test == 0 then
                return false
            end

            if (class == 3 or class == 7 or class == 8) and test == 1 then
                return false
            end
        end

        for name, skills in SimplePallyPower_Assignments do
            if (PaladinList[name]) and ((skills[class]) and (skills[class] == test)) then
                return false
            end
        end
        return true
    end

    function SimplePallyPower_CanControl(name)
        return (IsPartyLeader() or IsRaidLeader() or IsRaidOfficer() or (name == UnitName("player")))
    end

    function SimplePallyPower_CheckRaidLeader(nick)
        if GetNumRaidMembers() == 0 then
            for i = 1, GetNumPartyMembers(), 1 do
                if nick == UnitName("party" .. i) and UnitIsPartyLeader("party" .. i) then
                    return true
                end
            end
            return false
        end
        for i = 1, GetNumRaidMembers(), 1 do
            local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i)
            if (rank >= 1 and name == nick) then
                return true
            end
        end
        return false
    end

    function SimplePallyPower_ScanInventory()
        if not SimplePP_IsPally then
            return
        end
        local oldcount = SimplePP_Symbols
        SimplePP_Symbols = 0
        for bag = 0, 4 do
            local bagslots = GetContainerNumSlots(bag);
            if (bagslots) then
                for slot = 1, bagslots do
                    local link = GetContainerItemLink(bag, slot)
                    if (link and find(link, "Symbol of Kings")) then
                        local _, count, locked = GetContainerItemInfo(bag, slot);
                        SimplePP_Symbols = SimplePP_Symbols + count
                    end
                end
            end
        end
        if SimplePP_Symbols ~= oldcount then

        end
        --DEFAULT_CHAT_FRAME:AddMessage("[PallyPower old count] " .. oldcount, r, g, b, a)
        --DEFAULT_CHAT_FRAME:AddMessage("[PallyPower] " .. SimplePP_Symbols, r, g, b, a)
        --    if (AllPallys[UnitName("player")] ~= nil) then
        --	  DEFAULT_CHAT_FRAME:AddMessage(AllPallys[UnitName("player")], r, g, b, a)
        if (PaladinList[UnitName("player")] ~= nil) then
            PaladinList[UnitName("player")]["symbols"] = SimplePP_Symbols;
        end
        --	end;
    end

    SimplePP_ScanInfo = nil

    function SimplePallyPower_ScanRaid()
        if not SimplePP_IsPally then
            return
        end
        if not (SimplePP_ScanInfo) then
            SimplePP_Scanners = {}
            SimplePP_ScanInfo = {}
            if GetNumRaidMembers() > 0 then
                for i = 1, GetNumRaidMembers() do
                    insert(SimplePP_Scanners, "raid" .. i)
                end
                SIMPLEINRAID = 1
            else
                insert(SimplePP_Scanners, "player");
                for i = 1, GetNumPartyMembers() do
                    insert(SimplePP_Scanners, "party" .. i)
                end
                SIMPLEINRAID = 0
            end
        end
        local tests = db.scanperframe
        if (not tests) then
            tests = 1
        end

        while SimplePP_Scanners[1] do
            local unit = SimplePP_Scanners[1]
            local name = UnitName(unit)
            local class = UnitClass(unit)
            if (name and class) then
                local cid = SimplePallyPower_GetClassID(class)

                if cid == 5 then -- hunters
                    local petId = "raidpet" .. sub(unit, 5);

                    local pet_name = UnitName(petId)

                    if pet_name then
                        local classID = 9
                        if not SimplePP_ScanInfo[classID] then
                            SimplePP_ScanInfo[classID] = {}
                        end

                        SimplePP_ScanInfo[classID][petId] = {};
                        SimplePP_ScanInfo[classID][petId]["name"] = pet_name;
                        SimplePP_ScanInfo[classID][petId]["visible"] = UnitIsVisible(petId);

                        local j = 1
                        while UnitBuff(petId, j, true) do
                            local buffIcon, _ = UnitBuff(petId, j, true)
                            local txtID = SimplePallyPower_GetBuffTextureID(buffIcon)
                            if txtID > 5 then
                                txtID = txtID - 6
                            end
                            SimplePP_ScanInfo[classID][petId][txtID] = true
                            j = j + 1
                        end
                    end
                end

                if not SimplePP_ScanInfo[cid] then
                    SimplePP_ScanInfo[cid] = {}
                end
                SimplePP_ScanInfo[cid][unit] = {};
                SimplePP_ScanInfo[cid][unit]["name"] = name;
                SimplePP_ScanInfo[cid][unit]["visible"] = UnitIsVisible(unit);

                local j = 1
                while UnitBuff(unit, j, true) do
                    local buffIcon, _ = UnitBuff(unit, j, true)
                    local txtID = SimplePallyPower_GetBuffTextureID(buffIcon)
                    if txtID > 5 then
                        txtID = txtID - 6
                    end
                    SimplePP_ScanInfo[cid][unit][txtID] = true
                    j = j + 1
                end
            end
            remove(SimplePP_Scanners, 1)
            tests = tests - 1
            if (tests <= 0) then
                return
            end
        end
        SimpleCurrentBuffs = SimplePP_ScanInfo
        SimplePP_ScanInfo = nil
        SimplePP_NextScan = db.scanfreq
        SimplePallyPower_ScanInventory()
    end

    SimpleClassID = {
        [1] = "Warrior",
        [2] = "Rogue",
        [3] = "Priest",
        [4] = "Druid",
        [5] = "Paladin",
        [6] = "Hunter",
        [7] = "Mage",
        [8] = "Warlock",
        [9] = "Shaman",
        [10] = "Pet"
    }

    SimplePallyPower_BlessingID = {
        [0] = "Wisdom",
        [1] = "Might",
        [2] = "Salvation",
        [3] = "Light",
        [4] = "Kings",
        [5] = "Sanctuary"
    };

    function SimplePallyPower_GetClassID(class)
        for id, name in SimpleClassID do
            if (name == class) then
                return id
            end
        end
        return -1
    end

    function SimplePallyPower_GetBuffTextureID(text)
        for id, name in SimpleBBuffIcon do
            if (name == text) then
                return id
            end
        end
        return -2
    end

    function SimplePallyPowerBuffButton_OnLoad(btn)
        btn:SetBackdropColor(1, 1, 1, 1);
    end

    function SimplePallyPowerBuffButton_OnClick(btn, mousebtn)
        local _, class = UnitClass("player")
        if class ~= "PALADIN" then return end

        RestorSelfAutoCastTimeOut = 1;
        if (GetCVar("autoSelfCast") == "1") then
            RestorSelfAutoCast = true;
            SetCVar("autoSelfCast", "0");
        end

        ClearTarget()
        CastSpell(PaladinList[UnitName("player")][btn.buffID]["id"], BOOKTYPE_SPELL);
        local RecentCast = false
        for unit, stats in SimpleCurrentBuffs[btn.classID] do
            if not stats[btn.buffID] then
                if SpellCanTargetUnit(unit) and not (RecentCast and find(table.concat(btn.need, ", "), unit)) then
                    SpellTargetUnit(unit)
                    SimplePP_NextScan = 1
                    if (FiveMinBlessing == true) then
                        SimpleLastCast[btn.buffID .. btn.classID] = 10 * 60;
                    else
                        SimpleLastCast[btn.buffID .. btn.classID] = 30 * 60;
                    end
                    SimpleLastCastOn[btn.classID] = {}
                    insert(SimpleLastCastOn[btn.classID], unit)
                    --PallyPower_ShowFeedback(
                    --format(PallyPower_Casting, PallyPower_BlessingID[btn.buffID], PallyPower_ClassID[btn.classID],
                    --UnitName(unit)), 0.0, 1.0, 0.0);
                    TargetLastTarget()
                    return
                end
            end
        end
        SpellStopTargeting()
        TargetLastTarget()
        --[[ PallyPower_ShowFeedback(
            format(PallyPower_CouldntFind, PallyPower_BlessingID[btn.buffID], PallyPower_ClassID[btn.classID]), 1.0, 0.0,
            0.0); ]]
    end

    function SimplePallyPowerBuffButton_OnEnter(btn)
        local _, class = UnitClass("player")
        if class ~= "PALADIN" then return end

        --[[        SimpleTipOwner = this
        SimpleTip:SetOwner(this, "ANCHOR_TOPLEFT")
        SimpleTip:SetPoint("RIGHT", this, "LEFT", 0, 0)
        SimpleTip:AddDoubleLine(SimpleClassID[btn.classID], u.Colorize("Blessing of " .. SimplePallyPower_BlessingID[btn.buffID], 0.251, 0.878, 0.816), 1, 1, 1)
        SimpleTip:Show() ]]
        GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
        GameTooltip:AddDoubleLine(SimpleClassID[btn.classID],
            u.Colorize("Blessing of " .. SimplePallyPower_BlessingID[btn.buffID], 0.251, 0.878, 0.816), 1, 1, 1)
        GameTooltip:AddDoubleLine(u.Colorize("Has Buff:", 1, 1, 0.5),
            u.Colorize(table.concat(btn.have, ", "), 0.5, 1, 0.5), 1, 1, 1)
        GameTooltip:AddDoubleLine(u.Colorize("Needs Buff:", 1, 1, 0.5),
            u.Colorize(table.concat(btn.need, ", "), 0.5, 1, 0.5), 1, 1, 1)
        GameTooltip:AddDoubleLine(u.Colorize("Out of Range:", 1, 1, 0.5),
            u.Colorize(table.concat(btn.range, ", "), 0.5, 0.5, 1), 1, 1, 1)
        GameTooltip:AddDoubleLine(u.Colorize("Dead:", 1, 1, 0.5), u.Colorize(table.concat(btn.dead, ", "), 1, 0, 0), 1, 1,
            1)
        --[[         GameTooltip:AddLine("Has Buff: " .. table.concat(btn.have, ", "), 0.5, 1, 0.5);
        GameTooltip:AddLine("Need: " .. table.concat(btn.need, ", "), 1, 0.5, 0.5);
        GameTooltip:AddLine("Not Here: " .. table.concat(btn.range, ", "), 0.5, 0.5, 1);
        GameTooltip:AddLine("Dead: " .. table.concat(btn.dead, ", "), 1, 0, 0); ]]
        GameTooltip:Show()
    end

    function SimplePallyPowerBuffButton_OnLeave(btn)
        --SimpleTip:Hide()
        GameTooltip:Hide()
    end

    function SimplePallyPower_StartScaling(arg1)
        if arg1 == "LeftButton" then
            this:LockHighlight()
            PallyPower.FrameToScale = this:GetParent()
            PallyPower.ScalingWidth = this:GetParent():GetWidth() *
                PallyPower.FrameToScale:GetParent():GetEffectiveScale()
            PallyPower.ScalingHeight = this:GetParent():GetHeight() *
                PallyPower.FrameToScale:GetParent():GetEffectiveScale()
            PallyPower.Scaling:Show()
        end
    end

    function SimplePallyPower_StopScaling(arg1)
        if arg1 == "LeftButton" then
            PallyPower.Scaling:Hide()
            PallyPower.FrameToScale = nil
            this:UnlockHighlight()
        end
    end

    local function really_setpoint(frame, point, relativeTo, relativePoint, xoff, yoff)
        frame:SetPoint(point, relativeTo, relativePoint, xoff, yoff)
    end

    function SimplePallyPower_ScaleFrame(scale)
        local frame = PallyPower.FrameToScale
        local oldscale = frame:GetScale() or 1
        local framex = (frame:GetLeft()) * oldscale
        local framey = (frame:GetTop()) * oldscale

        frame:SetScale(scale)
        if frame:GetName() == "SimplePowerFrame" then
            really_setpoint(PallyPower.Frame, "TOPLEFT", "UIParent", "BOTTOMLEFT", framex / scale, framey / scale)
            db.scalemain = scale
        end
        if frame:GetName() == "SimplePallyPowerBuffBar" then
            really_setpoint(PallyPower.BuffBar, "TOPLEFT", "UIParent", "BOTTOMLEFT", framex / scale, framey / scale)
            db.scalebar = scale
        end
    end

    function SimplePallyPower_ScalingFrame_OnUpdate(arg1)
        if not PallyPower.ScalingTime then
            PallyPower.ScalingTime = 0
        end
        PallyPower.ScalingTime = PallyPower.ScalingTime + arg1
        if PallyPower.ScalingTime > 0.25 then
            PallyPower.ScalingTime = 0
            local frame = PallyPower.FrameToScale
            local oldscale = frame:GetEffectiveScale()
            local framex, framey, cursorx, cursory = frame:GetLeft() * oldscale, frame:GetTop() * oldscale,
                GetCursorPosition()
            if PallyPower.ScalingWidth > PallyPower.ScalingHeight then
                if (cursorx - framex) > 32 then
                    local newscale = (cursorx - framex) / PallyPower.ScalingWidth
                    SimplePallyPower_ScaleFrame(newscale)
                end
            else
                if (framey - cursory) > 32 then
                    local newscale = (framey - cursory) / PallyPower.ScalingHeight
                    SimplePallyPower_ScaleFrame(newscale)
                end
            end
        end
    end

    function SimplePallyPower_SetOption(opt, value)
        db[opt] = value
    end

    function SimplePallyPower_Options()
        PallyPower.Frame:Hide()
        SimpleUI_Config_Window_Toggle()
    end

    function SimplePallyPowerGridButton_OnMouseWheel(btn, arg1)
        local _, _, pnum, class = find(btn:GetName(), "SimplePowerFramePlayer(%d+)Class(%d+)");
        pnum = pnum + 0;
        class = class + 0;
        local pname = getglobal("SimplePowerFramePlayer" .. pnum .. "Name"):GetText()
        if not SimplePallyPower_CanControl(pname) then
            return false
        end

        if (arg1 == -1) then
            --mouse wheel down
            SimplePallyPower_PerformCycle(pname, class)
        else
            PallyPower_PerformCycleBackwards(pname, class)
        end
    end

    local function SimplePallyPower_OnLoad()
        this:RegisterEvent("SPELLS_CHANGED");
        this:RegisterEvent("PLAYER_ENTERING_WORLD");
        this:RegisterEvent("CHAT_MSG_ADDON");
        this:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH");
        this:RegisterEvent("PLAYER_LOGIN");
        this:RegisterEvent("PARTY_MEMBERS_CHANGED");
        this:SetBackdropColor(0.0, 0.0, 0.0, 0.5);
        this:SetScale(1);
    end

    local function CreatePallyPowerBuffBar()
        local buffBar = CreateFrame("Frame", "SimplePallyPowerBuffBar", UIParent)
        buffBar:SetFrameStrata("LOW")
        buffBar:EnableMouse(true)
        buffBar:SetMovable(true)
        buffBar:SetWidth(110)
        buffBar:SetHeight(302)
        buffBar:SetPoint("LEFT", UIParent, "LEFT", 10, 0)
        buffBar.startPosX = buffBar:GetLeft();
        buffBar.startPosY = buffBar:GetTop();

        local title = CreateFrame("Button", buffBar:GetName() .. "Title", buffBar)
        title:SetPoint("TOP", buffBar, "TOP", 0, -5)
        title:SetWidth(110)
        title:SetHeight(20)

        title:SetScript("OnEnter", function()
            if SimplePallyPower_ShowCredits then
                SimplePallyPower_ShowCredits();
            end
        end)
        title:SetScript("OnLeave", function()
            HideUIPanel(GameTooltip);
        end)

        title:SetScript("OnMouseDown", function()
            if SimplePallyPowerBuffBar_MouseDown then
                SimplePallyPowerBuffBar_MouseDown(arg1)
            end
        end)

        title:SetScript("OnMouseUp", function()
            if SimplePallyPowerBuffBar_MouseUp then
                SimplePallyPowerBuffBar_MouseUp()
            end
        end)

        title.text = title:CreateFontString(title:GetName() .. "Text", "OVERLAY")
        title.text:SetFontObject(GameFontNormal)
        title.text:SetText("Paladin Buffs")
        title.text:SetJustifyH("CENTER")
        title.text:SetWidth(130)
        title.text:SetHeight(12)
        title.text:SetPoint("CENTER", title, "CENTER", 0, 0)

        buffBar.Title = title
        buffBar.Title.Text = title.text

        for i = 1, 10 do
            local buffButton = CreateFrame("Button", buffBar:GetName() .. "Buff" .. i, buffBar,
                "SimplePallyPowerBuffButtonTemplate")

            buffButton.Border = CreateFrame("Frame", nil, buffButton)
            buffButton.Border:SetBackdrop({
                edgeFile = SimpleUI_GetTexture("ThickBorder"),
                edgeSize = 14,
            })
            buffButton.Border:SetPoint("TOPLEFT", buffButton, "TOPLEFT", -7, 4)
            buffButton.Border:SetPoint("BOTTOMRIGHT", buffButton, "BOTTOMRIGHT", 7, -4)
            buffButton.Border:SetFrameLevel(buffButton:GetFrameLevel())
            if i == 1 then
                buffButton:SetPoint("TOPLEFT", buffBar, "TOPLEFT", 5, -25)
            else
                buffButton:SetPoint("TOPLEFT", buffBar["Buff" .. (i - 1)], "BOTTOMLEFT", 0, 0)
            end
            buffBar["Buff" .. i] = buffButton
        end

        local resizeBtn = CreateFrame("Button", buffBar:GetName() .. "ResizeButton", buffBar, "SimplePowerResizeTemplate")
        resizeBtn:SetPoint("BOTTOMRIGHT", buffBar, "BOTTOMRIGHT", 1, 1)

        buffBar:SetScript("OnUpdate", function()
            if SimplePallyPower_OnUpdate then
                SimplePallyPower_OnUpdate(arg1)
            end
        end)

        return buffBar
    end

    local function CreatePallyPowerFrame()
        local frame = CreateFrame("Frame", "SimplePowerFrame", UIParent)
        frame:SetFrameStrata("LOW")
        frame:EnableMouse(false)
        frame:SetMovable(false)
        --frame:RegisterForDrag("LeftButton")
        frame:SetWidth(705)
        frame:SetHeight(760)
        frame:SetPoint("TOP", UIParent, "TOP", 0, -75)
        frame:SetBackdrop({
            bgFile = SimpleUI_GetTexture("RockBgLight"),
            edgeFile = SimpleUI_GetTexture("ThickBorder"),
            edgeSize = 14,
            insets = { left = 7, right = 7, top = 7, bottom = 7 }
        })
        frame:Hide()

        local addonNameTxt = frame:CreateFontString(nil, "OVERLAY")
        addonNameTxt:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -45)
        addonNameTxt:SetFontObject(GameFontNormal)
        addonNameTxt:SetText("SimpleUI Edition")

        local NUM_LINES = 10
        local verticalLines = {}
        for i = 1, NUM_LINES do
            local line = frame:CreateTexture(frame:GetName() .. "Line" .. i, "ARTWORK")
            line:SetWidth(1)
            line:SetHeight(56)
            line:SetTexture("Interface\\BUTTONS\\WHITE8X8")
            line:SetVertexColor(1, 0.84, 0, 1)

            if i == 1 then
                line:SetPoint("TOPLEFT", frame, "TOPLEFT", 135, -24)
            else
                line:SetPoint("TOPLEFT", verticalLines[i - 1], "TOPLEFT", 56, 0)
            end

            verticalLines[i] = line
        end

        local classIcons = {}
        for i = 1, 10 do
            local icon = frame:CreateTexture(frame:GetName() .. "Class" .. i, "ARTWORK")
            icon:SetWidth(32)
            icon:SetHeight(32)
            icon:SetTexture(classIconPaths[i])

            if i == 1 then
                icon:SetPoint("TOPLEFT", verticalLines[1], "TOPLEFT", 12, -12)
            else
                icon:SetPoint("TOPLEFT", classIcons[i - 1], "TOPLEFT", 56, 0)
            end

            classIcons[i] = icon
        end

        local title = CreateFrame("Button", frame:GetName() .. "Title", frame)
        title:SetPoint("TOP", frame, "TOP", 0, -7)
        title:SetWidth(100)
        title:SetHeight(20)

        title.TitleBarBorder = CreateFrame("Frame", nil, title)
        title.TitleBarBorder:SetBackdrop({
            bgFile = SimpleUI_GetTexture("StatusbarDefault"),
            tile = false,
            tileSize = 0,
            edgeFile = SimpleUI_GetTexture("ThickBorder"),
            edgeSize = 14,
            insets = { left = 6, right = 6, top = 6, bottom = 6 },
        })
        title.TitleBarBorder:SetBackdropColor(0.25, 0.25, 0.25, 1)
        title.TitleBarBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        title.TitleBarBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        title.TitleBarBorder:SetHeight(32)
        title.TitleBarBorder:SetFrameLevel(title:GetFrameLevel())

        title:SetScript("OnEnter", function()
            if SimplePallyPower_ShowCredits then
                SimplePallyPower_ShowCredits()
            end
        end)

        title:SetScript("OnLeave", function()
            HideUIPanel(GameTooltip)
        end)

        title:SetScript("OnMouseDown", function()
            if SimplePallyPowerFrame_MouseDown then
                SimplePallyPowerFrame_MouseDown(arg1)
            end
        end)

        title:SetScript("OnMouseUp", function()
            if SimplePallyPowerFrame_MouseUp then
                SimplePallyPowerFrame_MouseUp()
            end
        end)

        title:SetScript("OnUpdate", function()
            if SimplePallyPowerGrid_Update then
                SimplePallyPowerGrid_Update()
            end
        end)

        frame.Title = title

        local text = title:CreateFontString(title:GetName() .. "Text", "OVERLAY")
        text:SetFontObject(GameFontNormal)
        text:SetText("Pally Power")
        text:SetJustifyH("CENTER")
        text:SetWidth(100)
        text:SetHeight(12)
        text:SetPoint("LEFT", title, "LEFT", 5, 0)

        frame.Title.Text = text

        local close = CreateFrame("Button", frame:GetName() .. "CloseButton", frame, "UIPanelCLoseButton")
        close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

        frame.Close = close

        local refresh = CreateFrame("Button", frame:GetName() .. "Refresh", frame, "GameMenuButtonTemplate")
        refresh:SetText("Refresh")
        refresh:SetWidth(100)
        refresh:SetHeight(18)
        refresh:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -9, 9)
        refresh:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        local refreshNorm = refresh:GetNormalTexture()
        local refreshHigh = refresh:GetHighlightTexture()
        local refreshPush = refresh:GetPushedTexture()
        refreshNorm:SetTexture(SimpleUI_GetTexture("StatusbarDefault"))
        refreshNorm:SetVertexColor(0.25, 0.25, 0.25, 1)
        refreshHigh:SetTexture(SimpleUI_GetTexture("StatusbarDefault"))
        refreshHigh:SetVertexColor(0.7, 0.54, 0, 1)
        refreshPush:SetTexture(SimpleUI_GetTexture("StatusbarDefault"))
        refreshPush:SetVertexColor(0.5, 0.34, 0, 1)

        --SimpleUI_GetTexture("StatusbarDefault")
        refresh.Border = CreateFrame("Frame", nil, refresh)
        refresh.Border:SetBackdrop({
            edgeFile = SimpleUI_GetTexture("ThickBorder"),
            edgeSize = 14,
        })
        refresh.Border:SetPoint("TOPLEFT", refresh, "TOPLEFT", -7, 7)
        refresh.Border:SetPoint("BOTTOMRIGHT", refresh, "BOTTOMRIGHT", 7, -7)
        refresh.Border:SetHeight(32)
        refresh.Border:SetFrameLevel(refresh:GetFrameLevel() + 1)

        refresh:SetScript("OnClick", function()
            if SimplePallyPower_Refresh then
                SimplePallyPower_Refresh()
            end
        end)

        frame.Refresh = refresh

        local clear = CreateFrame("Button", frame:GetName() .. "Clear", frame, "GameMenuButtonTemplate")
        clear:SetText("Clear All")
        clear:SetWidth(100)
        clear:SetHeight(20)
        clear:SetPoint("BOTTOMRIGHT", refresh, "BOTTOMLEFT", -7, 0)
        clear:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        local clearNorm = clear:GetNormalTexture()
        local clearHigh = clear:GetHighlightTexture()
        local clearPush = clear:GetPushedTexture()
        clearNorm:SetTexture(SimpleUI_GetTexture("StatusbarDefault"))
        clearNorm:SetVertexColor(0.25, 0.25, 0.25, 1)
        clearHigh:SetTexture(SimpleUI_GetTexture("StatusbarDefault"))
        clearHigh:SetVertexColor(0.7, 0.54, 0, 1)
        clearPush:SetTexture(SimpleUI_GetTexture("StatusbarDefault"))
        clearPush:SetVertexColor(0.5, 0.34, 0, 1)

        clear.Border = CreateFrame("Frame", nil, clear)
        clear.Border:SetBackdrop({
            edgeFile = SimpleUI_GetTexture("ThickBorder"),
            edgeSize = 14,
        })
        clear.Border:SetPoint("TOPLEFT", clear, "TOPLEFT", -7, 7)
        clear.Border:SetPoint("BOTTOMRIGHT", clear, "BOTTOMRIGHT", 7, -7)
        clear.Border:SetHeight(32)
        clear.Border:SetFrameLevel(clear:GetFrameLevel() + 1)

        clear:SetScript("OnClick", function()
            if SimplePallyPower_Clear then
                SimplePallyPower_Clear()
            end
        end)

        frame.Clear = clear

        local options = CreateFrame("Button", frame:GetName() .. "Options", frame, "GameMenuButtonTemplate")
        options:SetText("Config")
        options:SetWidth(100)
        options:SetHeight(20)
        options:SetPoint("BOTTOMRIGHT", clear, "BOTTOMLEFT", -7, 0)
        options:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        local optionsNorm = options:GetNormalTexture()
        local optionsHigh = options:GetHighlightTexture()
        local optionsPush = options:GetPushedTexture()
        optionsNorm:SetTexture(SimpleUI_GetTexture("StatusbarDefault"))
        optionsNorm:SetVertexColor(0.25, 0.25, 0.25, 1)
        optionsHigh:SetTexture(SimpleUI_GetTexture("StatusbarDefault"))
        optionsHigh:SetVertexColor(0.7, 0.54, 0, 1)
        optionsPush:SetTexture(SimpleUI_GetTexture("StatusbarDefault"))
        optionsPush:SetVertexColor(0.5, 0.34, 0, 1)

        options.Border = CreateFrame("Frame", nil, options)
        options.Border:SetBackdrop({
            edgeFile = SimpleUI_GetTexture("ThickBorder"),
            edgeSize = 14,
        })
        options.Border:SetPoint("TOPLEFT", options, "TOPLEFT", -7, 7)
        options.Border:SetPoint("BOTTOMRIGHT", options, "BOTTOMRIGHT", 7, -7)
        options.Border:SetHeight(32)
        options.Border:SetFrameLevel(options:GetFrameLevel() + 1)

        options:SetScript("OnClick", function()
            SimplePallyPower_Options()
        end)

        frame.Options = options

        local resize = CreateFrame("Frame", frame:GetName() .. "ResizeButton", frame, "SimplePowerResizeTemplate")
        resize:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)

        frame.Resize = resize

        local NUM_PLAYER_FRAMES = 10
        local playerFrames = {}
        for i = 1, NUM_PLAYER_FRAMES do
            local playerFrame = CreateFrame("Frame", frame:GetName() .. "Player" .. i, frame, "SimpleUserTemplate")

            for lineIndex = 1, 11 do
                local lineName = playerFrame:GetName() .. "Line" .. lineIndex
                local line = _G[lineName]
                if line then
                    line:SetVertexColor(1, 0.84, 0, 1) -- Example: green color
                end
            end

            for classIndex = 1, 10 do
                local className = playerFrame:GetName() .. "Class" .. classIndex
                local class = _G[className]
                if class then
                    class.Glow = CreateFrame("Frame", nil, class)
                    class.Glow:SetPoint("TOPLEFT", class, "TOPLEFT", 11, -11)
                    class.Glow:SetPoint("BOTTOMRIGHT", class, "BOTTOMRIGHT", -11, 11)
                    class.Glow:SetBackdrop({
                        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
                        edgeSize = 2,
                    })
                    class.Glow:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

                    class:SetScript("OnEnter", function()
                        class.Glow:SetBackdropBorderColor(0.9, 0.74, 0, 1)
                    end)

                    class:SetScript("OnLeave", function()
                        class.Glow:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
                    end)
                end
            end

            if i == 1 then
                playerFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -80)
            else
                playerFrame:SetPoint("TOPLEFT", playerFrames[i - 1], "BOTTOMLEFT", 0, 0)
            end
            playerFrames[i] = playerFrame
        end


        frame.PlayerFrames = playerFrames

        frame:RegisterEvent("SPELLS_CHANGED");
        frame:RegisterEvent("PLAYER_ENTERING_WORLD");
        frame:RegisterEvent("CHAT_MSG_ADDON");
        frame:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH");
        frame:RegisterEvent("PLAYER_LOGIN");
        frame:RegisterEvent("PARTY_MEMBERS_CHANGED");
        --frame:SetBackdropColor(0.0, 0.0, 0.0, 0.5);
        frame:SetScale(1);


        frame:SetScript("OnEvent", function()
            if SimplePallyPower_OnEvent then
                SimplePallyPower_OnEvent(event)
            end
        end)

        frame:SetScript("OnMouseUp", function()
            if SimplePallyPowerFrame_MouseUp then
                SimplePallyPowerFrame_MouseUp()
            end
        end)

        frame:SetScript("OnMouseDown", function()
            if SimplePallyPowerFrame_MouseDown then
                SimplePallyPowerFrame_MouseDown(arg1)
            end
        end)

        frame:SetScript("OnHide", function()
            if this.isMoving then
                this:StopMovingOrSizing();
                this.isMoving = false;
            end
        end)

        return frame
    end

    local function CreateScalingFrame()
        local frame = CreateFrame("Frame", "SimplePallyPower_ScalingFrame")
        frame:SetScript("OnUpdate", function()
            if SimplePallyPower_ScalingFrame_OnUpdate then
                SimplePallyPower_ScalingFrame_OnUpdate(arg1)
            end
        end)
        frame:Hide()
        return frame
    end

    PallyPower.BuffBar = CreatePallyPowerBuffBar()
    PallyPower.Frame = CreatePallyPowerFrame()
    PallyPower.Scaling = CreateScalingFrame()
end)
