--------------------------------------------------------------------------------------
--	Backport and modifications by Sattva
--	Credit to simon_hirsig & tablegrapes
--	Credit to Macumba for checking all rares in list and then adding frFR database!
--	Code from unitscan & unitscan-rares
--------------------------------------------------------------------------------------
	
	-- Create global table
	_G.unitscanDB = _G.unitscanDB or {}

	-- Get locale table
	local void, unitscan = ...
	local L = unitscan.L

	-- Create locals
	local unitscan = CreateFrame'Frame'
	local forbidden
	local is_resting
	local is_flying
	local deadscan = false
	local unitscanLC, unitscanCB, usDropList, usConfigList, usLockList = {}, {}, {}, {}, {}
	local void

	--===== Check the current locale of the WoW client =====--
	local currentLocale = GetLocale()

	--===== Check for game version =====--
	local isTBC = select(4, GetBuildInfo()) == 20400 -- true if TBC 2.4.3
	local isWOTLK = select(4, GetBuildInfo()) == 30300 -- true if WOTLK 3.3.5

----------------------------------------------------------------------
--	L00: unitscan
----------------------------------------------------------------------

	-- Create event frame
	local usEvt = CreateFrame("FRAME")
	usEvt:RegisterEvent("ADDON_LOADED")
	usEvt:RegisterEvent("PLAYER_LOGIN")
	usEvt:RegisterEvent("PLAYER_ENTERING_WORLD")


