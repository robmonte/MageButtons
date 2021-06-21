-- debug, set debug level
-- 0: no debug, 1: minimal, 2: all
local debug = 0

local _, playerClass = UnitClass("player")
if playerClass ~= "MAGE" then
	print("MageButtons disabled, you are not a mage :(")
	return 0
end

local AceGUI = LibStub("AceGUI-3.0")
MageButtons = LibStub("AceAddon-3.0"):NewAddon("MageButtons", "AceEvent-3.0")
local addonName, addon = ...
local ldb = LibStub("LibDataBroker-1.1")
local channel = "RAID"
local MageButtonsMinimapIcon = LibStub("LibDBIcon-1.0")
local db
local castTable = {}
local lockStatus = 1

_G[addonName] = addon
addon.healthCheck = true
-- These two are used to ensure we wait with showing the UI until textures for the
-- spells are available
addon.notLoadedSpells = {}
addon.allSpellsLoaded = false

-- Add entries to keybinds page
BINDING_HEADER_MAGEBUTTONS = "MageButtons"
BINDING_NAME_MAGEBUTTONS_BUTTON1 = "Button 1"
BINDING_NAME_MAGEBUTTONS_BUTTON2 = "Button 2"
BINDING_NAME_MAGEBUTTONS_BUTTON3 = "Button 3"
BINDING_NAME_MAGEBUTTONS_BUTTON4 = "Button 4"
BINDING_NAME_MAGEBUTTONS_BUTTON5 = "Button 5"
BINDING_NAME_MAGEBUTTONS_BUTTON6 = "Button 6"

-- Saved Variables
MageButtonsDB = {}
if MageButtonsDB == nil then
	MageButtonsDB["position"] = {}
	MageButtonsDB["water"] = {}
	MageButtonsDB["food"] = {}
	MageButtonsDB["teleport"] = {}
	MageButtonsDB["portal"] = {}
	MageButtonsDB["managem"] = {}
	MageButtonsDB["ai"] = {}
end


-- slash commands
SlashCmdList["MAGEBUTTONS"] = function(inArgs)

	local wArgs = strtrim(inArgs)
	if wArgs == "" then
		print("usage: /magebuttons lock|move|unlock, minimap 0|1, config")
	elseif wArgs == "minimap 1" or wArgs == "minimap 0" then
		cmdarg, tog = string.split(" ", wArgs)
		MageButtons:maptoggle(tog)
	elseif wArgs == "move" or wArgs == "unlock" then
		lockStatus = addon:getSV("framelock", "lock")
		if lockStatus == 1 then
			addon:unlockAnchor()
		else
			addon:lockAnchor()
		end
	elseif wArgs == "lock" then
		magebuttons:lockAnchor()
	elseif wArgs == "config" then
		InterfaceOptionsFrame_OpenToCategory(mbPanel)
		InterfaceOptionsFrame_OpenToCategory(mbPanel)
	else
		print("usage: /MageButtons lock|move|unlock")
	end

end
SLASH_MAGEBUTTONS1 = "/magebuttons"

-- Set some default values
xOffset = 0
yOffset = 0
totalHeight, totalWidth, backdropPadding = 0, 0, 5
backdropAnchor = "TOP"
backdropParentAnchor = "BOTTOM"
--local backdropOffset = 0
local frameBG = "Interface\\ChatFrame\\ChatFrameBackground"
local growthDir, menuDir, btnSize, padding, border, backdropPadding, backdropRed, backdropGreen, backdropBlue, backdropAlpha, mouseover = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil


------------------
--- Main frame ---
------------------
MageButtonsConfig = CreateFrame("Frame", "MageButtonsFrame", UIParent, "BackdropTemplate")
MageButtonsConfig:SetMovable(false)
MageButtonsConfig:EnableMouse(false)
MageButtonsConfig:RegisterForDrag("LeftButton")
MageButtonsConfig:SetScript("OnDragStart", MageButtonsConfig.StartMoving)
MageButtonsConfig:SetScript("OnDragStop", MageButtonsConfig.StopMovingOrSizing)
MageButtonsConfig:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
MageButtonsConfig:SetSize(40, 10)
-- SetPoint is done after ADDON_LOADED

