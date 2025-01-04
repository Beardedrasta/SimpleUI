--[[
SimpleUI Cooldown Management for WoW Vanilla 1.12 - Turtle WoW
Author: BeardedRasta
Description: Provides enhanced cooldown tracking with custom text overlays.
--]]

-- Setup up Environment
local _G = getfenv(0)
local u = SUI_Util

SimpleUI:AddModule("Cooldown", function()
	if SimpleUI:IsDisabled("Cooldown") then return end

	-- Utility Functions --------------------------------------------
	local function SimpleUI_CooldownOnUpdate()
		local parent = this:GetParent()
		if not parent then
			return
		end

		local parentName = parent:GetName()
		if parentName and _G[parentName .. "Cooldown"] and not _G[parentName .. "Cooldown"]:IsShown() then
			this:Hide()
			return
		end

		-- Throttle updates to every 0.1 seconds
		this.tick = this.tick or 0.1
		if this.tick > GetTime() then
			return
		end
		this.tick = GetTime() + 0.1

		-- Sync alpha with parent
		if this:GetAlpha() ~= parent:GetAlpha() then
			this:SetAlpha(parent:GetAlpha())
		end

		-- Calculate remaining cooldown time
		if this.start < GetTime() then
			local remaining = this.duration - (GetTime() - this.start)
			if remaining >= 0 then
				this.text:SetText(u.GetColoredTimeString(remaining))
			else
				this:Hide()
			end
		else
			local time = time()
			local startupTime = time - GetTime()
			local cdTime = (2 ^ 32) / 1000 - this.start
			local cdStartTime = startupTime - cdTime
			local cdEndTime = cdStartTime + this.duration
			local remaining = cdEndTime - time

			if remaining >= 0 then
				this.text:SetText(u.GetColoredTimeString(remaining))
			else
				this:Hide()
			end
		end
	end

	-- Creates a cooldown overlay with text
	local size
	local function SimpleUI_CreateCooldown(cooldown, start, duration)


		cooldown.SimpleUI_CooldownText = CreateFrame("Frame", "SimpleUI_CooldownFrame", cooldown:GetParent())
		cooldown.SimpleUI_CooldownText:SetAllPoints(cooldown)
		cooldown.SimpleUI_CooldownText:SetFrameLevel(cooldown:GetParent():GetFrameLevel() + 1)
		cooldown.SimpleUI_CooldownText.text = cooldown.SimpleUI_CooldownText:CreateFontString(
			"SimpleUI_CooldownFrameText", "OVERLAY", "GameFontNormal")

		if cooldown.SimpleUI_CooldownSize then
			size = tonumber(cooldown.SimpleUI_CooldownSize)
		else
			size = 12
		end


		local height = cooldown:GetParent() and cooldown:GetParent():GetHeight() or cooldown:GetHeight() or 0
		size = math.max((height > 0 and height * 0.64 or 16), size)

		cooldown.SimpleUI_CooldownText.text:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\5.ttf", size, "OUTLINE")
		cooldown.SimpleUI_CooldownText.text:SetPoint("BOTTOM", cooldown.SimpleUI_CooldownText, "BOTTOM", 0, 0)
		cooldown.SimpleUI_CooldownText:SetScript("OnUpdate", SimpleUI_CooldownOnUpdate)
	end

	-- Setup a cooldown timer with custom behavior
	local function SetCooldown(this, start, duration, enable)
		if not this.SimpleUI_CooldownType or this.noCooldownCount then
			return
		end

		local parent = this.GetParent and this:GetParent()
		if parent and parent:GetWidth() / 36 > 0 then
			this:SetScale(parent:GetWidth() / 36)
			this:SetPoint("TOPLEFT", parent, "TOPLEFT", -1, 1)
			this:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 1, -1)
		end

		if this.SimpleUI_CooldownType == "NOGCD" and duration < 2 then
			return
		end

		if not this.SimpleUI_CooldownType and duration < 2 then
			return
		end

		if this.SimpleUI_CooldownStyleAnimation == 0 then
			this:SetAlpha(0)
		elseif not this.SimpleUI_CooldownStyleAnimation then
			this:SetAlpha(0)
		end

		if (not this.SimpleUI_CooldownStyleText or this.SimpleUI_CooldownStyleText == 1) and start > 0 and duration > 0 and (not enable or enable > 0) then
			if (not this.SimpleUI_CooldownText) then
				SimpleUI_CreateCooldown(this, start, duration)
			end

			this.SimpleUI_CooldownText.start = start
			this.SimpleUI_CooldownText.duration = duration
			this.SimpleUI_CooldownText:Show()
		elseif (this.SimpleUI_CooldownText) then
			this.SimpleUI_CooldownText:Hide()
		end
	end

	u.Hooksecurefunc("CooldownFrame_SetTimer", SetCooldown)
end)
