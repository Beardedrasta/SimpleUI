local Castbar = CreateFrame("Frame")
local _G = getfenv(0)
local u = SUI_Util
SuperWoW = SpellInfo ~= nil


SimpleUI:AddModule("Castbar", function()
    if SimpleUI:IsDisabled("Castbar") then return end

    local db = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].castbar
    local font = db.font;
    local fontSize = db.fontSize;
    local border = 2;
    local castTexture = SimpleUI_GetTexture(db.texture);
    local anchoredToFrame = db.anchorToFrame;

    ----------------------------------------------------------------
    -- 1) HELPER: CREATE THE FRAME
    ----------------------------------------------------------------

    local function CreateCastbar(name, parent, unitstr, unitname)
        local cb = CreateFrame("Frame", name, parent or UIParent)
        cb:SetHeight(fontSize * 1.5)
        cb:SetFrameStrata("MEDIUM")
        cb:SetFrameLevel(8)

        cb.unitstr = unitstr
        cb.unitname = unitname

        --cb.holder.overlay = cb.holder:CreateTexture(nil, "OVERLAY")
        --cb.holder.overlay:SetAllPoints(cb.holder)
        --cb.holder.overlay:SetTexture(0, 0.5, 0.9, 0.6)



        ----------------------------------------------------------------
        -- 1A) ICON FRAME & TEXTURES
        ----------------------------------------------------------------

        cb.icon = CreateFrame("Frame", nil, cb)
        cb.icon:SetPoint("TOPLEFT", 0, 0)
        cb.icon:SetHeight(16)
        cb.icon:SetWidth(16)

        cb.icon.texture = cb.icon:CreateTexture(nil, "OVERLAY")
        cb.icon.texture:SetAllPoints()
        cb.icon.texture:SetTexCoord(.08, .92, .08, .92)

        ----------------------------------------------------------------
        -- 1B) STATUSBAR (CAST BAR) & BACKDROP
        ----------------------------------------------------------------

        cb.bar = CreateFrame("StatusBar", nil, cb)
        cb.bar:SetStatusBarTexture(castTexture)
        cb.bar:ClearAllPoints()
        cb.bar:SetAllPoints(cb)
        cb.bar:SetMinMaxValues(0, 100)
        cb.bar:SetValue(20)
        local r, g, b, a = u.Strsplit(",", db.castbarcolor)
        cb.bar:SetStatusBarColor(r, g, b, a)

        cb.Border = CreateFrame("Frame", nil, cb.bar)
        cb.Border:SetBackdrop({
            edgeFile = SimpleUI_GetTexture("ThickBorder"),
            edgeSize = 14,
        })
        cb.Border:SetPoint("TOPLEFT", cb.icon, "TOPLEFT", -7, 7)
        cb.Border:SetPoint("BOTTOMRIGHT", cb.bar, "BOTTOMRIGHT", 7, -7)

        cb.BG = cb.bar:CreateTexture(nil, "BACKGROUND")
        cb.BG:SetTexture(0.1, 0.1, 0.1, 0.8)
        cb.BG:SetPoint("TOPLEFT", cb.icon, "TOPLEFT", 0, 0)
        cb.BG:SetPoint("BOTTOMRIGHT", cb.bar, "BOTTOMRIGHT", 0, 0)
        cb.BG:SetAllPoints(cb.bar)

        ----------------------------------------------------------------
        -- 1C) LEFT & RIGHT TEXT
        ----------------------------------------------------------------

        cb.bar.left = cb.bar:CreateFontString(nil, "DIALOG", "GameFontNormal")
        cb.bar.left:ClearAllPoints()
        cb.bar.left:SetPoint("TOPLEFT", cb.bar, "TOPLEFT", 3, 0)
        cb.bar.left:SetPoint("BOTTOMRIGHT", cb.bar, "BOTTOMRIGHT", -3, 0)
        cb.bar.left:SetNonSpaceWrap(false)
        cb.bar.left:SetFontObject(GameFontWhite)
        cb.bar.left:SetTextColor(1, 1, 1, 1)
        cb.bar.left:SetFont(font, fontSize, "OUTLINE")
        cb.bar.left:SetJustifyH("LEFT")

        cb.bar.right = cb.bar:CreateFontString(nil, "DIALOG", "GameFontNormal")
        cb.bar.right:ClearAllPoints()
        cb.bar.right:SetPoint("TOPLEFT", cb.bar, "TOPLEFT", 3, 0)
        cb.bar.right:SetPoint("BOTTOMRIGHT", cb.bar, "BOTTOMRIGHT", -3, 0)
        cb.bar.right:SetNonSpaceWrap(false)
        cb.bar.right:SetFontObject(GameFontWhite)
        cb.bar.right:SetTextColor(1, 1, 1, 1)
        cb.bar.right:SetFont(font, fontSize, "OUTLINE")
        cb.bar.right:SetJustifyH("RIGHT")

        ----------------------------------------------------------------
        -- 1D) LAG TEXTURE (for latency)
        ----------------------------------------------------------------

        cb.bar.lag = cb.bar:CreateTexture(nil, "OVERLAY")
        cb.bar.lag:SetPoint("TOPRIGHT", cb.bar, "TOPRIGHT", 0, 0)
        cb.bar.lag:SetPoint("BOTTOMRIGHT", cb.bar, "BOTTOMRIGHT", 0, 0)
        cb.bar.lag:SetTexture(1, 0.2, 0.2, 0.2)

        ----------------------------------------------------------------
        -- 1E) UPDATE SCRIPT
        ----------------------------------------------------------------

        cb:SetScript("OnUpdate", function()
            if this.drag and this.drag:IsShown() then
                this:SetAlpha(1)
                return
            end

            if not UnitExists(this.unitstr) then
                this:SetAlpha(0)
            end

            if this.fadeout and this:GetAlpha() > 0 then
                if this:GetAlpha() == 0 then
                    this.fadeout = nil
                end

                this:SetAlpha(this:GetAlpha() - 0.05)
            end

            --local channel
            local name = this.unitstr and UnitName(this.unitstr) or this.unitname
            local query = this.unitstr or this.unitname
            if not name then return end

            -- try to read cast and guid from SuperWoW (except for self casts)
            if SuperWoW and this.unitstr and not UnitIsUnit(this.unitstr, 'player') then
                local _, guid = UnitExists(this.unitstr)
                query = guid or query
            end

            ----------------------------------------------------------------
            -- Attempt to read cast info (or channel info if no cast)
            ----------------------------------------------------------------

            --[[             local cast, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(query)
            if not cast then
                channel, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(query)
                cast = channel
            end ]]

            local cast, nameSubtext, texture, startTime, endTime
            local isTradeSkill
            cast, nameSubtext, _, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(query)
            if not cast then
                cast, nameSubtext, _, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(query)
            end

            if cast then
                local duration = endTime - startTime
                local max = duration / 1000
                local cur = GetTime() - startTime / 1000

                this:SetAlpha(1)

                local isChannel = (UnitChannelInfo(query) ~= nil)
                local barColorKey = isChannel and "channelcolor" or "castbarcolor"
                this.bar:SetStatusBarColor(u.Strsplit(",", db[barColorKey]))
                this.bar:SetMinMaxValues(0, max)

                local spellname = this.showname and cast and (cast .. " ") or ""
                local rank = (this.showrank and nameSubtext and nameSubtext ~= "")
                    and string.format("|cffaaffcc[%s]|r", nameSubtext)
                    or ""

                ----------------------------------------------------------------
                -- If newly cast or channel changed
                ----------------------------------------------------------------

                if this.endTime ~= endTime then
                    this.bar.left:SetText(spellname .. rank)
                    this.fadeout = nil
                    this.endTime = endTime

                    -- set texture
                    if texture and this.showicon then
                        local size = this.unit == "player" and db.height or this:GetHeight()
                        this.icon:Show()
                        this.icon:SetHeight(size)
                        this.icon:SetWidth(size)
                        this.icon.texture:SetTexture(texture)
                        this.bar:SetPoint("TOPLEFT", this.icon, "TOPRIGHT", this.spacing, 0)
                    else
                        this.bar:SetPoint("TOPLEFT", this, 0, 0)
                        this.icon:Hide()
                    end

                    if this.showlag then
                        local _, _, lag = GetNetStats()
                        local width = this:GetWidth() / max * (lag / 1000)
                        this.bar.lag:SetWidth(math.min(this:GetWidth(), width))
                    else
                        this.bar.lag:Hide()
                    end
                end

                if isChannel then
                    cur = max + (startTime / 1000) - GetTime()
                end

                if cur > max then
                    cur = max
                elseif cur < 0 then
                    cur = 0
                end

                this.bar:SetValue(cur)

                ----------------------------------------------------------------
                -- Timer text (with delay if any)
                ----------------------------------------------------------------

                if this.showtimer then
                    if this.delay and this.delay > 0 then
                        local sign = isChannel and "-" or "+"
                        local delayStr = string.format("|cffffaaaa%s%.1f|r ", sign, this.delay)
                        this.bar.right:SetText(delayStr .. string.format("%.1f / %.1f", cur, u.Round(max, 1)))
                    else
                        this.bar.right:SetText(string.format("%.1f / %.1f", cur, u.Round(max, 1)))
                    end
                end

                this.fadeout = nil
            else
                this.bar:SetMinMaxValues(1, 100)
                this.bar:SetValue(100)
                this.fadeout = 1
                this.delay = 0
            end
        end)

        ----------------------------------------------------------------
        -- 1F) EVENT HANDLER (for delay, channel updates, etc.)
        ----------------------------------------------------------------
        ---

        cb:RegisterEvent("SPELLCAST_DELAYED")
        cb:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
        cb:RegisterEvent("SPELLCAST_START")
        cb:RegisterEvent("SPELLCAST_CHANNEL_START")

        local function CastEventHandler()
            if cb.unitstr and not UnitIsUnit(cb.unitstr, "player") then
                return
            end
            local isPlayer = (arg1 == "player")
            if not isPlayer then
                return
            end

            if event == "SPELLCAST_DELAYED" then
                local isCast, _, _, _, _, endTime = UnitCastingInfo(cb.unitstr or cb.unitname)
                if not isCast or not cb.endTime then
                    return
                end
                cb.delay = cb.delay + ((endTime - cb.endTime) / 1000)
            elseif event == "SPELLCAST_CHANNEL_UPDATE" then
                local isChannel, _, _, _, startTime, endTime = UnitChannelInfo(cb.unitstr or cb.unitname)
                if not isChannel then
                    return
                end

                local remainOld = cb.bar:GetValue()
                local remainNew = (endTime / 1000) - GetTime()
                cb.delay = (cb.delay or 0) + (remainOld - remainNew)
            else
                cb.delay = 0
            end
        end
        cb:SetScript("OnEvent", CastEventHandler)

        ----------------------------------------------------------------
        -- 1G) FINAL SETUP
        ----------------------------------------------------------------

        cb:SetAlpha(0)
        cb.delay = 0
        return cb
    end

    ----------------------------------------------------------------
    -- 2) DISABLE THE DEFAULT CASTBAR
    ----------------------------------------------------------------

    Castbar.bar = CreateFrame("Frame", "SimpleUICastbar", UIParent)

    CastingBarFrame:SetScript("OnShow", function()
        CastingBarFrame:Hide()
    end)
    CastingBarFrame:UnregisterAllEvents()
    CastingBarFrame:Hide()

    local function SetupCastbar(cbFrame, unitTag, target)
        cbFrame.showicon  = (db.showicon == 1)
        cbFrame.showname  = (db.showname == 1)
        cbFrame.showtimer = (db.showtimer == 1)
        cbFrame.showlag   = (db.showlag == 1)
        cbFrame.showrank  = (db.showrank == 1)
        cbFrame.spacing   = border * 2 + -1 * u.GetPerfectPixel()
        cbFrame.unit = unitTag

        local anchorFrame = SimpleUI[unitTag]
        local width = anchorFrame:GetWidth()
        cbFrame:SetPoint("BOTTOMLEFT", anchorFrame, "TOPLEFT", 0, 25)
        cbFrame:SetWidth(width)

        if db.height ~= -1 then
            cbFrame:SetHeight(20)
        end
    end

    Castbar.bar.player   = CreateCastbar("SimpleUIPlayerCastbar", UIParent, "player")
    local playerCast     = Castbar.bar.player
    playerCast.showicon  = (db.showicon == 1)
    playerCast.showname  = (db.showname == 1)
    playerCast.showtimer = (db.showtimer == 1)
    playerCast.showlag   = (db.showlag == 1)
    playerCast.showrank  = (db.showrank == 1)
    playerCast.spacing   = border * 2 + -1 * u.GetPerfectPixel()
    playerCast.unit = "player"

    local holder         = CreateFrame("Frame", Castbar.bar.player:GetName() .. "CastbarHolder", UIParent)
    holder:EnableMouse(true)
    holder:SetMovable(true)
    holder:SetClampedToScreen(true)
    holder:SetWidth(db.width)
    holder:SetHeight(db.height)
    holder:Hide()
    holder:SetFrameLevel(Castbar.bar.player:GetFrameLevel() + 1)
    holder:SetBackdrop({
        bgFile = "Interface\\AddOns\\SimpleUI\\Media\\Textures\\SimpleUI-Default.blp",
    })

    do
        local pos = db.Pos
        if pos then
            holder:ClearAllPoints()
            holder:SetPoint(pos.point, pos.parentName, pos.relativePoint, pos.xOfs, pos.yOfs)
        else
            holder:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
        end
        if not db.anchorToFrame then
            playerCast:ClearAllPoints()
            playerCast:SetPoint("BOTTOMLEFT", _G.SimpleUIplayer, "TOPLEFT", 0, 25)
            playerCast:SetWidth(_G.SimpleUIplayer:GetWidth())
        else
            playerCast:ClearAllPoints()
            playerCast:SetAllPoints(holder)
        end
    end

    holder:RegisterForDrag("LeftButton")
    holder:SetScript("OnMouseDown", function()
        holder:StartMoving()
    end)

    holder:SetScript("OnMouseUp", function()
        holder:StopMovingOrSizing()


        local point, relativeTo, relativePoint, xOfs, yOfs = this:GetPoint()
        local parentName = "UIParent"

        db.Pos = {
            point = point,
            parentName = parentName,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs,
        }

        --[[         if SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].castbar.anchorToFrame == 0 then
            local castbar = Castbar.bar.player
            castbar:ClearAllPoints()
            castbar:SetPoint(point, parentName, relativePoint, xOfs, yOfs)
        end ]]
    end)


    Castbar.bar.holder = holder


    Castbar.bar.target = CreateCastbar("SimpleUITargetCastbar", UIParent, "target")
    SetupCastbar(Castbar.bar.target, "target", "SimpleUI.target", true)

    function Castbar:UpdateVisibility(logic)
        local func = logic
        if func and holder then
            holder:Hide()
        else
            holder:Show()
        end
    end

    function Castbar:UpdateConfig()
        playerCast:SetWidth(db.width)
        playerCast:SetHeight(db.height)
        holder:SetWidth(db.width)
        holder:SetHeight(db.height)
    end


end)

function SimpleUI_ToggleCastbarOverlay(logic)
    Castbar:UpdateVisibility(logic)
end

function SimpleUI_UpdateCastbarConfig()
    Castbar:UpdateConfig()
end

--[[ function SimpleUI_RemoveCastFromPlayer()
    local db = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].castbar
    if db.anchorToFrame == 0 then
        Castbar.bar.player:ClearAllPoints()
        Castbar.bar.player:SetPoint("BOTTOMLEFT", _G.SimpleUIplayer, "TOPLEFT", 0, 25)
        Castbar.bar.player:SetWidth(_G.SimpleUIplayer:GetWidth())
    else
        Castbar.bar.player:SetAllPoints(_G.SimpleUIPlayerCastbarCastbarHolder)
    end
end ]]