----------------------------------------------------------------------
--	L01: Functions
----------------------------------------------------------------------

	-- Print text
	function unitscanLC:Print(text)
		DEFAULT_CHAT_FRAME:AddMessage(L[text], 1.0, 0.85, 0.0)
	end

	-- Lock and unlock an item
	function unitscanLC:LockItem(item, lock)
		if lock then
			item:Disable()
			item:SetAlpha(0.3)
		else
			item:Enable()
			item:SetAlpha(1.0)
		end
	end

	-- Hide configuration panels
	function unitscanLC:HideConfigPanels()
		for k, v in pairs(usConfigList) do
			v:Hide()
		end
	end

	-- Show a single line prefilled editbox with copy functionality
	function unitscanLC:ShowSystemEditBox(word, focuschat)
		if not unitscanLC.FactoryEditBox then
			-- Create frame for first time
			local eFrame = CreateFrame("FRAME", nil, UIParent)
			unitscanLC.FactoryEditBox = eFrame
			eFrame:SetSize(700, 110)
			eFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
			eFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			-- eFrame:SetFrameLevel(5000)
			eFrame:EnableMouse(true)
			eFrame:EnableKeyboard()
			eFrame:SetScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then
					eFrame:Hide()
				end
			end)
			-- Add background color
			eFrame.t = eFrame:CreateTexture(nil, "BACKGROUND")
			eFrame.t:SetAllPoints()
			eFrame.t:SetTexture(0.05, 0.05, 0.05, 0.9)
			-- Add copy title
			eFrame.f = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.f:SetPoint("TOPLEFT", x, y)
			eFrame.f:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -52)
			eFrame.f:SetWidth(676)
			eFrame.f:SetJustifyH("LEFT")
			eFrame.f:SetWordWrap(false)
			-- Add copy label
			eFrame.c = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.c:SetPoint("TOPLEFT", x, y)
			eFrame.c:SetText(L["Press CTRL/C to copy"])
			eFrame.c:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -82)
			-- Add feedback label
			eFrame.x = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.x:SetPoint("TOPRIGHT", x, y)
			eFrame.x:SetText("|cff00ff00Feedback Discord:|r |cffadd8e6Sattva#7238|r")

			eFrame.x:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -52)
			hooksecurefunc(eFrame.f, "SetText", function()
				eFrame.f:SetWidth(676 - eFrame.x:GetStringWidth() - 26)
			end)
			-- Add cancel label
			eFrame.x = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.x:SetPoint("TOPRIGHT", x, y)
			eFrame.x:SetText(L["Right-click to close"])
			eFrame.x:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -82)
			-- Create editbox
			eFrame.b = CreateFrame("EditBox", nil, eFrame, "InputBoxTemplate")
			eFrame.b:ClearAllPoints()
			eFrame.b:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 16, -12)
			eFrame.b:SetSize(672, 24)
			eFrame.b:SetFontObject("GameFontNormalLarge")
			eFrame.b:SetTextColor(1.0, 1.0, 1.0, 1)
			eFrame.b:DisableDrawLayer("BACKGROUND")
			-- eFrame.b:SetBlinkSpeed(0)
			eFrame.b:SetHitRectInsets(99, 99, 99, 99)
			eFrame.b:SetAutoFocus(true)
			eFrame.b:SetAltArrowKeyMode(true)
			eFrame.b:EnableMouse(true)
			eFrame.b:EnableKeyboard(true)
			-- Editbox texture
			eFrame.t = CreateFrame("FRAME", nil, eFrame.b)
			eFrame.t:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
			eFrame.t:SetPoint("LEFT", -6, 0)
			eFrame.t:SetWidth(eFrame.b:GetWidth() + 6)
			eFrame.t:SetHeight(eFrame.b:GetHeight())
			eFrame.t:SetBackdropColor(1.0, 1.0, 1.0, 0.3)
			-- Handler
			-- it doesnt work in 3.3.5
			eFrame.b:SetScript("OnKeyDown", function(void, key)
				if key == "c" and IsControlKeyDown() then
					LibCompat.After(0.1, function()
						eFrame:Hide()
						ActionStatus_DisplayMessage(L["Copied to clipboard."], true)
						if unitscanLC.FactoryEditBoxFocusChat then
							local eBox = ChatEdit_ChooseBoxForSend()
							ChatEdit_ActivateChat(eBox)
						end
					end)
				end
			end)
			-- Prevent changes
			-- eFrame.b:SetScript("OnEscapePressed", function() eFrame:Hide() end)
			-- eFrame.b:SetScript("OnEnterPressed", eFrame.b.HighlightText)
			-- eFrame.b:SetScript("OnMouseDown", eFrame.b.ClearFocus)
			-- eFrame.b:SetScript("OnMouseUp", eFrame.b.HighlightText)
			eFrame.b:SetScript("OnChar", function() eFrame.b:SetText(word); eFrame.b:HighlightText(); end);
			eFrame.b:SetScript("OnMouseUp", function() eFrame.b:HighlightText(); end);
			eFrame.b:SetScript("OnEscapePressed", function() eFrame:Hide() end)
			eFrame.b:SetFocus(true)
			eFrame.b:HighlightText()
			eFrame:Show()
		end
		if focuschat then unitscanLC.FactoryEditBoxFocusChat = true else unitscanLC.FactoryEditBoxFocusChat = nil end
		unitscanLC.FactoryEditBox:Show()
		unitscanLC.FactoryEditBox.b:SetText(word)
		unitscanLC.FactoryEditBox.b:HighlightText()
		unitscanLC.FactoryEditBox.b:SetScript("OnChar", function() unitscanLC.FactoryEditBox.b:SetFocus(true) unitscanLC.FactoryEditBox.b:SetText(word) unitscanLC.FactoryEditBox.b:HighlightText() end)
		unitscanLC.FactoryEditBox.b:SetScript("OnKeyUp", function() unitscanLC.FactoryEditBox.b:SetFocus(true) unitscanLC.FactoryEditBox.b:SetText(word) unitscanLC.FactoryEditBox.b:HighlightText() end)
	end

	-- Load a string variable or set it to default if it's not set to "On" or "Off"
	function unitscanLC:LoadVarChk(var, def)
		if unitscanDB[var] and type(unitscanDB[var]) == "string" and unitscanDB[var] == "On" or unitscanDB[var] == "Off" then
			unitscanLC[var] = unitscanDB[var]
		else
			unitscanLC[var] = def
			unitscanDB[var] = def
		end
	end

	-- Load a numeric variable and set it to default if it's not within a given range
	function unitscanLC:LoadVarNum(var, def, valmin, valmax)
		if unitscanDB[var] and type(unitscanDB[var]) == "number" and unitscanDB[var] >= valmin and unitscanDB[var] <= valmax then
			unitscanLC[var] = unitscanDB[var]
		else
			unitscanLC[var] = def
			unitscanDB[var] = def
		end
	end

	-- Load an anchor point variable and set it to default if the anchor point is invalid
	function unitscanLC:LoadVarAnc(var, def)
		if unitscanDB[var] and type(unitscanDB[var]) == "string" and unitscanDB[var] == "CENTER" or unitscanDB[var] == "TOP" or unitscanDB[var] == "BOTTOM" or unitscanDB[var] == "LEFT" or unitscanDB[var] == "RIGHT" or unitscanDB[var] == "TOPLEFT" or unitscanDB[var] == "TOPRIGHT" or unitscanDB[var] == "BOTTOMLEFT" or unitscanDB[var] == "BOTTOMRIGHT" then
			unitscanLC[var] = unitscanDB[var]
		else
			unitscanLC[var] = def
			unitscanDB[var] = def
		end
	end

	-- Load a string variable and set it to default if it is not a string (used with minimap exclude list)
	function unitscanLC:LoadVarStr(var, def)
		if unitscanDB[var] and type(unitscanDB[var]) == "string" then
			unitscanLC[var] = unitscanDB[var]
		else
			unitscanLC[var] = def
			unitscanDB[var] = def
		end
	end

	-- Show tooltips for checkboxes
	function unitscanLC:TipSee()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent()
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for dropdown menu tooltips
	function unitscanLC:ShowDropTip()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent():GetParent():GetParent()
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for configuration buttons and dropdown menus
	function unitscanLC:ShowTooltip()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = unitscanLC["PageF"]
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (unitscanLC["PageF"]:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Create configuration button
	function unitscanLC:CfgBtn(name, parent)
		local CfgBtn = CreateFrame("BUTTON", nil, parent)
		unitscanCB[name] = CfgBtn
		CfgBtn:SetWidth(20)
		CfgBtn:SetHeight(20)
		CfgBtn:SetPoint("LEFT", parent.f, "RIGHT", 0, 0)

		CfgBtn.t = CfgBtn:CreateTexture(nil, "BORDER")
		CfgBtn.t:SetAllPoints()
		CfgBtn.t:SetTexture("Interface\\WorldMap\\Gear_64.png")
		CfgBtn.t:SetTexCoord(0, 0.50, 0, 0.50);
		CfgBtn.t:SetVertexColor(1.0, 0.82, 0, 1.0)

		CfgBtn:SetHighlightTexture("Interface\\WorldMap\\Gear_64.png")
		CfgBtn:GetHighlightTexture():SetTexCoord(0, 0.50, 0, 0.50);

		CfgBtn.tiptext = L["Click to configure the settings for this option."]
		CfgBtn:SetScript("OnEnter", unitscanLC.ShowTooltip)
		CfgBtn:SetScript("OnLeave", GameTooltip_Hide)
	end

	-- Create a help button to the right of a fontstring
	function unitscanLC:CreateHelpButton(frame, panel, parent, tip)
		unitscanLC:CfgBtn(frame, panel)
		unitscanCB[frame]:ClearAllPoints()
		unitscanCB[frame]:SetPoint("LEFT", parent, "RIGHT", -parent:GetWidth() + parent:GetStringWidth(), 0)
		unitscanCB[frame]:SetSize(25, 25)
		unitscanCB[frame].t:SetTexture("Interface\\COMMON\\help-i.blp")
		unitscanCB[frame].t:SetTexCoord(0, 1, 0, 1)
		unitscanCB[frame].t:SetVertexColor(0.9, 0.8, 0.0)
		unitscanCB[frame]:SetHighlightTexture("Interface\\COMMON\\help-i.blp")
		unitscanCB[frame]:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
		unitscanCB[frame].tiptext = L[tip]
		unitscanCB[frame]:SetScript("OnEnter", unitscanLC.TipSee)
	end

	-- Show a footer
	function unitscanLC:MakeFT(frame, text, left, width)
		local footer = unitscanLC:MakeTx(frame, text, left, 96)
		footer:SetWidth(width); footer:SetJustifyH("LEFT"); footer:SetWordWrap(true); footer:ClearAllPoints()
		footer:SetPoint("BOTTOMLEFT", left, 96)
	end

	-- Capitalise first character in a string
	function unitscanLC:CapFirst(str)
		return gsub(string.lower(str), "^%l", strupper)
	end

	-- Show memory usage stat
	function unitscanLC:ShowMemoryUsage(frame, anchor, x, y)

		-- Create frame
		local memframe = CreateFrame("FRAME", nil, frame)
		memframe:ClearAllPoints()
		memframe:SetPoint(anchor, x, y)
		memframe:SetWidth(100)
		memframe:SetHeight(20)

		-- Create labels
		local pretext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		pretext:SetPoint("TOPLEFT", 0, 0)
		pretext:SetText(L["Memory Usage"])

		local memtext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		memtext:SetPoint("TOPLEFT", 0, 0 - 30)

		-- Create stat
		local memstat = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		memstat:SetPoint("BOTTOMLEFT", memtext, "BOTTOMRIGHT")
		memstat:SetText("(calculating...)")

		-- Create update script
		local memtime = -1
		memframe:SetScript("OnUpdate", function(self, elapsed)
			if memtime > 2 or memtime == -1 then
				UpdateAddOnMemoryUsage();
				memtext = GetAddOnMemoryUsage("unitscan")
				memtext = math.floor(memtext + .5) .. " KB"
				memstat:SetText(memtext);
				memtime = 0;
			end
			memtime = memtime + elapsed;
		end)

		-- Release memory
		unitscanLC.ShowMemoryUsage = nil

	end

	-- Check if player is in LFG queue
	function unitscanLC:IsInLFGQueue()
		if unitscanLC["GameVer"] == "5" then
			if GetLFGQueueStats(LE_LFG_CATEGORY_LFD) or GetLFGQueueStats(LE_LFG_CATEGORY_LFR) or GetLFGQueueStats(LE_LFG_CATEGORY_RF) then
				return true
			end
		else
			if MiniMapLFGFrame:IsShown() then return true end
		end
	end

	-- Check if player is in combat
	function unitscanLC:PlayerInCombat()
		if (UnitAffectingCombat("player")) then
			unitscanLC:Print("You cannot do that in combat.")
			return true
		end
	end

	--  Hide panel and pages
	function unitscanLC:HideFrames()

		-- Hide option pages
		for i = 0, unitscanLC["NumberOfPages"] do
			if unitscanLC["Page"..i] then
				unitscanLC["Page"..i]:Hide();
			end;
		end

		-- Hide options panel
		unitscanLC["PageF"]:Hide();

	end

	-- Find out if Leatrix Plus is showing (main panel or config panel)
	function unitscanLC:IsPlusShowing()
		if unitscanLC["PageF"]:IsShown() then return true end
		for k, v in pairs(usConfigList) do
			if v:IsShown() then
				return true
			end
		end
	end

	-- Check if a name is in your friends list or guild (does not check realm as realm is unknown for some checks)
	function unitscanLC:FriendCheck(name)

		-- Do nothing if name is empty (such as whispering from the Battle.net app)
		if not name then return end

		-- Update friends list
		ShowFriends()

		-- Remove realm if it exists
		if name ~= nil then
			name = strsplit("-", name, 2)
		end

		-- Check character friends
		for i = 1, GetNumFriends() do
			local friendName, _, _, _, friendConnected = GetFriendInfo(i)
			if friendName ~= nil then -- Check if name is not nil
				friendName = strsplit("-", friendName, 2)
			end

			if (name == friendName) and friendConnected then -- Check if name matches and friend is connected
				return true
			end
		end

		-- -- Check Battle.net friends -- obviously disable as there is no bnet friends in 3.3.5 and 2.4.3
		-- local numfriends = BNGetNumFriends()
		-- for i = 1, numfriends do
		-- 	local numtoons = C_BattleNet.GetFriendNumGameAccounts(i)
		-- 	for j = 1, numtoons do
		-- 		local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
		-- 		local characterName = gameAccountInfo.characterName
		-- 		local client = gameAccountInfo.clientProgram
		-- 		if client == "WoW" and characterName == name then
		-- 			return true
		-- 		end
		-- 	end
		-- end

		-- Check guild members if guild is enabled (new members may need to press J to refresh roster)
		if unitscanLC["FriendlyGuild"] == "On" then
			local gCount = GetNumGuildMembers()
			for i = 1, gCount do
				local gName, void, void, void, void, void, void, void, gOnline = GetGuildRosterInfo(i)
				if gOnline then
					gName = strsplit("-", gName, 2)
					-- Return true if character name matches
					if (name == gName) then
						return true
					end
				end
			end
		end

	end


---------------------------------------------------------------------------------------------------
-- Functions mainly for restrictions and conditions for unit scanning, RAID mark setup conditions.
---------------------------------------------------------------------------------------------------


	unitscan:SetScript('OnUpdate', function() unitscan.UPDATE() end)
	unitscan:SetScript('OnEvent', function(_, event, arg1)
		if event == 'ADDON_LOADED' and arg1 == 'unitscan' then
			unitscan.LOAD()
		elseif event == 'ADDON_ACTION_FORBIDDEN' and arg1 == 'unitscan' then
			forbidden = true
		elseif event == 'PLAYER_TARGET_CHANGED' then
			if UnitName'target' and strupper(UnitName'target') == unitscan.button:GetText() and not GetRaidTargetIndex'target' and (not UnitInRaid'player' or IsRaidOfficer() or IsRaidLeader()) then
				SetRaidTarget('target', 2)
			end
			unitscan.checkTargetDead()
		elseif event == 'UNIT_HEALTH' and arg1 == 'target' then
			-- Catches the case where the mob dies while already targeted (no PLAYER_TARGET_CHANGED fires).
			unitscan.checkTargetDead()
		elseif event == 'ZONE_CHANGED_NEW_AREA' or event == 'PLAYER_LOGIN' or event == 'PLAYER_UPDATE_RESTING' then
			local loc = GetRealZoneText()
			local _, instance_type = IsInInstance()
			is_resting = IsResting()
			is_flying = IsFlying()
			nearby_targets = {}

			if instance_type == "raid" or instance_type == "pvp" then return end
			if loc == nil then return end

			unitscan.build_nearby_targets(loc)
			-- print("nearby_targets:", table.concat(nearby_targets, ", ")) -- Don't delete, it's a useful debug code to print what was added to the rare list scanning.
		end
	end)


-------------------------------------------------------------------------------------
-- rare_spawns is structured as { [zone] = { "UNIT NAME", "UNIT NAME", ... } }.
-- These helpers walk that structure.
-------------------------------------------------------------------------------------


	--===== Fills nearby_targets with every non-ignored, hostile-or-unknown rare listed for the zone `loc` =====--
	function unitscan.build_nearby_targets(loc)
		local seen = {} -- a unit listed under several matching zones is only added once
		for zone, names in pairs(rare_spawns) do
			if loc == zone or string.match(loc, zone) or zone == "A H" then
				for _, name in ipairs(names) do
					if not seen[name] and not unitscan_ignored[name] then
						local reaction = UnitReaction("player", name)
						if not reaction or reaction < 4 then
							seen[name] = true
							table.insert(nearby_targets, name)
						end
					end
				end
			end
		end
	end


	--===== Returns true if `name` is listed under any zone in rare_spawns =====--
	function unitscan.is_rare_spawn(name)
		for _, names in pairs(rare_spawns) do
			for _, n in ipairs(names) do
				if n == name then return true end
			end
		end
		return false
	end


-------------------------------------------------------------------------------------
-- Function to refresh current rare mob list, after doing /unitscan ignore #unitname
-------------------------------------------------------------------------------------


	function unitscan.refresh_nearby_targets()
		-- print("Refreshed nearby rare list.")
	    local loc = GetRealZoneText()
	    local _, instance_type = IsInInstance()
	    is_resting = IsResting()
	    is_flying = IsFlying()
	    nearby_targets = {}
	    
	    if instance_type == "raid" or instance_type == "pvp" then return end
	    if loc == nil then return end
	    
	    unitscan.build_nearby_targets(loc)

	    -- print("nearby_targets:", table.concat(nearby_targets, ", "))
	end


--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

	unitscan:RegisterEvent'ADDON_LOADED'
	unitscan:RegisterEvent'ADDON_ACTION_FORBIDDEN'
	unitscan:RegisterEvent'PLAYER_TARGET_CHANGED'
	unitscan:RegisterEvent'UNIT_HEALTH'
	unitscan:RegisterEvent'ZONE_CHANGED_NEW_AREA'
	unitscan:RegisterEvent'PLAYER_LOGIN'
	unitscan:RegisterEvent'PLAYER_UPDATE_RESTING'


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

	--===== Some Colors for borders of button =====--
	local BROWN = {.7, .15, .05}
	local YELLOW = {1, 1, .15}


--------------------------------------------------------------------------------
-- Creating SavedVariables DB tables here. 
--------------------------------------------------------------------------------

	--===== DB Table for user-added targets via /unitscan "name" or /unitscan target =====--
	unitscan_targets = {}

	--===== DB Table for user-added rare spawns to ignore from scanning =====--
	unitscan_ignored = {}

	--===== DB Table for Default Settings =====--
	unitscan_defaults = {
		CHECK_INTERVAL = .3,
		DEAD_COOLDOWN_HOURS = 8, -- hours before a dead mob is scanned again (configurable via /unitscan cooldown <hours>)
	}

	--===== DB Table for mobs confirmed dead/corpse. Stores { [name] = timestamp } and persists across sessions. =====--
	--===== Mobs in this table are skipped from scanning for DEAD_COOLDOWN_HOURS (default 8h). =====--
	unitscan_dead = {}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

	--===== Not a SavedVariables table to prevent spamming the alert. =====--
	local found = {}


--------------------------------------------------------------------------------------
-- Rare Databases corrected, translated by Sattva & Macumba & "that guy" from discord.
-- Database is automatically set by current locale. Only enUS database has updated
-- units for Epoch Reborn
--------------------------------------------------------------------------------------

	rare_spawns = {}
	if currentLocale == "enUS" or currentLocale == "enGB" then
			rare_spawns = rare_spawns_data["enUS"]
	elseif currentLocale == "ruRU" then
			rare_spawns = rare_spawns_data["ruRU"]
	elseif currentLocale == "frFR" then
			rare_spawns = rare_spawns_data["frFR"]
	elseif currentLocale == "zhCN" then
			rare_spawns = rare_spawns_data["zhCN"]
	-- elseif currentLocale == "deDE" then
	--     rare_spawns = rare_spawns_deDE
	-- elseif currentLocale == "esES" or currentLocale == "esMX" then
	--     rare_spawns = rare_spawns_esES
	else
			if DEFAULT_CHAT_FRAME then
				DEFAULT_CHAT_FRAME:AddMessage(
						"|cFF00FF00unitscan warning:|r |cffffff9aUnsupported client language: "
						.. currentLocale .. ". The built-in rare list is not available.|r"
						.. "|cFFFFFF00 You can still add units using unitscan commands!|r"
				)
			end
			rare_spawns = {}
	end


--------------------------------------------------------------------------------
-- Play sound if wasn't played recently.
--------------------------------------------------------------------------------


do
	local last_played
	
	function unitscan.play_sound()
		if not last_played or GetTime() - last_played > 3 then
			PlaySoundFile([[Interface\AddOns\unitscan\assets\Event_wardrum_ogre.ogg]], 'Sound')
			PlaySoundFile([[Sound\Interface\MapPing.wav]], 'Sound')
			last_played = GetTime()
		end
	end
end


--------------------------------------------------------------------------------
-- Main function to scan for targets.
--------------------------------------------------------------------------------


function unitscan.target(name)
	forbidden = false
	TargetUnit(name)
	if forbidden then
		-- Mob is nearby. The alive/dead check is handled by unitscan.checkTargetDead()
		-- via PLAYER_TARGET_CHANGED, which is the only reliable place to read unit state.
		if not found[name] then
			found[name] = true
			--FlashClientIcon()
			unitscan.play_sound()
			unitscan.flash.animation:Play()
			unitscan.discovered_unit = name
			
			-- if InCombatLockdown() then
				print("|cFF00FF00unitscan found - |r |cffffff00" .. name .. "|r")
			-- end
		end
	else
		found[name] = false
	end
end

-- Called on PLAYER_TARGET_CHANGED. This is the only reliable moment to check
-- whether a tracked mob is dead, because the target frame has fully updated.
function unitscan.checkTargetDead()
	-- Never track dead mobs inside instances — they reset on every run.
	local _, instance_type = IsInInstance()
	if instance_type and instance_type ~= "none" then return end

	local targetName = UnitName("target")
	if not targetName then return end
	local key = strupper(targetName)
	-- Only act if this target is actually being tracked (custom list or nearby rares).
	local isTracked = unitscan_targets[key]
	if not isTracked then
		for _, n in pairs(nearby_targets) do
			if strupper(n) == key then
				isTracked = true
				break
			end
		end
	end
	if not isTracked then return end
	if UnitIsDead("target") or UnitIsCorpse("target") then
		-- Claude: already announced this death — retargeting the corpse (loot/skin) must not repeat the message
		if unitscan_dead[key] then return end
		-- Get respawn duration: prefer pfQuest's data, fall back to configured default.
		local respawn_secs, from_pfquest = unitscan.pfquest_get_respawn(key)
		unitscan_dead[key] = { t = time(), secs = respawn_secs, from_pfquest = from_pfquest }
		found[key] = nil
		if unitscan.button:IsShown() and strupper(unitscan.button:GetText()) == key then
			if not InCombatLockdown() then
				unitscan.button:Hide()
			end
		end
		-- Hide the rare's pfQuest map icon immediately.
		unitscan.pfquest_hide(targetName)
		local display_hours = string.format("%.1f", respawn_secs / 3600)
		print("|cFF00FF00unitscan:|r |cffffff00" .. targetName .. "|r |cffff4444is dead. Pausing scan for " .. display_hours .. "h.|r")
	end
end


--------------------------------------------------------------------------------
-- Functions that creates button, and other visuals during alert.
--------------------------------------------------------------------------------


function unitscan.LOAD()
	-- Backfill any missing keys into unitscan_defaults that were added in newer versions.
	-- This handles the case where a SavedVariables file from an older version is loaded,
	-- which would be missing newly added keys (causing nil arithmetic errors).
	if unitscan_defaults.CHECK_INTERVAL == nil then unitscan_defaults.CHECK_INTERVAL = 0.3 end
	if unitscan_defaults.DEAD_COOLDOWN_HOURS == nil then unitscan_defaults.DEAD_COOLDOWN_HOURS = 8 end
	if unitscan_dead == nil then unitscan_dead = {} end
	-- Migrate old-format entries (plain timestamp numbers) to new table format.
	-- pfQuest respawn data isn't available yet at LOAD time, so use the default hours.
	for name, dead in pairs(unitscan_dead) do
		if type(dead) == "number" then
			unitscan_dead[name] = { t = dead, secs = unitscan_defaults.DEAD_COOLDOWN_HOURS * 3600, from_pfquest = false }
		end
	end

	UIParent:UnregisterEvent'ADDON_ACTION_FORBIDDEN'
	do
		local flash = CreateFrame'Frame'
		unitscan.flash = flash
		flash:Show()
		flash:SetAllPoints()
		flash:SetAlpha(0)
		flash:SetFrameStrata'LOW'
		SetCVar("Sound_EnableErrorSpeech", 0)
		
		local texture = flash:CreateTexture()
		texture:SetBlendMode'ADD'
		texture:SetAllPoints()
		texture:SetTexture[[Interface\FullScreenTextures\LowHealth]]

		flash.animation = CreateFrame'Frame'
		flash.animation:Hide()
		flash.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .5 then
				flash:SetAlpha(t * 2)
			elseif t <= 1 then
				flash:SetAlpha(1)
			elseif t <= 1.5 then
				flash:SetAlpha(1 - (t - 1) * 2)
			else
				flash:SetAlpha(0)
				self.loops = self.loops - 1
				if self.loops == 0 then
					self.t0 = nil
					self:Hide()
				else
					self.t0 = GetTime()
				end
			end
		end)
		function flash.animation:Play()
			if self.t0 then
				self.loops = 2
			else
				self.t0 = GetTime()
				self.loops = 1
			end
			self:Show()
		end
	end
	
	local button = CreateFrame('Button', 'unitscan_button', UIParent, 'SecureActionButtonTemplate')
	-- first code to set left and right click of button
	button:SetAttribute("type1", "macro")
	button:SetAttribute("type2", "macro")
	-- rest of button code
	button:Hide()
	unitscan.button = button
	button:SetPoint('BOTTOM', UIParent, 0, 128)
	button:SetWidth(150)
	button:SetHeight(42)
	button:SetScale(1.25)
	button:SetMovable(true)
	button:SetUserPlaced(true)
	button:SetClampedToScreen(true)

	-- code to enable ctrl-click to move (it has nothing to do with left and right click function)
	button:SetScript('OnMouseDown', function(self)
	    if IsControlKeyDown() then
	        self:RegisterForClicks("AnyDown", "AnyUp")
	        self:StartMoving()
	    end
	end)
	button:SetScript('OnMouseUp', function(self)
	    self:StopMovingOrSizing()
	    self:RegisterForClicks("AnyDown", "AnyUp")
	end) 

	button:SetFrameStrata'LOW'
	button:SetNormalTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Parchment-Horizontal]]
	
	if isWOTLK or isTBC then
		button:SetBackdrop{
			tile = true,
			edgeSize = 16,
			edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
		}
		button:SetBackdropBorderColor(unpack(BROWN))
		button:SetScript('OnEnter', function(self)
			self:SetBackdropBorderColor(unpack(YELLOW))
		end)
		button:SetScript('OnLeave', function(self)
			self:SetBackdropBorderColor(unpack(BROWN))
		end)
	end

	function button:set_target(name)
		-- string that adds name text to the button
		self:SetText(name)
		-- second code to set left and right click of button macro texts
		self:SetAttribute("macrotext1", "/cleartarget\n/targetexact " .. name)
		self:SetAttribute("macrotext2", "/click unitscan_close") -- this is made to click "close" button code for which is defined below
		-- rest of code
		self:Show()
		self.glow.animation:Play()
		self.shine.animation:Play()
	end
	
	do
		local background = button:GetNormalTexture()
		background:SetDrawLayer'BACKGROUND'
		background:ClearAllPoints()
		background:SetPoint('BOTTOMLEFT', 3, 3)
		background:SetPoint('TOPRIGHT', -3, -3)
		background:SetTexCoord(0, 1, 0, .25)
	end
	
	do
		local title_background = button:CreateTexture(nil, 'BORDER')
		title_background:SetTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Title]]
		title_background:SetPoint('TOPRIGHT', -5, -5)
		title_background:SetPoint('LEFT', 5, 0)
		title_background:SetHeight(18)
		title_background:SetTexCoord(0, .9765625, 0, .3125)
		title_background:SetAlpha(.8)


		--===== Create Title (UNIT name) =====--
		local title = button:CreateFontString(nil, 'OVERLAY')
		title:SetFont(GameFontNormal:GetFont(), 14, 'OUTLINE')
		--title:SetWordWrap(false)

		--===== Fix for UNIT name in Chinese, should i add zhTW? =====--
		-- if currentLocale == "zhCN" and isWOTLK then
		-- 	title:SetFont([[Fonts\ZYHei.ttf]], 14)
		-- else	
		-- 	title:SetFont([[Fonts\FRIZQT__.TTF]], 14)
		-- end

		title:SetShadowOffset(1, -1)
		title:SetPoint('TOPLEFT', title_background, 0, 0)
		title:SetPoint('RIGHT', title_background)
		button:SetFontString(title)

		local subtitle = button:CreateFontString(nil, 'OVERLAY')
		subtitle:SetFont([[Fonts\FRIZQT__.TTF]], 14)
		subtitle:SetTextColor(0, 0, 0)
		subtitle:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -4)
		subtitle:SetPoint('RIGHT', title)
		subtitle:SetText'Unit Found!'
	end
	
	do
		local model = CreateFrame('PlayerModel', nil, button)
		button.model = model
		model:SetPoint('BOTTOMLEFT', button, 'TOPLEFT', 0, -4)
		model:SetPoint('RIGHT', 0, 0)
		model:SetHeight(button:GetWidth() * .6)
	end
	
	-- Shared function: apply 1h cooldown when popup is dismissed inside an instance.
	-- Called from both the X button and the right-click path.
	function unitscan.instance_dismiss()
		local _, instance_type = IsInInstance()
		if not instance_type or instance_type == "none" then return end
		local name = unitscan.button:GetText()
		if not name or name == "" then return end
		local key = strupper(name)
		local existing = unitscan_dead[key]
		local one_hour = 3600
		if not existing or (type(existing) == "table" and existing.secs < one_hour) then
			unitscan_dead[key] = { t = time(), secs = one_hour, from_pfquest = false }
			found[key] = nil
			print("|cFF00FF00unitscan:|r |cffffff00" .. name .. "|r |cffff4444dismissed in instance. Pausing scan for 1h.|r")
		end
	end

	do
		local close = CreateFrame('Button', "unitscan_close", button, 'SecureHandlerClickTemplate')
		close:SetPoint('BOTTOMRIGHT', 5, -5)
		close:SetWidth(32)
		close:SetHeight(32)
		close:SetScale(.8)
		close:SetHitRectInsets(8, 8, 8, 8)
		close:SetAttribute("_onclick", "self:GetParent():Hide()")
		close:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
		close:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
		close:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
		-- PreClick fires in normal (insecure) Lua before the secure _onclick hides the frame,
		-- so button:GetText() is still valid here. This works both in and out of combat.
		close:SetScript("PreClick", function() unitscan.instance_dismiss() end)
	end

	-- Right-click on the main button triggers "/click unitscan_close" via macrotext2.
	-- PostClick catches this so both dismiss paths apply the instance cooldown.
	button:SetScript("PostClick", function(self, btn)
		if btn == "RightButton" then
			unitscan.instance_dismiss()
		end
	end)
	
	do
		local glow = button.model:CreateTexture(nil, 'OVERLAY')
		button.glow = glow
		glow:SetPoint('CENTER', button, 'CENTER')
		glow:SetWidth(400 / 300 * button:GetWidth())
		glow:SetHeight(171 / 70 * button:GetHeight())
		glow:SetTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Alert-Glow]]
		glow:SetBlendMode'ADD'
		glow:SetTexCoord(0, .78125, 0, .66796875)
		glow:SetAlpha(0)

		glow.animation = CreateFrame'Frame'
		glow.animation:Hide()
		glow.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .2 then
				glow:SetAlpha(t * 5)
			elseif t <= .7 then
				glow:SetAlpha(1 - (t - .2) * 2)
			else
				glow:SetAlpha(0)
				self:Hide()
			end
		end)
		function glow.animation:Play()
			self.t0 = GetTime()
			self:Show()
		end
	end

	do
		local shine = button:CreateTexture(nil, 'ARTWORK')
		button.shine = shine
		shine:SetPoint('TOPLEFT', button, 0, 8)
		shine:SetWidth(67 / 300 * button:GetWidth())
		shine:SetHeight(1.28 * button:GetHeight())
		shine:SetTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Alert-Glow]]
		shine:SetBlendMode'ADD'
		shine:SetTexCoord(.78125, .912109375, 0, .28125)
		shine:SetAlpha(0)
		
		shine.animation = CreateFrame'Frame'
		shine.animation:Hide()
		shine.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .3 then
				shine:SetPoint('TOPLEFT', button, 0, 8)
			elseif t <= .7 then
				shine:SetPoint('TOPLEFT', button, (t - .3) * 2.5 * self.distance, 8)
			end
			if t <= .3 then
				shine:SetAlpha(0)
			elseif t <= .5 then
				shine:SetAlpha(1)
			elseif t <= .7 then
				shine:SetAlpha(1 - (t - .5) * 5)
			else
				shine:SetAlpha(0)
				self:Hide()
			end
		end)
		function shine.animation:Play()
			self.t0 = GetTime()
			self.distance = button:GetWidth() - shine:GetWidth() + 8
			self:Show()
			button:SetAlpha(1)
		end
	end
