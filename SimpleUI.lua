--[[
SimpleUI Addon for WoW Vanilla 1.12 - Turtle WoW
Version: 1.0
Author: BeardedRasta
Description: A modular UI enhancement addon with profile management, commands, and configuration setup.
]]

-- Credits
-- Code Snipets
----pfUI, SUCC-ui

--Inspirations
----LS:UI, ELvUI, WoD original interface, punsch

--Partner Addon(recommended to use with SimpleUI)
----HealersMate, SUCC-bag


--Constants
SimpleUI = CreateFrame("Frame", nil, UIParent);

local SimpleUIDBVersion = 2
--oficial release value = 2
SimpleUIVersion = "1.0.0-alpha"
local __off

TestUI = false

-- Addon Initilization ----------------------------------------------------------------

function SimpleUI:RegisterForEvent(event, callback, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
	if not self.eventFrame then
		self.eventFrame = CreateFrame("Frame")
		self.eventFrame:SetScript("OnEvent", function()
            local e = event
            local store = this.events[e]
            if store then
                for func, args in pairs(store) do
                    func(unpack(args), arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
                end
            end
		end)
        self.eventFrame.events = {}
	end
    local frame = self.eventFrame
    frame.events[event] = frame.events[event] or {}
    frame.events[event][callback] = {arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8}

	self.frame:RegisterEvent(event)
end

-- Initializes the addon and its componenets
function SimpleUI_Initialize()
    SimpleUI.Util = SimpleUI.Util or {};
    SimpleUI.Element = SimpleUI.Element or {};
    SimpleUI.Unitframe = SimpleUI.Unitframe or {};
    SimpleUI.Addon = SimpleUI.Addon or {};
    SimpleUI.movables = SimpleUI.movables or {}
    SimpleUI_cache = {};

    SimpleUI.L = SimpleUI.L or AceLibrary("AceLocale-2.2"):new("SimpleUI");
    SimpleUI.DD = SimpleUI.DD or AceLibrary("Dewdrop-2.0");
    SimpleUI.Tab = SimpleUI.Tab or AceLibrary("Tablet-2.0");
    SimpleUI.Console = SimpleUI.Console or AceLibrary("AceConsole-2.0")

    SLASH_SIMPLEUI1 = "/sui";
    SLASH_SIMPLEUI2 = "/simpleui";
    SlashCmdList["SIMPLEUI"] = SimpleUI_Commands;

    SimpleUI:SetScript("OnEvent", SimpleUI_OnEvent)
    SimpleUI:RegisterEvent("ADDON_LOADED")
    SimpleUI:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function SimpleUI_OnEvent()
    if (event == "ADDON_LOADED") then
        if (arg1 == "SimpleUI") then
            SimpleUI:UnregisterEvent("ADDON_LOADED");

            if SimpleUIDB == nil then
                SimpleUI_SetupDefaults();
            elseif SimpleUIDB.DBVersion ~= SimpleUIDBVersion then
                SimpleUI_SystemMessage("DB outdated, Settings reset to defaults");
                SimpleUI_SetupDefaults();
            end

            if SimpleUIProfile == nil or not SimpleUIDB.Profiles[SimpleUIProfile] then
                SimpleUIProfile = "Default"
                SimpleUI_SystemMessage("Profile not found, using Default profile")
            end


            if not SimpleUIDB.Profiles[SimpleUIProfile].SilenceWelcomeMessage then
                SimpleUI_SystemMessage("v" .. SimpleUIVersion .. " by BeardedRasta. /sui");
            end
            -- Module Initilization Function
            SimpleUI:RunModules()
        end
    elseif (event == "PLAYER_ENTERING_WORLD") then
        SimpleUI:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end

-- Utility Functions -------------------------------------------------------------

function TableLength(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

-- Sends a system message to the default chat frame
function SimpleUI_SystemMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage("Simple: |cff1a9fc0UI|cFFFFFFFF: " .. msg)
end


-- Parses the first word of a command and returns it with the remaining text
function SimpleUI_GetCommand(msg)
    if msg then
        local a, b, c = strfind(msg, "(%S+)");
        if a then
            return c, strsub(msg, b + 2);
        else
            return "";
        end
    end
end

function SimpleUI_Commands(msg)
    msg = strlower(msg);
    local command, subCommand = SimpleUI_GetCommand(msg);
    if command == "lock" then
        SimpleUI_SystemMessage("Movers coming soon...");
    elseif command == "config" then
        SimpleUI_Config_Window_Toggle()
    elseif command == "reset" then
        SimpleUI_SystemMessage("Reset to defaults");
        SimpleUI_SetupDefaults()
    else
        SimpleUI_SystemMessage("/sui |cff1a9fc0config|r, |cff1a9fc0reset|r, |cff1a9fc0lock|r")
    end
end

-- Copies table "a" into table "b" recursively
function SimpleUI_Copy(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        return
    end
    for k, v in pairs(a) do
        if type(v) ~= "table" then
            b[k] = v;
        else
            local x = {}
            SimpleUI_Copy(v, x);
            b[k] = x;
        end
    end
    return b
end

-- Default Setup -----------------------------------------------------------------------

-- Sets up default profiles and database
function SimpleUI_SetupDefaults()
    SimpleUIProfile = "Default"
    SimpleUIDB = {
        DBVersion = SimpleUIDBVersion,
        Profiles = {}
    }
    SimpleUIDB.Profiles[SimpleUIProfile] = SimpleUI_Copy(SimpleUI_Database.Default, {})
    SimpleUIDB.Profiles[SimpleUIProfile].Name = "Default";
    SimpleUI_Config_EditFrame_UpdateAll()
    --Update Options Frame
    --Update All Entities
end

-- Module Management -------------------------------------------------------------------

function SimpleUI:AddModule(name, func)
    self.moduleslist = self.moduleslist or {}

    local index = TableLength(self.moduleslist) + 1
    self.moduleslist[index] = { name = name, func = func }
end

function SimpleUI:RunModules()
    self.moduleslist = self.moduleslist or {}
     for i = 1, TableLength(self.moduleslist) do
        local module = self.moduleslist[i]
        if module and type(module.func) == "function" then
            --DEFAULT_CHAT_FRAME:AddMessage("Running module: " .. module.name)
            module.func()
        end
     end
end

function SimpleUI:IsDisabled(arg1, arg2, arg3, arg4, arg5)
    SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled = SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled or {}

	local args = { arg1, arg2, arg3, arg4, arg5 }
    for i = 1, TableLength(args) do
        local arg = args[i]
        if arg and SimpleUIDB.Profiles[SimpleUIProfile]["Entities"]["Modules"].disabled[arg] == 1 then
            return true
        end
    end
	return false
end

-- Fonts Setup ----------------------------------------------------------------

local function SimpleUI_SetupFonts()
    SimpleUIFont = CreateFont("SimpleUI_Font");
    SimpleUIFont:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\SimpleUI.ttf", 13, "")
    SimpleUIFont:SetTextColor(1, 0.82, 0)
    SimpleUIFont:SetShadowColor(0, 0, 0, 1)
    SimpleUIFont:SetShadowOffset(0.7, -0.7)

    SimpleUIAuraFont = CreateFont("SimpleUI_AuraFont");
    SimpleUIAuraFont:SetFont("Interface\\AddOns\\SimpleUI\\Media\\Fonts\\5.ttf", 12, "OUTLINE")
    SimpleUIAuraFont:SetTextColor(0.102, 0.624, 0.753)
    SimpleUIAuraFont:SetShadowColor(0, 0, 0, 1)
    SimpleUIAuraFont:SetShadowOffset(0.8, -0.8)
end

function SimpleUI_GetTexture(string)
    if SimpleUITextures[string] then
        return SimpleUITextures[string]
    end
    return ""
end

function SimpleUI_GetFont(s)
	if SimpleUIFonts[s] then return SimpleUIFonts[s] end
	return GameFontNormal:GetFont()
end

SimpleUI_SetupFonts()
SimpleUI_Initialize()
