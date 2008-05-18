--[[-----------------------------------------------------------------------------
Name: FBagOfHolding.lua
Revision: $Rev$
Author(s): Feithar
Description:
-------------------------------------------------------------------------------]]

local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

local defaults = {
	profile = {
		["gridScale"] = 1.0,
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
			{
				name = "Eggs",
				filter = {
					name = "And",
					arg = {
						{
							name = "Character",
						},
						{
							name = "Item Name",
							arg = "egg",
						},
					},
				},
				viewAsList = true;
			},
		},
	},
	{
		activeTab = 1;
		tabs = {
			{
				name = "Test",
				filter = {
					name = "And",
					arg = {
						{
							name = "Character",
						},
						{
							name = "Item Name",
							arg = "shard",
						},
					},
				},
				viewAsList = true;
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
										"AceTimer-3.0",
										"LibFuBarPlugin-Mod-3.0");

--*****************************************************************************
-- Events
--*****************************************************************************

function FBoH:BANKFRAME_CLOSED()
	self.bankIsOpen = false;
	self:UpdateBags();
end

function FBoH:BANKFRAME_OPENED()
	self.bankIsOpen = true;
	self:ScanContainer();
end

function FBoH:OnInitialize()
	self.items = FBoH_ItemDB;

	self.db = LibStub("AceDB-3.0"):New("FBoH_DB", defaults, "Default")
	
	-- Create the FuBarPlugin bits.
	self:SetFuBarOption("GameTooltip", true);
--	self:SetFuBarOption("hasNoColor", true)
--	self:SetFuBarOption("cannotDetachTooltip", true)
--	self:SetFuBarOption("hideWithoutStandby", true)
--	self:SetFuBarOption("configType", "Dewdrop-2.0");
	self:SetFuBarOption("iconPath", "Interface\\Buttons\\Button-Backpack-Up");

	optFrame = AceConfig:AddToBlizOptions(L["FBoH"], L["FBoH"]);	
end

FBoH.filters = {};
FBoH.bagViews = {};

function FBoH:OnEnable()
	self.items:CheckVersion();
	
	self:RegisterEvent("BANKFRAME_OPENED");
	self:RegisterEvent("BANKFRAME_CLOSED");

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
	
	TipHooker:Hook(self.ProcessTooltip, "item")

	self:ScanContainer(0);	-- Because WoW doesn't update the main bag when the player logs in...
	self:ScanInventory();
	
	self.db.profile.viewDefs = self.db.profile.viewDefs or defaultViewDefinitions;
--	self.db.profile.viewDefs = defaultViewDefinitions;
	self.bagViews = {};
	
	local viewDefs = self.db.profile.viewDefs;
	for k, v in pairs(viewDefs) do
		self.bagViews[k] = FBoH_ViewModel(v);
		if FBoH_TabModel.defaultTab then
			FBoH_TabModel.defaultTab.filterCache = nil;
		end
	end
	self:RenumberViewIDs();
end

function FBoH:OnDisable()
	TipHooker:Unhook(self.ProcessTooltip, "item")
end

function FBoH.ProcessTooltip(tooltip, name, link)
	local output = FBoH:GetItemCounts(link);
	
	if output then
		for _, v in pairs(output) do
			tooltip:AddLine(v, 0, 1, 1);
		end
	end
	
	tooltip:Show();
end

function FBoH:ShowConfig()
	AceConfig:SetDefaultSize(L["FBoH"], 500, 550)
	AceConfig:Open(L["FBoH"], configFrame)
end
FBoH.OpenMenu = FBoH.ShowConfig -- for FuBar

--*****************************************************************************
-- Commands
--*****************************************************************************

function FBoH:CmdPurge()
	self.items:Purge();
	self:ScanContainer();
end

function FBoH:CmdScan()
	self:ScanContainer();
end
--[[
function FBoH:CmdShowBags()
	for k, v in pairs(self.bagViews) do
		self:Print(L["Bag View"] .. ": " .. k);
		for i, t in ipairs(v.viewDef.tabs) do
			self:Print("   Tab: " .. t.name);
			local items = v.tabData[i]:GetItems();
			for _, j in pairs(items) do
				self:Print("      " .. j.character .. " (" .. j.realm .. ") " .. L[j.bagType] .. " [" .. j.bagIndex .. ", " .. j.slotIndex .. "] " .. j.itemLink);
			end
		end
	end	
end
]]
function FBoH:CmdCreateNewView()
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

	self:RenumberViewIDs();	

	local view = self.bagViews[#(self.bagViews)];
	
	view:Show();

	FBoH_Configure:SetModel(view);
	FBoH_Configure:Show();
end

--[[
function FBoH:CmdDock()
	if #(self.bagViews) < 1 then
		self:Print("No views available for docking");
	end
	
	local sourceView = 2;
	local targetView = 1;
	local targetTab = 1;
	
	self:Dock(sourceView, targetView, targetTab);
end

function FBoH:CmdUndock()
	local tabCount = #(self.bagViews[1].viewDef.tabs);
	if tabCount <= 1 then
		self:Print("No tabs available for undocking");
		return
	end
	
	local sourceBag = 1;
	local sourceTab = 2;

	self:UndockView(sourceBag, sourceTab);
end
]]
function FBoH:GetGridScale()
	return self.db.profile.gridScale;
end

function FBoH:SetGridScale(scale)
	self.db.profile.gridScale = scale;
	
	for _, v in pairs(self.bagViews) do
		v.view:SetGridScale(scale);
	end
end

--*****************************************************************************
-- FuBar Functions
--*****************************************************************************

function FBoH:OnFuBarClick()
	for k, v in pairs(self.bagViews) do
		v:Show();
	end
	
--	local bag = self.bagViews[1];
--	if bag then
--		if bag:IsShown() then bag:Hide() else bag:Show() end;
--	end
end

function FBoH:OnUpdateFuBarText()
	local total, free = self.items:GetBagUsage("Bags");
	
	local used = total - free;
	
	local text = used .. "/" .. total;
	local c = Crayon:GetThresholdHexColor(free / total);
	
	self:SetFuBarText("|cff" .. c .. used .. " |cffffffff/ |cff" .. c .. total);
end

function FBoH:OnUpdateFuBarTooltip()
	local igtotal, igfree, itotal, ifree = self.items:GetBagUsage("Bags");
	local bgtotal, bgfree, btotal, bfree = self.items:GetBagUsage("Bank");
	
	local iused = itotal - ifree;
	local bused = btotal - bfree;
	local igused = igtotal - igfree;
	local bgused = bgtotal - bgfree;

	GameTooltip:AddLine(L["Feithar's Bag of Holding"]);
	
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
end

--*****************************************************************************
-- View Docking
--*****************************************************************************

function FBoH:RenumberViewIDs()
	for i, v in ipairs(self.bagViews) do
		v.viewIndex = i;
	end
end

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
	
	self:RenumberViewIDs();
	
	return newBagView;
end

--*****************************************************************************
-- Item Count Data Access
--*****************************************************************************

function FBoH:GetItemBagAndSlotIDs(item)
	return self:GetBagID(item.bagType, item.bagIndex), item.slotIndex;
end

function FBoH:GetItemCounts(itemLink)
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

--*****************************************************************************
-- Bag Scanning
--*****************************************************************************

function FBoH:GetBagKeys(bagID)
	if (bagID >= 0) and (bagID <= NUM_BAG_SLOTS) then
		return "Bags", bagID + 1;
	end
	
	if bagID == BANK_CONTAINER then
		return "Bank", 1;
	end
	
	if (bagID > NUM_BAG_SLOTS) and (bagID <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) then
		return "Bank", (bagID - NUM_BAG_SLOTS) + 1;
	end
	
	if bagID == -2 then
		return "Keyring", 1;
	end
end

function FBoH:GetBagUsage(...)
	return self.items:GetBagUsage(...);
end

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

function FBoH:ScanBag(bagID)
	if (bagID >= NUM_BAG_SLOTS + 1) or (bagID == BANK_CONTAINER) then
		if self:IsBankOpen() == false then
			return;
		end
	end
	
	local bType, bID = self:GetBagKeys(bagID);		
	local size = GetContainerNumSlots(bagID);

	for slotID = 1, size do
		local i = nil;
		
		local itemLink = GetContainerItemLink(bagID, slotID);
		local _, itemCount = GetContainerItemInfo(bagID, slotID);

		FBoH_ItemTooltip:ClearLines();
		FBoH_ItemTooltip:SetBagItem(bagID, slotID)
		local soulbound = nil;
		for i=1,FBoH_ItemTooltip:NumLines() do
			local text = _G["FBoH_ItemTooltipTextLeft" .. i]:GetText();
			if text == L["Soulbound"] or text == L["Quest Item"] then
				soulbound = true;
			end
		end
		
		self.items:SetItem(bType, bID, slotID, itemLink, itemCount, soulbound);
	end

	self.items:UpdateBagUsage(bType, bID);
	
	self.scanQueues[bagID] = nil;
end

function FBoH:DoScanContainer(bagID, arg)
	if type(bagID) == "string" then
		bagID = arg;
	end
	
	if bagID then
		if self.scanQueues.all == true then
			return
		end
		
		self:ScanBag(bagID);
	else
		self:ScanBag(0);
		
		for bag = 1, NUM_BAG_SLOTS do
			self:ScanBag(bag);
		end
		
		if self:IsBankOpen() then
			self:ScanBag(BANK_CONTAINER);
		
			for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
				self:ScanBag(bag);
			end
		end
		
		self.scanQueues = {};
	end
	
	self:UpdateFuBarPlugin();
	self:UpdateBags();
end

function FBoH:ScanAllContainers()
	self:ScanContainer();
end

function FBoH:ScanContainer(bagID)
	if self.scanQueues.all == true then
		return;
	end
	
	if bagID == nil then
		self.scanQueues.all = true;
	else
		if self.scanQueues[bagID] == true then
			return;
		end
		self.scanQueues[bagID] = true;
	end
	
	self:ScheduleTimer(function() FBoH:DoScanContainer(bagID); end, 0);
end

--*****************************************************************************
-- Inventory Scanning
--*****************************************************************************

function FBoH:DoScanInventory()
	for id, _ in pairs(self.inventorySlots) do
		local iLink = GetInventoryItemLink("player", id);

--[[
		FBoH_ItemTooltip:ClearLines();
		FBoH_ItemTooltip:SetInventoryItem("player", BankButtonIDToInvSlotID(id, nil))
		local soulbound = nil;
		for i=1,FBoH_ItemTooltip:NumLines() do
			local text = _G["FBoH_ItemTooltipTextLeft" .. i]:GetText();
			if text == L["Soulbound"] or text == L["Quest Item"] then
				soulbound = true;
			end
		end
]]
		
		self.items:SetItem("Wearing", 1, id, iLink, 1, soulbound);
	end
	
	self.scanInventoryQueued = nil;
end

function FBoH:ScanInventory()
	if self.scanInventoryQueued == true then return end;
	self.scanInventoryQueued = true;
	self:ScheduleTimer(function() FBoH:DoScanInventory(); end, 0);
end

function FBoH:UpdateBags()
	if self.bagUpdateQueued then return end;
	
	self.bagUpdateQueued = true;
	self:ScheduleTimer(function() FBoH:DoUpdateBags(); end, 0);
end

function FBoH:DoUpdateBags()
	for k, v in pairs(self.bagViews) do
		v:UpdateBag()
	end
	self.bagUpdateQueued = nil;
end

function FBoH:IsBankOpen()
	return self.bankIsOpen;
end
--[[
function FBoH:GenerateUniqueBagViewID()
	self.NextUniqueBagID = self.NextUniqueBagID or 1;
	while true do
		local done = true;
		for k, v in pairs(self.db.profile.bagDefs) do
			if self.NextUniqueBagID == v.id then
				self.NextUniqueBagID = self.NextUniqueBagID + 1;
				done = false;
			end
		end
		if done then
			return self.NextUniqueBagID;
		end
	end
end
]]
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
	-- Sort by realm and character, just in case
	if a.realm < b.realm then return true end;
	if a.realm > b.realm then return false end;
	if a.character < b.character then return true end;
	if a.character > b.character then return false end;
		
	-- Always sort by location first
	if a.bagType < b.bagType then return true end;
	if a.bagType > b.bagType then return false end;

	-- Do configured sorts now...
	local aName, aRarity = a.detail.name, a.detail.rarity;
	local bName, bRarity = b.detail.name, b.detail.rarity;
	
	aName = aName or "Unknown";
	bName = bName or "Unknown";
	
	aRarity = aRarity or 0;
	bRarity = bRarity or 0;
	
	if aRarity > bRarity then return true end;
	if aRarity < bRarity then return false end;
	
	if aName < bName then return true end;
	if aName > bName then return false end;
	
	-- As a last resort, sort in natural order
	if a.bagIndex < b.bagIndex then return true end;
	if a.bagIndex > b.bagIndex then return false end;
	if a.slotIndex < b.slotIndex then return true end;
	if a.slotIndex > b.slotIndex then return false end;
	
	return false;
end

--*****************************************************************************
-- Item Filters.
--*****************************************************************************

function FBoH:RegisterFilter(filter)
	self.filters[filter.name] = filter;
	
	for k, v in pairs(self.bagViews) do
		v:SetFilter()
	end
	self.bagUpdateQueued = nil;	
end

function FBoH:GetFilter(filterName)
	return self.filters[filterName];
end

function FBoH:GetFilters(allFilters)
	local rVal = {};
	for k, v in pairs(self.filters) do
		if allFilters or (not v.internal) then
			local newFilter = {
				label = v.desc or k;
				key = k;
			};
			table.insert(rVal, newFilter);
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

FBoH:RegisterFilter(andFilter);

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

FBoH:RegisterFilter(orFilter);

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


FBoH:RegisterFilter(notFilter);
