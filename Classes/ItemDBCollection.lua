FBoH_SetVersion("$Revision$");

FBoH_Classes = FBoH_Classes or {};

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

--[[

This file contains several classes that implement the nested structure of
the item database used by FBoH to store inventory data. The ItemDBCollection
class implements the common code, while the other classes in this file implement
the unique features of each layer.

--]]

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

local FOO = LibStub:GetLibrary("LibFOO-1.0");

local ItemContainer = FBoH_Classes.ItemContainer;

FBoH_Classes.ContainerType = FOO.class();
local ContainerType = FBoH_Classes.ContainerType;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

function ContainerType:__init(object)
	object = object or {};
	for k, v in pairs(object) do
		object[k] = ItemContainer(v);
	end;
	return FOO.rawnew(self, object);
end;

function ContainerType:FindItems(searchCollector)
	for k, v in pairs(self) do
		searchCollector:SetProperty("bagIndex", k);
		v:FindItems(searchCollector);
	end;
	searchCollector:SetProperty("bagIndex", nil);
end;

function ContainerType:GetBagUsage(bagId)
	local gTotal, gFree, total, free = 0, 0, 0, 0;
	
	for k, v in pairs(self) do
		if (bagId == nil) or (bagId == k) then
			local gt, gf, t, f = v:GetUsage();
			gTotal = gTotal + gt;
			gFree = gFree + gf;
			total = total + t;
			free = free + f;
		end
	end
	
	return gTotal, gFree, total, free;
end

function ContainerType:GetEmptySlots(searchCollector, bagId)
	for k, v in pairs(self) do
		if (bagId == nil) or (bagId == k) then
			searchCollector:SetProperty("firstBagID", k);
			v:GetEmptySlots(searchCollector);
		end
	end
	searchCollector:SetProperty("firstBagID", nil);
end;

function ContainerType:SetItem(bagId, slotId, itemKey, count, soulbound, lastUpdate)
	self[bagId] = self[bagId] or ItemContainer();
	self[bagId]:SetItem(slotId, itemKey, count, soulbound, lastUpdate);
end;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

FBoH_Classes.CharacterDB = FOO.class();
local CharacterDB = FBoH_Classes.CharacterDB;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

function CharacterDB:__init(object)
	object = object or {};
	for k, v in pairs(object) do
		object[k] = ContainerType(v);
	end;
	return FOO.rawnew(self, object);
end;

function CharacterDB:FindItems(searchCollector, isCurrentCharacter)
	for k, v in pairs(self) do
		if isCurrentCharacter == false or k ~= "Wearing" then
			searchCollector:SetProperty("bagType", k);
			v:FindItems(searchCollector);
		end;
	end;
	searchCollector:SetProperty("bagType", nil);
end;

function CharacterDB:GetBagUsage(bagType, bagId)
	local gTotal, gFree, total, free = 0, 0, 0, 0;
	
	for k, v in pairs(self) do
		if (bagType == nil) or (bagType == k) then
			local gt, gf, t, f = v:GetUsage(bagId);
			gTotal = gTotal + gt;
			gFree = gFree + gf;
			total = total + t;
			free = free + f;
		end
	end
	
	return gTotal, gFree, total, free;
end;

function CharacterDB:GetEmptySlots(searchCollector, bagType, bagId)
	for k, v in pairs(self) do
		if (bagType == nil) or (bagType == k) then
			v:GetEmptySlots(searchCollector, bagId);
		end
	end
end;

function CharacterDB:SetItem(bagType, bagId, slotId, itemKey, count, soulbound, lastUpdate)
	self[bagType] = self[bagType] or ContainerType();
	self[bagType]:SetItem(bagId, slotId, itemKey, count, soulbound, lastUpdate);
end;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

FBoH_Classes.GuildDB = FOO.class();
local GuildDB = FBoH_Classes.GuildDB;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

function GuildDB:__init(object)
	object = object or {};
	for k, v in pairs(object) do
		object[k] = ContainerType(v);
	end;
	return FOO.rawnew(self, object);
end;

function GuildDB:FindItems(searchCollector)
	if self.tabs then
		searchCollector:SetProperty("bagType", "Guild Bank");
		self.tabs:FindItems(searchCollector);
		searchCollector:SetProperty("bagType", nil);
	end;
end;

function GuildDB:GetBagUsage(tabId)
	if self.tabs == nil then return 0, 0, 0, 0; end;
	return self.tabs:GetUsage(tabId);
end;

function GuildDB:GetEmptySlots(searchCollector, tabId)
	if self.tabs then
		self.tabs:GetEmptySlots(searchCollector, tabId);
	end
end;

function GuildDB:SetItem(tabId, slotId, itemKey, count, soulbound, lastUpdate)
	self.tabs = self.tabs or ContainerType();
	self.tabs:SetItem(tabId, slotId, itemKey, count, soulbound, lastUpdate);
end;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

FBoH_Classes.CharactersDB = FOO.class();
local CharactersDB = FBoH_Classes.CharactersDB;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

function CharactersDB:__init(object)
	object = object or {};
	for k, v in pairs(object) do
		object[k] = CharacterDB(v);
	end;
	return FOO.rawnew(self, object);
end;

function CharactersDB:FindItems(searchCollector, subset, isCurrentRealm)
	local charName = UnitName("player");
	
	for k, v in pairs(self) do
		local isCurrentCharacter = nil;
		
		if isCurrentRealm then
			if k == charName then
				isCurrentCharacter = true;
			end
		end
		
		if (subset == "both") or
				(subset == "char" and isCurrentCharacter) or
				(subset == "alt" and (not isCurrentCharacter)) then
			searchCollector:SetProperty("character", k);
			v:FindItems(searchCollector, isCurrentCharacter);
		end;
	end;
	searchCollector:SetProperty("character", nil);