MageButtonsFrame.texture = MageButtonsFrame:CreateTexture(nil, "BACKGROUND")
MageButtonsFrame.texture:SetAllPoints(MageButtonsFrame)
MageButtonsFrame:SetBackdrop({bgFile = [[Interface\ChatFrame\ChatFrameBackground]]})
MageButtonsFrame:SetBackdropColor(0, 0, 0, 0)

local buttonTypes = { "Water", "Food", "Teleports", "Portals", "Gems", "Polymorph"}
local btnSize = 0

local spellNames = {}

function addon:makeSpellTable(spell_id_list)
  local tbl = {}
  --print(spell_id_list)

  for i = 1, #spell_id_list, 1 do
    if IsSpellKnown(spell_id_list[i]) then
      local name = GetSpellInfo(spell_id_list[i])
      local subtext = GetSpellSubtext(spell_id_list[i]) or ''  -- NOTE will return nil at first unless its locally cached
      name = name .. "(" .. subtext .. ")"  -- For some reason the "()" are required for tooltips
      table.insert(tbl, name)
    end
  end

  return tbl
end

function addon:startLoadingSpellData(spell_id_list)
    for i = 1, #spell_id_list, 1 do
		addon.notLoadedSpells[spell_id_list[i]] = true
        C_Spell.RequestLoadSpellData(spell_id_list[i])
    end
end

--------------
--- Events ---
--------------
local function onevent(self, event, arg1, ...)
	if event == "SPELL_DATA_LOAD_RESULT" then
		local loadedSpellId = arg1
		addon.notLoadedSpells[loadedSpellId] = nil
		local numRemainingToLoad = 0
		for _, v in pairs(addon.notLoadedSpells) do
			if v ~= nil then
				numRemainingToLoad = numRemainingToLoad + 1
			end
		end
		if numRemainingToLoad == 0 and not addon.allSpellsLoaded then
			addon.allSpellsLoaded = true
			addon:onSpellsLoaded()
		end
	end
	if event == "ADDON_LOADED" and arg1 == "MageButtons" then
			--print(event)

		-- Set up lists of spells
		-- Bottom <--> Top
		WaterSpells = {5504, 5505, 5506, 6127, 10138, 10139, 10140, 37420, 43987, 27090}
		FoodSpells  = {587, 597, 990, 6129, 10144, 10145, 28612, 33717}
		TeleportSpells = {}
		PortalSpells  = {}

		if UnitFactionGroup("player") == "Alliance" then
				-- Darnassus (3565), Exodar (32271), Theramore (49359), Ironforge (3562), Stormwind (3561), Shattrath (33690)
			TeleportSpells = {3565, 32271, 49359, 3562, 3561, 33690} -- {3565, 3561, 3562, 32271, 49359, 33690}
				-- Darnassus (11419), Exodar (32266) Theramore (49360) Ironforge (11416) Stormwind (10059), Shattrath (33691)
			PortalSpells   = {11419, 32266, 49360, 11416, 10059, 33691} -- {11419, 10059, 11416, 32266, 49360, 33691}
		else
				-- Silvermoon (32272), Undercity (3563), Thunder Bluff (3566), Stonard (49358), Orgrimmar (3567), Shattrath (35715)
			TeleportSpells = {32272, 3563, 3566, 49358, 3567, 35715} -- {3566, 3563, 3567, 32272, 49358, 35715}
				-- Silvermoon (32267), Undercity (11418), Thunder Bluff (11420), Stonard (49361), Orgrimmar (11417), Shattrath (35717)
			PortalSpells   = {32267, 11418, 11420, 49361, 11417, 35717} -- {11420, 11418, 11417, 32267, 49361, 35717}
		end
		GemSpells = {759, 3552, 10053, 10054, 27101}
		-- pig, turtle, ???
		PolymorphSpells = {28272, 28271, 28270}  -- REM: insert basic sheep a little later

		-- Start loading spell data, once all data is available the event handler for
		-- "SPELL_DATA_LOAD_RESULT" will continue the loading of the addon
		addon:startLoadingSpellData(WaterSpells)
		addon:startLoadingSpellData(FoodSpells)
		addon:startLoadingSpellData(TeleportSpells)
		addon:startLoadingSpellData(PortalSpells)
		addon:startLoadingSpellData(GemSpells)
		addon:startLoadingSpellData(PolymorphSpells)
		addon:startLoadingSpellData({12826, 12825, 12824, 118}) -- Basic sheep spell ranks
	end