end


--------------------------------------------------------------------------------
-- Function to scan for units with conditions. 
--------------------------------------------------------------------------------


do
	unitscan.last_check = GetTime()
	function unitscan.UPDATE()
		if is_resting or IsFlying() or UnitOnTaxi("player") then return end
		if InCombatLockdown() then return end
		if unitscan.discovered_unit then
			unitscan.button:set_target(unitscan.discovered_unit)
			unitscan.discovered_unit = nil
		end
		if GetTime() - unitscan.last_check >= unitscan_defaults.CHECK_INTERVAL then
			unitscan.last_check = GetTime()
			local now = time()
			for name in pairs(unitscan_targets) do
				local dead = unitscan_dead[name]
				if dead then
					if now - dead.t >= dead.secs then
						unitscan_dead[name] = nil
						print("|cFF00FF00unitscan:|r |cffffff00" .. name .. "|r |cff00ff00cooldown expired. Resuming scan.|r")
						unitscan.pfquest_show()
					end
				else
					unitscan.target(name)
				end
			end
			for _, name in pairs(nearby_targets) do
				local dead = unitscan_dead[name]
				if dead then
					if now - dead.t >= dead.secs then
						unitscan_dead[name] = nil
						print("|cFF00FF00unitscan:|r |cffffff00" .. name .. "|r |cff00ff00cooldown expired. Resuming scan.|r")
						unitscan.pfquest_show()
					end
				else
					unitscan.target(name)
				end
			end
		end
	end