end;

function CharactersDB:GetBagUsage(bagType, bagId, character)
	character = character or UnitName("player");
	
	local v = self[character];
	if v then
		return v:GetUsage(bagType, bagId);
	end
	
	return 0, 0, 0, 0;
end;

function CharactersDB:GetEmptySlots(searchCollector, bagType, bagId, character)
	character = character or UnitName("player");
	
	local v = self[character];
	if v then
		v:GetEmptySlots(searchCollector, bagType, bagId);
	end
end;

function CharactersDB:SetItem(bagType, bagId, slotId, itemKey, count, soulbound, character, lastUpdate)
	character = character or UnitName("player");

	self[character] = self[character] or CharacterDB();
	self[character]:SetItem(bagType, bagId, slotId, itemKey, count, soulbound, lastUpdate);
end;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

if WoWUnit then

FBoH_UnitTests.ContainerType = {
	
	setUp = function()
		local env = {};
		
		env.container = {
			["content"] = {
				[1] = {
					["lastUpdate"] = 1212116014,
					["count"] = 1,
					["key"] = "30623:0:0:0:0:0:0",
				}, -- [1]
				[10] = {
					["lastUpdate"] = 1212116014,
					["count"] = 1,
					["key"] = "28395:0:0:0:0:0:0",
				}, -- [10]

			},
			["size"] = {
				["total"] = 32,
				["general"] = true,
				["free"] = 30,
			},
		};
		
		env.containers = {
			[1] = env.container;
		};
		
		-- Simulates a search collector that returns every item in slot 1 of container 1, 
		-- and slot 10 of container 2
		env.searchCollector = FBoH_Classes.SearchCollector{
			filter = function(item) 
				if item.bagIndex == 1 then
					if item.slotIndex == 1 then return true end;
				end;
				if item.bagIndex == 2 then
					if item.slotIndex == 10 then return true end;
				end;
				return false;
			end;
			sorters = function(a, b)
				if a.bagIndex < b.bagIndex then return true end;
				return false;
			end;
			itemCache = {
				GetItemDetailWithKey = function()
					return {};
				end;
			};
		};

		env.findResults = {
			{
				bagIndex = 1,
				slotIndex = 1,
				itemKey = "30623:0:0:0:0:0:0",
				itemCount = 1,
				soulbound = nil,
				lastUpdate = 1212116014,
				detail = {},
				itemLink = nil,
			},
			{
				bagIndex = 2,
				slotIndex = 10,
				itemKey = "28395:0:0:0:0:0:0",
				itemCount = 1,
				soulbound = nil,
				lastUpdate = 1212116014,
				detail = {},
				itemLink = nil,
			},
		};
		
		env.emptySearchCollector = FBoH_Classes.SearchCollector{
			filter = function() 
				return true; 
			end;
			sorters = function(a, b)
				if (a.firstBagID or 0) < (b.firstBagID or 0) then return true end;
				return false;
			end;
		};
		
		env.getEmptyResults = {
			{
				firstBagID = 1,
				restrictionCode = 0;
				slotCount = 30;
				firstSlotID = 2;
			},
			{
				firstBagID = 2,
				restrictionCode = 0;
				slotCount = 30;
				firstSlotID = 2;
			},
		};
		
		return env;
	end;
	
	testCreateEmptyContainerType = function()
		local containerType = ContainerType{}
		assertEquals({}, containerType);
	end;
	
	testCreateExistingContainerType = function(env)
		local storedData = env.containers;
		
		local containerType = ContainerType(storedData);
		
		assertEquals(storedData, containerType);
		
		for k, v in pairs(storedData) do
			assert(FOO.instanceof(v, ItemContainer), "Member " .. tostring(k) .. " is not an item container");
		end;
	end;
	
	testFindItems = function(env)
		local containerType = ContainerType{
			[1] = env.container;
			[2] = env.container;
		};
		local searchCollector = env.searchCollector;
		local expected = env.findResults;
		
		containerType:FindItems(searchCollector);
		local results = searchCollector:GetResults();
		
		assertEquals(expected, results);
	end;
	
	testGetBagUsageAll = function(env)
		local containerType = ContainerType{
			[1] = env.container;
			[2] = env.container;
		};
		local eGtotal, eGfree, eTotal, eFree = 64, 60, 64, 60;
		
		local gTotal, gFree, total, free = containerType:GetBagUsage();
		
		assertEquals(eGtotal, gTotal);
		assertEquals(eGfree, gFree);
		assertEquals(gTotal, total);
		assertEquals(gFree, free);
	end;
	
	testGetEmptySlotsAll = function(env)
		local containerType = ContainerType{
			[1] = env.container;
			[2] = env.container;
		};
		local searchCollector = env.emptySearchCollector;
		local expected = env.getEmptyResults;
		
		containerType:GetEmptySlots(searchCollector);
		local results = searchCollector:GetResults();
		
		assertEquals(expected, results);		
	end;
	
	testSetItem = function()
		local containerType = ContainerType();
		local bagId = 1;
		local slotId = 1;
		local itemKey = "30623:0:0:0:0:0:0";
		local count = 4;
		local soulbound = true;
		local lastUpdate = 123456;
		local expected = {
			{
				["content"] = {
					{
						["lastUpdate"] = lastUpdate,
						["count"] = count,
						["key"] = itemKey,
						["soulbound"] = soulbound,
					}, -- [1]
				},
			},
		};
		
		assertEquals({}, containerType);
		
		containerType:SetItem(bagId, slotId, itemKey, count, soulbound, lastUpdate);
		
		assertEquals(expected, containerType);
	end;
	
};

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

end