end

function addon:onSpellsLoaded()
	-- Choose the highest rank of sheep polymorph
	local sheep = 9999 -- A spell you will never know

	if     IsSpellKnown(12826) then sheep = 12826   -- rank 4
	elseif IsSpellKnown(12825) then sheep = 12825   -- rank 3
	elseif IsSpellKnown(12824) then sheep = 12824   -- rank 2
	elseif IsSpellKnown(118)   then sheep = 118     -- rank 1
		end
	table.insert(PolymorphSpells, 1, sheep)

	-- Create the various spell tables using helper function
	WaterTable     = addon:makeSpellTable(WaterSpells)
	FoodTable      = addon:makeSpellTable(FoodSpells)
	TeleportsTable = addon:makeSpellTable(TeleportSpells)
	PortalsTable   = addon:makeSpellTable(PortalSpells)
	GemsTable      = addon:makeSpellTable(GemSpells)
	PolymorphTable = addon:makeSpellTable(PolymorphSpells)
		
	-- Get saved frame location
	local relPoint, anchorX, anchorY = addon:getAnchorPosition()
	MageButtonsConfig:ClearAllPoints()
	MageButtonsConfig:SetPoint(relPoint, UIParent, relPoint, anchorX, anchorY)
	
	
	addon:makeBaseButtons()

	-----------------
	-- Data Broker --
	-----------------
	lockStatus = addon:getSV("framelock", "lock")
	
	db = LibStub("AceDB-3.0"):New("MageButtonsDB", SettingsDefaults)
	MageButtonsDB.db = db;
	MageButtonsMinimapData = ldb:NewDataObject("MageButtons",{
		type = "data source",
		text = "MageButtons",
		icon = "Interface/Icons/Spell_Holy_MagicalSentry.blp",
		OnClick = function(self, button)
			if button == "RightButton" then
				if IsShiftKeyDown() then
					MageButtons:maptoggle("0")
					print("MageButtons: Hiding icon, re-enable with: /MageButtons minimap 1")
				else
					InterfaceOptionsFrame_OpenToCategory(mbPanel)
					InterfaceOptionsFrame_OpenToCategory(mbPanel)
					InterfaceOptionsFrame_OpenToCategory(mbPanel)
				end
			
			elseif button == "LeftButton" then
				if lockStatus == 0 then
					-- Not locked, lock it and save the anchor position
					addon:lockAnchor()
				else
					-- locked, unlock
					addon:unlockAnchor()
				end
			end
		end,
		
		-- Minimap Icon tooltip
		OnTooltipShow = function(tooltip)
			tooltip:AddLine("|cffffffffMageButtons|r\nLeft-click to lock/unlock.\nRight-click to configure.\nShift+Right-click to hide minimap button.")
		end,
	})

	-- display the minimap icon?
	local mmap = addon:getSV("minimap", "icon") or 1
	if mmap == 1 then
		MageButtonsMinimapIcon:Register("mageButtonsIcon", MageButtonsMinimapData, MageButtonsDB)
		addon:maptoggle(1)
	else
		addon:maptoggle(0)
	end
end

-------------------------------
--- Minimap toggle function ---
-------------------------------
function addon:maptoggle(mtoggle)
	if ( debug == 1 ) then print("icon state: " .. mtoggle) end
	
	local mmTbl = {
		icon = mtoggle
	}
	
	MageButtonsDB["minimap"] = mmTbl
	
	if mtoggle == "0" or mtoggle == 0 then
		if ( debug >= 1 ) then print("hiding icon") end
		MageButtonsMinimapIcon:Hide("mageButtonsIcon")
	else
		if (MageButtonsMinimapIcon:IsRegistered("mageButtonsIcon")) then
			MageButtonsMinimapIcon:Show("mageButtonsIcon")
		else
			MageButtonsMinimapIcon:Register("mageButtonsIcon", MageButtonsMinimapData, MageButtonsDB)
			MageButtonsMinimapIcon:Show("mageButtonsIcon")
		end
	end
end

