--[[-----------------------------------------------------------------------------
Name: FBagOfHolding.lua
Revision: $Revision$
Author(s): Feithar
Description:
-------------------------------------------------------------------------------]]

local Dewdrop = AceLibrary("Dewdrop-2.0");

local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision$");

local FBOH_VERSION = "0.9.2";

local defaults = {
	profile = {
		gridScale = 1.0,
		hookOpenAllBags = true;
		hookToggleBackpack = true;
		hookToggleBags = {
			"default",
			"default",
			"default",
			"default",
		},
	},
};

local defaultViewDefinitions = {
	{
		activeTab = 1,
		tabs = {
			{
				name = L["Main Bag"],
				filter = "default"
			},
		},
	},
};

local Crayon = LibStub("LibCrayon-3.0");
local TipHooker = LibStub("LibTipHooker-3.0");
local AceConfig = LibStub("AceConfigDialog-3.0");

FBoH = LibStub("AceAddon-3.0"):NewAddon("Feithar's Bag of Holding",
										"AceConsole-3.0",
										"AceEvent-3.0",
										"AceHook-3.0",
										"AceTimer-3.0",
										"LibFuBarPlugin-Mod-3.0");

--*****************************************************************************
-- Error handling and debugging
--*****************************************************************************

local
function _ErrorHandler(msg)
	FBoH:Debug("|cffff0000UNHANDLED ERROR:|r |cffffff00" .. tostring(msg) .. "|r");
end

local
function _SafeCall(method)
	xpcall(method, _ErrorHandler);
end

function FBoH:Debug(message)
	if self.db.profile.debugMessages then self:Print(message) end;
end

FBoH._SafeCall = _SafeCall;

--*****************************************************************************
-- Private Methods
--*****************************************************************************

-- Simple shallow copy for copying defaults
local
function _CopyTable(src, dest)
	if type(dest) ~= "table" then dest = {} end
	if type(src) == "table" then
		for k,v in pairs(src) do
			if type(v) == "table" then
				-- try to index the key first so that the metatable creates the defaults, if set, and use that table
				v = _CopyTable(v, dest[k])
			end
			dest[k] = v
		end
	end
	return dest
end

local
function _DewdropMenuPoint(frame)
	local x, y = frame:GetCenter()
	local leftRight
	if x < GetScreenWidth() / 2 then
		leftRight = "LEFT"
	else
		leftRight = "RIGHT"
	end
	if y < GetScreenHeight() / 2 then
		return "BOTTOM" .. leftRight, "TOP" .. leftRight
	else
		return "TOP" .. leftRight, "BOTTOM" .. leftRight
	end
end
	
local
function _GetItemCounts(self, itemLink)
	local itemKey = self.items:GetItemKey(itemLink);
	local realm = GetRealmName();
	
	local f = {
		{
			filter = self:GetFilter("Item Key").filter;
			arg = itemKey;
		},
		{
			filter = self:GetFilter("Character").filter;
			arg = realm .. ".*"
		}
	};
	
	local results = self.items:FindItems(self:GetFilter("And").filter, f);
	
	local rVal = {};
	
	local counters = {};
	local resultCount = 0;
	local totalCount = 0;
	for _, data in ipairs(results) do
		counters[data.character] = counters[data.character] or {};
		counters[data.character][data.bagType] = counters[data.character][data.bagType] or 0;
		counters[data.character][data.bagType] = counters[data.character][data.bagType] + data.itemCount;
	end

	for cName, cData in pairs(counters) do
		local str = cName .. ":";
		local subCounters = {};
		for bType, cnt in pairs(cData) do
			table.insert(subCounters, " [" .. bType .. ": " .. cnt .. "]");
			resultCount = resultCount + 1;
			totalCount = totalCount + cnt;
		end
		table.sort(subCounters);
		for _, v in ipairs(subCounters) do
			str = str .. v;
		end
		table.insert(rVal, str);
	end

	if resultCount > 1 then
		table.sort(rVal);
		table.insert(rVal, "Total: " .. totalCount);
	end
	
	return rVal;
