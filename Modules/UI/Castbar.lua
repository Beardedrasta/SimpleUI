SimpleUI:AddModule("Castbar", function()
    if SimpleUI:IsDisabled("Castbar") then return end

    local _G = getfenv(0)
    local SUI
    SuperWow = (SpellInfo ~= nil)

    ----------------------------------------------------------------
    -- Castbar Object
    ----------------------------------------------------------------
    SUICastbar = {}
    SUICastbar.__index = SUICastbar

    function SUICastbar:New(name, parent, unitstr, unitname)
        SUI = SimpleUI
        local obj = {
            name     = name,
            parent   = parent or UIParent,
            unitstr  = unitstr,
            unitname = unitname,
            db       = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Unitframes"].castbar,
            util     = SUI_Util,
            frame    = CreateFrame("Frame", name, parent or UIParent),
            holder   = CreateFrame("Frame", name.."Holder", UIParent)
        }
        setmetatable(obj, self)
        obj:Initialize()
        return obj
    end

    function SUICastbar:Initialize()
        local db = self.db
        local frame = self.frame

        frame:SetHeight(db.height)
        frame:SetWidth(db.width)
        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(8)

        self.holder:SetHeight(db.height)
        self.holder:SetWidth(db.width)
        self.holder.tex = self.holder:CreateTexture(nil, "OVERLAY")
        self.holder.tex:SetAllPoints()
        self.holder.tex:SetTexture(SimpleUI_GetTexture(db.texture))
        self.holder.tex:SetVertexColor(1, 1, 1, 0.6)

        self.icon = CreateFrame("Frame", nil, frame)
        self.icon:SetPoint("TOPLEFT", 0, 0)
        self.icon:SetWidth(16)
        self.icon:SetHeight(16)
        self.icon.texture = self.icon:CreateTexture(nil, "OVERLAY")
        self.icon.texture:SetAllPoints()
        self.icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        self.bar = CreateFrame("StatusBar", nil, frame)
        self.bar:SetStatusBarTexture(SimpleUI_GetTexture(db.texture))
        self.bar:SetAllPoints(frame)
        self.bar:SetMinMaxValues(0, 100)
        self.bar:SetValue(20)

        self.bar:SetStatusBarColor(self.util.Strsplit(", ", db.castbarcolor))

        self.border = CreateFrame("Frame", nil, self.bar)
        self.border:SetBackdrop({
            edgeFile = SimpleUI_GetTexture("ThickBorder"),
            edgeSize = 14,
        })
        self.border:SetPoint("TOPLEFT", self.icon, "TOPLEFT", -7, 7)
        self.border:SetPoint("BOTTOMRIGHT", self.bar, "BOTTOMRIGHT", 7, -7)

        self.bg = self.bar:CreateTexture(nil, "BACKGROUND")
        self.bg:SetTexture(0.1, 0.1, 0.1, 0.8)
        self.bg:SetAllPoints(self.bar)

        self.leftText = self.bar:CreateFontString(nil, "DIALOG", "GameFontNormal")
        self.leftText:SetPoint("LEFT", self.bar, "LEFT", 3, 0)
        self.leftText:SetFont(db.font, db.fontSize, "OUTLINE")
        self.leftText:SetJustifyH("LEFT")

        self.rightText = self.bar:CreateFontString(nil, "DIALOG", "GameFontNormal")
        self.rightText:SetPoint("RIGHT", self.bar, "RIGHT", -3, 0)
        self.rightText:SetFont(db.font, db.fontSize, "OUTLINE")
        self.rightText:SetJustifyH("RIGHT")

        self.lag = self.bar:CreateTexture(nil, "OVERLAY")
        self.lag:SetPoint("TOPRIGHT", self.bar, "TOPRIGHT", 0, 0)
        self.lag:SetPoint("BOTTOMRIGHT", self.bar, "BOTTOMRIGHT", 0, 0)
        self.lag:SetTexture(1, 0.2, 0.2, 0.2)

        frame:SetAlpha(0)
        self.fadeout = 1
        self.delay = 0
        self.spacing = 2 * 2 + -1
    end

    function SUICastbar:Update()
        if self.unitstr and not UnitIsUnit(self.unitstr, "player") then
            return
        end

        local isPlayer = (arg1 == "player")
        if not isPlayer then
            return
        end

        if event == "SPELLCAST_DELAYED" then
            local isCast, _, _, _, _, endTime = UnitCastingInfo(self.unitstr or self.unitname)
            if not isCast or not self.endTime then
                return
            end
            self.delay = self.delay + ((endTime - self.endTime) / 1000)
        elseif event == "SPELLCAST_CHANNEL_UPDATE" then
            local isChannel, _, _, _, startTime, endTime = UnitChannelInfo(cb.unitstr or self.unitname)
            if not isChannel then
                return
            end

            local remainOld = self.bar:GetValue()
            local remainNew = (endTime / 1000) - GetTime()
            self.delay = (self.delay or 0) + (remainOld - remainNew)
        else
            self.delay = 0
        end
    end

    function SUICastbar:HandleEvents()
        SUICastbar:Update()
    end

    function SUICastbar:RegisterEvents()
        self.frame:RegisterEvent("SPELLCAST_START")
        self.frame:RegisterEvent("SPELLCAST_STOP")
        self.frame:RegisterEvent("SPELLCAST_CHANNEL_START")
        self.frame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
        self.frame:RegisterEvent("SPELLCAST_DELAYED")
        self.frame:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
        self.frame:SetScript("OnEvent", function() self:HandleEvents() end)
    end

    ----------------------------------------------------------------
    -- OnUpdate Script
    ----------------------------------------------------------------

    function SUICastbar:HandleScripts()
        if not UnitExists(self.unitstr) then
            self.frame:SetAlpha(0)
        end

        if self.fadeout and (self.frame:GetAlpha() > 0) then
            local alpha = self.frame:GetAlpha() - 0.05
            if alpha <= 0 then
                alpha = 0
                self.fadeout = nil
            end
            self.frame:SetAlpha(alpha)
        end

        local ident = self.unitstr and UnitName(self.unitstr) or self.unitname
        local query = self.unitstr or self.unitname
        if not ident then return end

        if SuperWow and self.unitstr and not UnitIsUnit(self.unitstr, "player") then
            local _, guid = UnitExists(self.unitstr)
            query = guid or query
        end

        local cast, nameSubtext, _, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(self.unitstr or self
            .unitname)
        local isChannel
        if not cast then
            cast, nameSubtext, _, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(self.unitstr or
            self.unitname)
            isChannel = (cast ~= nil)
        end

        if cast then
            local max = (endTime - startTime) / 1000
            local duration = endTime - startTime
            local current = (not isChannel) and (GetTime() - startTime / 1000) or (max + (startTime / 1000) - GetTime())

            if current < 0 then current = 0 end
            if current > max then current = max end

            self.frame:SetAlpha(1)
            self.bar:SetMinMaxValues(0, max)

            local colorKey = isChannel and "channelcolor" or "castbarcolor"
            self.bar:SetStatusBarColor(self.util.Strsplit(",", self.db[colorKey]))
            self.bar:SetValue(current)

            if self.endTime ~= endTime then
                self.endTime = endTime
                self.leftText:SetText(nameSubtext and nameSubtext ~= "" and (cast .. " |cffaaffcc[" .. nameSubtext .. "]|r") or
                cast)
                self.fadeout = nil

                if texture then
                    local size
                    if self.unitstr == "player" and (self.db.anchorToFrame or self.db.anchorToFrame == 1) then
                        size = self.db.height
                    else
                        size = self.frame:GetHeight()
                    end
                    self.icon:Show()
                    self.icon:SetHeight(size)
                    self.icon:SetWidth(size)
                    self.icon.texture:SetTexture(texture)
                    self.bar:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", self.spacing, 0)
                else
                    self.icon:Hide()
                    self.bar:SetPoint("TOPLEFT", self.frame, 0, 0)
                end

                local _, _, lag = GetNetStats()
                local width = (self.frame:GetWidth() / max) * (lag / 1000)
                self.lag:SetWidth(math.min(self.frame:GetWidth(), width))
            end

            if self.delay and self.delay > 0 then
                local sign = isChannel and "-" or "+"
                self.rightText:SetText(
                    string.format("|cffffaaaa%s%.1f|r %.1f / %.1f", sign, self.delay, current,self.util.Round(max, 1))
                )
            else
                self.rightText:SetText(
                    string.format("%.1f / %.1f", current, self.util.Round(max, 1))
                )
            end
        else
            self.bar:SetMinMaxValues(1, 100)
            self.bar:SetValue(100)
            self.fadeout = 1
            self.delay = 0
        end
    end

    function SUICastbar:EnableScripts()
        self.frame:SetScript("OnUpdate", function() self:HandleScripts() end)
        self.frame:SetAlpha(0)
        self.delay = 0
    end

    function SUICastbar:SetupCastbar()
        local anchorFrame = SimpleUI[self.unitstr]
        local width = anchorFrame:GetWidth()
        local pos = self.db.Pos

        self.holder:EnableMouse(true)
        self.holder:SetMovable(true)
        self.holder:SetClampedToScreen(true)
        self.holder:Hide()
        self.holder:SetFrameLevel(self.frame:GetFrameLevel() + 1)
        
        if pos then
            self.holder:ClearAllPoints()
            self.holder:SetPoint(pos.point, pos.parentName, pos.relativePoint, pos.xOfs, pos.yOfs)
        else
            self.holder:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        end

        if self.unitstr == "player" then
            if not self.db.anchorToFrame or self.db.anchorToFrame == 0 then
                self.frame:ClearAllPoints()
                self.frame:SetPoint("BOTTOMLEFT", _G.SimpleUIplayer, "TOPLEFT", 0, 25)
                self.frame:SetWidth(anchorFrame:GetWidth())
            else
                self.frame:ClearAllPoints()
                self.frame:SetAllPoints(self.holder)
            end
        else
            self.frame:ClearAllPoints()
            self.frame:SetPoint("BOTTOMLEFT", anchorFrame, "TOPLEFT", 0, 25)
            self.frame:SetWidth(width)
        end

        self.holder:RegisterForDrag("LeftButton")
        self.holder:SetScript("OnMouseDown", function()
            self.holder:StartMoving()
        end)

        self.holder:SetScript("OnMouseUp", function()
            self.holder:StopMovingOrSizing()

            local p, r, rP, x, y = self.holder:GetPoint()
            local pN = "UIParent"

            self.db.Pos = {
                point = p,
                parentName = pN,
                relativePoint = rP,
                xOfs = x,
                yOfs = y,
            }
        end)

        if self.db.height ~= -1 then
            self.frame:SetHeight(20)
        end
    end

    function SUICastbar:UpdateVisibility(logic)
        if logic then
            self.holder:Hide()
        else
            self.holder:Show()
        end
    end

    function SUICastbar:UpdateConfig()
        self.frame:SetWidth(self.db.width)
        self.frame:SetHeight(self.db.height)
        self.holder:SetWidth(self.db.width)
        self.holder:SetHeight(self.db.height)

        local anchorFrame = SimpleUI[self.unitstr]
        if not self.db.anchorToFrame or self.db.anchorToFrame == 0 then
            self.frame:ClearAllPoints()
            self.frame:SetPoint("BOTTOMLEFT", anchorFrame, "TOPLEFT", 0, 25)
            self.frame:SetWidth(anchorFrame:GetWidth())
        else
            self.frame:ClearAllPoints()
            self.frame:SetAllPoints(self.holder)
        end
    end

    local playerCastbar = SUICastbar:New("SUITEST_PlayerCastbar", UIParent, "player", "player")
    playerCastbar:RegisterEvents()
    playerCastbar:EnableScripts()
    playerCastbar:SetupCastbar()


    local targetCastbar = SUICastbar:New("SUITEST_TargetCastbar", UIParent, "target", "target")
    targetCastbar:RegisterEvents()
    targetCastbar:EnableScripts()
    targetCastbar:SetupCastbar()

    function SimpleUI_ToggleCastbarOverlay(logic)
        playerCastbar:UpdateVisibility(logic)
    end

    function SimpleUI_UpdateCastbarConfig()
        playerCastbar:UpdateConfig()
    end

    CastingBarFrame:SetScript("OnShow", function() CastingBarFrame:Hide() end)
    CastingBarFrame:UnregisterAllEvents()
    CastingBarFrame:Hide()
end)