------------------------
-- Lock/Unlock anchor --
------------------------
function addon:lockAnchor()
	MageButtonsConfig:SetMovable(false)
	MageButtonsConfig:EnableMouse(false)
	MageButtonsFrame:SetBackdropColor(0, 0, 0, 0)

	local _, _, relativePoint, xPos, yPos = MageButtonsConfig:GetPoint()
	addon:setAnchorPosition(relativePoint, xPos, yPos)
	lockStatus = 1
	lockTbl = {
		lock = 1,
	}

	MageButtonsDB["framelock"] = lockTbl
end

function addon:unlockAnchor()
MageButtonsConfig:SetMovable(true)
	MageButtonsConfig:EnableMouse(true)
	MageButtonsFrame:SetBackdropColor(0, .7, 1, 1)
	lockStatus = 0
	lockTbl = {
		lock = 0,
	}

	MageButtonsDB["framelock"] = lockTbl
end

------------------------------
-- Retrieve anchor position --
------------------------------
function addon:getAnchorPosition()
	local posTbl = MageButtonsDB["position"]
	if posTbl == nil then
		return "CENTER", 200, -200
	else
		-- Table exists, get the value if it is defined
		relativePoint = posTbl["relativePoint"] or "CENTER"
		xPos = posTbl["xPos"] or 200
		yPos = posTbl["yPos"] or -200
		return relativePoint, xPos, yPos
	end
end

--------------------------
-- Save anchor position --
--------------------------
function addon:setAnchorPosition(relativePoint, xPos, yPos)
	posTbl = {
		relativePoint = relativePoint,
		xPos = xPos,
		yPos = yPos,
	}

	MageButtonsDB["position"] = posTbl
	
	--MageButtonsConfig:SetPoint("CENTER", xPos, yPos)
end

local baseButtons = {}
local baseButtonBackdrops = {}
local baseButtonBackdropFrames = {}
local menuStatus = {}
local teleportButtons, portalButtons, polymorphButtons = {}, {}, {}
local buttonBackdrops = {}
local buttonStore = {}
local backdropStore = {}

