local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision$");

local _SafeCall = FBoH._SafeCall;

--*****************************************************************************
-- Private Methods
--*****************************************************************************

local
function _GetBagKeys(bagID)
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

local
function _ScanBag(self, bagID)
	_SafeCall(function()
		if (bagID >= NUM_BAG_SLOTS + 1) or (bagID == BANK_CONTAINER) then
			if self:IsBankOpen() == false then
				return;
			end
		end
		
		local bType, bID = _GetBagKeys(bagID);		
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
	end);
end

local
function _DoUpdateBags(self)
	_SafeCall(function()
		for k, v in pairs(self.bagViews) do
			v:UpdateBag();
		end
		self.bagUpdateQueued = nil;
	end);
end

local
function _UpdateBags(self)
	_SafeCall(function()
		if self.bagUpdateQueued then return end;
		
		self.bagUpdateQueued = true;
		self:ScheduleTimer(function() _DoUpdateBags(self); end, 0);
	end);
end

local
function _DoScanContainer(self, bagID, arg)
	_SafeCall(function()
		if type(bagID) == "string" then
			bagID = arg;
		end
		
		if bagID then
			if self.scanQueues.all == true then
				return
			end
			
			_ScanBag(self, bagID);
		else
			_ScanBag(self, 0);
			
			for bag = 1, NUM_BAG_SLOTS do
				_ScanBag(self, bag);
			end
			
			if self:IsBankOpen() then
				_ScanBag(self, BANK_CONTAINER);
			
				for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
					_ScanBag(self, bag);
				end
			end
			
			self.scanQueues = {};
		end
		
		self:UpdateDataBroker();
		_UpdateBags(self);
	end);
end

local
function _DoScanInventory(self)
	_SafeCall(function()
		for id, _ in pairs(self.inventorySlots) do
			local iLink = GetInventoryItemLink("player", id);
			self.items:SetItem("Wearing", 1, id, iLink, 1, soulbound);
		end
		
		self.scanInventoryQueued = nil;
	end);
end

local
function _DoUpdateBagsGuild(self)
	_SafeCall(function()
		for k, v in pairs(self.bagViews) do
			v:UpdateBag("gbank");
		end
		self.guildBagUpdateQueued = nil;
	end);
end

local
function _UpdateBagsGuild(self)
	_SafeCall(function()
		if self.guildBagUpdateQueued then return end;
		self.guildBagUpdateQueued = true;
		self:ScheduleTimer(function() _DoUpdateBagsGuild(self); end, 0);
	end);
end

local
function _ScanGuildBank(self)
	local numTabs = GetNumGuildBankTabs();
	for tab = 1, numTabs do
		if IsTabViewable(tab) then
			for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
				local link = GetGuildBankItemLink(tab, slot);
				if link then
					local _, count = GetGuildBankItemInfo(tab, slot);
					self.items:SetGuildItem(tab, slot, link, count);
				else
					self.items:SetGuildItem(tab, slot, nil, 0);
				end
			end
		end
	end
	_UpdateBagsGuild(self);
end

--*****************************************************************************
-- Events
--*****************************************************************************

function FBoH:BANKFRAME_CLOSED()
	_SafeCall(function()
		self.bankIsOpen = false;
		_UpdateBags(self);
	end);
end

function FBoH:BANKFRAME_OPENED()
	_SafeCall(function()
		self.bankIsOpen = true;
		self:ScanContainer();
	end);
end

function FBoH:GUILDBANKFRAME_OPENED()
	_SafeCall(function()
		self.guildBankIsOpen = true;

		local numTabs = GetNumGuildBankTabs();
		for tab = 1, numTabs do
			if IsTabViewable(tab) then
				QueryGuildBankTab(tab);
			end
		end
	end);
end

function FBoH:GUILDBANKFRAME_CLOSED()
	_SafeCall(function()
		self.guildBankIsOpen = false;
		_UpdateBagsGuild(self);
	end);
end

function FBoH:GUILDBANKBAGSLOTS_CHANGED()
	_SafeCall(function()
		if self.guildBankIsOpen then
			_ScanGuildBank(self);
		end
	end);
end

--*****************************************************************************
-- Public Interface
--*****************************************************************************

function FBoH:ScanAllContainers()
	_SafeCall(function()
		self:ScanContainer();
	end);
end

function FBoH:ScanContainer(bagID)
	_SafeCall(function()
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
		
		self:ScheduleTimer(function() _DoScanContainer(self, bagID); end, 0);
	end);
end

function FBoH:ScanInventory()
	_SafeCall(function()
		if self.scanInventoryQueued == true then return end;
		self.scanInventoryQueued = true;
		self:ScheduleTimer(function() _DoScanInventory(self); end, 0);
	end);
end