end

local
function _ProcessTooltip(tooltip, name, link)
	local output = _GetItemCounts(FBoH, link);
	
	if output then
		for _, v in pairs(output) do
			tooltip:AddLine(v, 0, 1, 1);
		end
	end
	
	tooltip:Show();
end

local
function _RenumberViewIDs(self)
	for i, v in ipairs(self.bagViews) do
		v.viewIndex = i;
	end
end

--*****************************************************************************
-- Events
--*****************************************************************************

function FBoH:OnInitialize()
	_SafeCall(function()
		self.items = FBoH_ItemDB;

		self.db = LibStub("AceDB-3.0"):New("FBoH_DB", defaults)
		
		self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
		self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
		self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
		
		self.configOptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

		-- Create the FuBarPlugin bits.
		self:SetFuBarOption("GameTooltip", true);
		self:SetFuBarOption("iconPath", "Interface\\Buttons\\Button-Backpack-Up");

		self.sessionStartTime = time() + 10;
		
		optFrame = AceConfig:AddToBlizOptions(L["FBoH"], L["FBoH"]);	
	end);
end

FBoH.filters = {};
FBoH.bagViews = {};

function FBoH:OnEnable()
	_SafeCall(function()
		self.items:CheckVersion();
		
		self:RegisterEvent("BANKFRAME_OPENED");
		self:RegisterEvent("BANKFRAME_CLOSED");

		self:RegisterEvent("GUILDBANKFRAME_OPENED");
		self:RegisterEvent("GUILDBANKFRAME_CLOSED");
		self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED");
		
		self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED", "ScanAllContainers");
		self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", "ScanAllContainers");
		self:RegisterEvent("BAG_UPDATE", "ScanContainer");
		self:RegisterEvent("UNIT_INVENTORY_CHANGED", "ScanInventory");

		local iSlots = {
			"HeadSlot",
			"NeckSlot",
			"ShoulderSlot",
			"BackSlot",
			"ChestSlot",
			"ShirtSlot",
			"TabardSlot",
			"WristSlot",
			"HandsSlot",
			"WaistSlot",
			"LegsSlot",
			"FeetSlot",
			"Finger0Slot",
			"Finger1Slot",
			"Trinket0Slot",
			"Trinket1Slot",

			"MainHandSlot",
			"SecondaryHandSlot",
			"RangedSlot",
			"AmmoSlot",

			"Bag0Slot",
			"Bag1Slot",
			"Bag2Slot",
			"Bag3Slot"
		};

		self.inventorySlots = {};
		
		for _, v in pairs(iSlots) do
			local id, tex = GetInventorySlotInfo(v);
			self.inventorySlots[id] = {
				name = v;
				texture = tex;
			};
		end
		
		self.bankIsOpen = false;
		self.scanQueues = {};
		
		TipHooker:Hook(_ProcessTooltip, "item")

		self:RawHook("OpenAllBags", true);
		self:Hook("CloseAllBags", true);
		self:RawHook("ToggleBackpack", true);
		self:RawHook("ToggleBag", true);
		
		self:ScanContainer(0);	-- Because WoW doesn't update the main bag when the player logs in...
		self:ScanInventory();
		
		self:OnProfileChanged();
	end);
end

function FBoH:OnDisable()
	_SafeCall(function()
		self:UnhookAll();
		TipHooker:Unhook(_ProcessTooltip, "item")
	end);
end

function FBoH:OnProfileChanged()
	_SafeCall(function()
		-- First, if we have existing bag views, hide them all
		if self.bagViews then
			for _, v in pairs(self.bagViews) do
				v:Hide();
			end
		end
		
		FBoH_Configure:Hide();
		
		self.db.profile.viewDefs = self.db.profile.viewDefs or _CopyTable(defaultViewDefinitions);
--		self.db.profile.viewDefs = defaultViewDefinitions;
		self.bagViews = {};
		
		local viewDefs = self.db.profile.viewDefs;
		for k, v in pairs(viewDefs) do
			self.bagViews[k] = FBoH_ViewModel(v);
			if FBoH_TabModel.defaultTab then
				FBoH_TabModel.defaultTab.filterCache = nil;
			end
		end
		_RenumberViewIDs(self);
	end);