end


--------------------------------------------------------------------------------
-- Prints to add prefix to message and color text.
--------------------------------------------------------------------------------


function unitscan.print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00/unitscan|r " .. "|cffffff9a" .. msg .. "|r")
    end
end


function unitscan.ignoreprint(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00/unitscan ignore|r " .. "|cffff0000" .. msg .. "|r")
    end
end

--------------------------------------------------------------------------------
-- Function for sorting targets alphabetically. For user QOL.
--------------------------------------------------------------------------------


function unitscan.sorted_targets()
	local sorted_targets = {}
	for key in pairs(unitscan_targets) do
		tinsert(sorted_targets, key)
	end
	sort(sorted_targets, function(key1, key2) return key1 < key2 end)
	return sorted_targets
end


--------------------------------------------------------------------------------
-- Function to add current target to the scanning list.
--------------------------------------------------------------------------------


function unitscan.toggle_target(name)
	local key = strupper(name)
	if unitscan_targets[key] then
		unitscan_targets[key] = nil
		found[key] = nil
		unitscan.print('- ' .. key)
	elseif key ~= '' then
		unitscan_targets[key] = true
		unitscan.print('+ ' .. key)
	end
end


--------------------------------------------------------------------------------
-- Slash Commands /unitscan
--------------------------------------------------------------------------------

	
SlashCmdList["UNITSCAN"] = function(parameter)
	local _, _, command, args = string.find(parameter, '^(%S+)%s*(.*)$')
	
	--===== Slash to put current player target to the unit scanning list. =====--	
	if command == "target" then
		local targetName = UnitName("target")
		if targetName then
			local key = strupper(targetName)
			if not unitscan_targets[key] then
				unitscan_targets[key] = true
				unitscan.print("+ " .. key)
			else
				unitscan_targets[key] = nil
				unitscan.print("- " .. key)
				found[key] = nil
			end
		else
			unitscan.print("No target selected.")
		end

	--===== Slash to change unit scanning interval. Default is 0.3 =====--	
	elseif command == "interval" then
		local newInterval = tonumber(args)
		if newInterval then
			unitscan_defaults.CHECK_INTERVAL = newInterval
			unitscan.print("Check interval set to " .. newInterval)
		else
			unitscan.print("Invalid interval value. Usage: /unitscan interval <number>")
		end

	--===== Slash Ignore Rare =====--	
	elseif command == "ignore" then
		if args == "" then
			-- print list of ignored NPCs
			if next(unitscan_ignored) == nil then
				print(" ")
			unitscan.ignoreprint("list is empty.")
			else
			print("|cffff0000" .. " Ignore list " .. "|r"  .. "currently contains:")
			for rare in pairs(unitscan_ignored) do
				unitscan.ignoreprint(rare)
			end
		end

			return
		else
	        local rare = string.upper(args)
	        if not unitscan.is_rare_spawn(rare) then
	            -- rare does not exist in rare_spawns table
	            unitscan.print("|cffffff00" .. args .. "|r" .. " is not a valid rare spawn.")

	            return
	    end

		if unitscan_ignored[rare] then
			-- remove rare from ignore list
			unitscan_ignored[rare] = nil
			unitscan.ignoreprint("- " .. rare)
			unitscan.refresh_nearby_targets()
			found[rare] = nil
		else
			-- add rare to ignore list
			unitscan_ignored[rare] = true
			unitscan.ignoreprint("+ " .. rare)
			unitscan.refresh_nearby_targets()
		end

		return
		end


	--===== Slash to avoid people confusion if they do /unitscan name =====--	
	elseif command == "name" then
		print(" ")
		unitscan.print("replace |cffffff00'name'|r with npc you want to scan.")
		print(" - for example: |cFF00FF00/unitscan|r |cffffff00Hogger|r")

	--===== Slash to only print currently tracked non-rare targets. =====--	
	elseif command == "targets" then
		if unitscan_targets then
			for k, v in pairs(unitscan_targets) do
				unitscan.print(tostring(k))
			end
		end

	--===== Slash to show rare spawns that are currently being scanned. =====--	
	elseif command == "nearby" then
		print(" ")
		unitscan.print("Is someone missing?")
						print(" - Add it to your list with |cFF00FF00/unitscan|r |cffffff00name|r")
				unitscan.print("|cffff0000ignore|r")
				print(" - Adds/removes the rare mob 'name' from the unit scanner |cffff0000ignore list.|r")
				print(" ")
		for key,val in pairs(nearby_targets) do
			if not (val == "Lumbering Horror" or val == "Spirit of the Damned" or val == "Bone Witch") then
				unitscan.print(val)
			end
		end

	--===== Slash to list mobs currently on dead cooldown with time remaining =====--
	elseif command == "cooldowns" then
		if next(unitscan_dead) == nil then
			print(" ")
			unitscan.print("No mobs are currently on cooldown.")
		else
			local now = time()
			print(" ")
			print("|cFF00FF00unitscan|r |cffff4444dead cooldowns|r (rescan in):")
			for name, dead in pairs(unitscan_dead) do
				-- Support both old format (plain timestamp) and new format ({t, secs}).
				local deathtime = type(dead) == "table" and dead.t or dead
				local cooldown_secs = type(dead) == "table" and dead.secs or (unitscan_defaults.DEAD_COOLDOWN_HOURS * 3600)
				local remaining = cooldown_secs - (now - deathtime)
				if remaining > 0 then
					local h = math.floor(remaining / 3600)
					local m = math.floor((remaining % 3600) / 60)
					local s = remaining % 60
					local timestr
					if h > 0 then
						timestr = h .. "h " .. m .. "m"
					elseif m > 0 then
						timestr = m .. "m " .. s .. "s"
					else
						timestr = s .. "s"
					end
					local source = (type(dead) == "table" and dead.from_pfquest) and "|cff33ffcc[pfQ]|r " or ""
					print(" |cffffff00" .. name .. "|r " .. source .. "- |cffff9900" .. timestr .. "|r")
				end
			end
		end

	--===== Slash to set the dead-mob rescan cooldown in hours =====--
	elseif command == "cooldown" then
		local hours = tonumber(args)
		if hours and hours > 0 then
			unitscan_defaults.DEAD_COOLDOWN_HOURS = hours
			unitscan.print("Respawn cooldown set to |cffffff00" .. hours .. " hour(s)|r.")
		else
			unitscan.print("Current respawn cooldown: |cffffff00" .. unitscan_defaults.DEAD_COOLDOWN_HOURS .. " hour(s)|r.")
			print(" - Usage: |cFF00FF00/unitscan cooldown|r |cffffff00<hours>|r")
			print(" - Tip: most WotLK rares = 8h, Outland rares = 6h, low-level rares = 2-4h")
		end

	--===== Slash to show all avaliable commands =====--
	elseif command == 'help' then

		print(" ")
		print("|cfff0d440Available commands:|r")

		unitscan.print("target")
		print(" - Adds/removes the name of your |cffffff00current target|r to the scanner.")
		-- print(" ")
		unitscan.print("name")
		print(" - Adds/removes the |cffffff00mob/player 'name'|r from the unit scanner.")
		-- print(" ")
		unitscan.print("nearby")
		print(" - List of |cffffff00rare mob names|r that are being scanned in your current zone.")
		unitscan.print("|cffff0000ignore|r")
			print(" - Adds/removes the rare mob 'name' from the unit scanner |cffff0000ignore list.|r")
		unitscan.print("|cffffff00cooldowns|r")
			print(" - Lists all mobs currently on dead cooldown with |cffffff00time remaining|r.")
		unitscan.print("|cffffff00cooldown <hours>|r")
			print(" - Sets how long dead mobs are skipped before rescanning. Default: |cffffff008h|r")
			print("   (WotLK rares ~8h, Outland ~6h, low-level ~2-4h)")

	--===== Slash without any arguments (/untiscan) prints currently tracked user-defined units and some basic available slash commands  =====--
	--===== If an agrugment after /unitscan is given, it will add a unit to the scanning targets. =====--
	elseif not command then
		print(" ")
		unitscan.print("|cffffff00help|r")
		print(" - Displays available unitscan |cffffff00commands|r")
		print(" ")
		if unitscan_targets then
			if next(unitscan_targets) == nil then
				unitscan.print("Unit Scanner is currently empty.")
			else
				print(" |cffffff00Unit Scanner|r currently contains:")
				for k, v in pairs(unitscan_targets) do
					unitscan.print(tostring(k))
				end
			end
		end
	else
		unitscan.toggle_target(parameter)
	end
end
SLASH_UNITSCAN1 = "/unitscan"


--------------------------------------------------------------------------------
-- pfQuest integration: hide/show rare map icons based on unitscan_dead state,
-- and look up per-mob respawn timers from pfQuest's unit database.
--
-- pfQuest stores rare nodes under pfMap.nodes["TRACK_RARES"][map][coords][title]
-- where title == the mob's display-case name (e.g. "Lady Sesspira").
--
-- pfQuest stores respawn data in:
--   pfDB["units"]["data"][id]["coords"] = { {x, y, zone, respawn_secs}, ... }
--   pfDB["units"][locale][id]           = "Mob Name"
-- We build a reverse name→respawn cache at login for fast lookup.
--------------------------------------------------------------------------------

-- Cache: UPPERCASE_NAME → respawn_seconds (built at PLAYER_LOGIN from pfQuest db).
unitscan.pfquest_respawn_cache = {}

-- Build the reverse-lookup cache from pfQuest's unit database.
-- Iterates the locale name table to find IDs, then reads respawn from data table.
function unitscan.pfquest_build_cache()
	unitscan.pfquest_respawn_cache = {}
	if not pfDB or not pfDB["units"] then return end

	local locale = GetLocale()
	local loc_table = pfDB["units"][locale] or pfDB["units"]["enUS"]
	local data_table = pfDB["units"]["data"]
	if not loc_table or not data_table then return end

	for id, name in pairs(loc_table) do
		local unit = data_table[id]
		if unit and unit["coords"] then
			-- Find the highest respawn value across all spawn points for this mob.
			-- (Some mobs share a name but have different spawn-point timers;
			--  we take the max to be safe — better to wait too long than too short.)
			local max_respawn = 0
			for _, coord in pairs(unit["coords"]) do
				local respawn = coord[4] or 0
				if respawn > max_respawn then max_respawn = respawn end
			end
			if max_respawn > 0 then
				unitscan.pfquest_respawn_cache[strupper(name)] = max_respawn
			end
		end
	end
end

-- Look up a mob's respawn time in seconds.
-- Returns pfQuest's value if available, otherwise falls back to DEAD_COOLDOWN_HOURS.
function unitscan.pfquest_get_respawn(upperName)
	local cached = unitscan.pfquest_respawn_cache[upperName]
	if cached and cached > 0 then
		return cached, true   -- seconds, from_pfquest=true
	end
	return (unitscan_defaults.DEAD_COOLDOWN_HOURS or 8) * 3600, false
end

-- Immediately delete a specific mob's TRACK_RARES nodes from the map.
-- 'displayName' is the original mixed-case name as pfQuest stored it.
function unitscan.pfquest_hide(displayName)
	if not pfMap or not pfMap.nodes or not pfMap.nodes["TRACK_RARES"] then return end
	pfMap:DeleteNode("TRACK_RARES", displayName)
	if pfMap.UpdateNodes then
		pfMap:UpdateNodes()
	end
end

-- After cooldown expires, trigger a full pfQuest node refresh so the icon comes back.
function unitscan.pfquest_show()
	if not pfMap or not pfMap.UpdateNodes then return end
	pfMap:UpdateNodes()
end

-- Hook pfMap:UpdateNodes to filter out dead-cooldown mobs every time the map redraws.
local function unitscan_hook_pfquest()
	if not pfMap or not pfMap.UpdateNodes then return end

	local orig_UpdateNodes = pfMap.UpdateNodes
	pfMap.UpdateNodes = function(self, ...)
		orig_UpdateNodes(self, ...)
		if not pfMap.nodes or not pfMap.nodes["TRACK_RARES"] then return end
		local now = time()
		for name, dead in pairs(unitscan_dead) do
			local deathtime = type(dead) == "table" and dead.t or dead
			local cooldown_secs = type(dead) == "table" and dead.secs or (unitscan_defaults.DEAD_COOLDOWN_HOURS * 3600)
			if now - deathtime < cooldown_secs then
				for map, coords_table in pairs(pfMap.nodes["TRACK_RARES"]) do
					for coords, title_table in pairs(coords_table) do
						for title, _ in pairs(title_table) do
							if strupper(title) == name then
								pfMap.nodes["TRACK_RARES"][map][coords][title] = nil
							end
						end
						-- Claude: clean up empty coords table so UpdateMinimap doesn't render a
						-- featureless dot with all-UNKNOWN tooltip data for the dead rare
						if next(pfMap.nodes["TRACK_RARES"][map][coords]) == nil then
							pfMap.nodes["TRACK_RARES"][map][coords] = nil
						end
					end
				end
			end
		end
	end
end

-- Install hooks and build cache after all addons have loaded.
local pfquest_hook_frame = CreateFrame("Frame")
pfquest_hook_frame:RegisterEvent("PLAYER_LOGIN")
pfquest_hook_frame:SetScript("OnEvent", function()
	unitscan_hook_pfquest()
	unitscan.pfquest_build_cache()
	pfquest_hook_frame:UnregisterEvent("PLAYER_LOGIN")
end)