------------------
-- Base Buttons --
------------------
function addon:makeBaseButtons()
	local baseSpells = { Water = WaterTable[#WaterTable], Food = FoodTable[#FoodTable], Teleports = TeleportsTable[#TeleportsTable], Portals = PortalsTable[#PortalsTable], Gems = GemsTable[#GemsTable], Polymorph = PolymorphTable[#PolymorphTable]}
	local spellCounts = {Water = #WaterTable, Food = #FoodTable, Teleports = #TeleportsTable, Portals = #PortalsTable, Gems = #GemsTable, Polymorph = #PolymorphTable}
	local createButtonMenu = {addon:getSV("buttons", "a") or buttonTypes[1], addon:getSV("buttons", "b") or buttonTypes[2], 
							  addon:getSV("buttons", "c") or buttonTypes[3], addon:getSV("buttons", "d") or buttonTypes[4], 
							  addon:getSV("buttons", "e") or buttonTypes[5], addon:getSV("buttons", "f") or buttonTypes[6]}

	-- These store the menu state for each button (0 = closed, 1 = open)
	WaterMenu, FoodMenu, TeleportsMenu, PortalsMenu, GemsMenu, PolymorphMenu = 0, 0, 0, 0, 0, 0

	-- Pull items from Saved Variables
	growthDir = addon:getSV("growth", "direction") or "Horizontal"
	menuDir = addon:getSV("growth", "buttons") or "Up"
	btnSize = addon:getSV("buttonSettings", "size") or 26
	padding = addon:getSV("buttonSettings", "padding") or 5
	border = addon:getSV("borderStatus", "borderStatus") or 1
	backdropPadding = addon:getSV("buttonSettings", "bgpadding") or 2.5
	backdropRed = addon:getSV("bgcolor", "red") or .1
	backdropGreen = addon:getSV("bgcolor", "green") or .1
	backdropBlue = addon:getSV("bgcolor", "blue") or .1
	backdropAlpha = addon:getSV("bgcolor", "alpha") or 1
	mouseover = MageButtons:getSV("mouseover", "mouseover") or 0

	local keybindTable = {"MAGEBUTTONS_BUTTON1", "MAGEBUTTONS_BUTTON2", "MAGEBUTTONS_BUTTON3", "MAGEBUTTONS_BUTTON4", "MAGEBUTTONS_BUTTON5", "MAGEBUTTONS_BUTTON6"}

	local RUNE_OF_TELEPORTATION = 17031
	local RUNE_OF_PORTALS = 17032
	local reagentIds = {}
	reagentIds[RUNE_OF_PORTALS] = true
	reagentIds[RUNE_OF_TELEPORTATION] = true
	local reagentCounts = {}
	reagentCounts[RUNE_OF_PORTALS] = 0
	reagentCounts[RUNE_OF_TELEPORTATION] = 0
	for bagId = BACKPACK_CONTAINER, BACKPACK_CONTAINER + NUM_BAG_SLOTS, 1 do
		local numSlotsInBag = GetContainerNumSlots(bagId)
		for slotId = 0, numSlotsInBag, 1 do
			local itemId = GetContainerItemID(bagId, slotId)
			local _, itemCount, _, _, _, _, _, _, _, _ = GetContainerItemInfo(bagId, slotId)
			if reagentIds[itemId] then
				reagentCounts[itemId] = reagentCounts[itemId] + itemCount
			end
		end
	end
	local baseSpellToReagentCount = {
		Teleports = reagentCounts[RUNE_OF_TELEPORTATION],
		Portals = reagentCounts[RUNE_OF_PORTALS],
	}

	local j = 0
	for j = 1, #createButtonMenu, 1 do
		--createItem = createButtonMenu[j]
		local btnType = createButtonMenu[j]
		local baseSpell = baseSpells[btnType]
		local spellCount = spellCounts[btnType]
		local reagentCount = baseSpellToReagentCount[btnType]
		--local keybind = "U"

		if baseSpell ~= nil and baseSpell ~= "none" then
			--keybind = GetBindingKey("MAGEBUTTONS_BUTTON1")
			--print(keybind)
			
			-- Hide the button if it already exists
			if baseButtons[btnType] then
				baseButtons[btnType]:Hide()
			end
			
			-- Create new button
			local baseButton = CreateFrame("Button", btnType .. "Base", MageButtonsConfig, "SecureActionButtonTemplate");
			baseButton:RegisterForClicks("LeftButtonDown", "RightButtonDown")
			baseButton:SetAttribute("*type1", "spell");
			baseButton:SetAttribute("spell", baseSpell);
			
			-- Get keybindings
			--print(GetBindingKey(keybindTable[j]))
			if GetBindingKey(keybindTable[j]) ~= nil then
				--print("bound")
				local keybind = GetBindingKey(keybindTable[j])
				SetBindingClick(keybind, baseButton:GetName());
			end
			
			-- default menu status to 0 (closed)
			menuStatus[j] = 0
			
			-- Set the click properties of the button
			-- Left click: cast spell; Right click: open or close menu
			baseButton:SetScript("PostClick", function(self, button)
				if button == "RightButton" then
					if menuStatus[j] == 0 then
						MageButtons:showButtons(btnType, spellCount)
						menuStatus[j] = 1
					else
						MageButtons:hideButtons(btnType, spellCount)
						menuStatus[j] = 0
					end
				else
					MageButtons:hideButtons(btnType, spellCount)
					menuStatus[j] = 0
				end
			end)
			

			-- Button properties
			baseButton:SetPoint("TOP", MageButtonsFrame, "BOTTOM", xOffset, yOffset)
			baseButton:SetSize(btnSize, btnSize)
			baseButton:SetFrameStrata("HIGH")
			baseButton.t = baseButton:CreateTexture(nil, "BACKGROUND")
			local _, _, buttonTexture = GetSpellInfo(baseSpell)
			baseButton.t:SetTexture(buttonTexture)
			
			if border == 1 then
				baseButton.t:SetTexCoord(0.06,0.94,0.06,0.94)
			end
			baseButton.t:SetAllPoints()
			
			-- Tooltip
			baseButton:SetScript("OnEnter",function(self,motion)
				GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
				GameTooltip:ClearAllPoints()
				GameTooltip:SetPoint("BOTTOMLEFT", baseButton, "TOPRIGHT", 10, 5)
				GameTooltip:SetSpellBookItem(MageButtons:getTooltipNumber(baseSpell), BOOKTYPE_SPELL)
				GameTooltip:Show()
				
				if mouseover == 1 then
					-- Display menu on mouseover
					MageButtons:showButtons(btnType, spellCount)
				end
			end)
			
			baseButton:SetScript("OnLeave",function(self,motion)
				GameTooltip:Hide()
				
				if mouseover == 1 then
					-- Hide menu
					MageButtons:hideButtons(btnType, spellCount)
				end
			end)

			if reagentCount ~= nil then
				baseButton.Text = baseButton:CreateFontString(nil, "ARTWORK")
				baseButton.Text:SetFontObject(NumberFontNormal)
				baseButton.Text:SetText(("%d"):format(reagentCount))
				baseButton.Text:Show()
				baseButton.Text:ClearAllPoints()
				baseButton.Text:SetPoint("BOTTOMRIGHT", baseButton, "BOTTOMRIGHT")
			end

			-- Store the button in a table for easy access
			baseButtons[btnType] = baseButton

			-- Hide the background if it already exits
			if baseButtonBackdrops[btnType] then
				baseButtonBackdrops[btnType]:Hide()
			end
			
			-- Create new backdrop
			local baseButtonBackdrop = CreateFrame("Frame", "baseButtonBackdropFrame" .. j, UIParent, "BackdropTemplate")
			baseButtonBackdrop:ClearAllPoints()
			baseButtonBackdrop:SetPoint("CENTER", baseButtons[btnType], "CENTER", 0, 0)
			baseButtonBackdrop:SetSize(btnSize + backdropPadding * 2, btnSize + backdropPadding * 2)
			
			-- Store it in table
			baseButtonBackdrops[btnType] = baseButtonBackdrop

			baseButtonBackdrops[btnType].texture = baseButtonBackdrops[btnType]:CreateTexture(nil, "BACKGROUND")
			baseButtonBackdrops[btnType].texture:ClearAllPoints()
			baseButtonBackdrops[btnType].texture:SetAllPoints(baseButtonBackdrops[btnType])
			baseButtonBackdrops[btnType]:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
			baseButtonBackdrops[btnType]:SetBackdropColor(backdropRed, backdropGreen, backdropBlue, backdropAlpha)

			if mouseover == 1 then
				baseButtonBackdrops[btnType]:SetScript("OnEnter",function(self,motion)
					-- Display menu on mouseover
					MageButtons:showButtons(btnType, spellCount)
				end)

				baseButtonBackdrops[btnType]:SetScript("OnLeave",function(self,motion)
					-- Hide menu
					MageButtons:hideButtons(btnType, spellCount)
				end)
			end

			-- Show the backdrop
			baseButtons[btnType]:Show()
			

			-- Determine the growth criteria based on user settings
			if growthDir == "Vertical" then
				yOffset = yOffset - (btnSize + padding)
				totalHeight = -(yOffset - backdropPadding)
				totalWidth = btnSize + backdropPadding + backdropPadding
				xOffset = 0
			elseif growthDir == "Horizontal" then
				yOffset = 0
				xOffset = xOffset + (btnSize + padding)
				totalHeight = btnSize + backdropPadding + backdropPadding
				totalWidth = xOffset + backdropPadding
				backdropAnchor = "TOPLEFT"
				backdropParentAnchor = "BOTTOM"
				--backdropOffset = -(btnSize / 2 + backdropPadding)
			else
				print("MageButtons: Invalid growth direction")
			end
		end
		
	end
	

	-- Create the menu buttons for each spell type
	MageButtons:makeButtons("Water", WaterTable)
	MageButtons:makeButtons("Food", FoodTable)
	MageButtons:makeButtons("Teleports", TeleportsTable)
	MageButtons:makeButtons("Portals", PortalsTable)
	MageButtons:makeButtons("Gems", GemsTable)
	MageButtons:makeButtons("Polymorph", PolymorphTable)
	
	xOffset = 0
	yOffset = 0
end

-----------------------
-- Make menu buttons --
-----------------------
function addon:makeButtons(btnType, typeTable)
	-- Create buttons of the requested type
	-- type = Portal, Water, etc
	-- typeTable = table of values from the start of this file (WaterTable, etc)
	-- i = index to define unique button names (PortalsButton1, PortalsButton2, etc)
	local btnAnchor = nil
	local parentAnchor = nil
	local xOffset = 0
	local yOffset = 0
	
	local spellCounts = {Water = #WaterTable, Food = #FoodTable, Teleports = #TeleportsTable, Portals = #PortalsTable, Gems = #GemsTable, Polymorph = #PolymorphTable}
	local spellCount = spellCounts[btnType]
	
	--print(btnSize, menuDir)

	if menuDir == "Down" then
		--yOffset = yOffset - (btnSize + padding)
		btnAnchor = "TOP"
		parentAnchor = "BOTTOM"
		yOffset = -padding
		yOffsetGrowth = -(btnSize + padding)
		xOffsetGrowth = 0
	elseif menuDir == "Up" then
		--yOffset = yOffset + (btnSize + padding)
		btnAnchor = "BOTTOM"
		parentAnchor = "TOP"
		yOffset = padding
		yOffsetGrowth = btnSize + padding
		xOffsetGrowth = 0
	elseif menuDir == "Right" then
		--xOffset = xOffset + (btnSize + padding)
		btnAnchor = "LEFT"
		parentAnchor = "RIGHT"
		xOffset = padding
		yOffsetGrowth = 0
		xOffsetGrowth = btnSize + padding
	elseif menuDir == "Left" then
		--yOffset = 0
		--xOffset = xOffset - (btnSize + padding)	
		btnAnchor = "RIGHT"
		parentAnchor = "LEFT"
		xOffset = -padding
		yOffsetGrowth = 0
		xOffsetGrowth = -(btnSize + padding)
	else
		print("MageButtons: Invalid growth direction")
	end
	
	local i
	for i = 1, #typeTable, 1 do
		if typeTable[i] ~= nil then

			-- Hide the button if it already exists
			if buttonStore[btnType .. i] then
				backdropStore[btnType .. i]:Hide()
				buttonStore[btnType .. i]:Hide()
			end

			-- Create new button
			local button = CreateFrame("Button", "button", MageButtonsConfig)
			button:ClearAllPoints()

			button:SetPoint(btnAnchor, baseButtons[btnType], parentAnchor, xOffset, yOffset)
			button:SetSize(btnSize, btnSize)
			button:SetFrameStrata("HIGH")
			button:SetScript("OnClick", function()
				MageButtons:hideButtons(btnType, #typeTable)
				baseButtons[btnType]:SetAttribute("spell", typeTable[i])
				local _, _, buttonTexture = GetSpellInfo(typeTable[i])
				baseButtons[btnType].t:ClearAllPoints()
				baseButtons[btnType].t:SetTexture(nil)
				baseButtons[btnType].t:SetTexture(buttonTexture)
				baseButtons[btnType].t:SetAllPoints()
				
				baseButtons[btnType]:SetScript("OnEnter",function(self,motion)
					GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
					GameTooltip:ClearAllPoints()
					GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 10, 5)
					
					GameTooltip:SetSpellBookItem(MageButtons:getTooltipNumber(typeTable[i]), BOOKTYPE_SPELL)
					
					if mouseover == 1 then
						-- Display menu on mouseover
						MageButtons:showButtons(btnType, spellCount)
					end
					
					GameTooltip:Show()
				end)

				baseButtons[btnType]:SetScript("OnLeave",function(self,motion)
					GameTooltip:Hide()
					
					if mouseover == 1 then
						-- Hide menu
						MageButtons:hideButtons(btnType, spellCount)
					end
				end)
			end)
			
			-- Tooltip
			button:SetScript("OnEnter",function(self,motion)
				GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
				GameTooltip:ClearAllPoints()
				GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 10, 5)
				
				GameTooltip:SetSpellBookItem(MageButtons:getTooltipNumber(typeTable[i]), BOOKTYPE_SPELL)
				GameTooltip:Show()
				
				if mouseover == 1 then
					-- Display menu on mouseover
					addon:showButtons(btnType, spellCount)
				end
			end)
			
			button:SetScript("OnLeave",function(self,motion)
				GameTooltip:Hide()
				
				if mouseover == 1 then
					-- Hide menu
					addon:hideButtons(btnType, spellCount)
				end
			end)
			
			-- Store the button in a table
			buttonStore[btnType .. i] = button

			button.t = button:CreateTexture(nil, "BACKGROUND")
			local _, _, buttonTexture2 = GetSpellInfo(typeTable[i])
			button.t:SetTexture(buttonTexture2)
			if border == 1 then
				button.t:SetTexCoord(0.1,0.9,0.1,0.9)
			end
			button.t:SetAllPoints()
			

			-- Create button background
			local buttonBackdrop = CreateFrame("Frame", btnType .. "buttonBackdropFrame" .. i, UIParent, "BackdropTemplate")
			buttonBackdrop:SetPoint("CENTER", buttonStore[btnType .. i], "CENTER", 0, 0)
			buttonBackdrop:SetSize(btnSize + backdropPadding * 2, btnSize + backdropPadding * 2)

			buttonBackdrop.texture = buttonBackdrop:CreateTexture(nil, "BACKGROUND")
			buttonBackdrop.texture:ClearAllPoints(buttonBackdrop)
			buttonBackdrop.texture:SetAllPoints(buttonBackdrop)
			buttonBackdrop:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
			buttonBackdrop:SetBackdropColor(backdropRed, backdropGreen, backdropBlue, backdropAlpha)
			
			if mouseover == 1 then
				buttonBackdrop:SetScript("OnEnter",function(self,motion)
					-- Display menu on mouseover
					addon:showButtons(btnType, spellCount)
				end)
				
				buttonBackdrop:SetScript("OnLeave",function(self,motion)
					-- Hide menu
					addon:hideButtons(btnType, spellCount)
				end)
			end
						
			backdropStore[btnType .. i] = buttonBackdrop
		
			backdropStore[btnType .. i]:Hide()
			buttonStore[btnType .. i]:Hide()
			
			-- Add level requirement
			-- local level = 0
			-- if showLevels then
				-- local spellLevels = {
					-- 5504 = 1,
					-- 5505 = 5,
					-- 5506 = 15,
					-- 6127 = 25,
					-- 10138 = 35,
					-- 10139 = 45,
					-- 10140 = 55,
					-- 587 = 1,
					-- 597 = 5,
					-- 990 = 15,
					-- 6129 = 25,
					-- 10144 = 35,
					-- 10145 = 45,
					-- 28612 = 55,
				-- }
				-- level = spellLevels[typeTable[i]]
			-- end
			
			yOffset = yOffset + yOffsetGrowth
			xOffset = xOffset + xOffsetGrowth
		end
	end
end

-- Show the menu buttons
function addon:showButtons(btnType, count)
	for i = 1, count, 1 do
		buttonStore[btnType .. i]:Show()
		backdropStore[btnType .. i]:Show()
	end
end

-- Hide the menu buttons
function addon:hideButtons(btnType, count)
	for i = 1, count, 1 do
		buttonStore[btnType .. i]:Hide()
		backdropStore[btnType .. i]:Hide()
	end
end

-- Get tooltip information
function addon:getTooltipNumber(spellName)
	local slot = 1
	while true do
		local spell, rank = GetSpellBookItemName(slot, BOOKTYPE_SPELL)
		if rank ~= nil then
			spell = spell .. "(" .. rank .. ")"
		end

		if (not spell) then
			break
		elseif (spell == spellName) then
			return slot
		end
	   slot = slot + 1
	end
end

-- Function to retrieve Saved Variables
function addon:getSV(category, variable)
	local vartbl = MageButtonsDB[category]
	
	if vartbl == nil then
		vartbl = {}
	end
	
	if ( vartbl[variable] ~= nil ) then
		--print("getSV - " .. variable .. ": " .. vartbl[variable])
		return vartbl[variable]
	else
		return nil
	end
end

-- Not used
-- function addon:getButtonType(btnNumber)
	-- local buttontbl = MageButtonsDB["buttons"]
	-- if ( buttontbl[btnNumber] == "none" ) then
		-- return "none"
	-- else
		-- return buttontbl[btnNumber]
	-- end
-- end

-- Register Events
MageButtonsConfig:RegisterEvent("ADDON_LOADED")
MageButtonsConfig:RegisterEvent("SPELL_DATA_LOAD_RESULT")
MageButtonsConfig:SetScript("OnEvent", onevent)