end

function FBoH:ShowConfig()
	_SafeCall(function()
		AceConfig:SetDefaultSize(L["FBoH"], 500, 550)
		AceConfig:Open(L["FBoH"], configFrame)
	end);
end
FBoH.OpenMenu = FBoH.ShowConfig -- for FuBar

function FBoH:CanViewAsList()
	return self.canViewAsList;
end

--*****************************************************************************
-- FuBar Functions
--*****************************************************************************

local
function ShowView(bagIndex, tabIndex)
	local view = FBoH.bagViews[bagIndex];
	view:Show();
	view:SelectTab(tabIndex);
end

function FBoH:OnFuBarClick()
	_SafeCall(function()
		GameTooltip:Hide();
		
		local fubarFrame = self:GetFrame();
		if self:IsFuBarMinimapAttached() then
			fubarFrame = Minimap;
		end
		
		Dewdrop:Open(fubarFrame,
			'children', function()
				Dewdrop:AddLine(
					'text', L["Feithar's Bag of Holding"],
					'textR', 1, 'textG', 1, 'textB', 0,
					'notClickable', true,
					'notCheckable', true
				);
				Dewdrop:AddSeparator();
				
				for vi, v in ipairs(self.bagViews) do
					for ti, t in ipairs(v.viewDef.tabs) do
						Dewdrop:AddLine(
							'text', t.name,
							'func', ShowView,
							'arg1', vi, 'arg2', ti,
							'closeWhenClicked', true
						);
					end
					Dewdrop:AddSeparator();
				end
				
				Dewdrop:AddLine(
					'text', L["Open All Views"],
					'func', function()
						for _, v in ipairs(FBoH.bagViews) do
							v:Show();
						end
					end
				);
				Dewdrop:AddSeparator();
				
				Dewdrop:AddLine(
					'text', L["Create New View"],
					'textR', 1, 'textG', 0.8, 'textB', 0.2,
					'func', function()
						FBoH:CreateNewView();
					end
				);
			end,
			'point', _DewdropMenuPoint
		);
	end);
end

function FBoH:OnUpdateFuBarText()
	_SafeCall(function()
		local total, free = self.items:GetBagUsage("Bags");
	
		local used = total - free;
		
		local text = used .. "/" .. total;
		local c = Crayon:GetThresholdHexColor(free / total);
		
		self:SetFuBarText("|cff" .. c .. used .. " |cffffffff/ |cff" .. c .. total);
	end);
end

function FBoH:OnUpdateFuBarTooltip()
	_SafeCall(function()
		local igtotal, igfree, itotal, ifree = self.items:GetBagUsage("Bags");
		local bgtotal, bgfree, btotal, bfree = self.items:GetBagUsage("Bank");
		
		local iused = itotal - ifree;
		local bused = btotal - bfree;
		local igused = igtotal - igfree;
		local bgused = bgtotal - bgfree;

		GameTooltip:AddLine(L["Feithar's Bag of Holding"]);
		GameTooltip:AddLine(FBOH_VERSION .. "." .. FBoH_GetVersion(), 0, 1, 1);
		GameTooltip:AddLine(" ");
		
		local numbers;
		if itotal ~= igtotal then
			numbers = igused .. "/" .. igtotal .. " (" .. iused .. "/" .. itotal .. ")"
		else
			numbers = igused .. "/" .. igtotal
		end
		local r,g,b = Crayon:GetThresholdColor(ifree / itotal);
		GameTooltip:AddDoubleLine(L["Bags"] .. ": ", numbers, 1, 1, 1, r, g, b);
		
		if btotal ~= bgtotal then
			numbers = bgused .. "/" .. bgtotal .. " (" .. bused .. "/" .. btotal .. ")";
		else
			numbers = bgused .. "/" .. bgtotal
		end
		local r,g,b = Crayon:GetThresholdColor(bfree / btotal);
		GameTooltip:AddDoubleLine(L["Bank"] .. ": ", numbers, 1, 1, 1, r, g, b);
		
		GameTooltip:AddLine(" ");
		
		GameTooltip:AddLine(L["FuBar Hint"], 0, 1, 0, 1);
		
	    -- tablet:SetHint(L["Hint"])
	    -- as a rule, if you have an OnClick or OnDoubleClick or OnMouseUp or OnMouseDown, you should set a hint.
	end);
end

--*****************************************************************************
-- Creating/Deleting Views
--*****************************************************************************

function FBoH:CreateNewView()
	local newView = {
		tabs = {
			{
				name = "New View",
				filter = {
					name = "Character",
				},
			},
		},
	};
	
	table.insert(self.db.profile.viewDefs, newView);
	table.insert(self.bagViews, FBoH_ViewModel(newView));

	if FBoH_TabModel.defaultTab then
		FBoH_TabModel.defaultTab.filterCache = nil;
	end

	_RenumberViewIDs(self);	

	local view = self.bagViews[#(self.bagViews)];
	
	view:Show();

	FBoH_Configure:SetModel(view);
	FBoH_Configure:Show();
end

function FBoH:DeleteViewTab(tabModel)
	if tabModel.tabDef.filter == "default" then
		FBoH:Print("Can not delete the default view!");
		return;
	end
	
--	FBoH:Print("Deleting tab: " .. tabModel.tabDef.name);
	
	tabModel.tabDef.DELETE_THIS_TAB = true;
	
	local delViewID, delTabID, delTabCount = nil, nil;
	local delView = nil;
	
	for vi, view in ipairs(self.bagViews) do
		for ti, tab in ipairs(view.tabData) do
			if tab.tabDef.DELETE_THIS_TAB then
				delView = view;
				delViewID = vi;
				delTabID = ti;
				delTabCount = #(view.tabData);
				tab.tabDef.DELETE_THIS_TAB = nil;
			end
		end
	end
	
--	FBoH:Print("   Tab " .. delTabID .. " from view " .. delViewID .. " (with " .. delTabCount .. " tabs)");
	
	if delTabCount == 1 then
		table.remove(self.bagViews, delViewID);
		table.remove(self.db.profile.viewDefs, delViewID);
		
		delView:Hide();
		delView.viewDef = nil;
		delView.tabDef = nil;
	else
		table.remove(delView.viewDef.tabs, delTabID);
		table.remove(delView.tabData, delTabID):Hide();
		delView:SelectTab(1);
	end

	_RenumberViewIDs(self);
end

function FBoH:OpenAllBags()
	_SafeCall(function()
		if self.db.profile.hookOpenAllBags then
			local showBags = false;
			for _, v in ipairs(self.bagViews) do
				if not v:IsShown() then
					showBags = true;
				end
			end
			
			for _, v in ipairs(self.bagViews) do
				if showBags then
					v:Show();
				else
					v:Hide();
				end
			end	
		else
			local close, back, toggle = self.db.profile.hookCloseAllBags, self.db.profile.hookToggleBackpack, self.db.profile.hookToggleBags;
			self.db.profile.hookCloseAllBags, self.db.profile.hookToggleBackpack, self.db.profile.hookToggleBags = false, false, {};
			self.hooks.OpenAllBags()
			self.db.profile.hookCloseAllBags, self.db.profile.hookToggleBackpack, self.db.profile.hookToggleBags = close, back, toggle;
		end
	end);
end

function FBoH:CloseAllBags()
	for _, v in ipairs(self.bagViews) do
		v:Hide();
	end
end

function FBoH:ToggleBackpack()
	if self.db.profile.hookToggleBackpack then
		for _, v in ipairs(self.bagViews) do
			for i, t in ipairs(v.viewDef.tabs) do
				if t.filter == "default" then
					if v:IsShown() then
						if v.viewDef.activeTab == i then
							v:Hide();
						else
							v:SelectTab(i);
						end
					else
						v:SelectTab(i);
						v:Show();
					end
				end
			end
		end
	else
		self.hooks.ToggleBackpack()
	end
end

function FBoH:ToggleBag(id, force)
	local tabID = nil;
	if self.db.profile.hookToggleBags and self.db.profile.hookToggleBags[id] then
		if self.db.profile.hookToggleBags[id] ~= "blizzard" then
			tabID = self.db.profile.hookToggleBags[id];
		end
	end
	
	if tabID then
		if tabID == "default" then
			if not FBoH_TabModel.defaultTab then return end;
			tabID = FBoH_TabModel.defaultTab.id;
		else
			tabID = tonumber(tabID);
		end
		
		for _, v in ipairs(self.bagViews) do
			for i, t in ipairs(v.tabData) do
				if t.id == tabID then
					if v:IsShown() then
						if v.viewDef.activeTab == i then
							v:Hide();
						else
							v:SelectTab(i);
						end
					else
						v:SelectTab(i);
						v:Show();
					end
				end
			end
		end
	else
		self.hooks.ToggleBag(id, force);
	end
end

--*****************************************************************************
-- View Docking
--*****************************************************************************

function FBoH:DockView(sourceView, targetView, targetTab)
	if sourceView == targetView then
--		self:Print("Can not dock view " .. sourceView .. " into itself!");
		return;
	end
	
--	self:Print("Docking view " .. sourceView .. " into view " .. targetView .. " after tab " .. targetTab);
	
	FBoH_Configure:Hide();
	
	-- remove the view and definition
	local oldView = table.remove(self.bagViews, sourceView);
	table.remove(self.db.profile.viewDefs, sourceView);
	local wasShown = oldView:IsShown();
	oldView:Hide();
	
	local newView = self.bagViews[targetView];
	
	local newTabs = {};
	local newTabData = {};
	local tabCount = 1;
	
	for i = 1, targetTab do
		table.insert(newTabs, newView.viewDef.tabs[i]);
		table.insert(newTabData, newView.tabData[i]);
--		self:Print("Added tab " .. tabCount .. " from target view");
		tabCount = tabCount + 1;
	end
	
	for i, t in ipairs(oldView.viewDef.tabs) do
		table.insert(newTabs, t);
		table.insert(newTabData, oldView.tabData[i]);
--		self:Print("Added tab " .. tabCount .. " from source view");
		tabCount = tabCount + 1;
	end
	
	for i = targetTab + 1, #(newView.viewDef.tabs) do
		table.insert(newTabs, newView.viewDef.tabs[i]);
		table.insert(newTabData, newView.tabData[i]);
--		self:Print("Added tab " .. tabCount .. " from target view");
		tabCount = tabCount + 1;
	end
	
	oldView.viewDef = nil;
	oldView.tabData = nil;
	
	newView.viewDef.tabs = newTabs;
	newView.tabData = newTabData;
	
	newView:SelectTab(targetTab + 1);
	if wasShown then
		newView:Show();
	else
		newView:Hide();
	end
end

function FBoH:UndockView(sourceView, sourceTab)
--	self:Print("Undocking tab " .. sourceTab .. " from the view " .. sourceView);

	FBoH_Configure:Hide();
	
	-- Remove the tab from the main bag, and update it.
	local tabDef = table.remove(self.bagViews[sourceView].viewDef.tabs, sourceTab);
	local tabData = table.remove(self.bagViews[sourceView].tabData, sourceTab);
	self.bagViews[sourceView]:SelectTab(1);
	
--	self:Print(#(self.db.profile.viewDefs[sourceView].tabs) .. " tabs remaining in source view");
	
	-- Create a new bag
	local newViewDef = {
		activeTab = 1;
		tabs = {
			tabDef
		}
	};
	local newTabData = {
		tabData;
	};
	
	local newBagView = FBoH_ViewModel(newViewDef, newTabData);
	table.insert(self.bagViews, newBagView);
	table.insert(self.db.profile.viewDefs, newViewDef);

	if FBoH_TabModel.defaultTab then
		FBoH_TabModel.defaultTab.filterCache = nil;
	end
	
	if self.bagViews[sourceView]:IsShown() then
		newBagView:Show();
	else
		newBagView:Hide();
	end
	
	_RenumberViewIDs(self);
	
	return newBagView;
end

function FBoH:GetUniqueTabID()
	local rVal = time();
	local unique = false;
	
	while unique == false do
		unique = true;
		for _, v in ipairs(self.db.profile.viewDefs) do
			for _, t in ipairs(v.tabs) do
				if t.id == rVal then
					unique = false;
					rVal = rVal + 1;
				end
			end
		end
	end
	
	return rVal;
end

--*****************************************************************************
-- Item Count Data Access
--*****************************************************************************

function FBoH:GetItemBagAndSlotIDs(item)
	return self:GetBagID(item.bagType, item.bagIndex), item.slotIndex;
end

--*****************************************************************************
-- Bag Scanning
--*****************************************************************************

function FBoH:GetEmptySlots(...)
	return self.items:GetEmptySlots(...);
end

function FBoH:GetBagID(bagType, bagIndex)
	if bagType == "Bags" then
		return bagIndex - 1;
	end
	
	if bagType == "Bank" then
		if bagIndex == 1 then return BANK_CONTAINER end;
		return (bagIndex - 1) + NUM_BAG_SLOTS;
	end
	
	if bagType == "Keyring" then
		return -2;
	end
	
	return nil;
end

--*****************************************************************************
-- Inventory Scanning
--*****************************************************************************

function FBoH:IsBankOpen()
	return self.bankIsOpen;
end

function FBoH:GetBagViewByID(bagViewID)
	for k, v in pairs(self.bagViews) do
		if v.bagDef.id == bagViewID then
			return v;
		end
	end
	return nil;
end

--*****************************************************************************
-- Item Sorting.
--*****************************************************************************

function FBoH.Sort_Items(a, b)
	-- Current character always comes first.
	local chr = UnitName("player");
	if a.realm == b.realm then
		if (a.character == chr) and (b.character ~= chr) then return true end;
		if (a.character ~= chr) and (b.character == chr) then return false end;
	end
	
	-- For the current character, always sort by bag type first so we can group correctly
	if (a.character == chr) and (a.realm == GetRealmName()) then
		if a.bagType < b.bagType then return true end;
		if a.bagType > b.bagType then return false end;
	end
	
	-- Do configured sorts now...
	local sorters = FBoH.sorters or {};
	for _, s in ipairs(sorters) do
		local rTrue, rFalse = true, false;
		if s.descending then
			rTrue, rFalse = false, true;
		end
		
		local sorter = FBoH:GetSorter(s.name);
		if sorter.sortCompare(a, b) then return rTrue end;
		if sorter.sortCompare(b, a) then return rFalse end;
	end
	
	-- If configured sorts didn't get everything else figured out, do the rest...
	
	local aName, aRarity = a.detail.name, a.detail.rarity;
	local bName, bRarity = b.detail.name, b.detail.rarity;
	
	aName = aName or "Unknown";
	bName = bName or "Unknown";
	
	aRarity = aRarity or 0;
	bRarity = bRarity or 0;
	
	-- Sort by quality
	if aRarity > bRarity then return true end;
	if aRarity < bRarity then return false end;

	-- Sory be name
	if aName < bName then return true end;
	if aName > bName then return false end;
	
	-- Sort by realm and character
	if a.realm < b.realm then return true end;
	if a.realm > b.realm then return false end;
	if a.character < b.character then return true end;
	if a.character > b.character then return false end;
		
	-- Sort by bag type
	if a.bagType < b.bagType then return true end;
	if a.bagType > b.bagType then return false end;

	-- As a last resort, sort in the order they appear in the default UI
	if a.bagIndex < b.bagIndex then return true end;
	if a.bagIndex > b.bagIndex then return false end;
	if a.slotIndex < b.slotIndex then return true end;
	if a.slotIndex > b.slotIndex then return false end;
	
	return false;
end

--*****************************************************************************
-- Item Properties.
--*****************************************************************************

function FBoH:RegisterProperty(property)
	self.filters[property.name] = property;
	
	for k, v in pairs(self.bagViews) do
		v:SetFilter()
	end
	self.bagUpdateQueued = nil;	
end

function FBoH:GetFilter(filterName)
	local rVal = self.filters[filterName];

	if rVal == nil then
		rVal = {
			name = filterName,
			desc = L["Undefined"],
			undefined = true;
		};
	end
	if rVal.filter == nil then
		rVal.filter = function() return false end;
	end
	
	return rVal;
end

function FBoH:GetFilters(allFilters)
	local rVal = {};
	for k, v in pairs(self.filters) do
		if allFilters or (not v.internal) then
			if v.filter then
				local newFilter = {
					label = v.desc or k;
					key = k;
				};
				table.insert(rVal, newFilter);
			end
		end
	end
	table.sort(rVal, function(a, b)
		return (a.label < b.label);
	end);
	return rVal;
end

function FBoH:GetSorter(sorterName)
	local rVal = self.filters[sorterName];

	if rVal == nil then
		rVal = {
			name = sorterName,
			desc = L["Undefined"],
			undefined = true;
		};
	end
	if rVal.sortCompare == nil then
		rVal.sortCompare = function() return false end;
	end
	
	return rVal;
end

function FBoH:GetSorters(allSorters)
	local rVal = {};
	for k, v in pairs(self.filters) do
		if allSorters or (not v.internal) then
			if v.sortCompare then
				local newSorter = {
					label = v.desc or k;
					key = k;
				};
				table.insert(rVal, newSorter);
			end
		end
	end
	table.sort(rVal, function(a, b)
		return (a.label < b.label);
	end);
	return rVal;
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local andFilter = {};

andFilter.name = "And";
andFilter.internal = true;
function andFilter.filter(itemProps, filters)
	for _, filter in ipairs(filters) do
		if filter.filter(itemProps, filter.arg) == false then
			return false;
		end
	end
	return true;
end

FBoH:RegisterProperty(andFilter);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local orFilter = {};

orFilter.name = "Or";
orFilter.internal = true;
function orFilter.filter(itemProps, filters)
	for _, filter in ipairs(filters) do
		if filter.filter(itemProps, filter.arg) == true then
			return true;
		end
	end
	return false;
end

FBoH:RegisterProperty(orFilter);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local notFilter = {};

notFilter.name = "Not";
notFilter.internal = true;
function notFilter.filter(itemProps, filter)
	if filter.filter(itemProps, filter.arg) == true then
		return false;
	else
		return true;
	end
end


FBoH:RegisterProperty(notFilter);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local itemKeyProperty = {};

itemKeyProperty.name = "Item Key";
itemKeyProperty.internal = true;
function itemKeyProperty.filter(itemProps, key)
	if itemProps.itemKey == key then
		return true;
	else
		return false;
	end
end

FBoH:RegisterProperty(itemKeyProperty);

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

FBoH_UnitTests.Core = {

	setUp = function()
		FBoH_UnitTests.Core.wasDebugEnabled = FBoH:IsDebugEnabled();
		FBoH:SetDebugEnabled(nil);
	end;
	
	tearDown = function()
		FBoH:SetDebugEnabled(FBoH_UnitTests.Core.wasDebugEnabled);
	end;
	
	testHandleError = function()
		_SafeCall(function() error("Throw a test error"); end);
	end;
	
};
