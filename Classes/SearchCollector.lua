FBoH_SetVersion("$Revision$");

FBoH_Classes = FBoH_Classes or {};

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

--[[

The SearchCollector provides an means for different parts of the item
database to return information about items that meet search criteria.
It should be initialized with a filter and a sorter, then passed through
the item database objects. Each object will update the agent with
partial information about objects. As the agent discovers objects that
pass the filter, they are recorded, then output in sorted order once the
search is completed.

The search output should be an array with each element using the
following format:

{
	realm = string		<- the realm name
	character = string		<- the character name
	bagType = string		<- the type of container (bag, bank, mailbox, etc.)
	bagIndex = integer		<- which bag, bank slot, etc.
	slotIndex = integer		<- which slot in the container
	
	lastUpdate = integer	<- timestamp of when the item was placed into the slot
	itemKey = itemKey		<- item key (as used by ItemDetailCache)
	itemCount = integer		<- the number of items in the stack
	soulbound = true/nil	<- true if the item is soulbound to the player
	
	detail = itemDetails		<- detail table returned by ItemDetailCache
	itemLink = itemLink		<- an item link for the item
	
}

--]]

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

local FOO = LibStub:GetLibrary("LibFOO-1.0");

FBoH_Classes.SearchCollector = FOO.class();
local SearchCollector = FBoH_Classes.SearchCollector;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

local currentItem = {};

local
function _AddItem(item, results)
	if item.prev then _AddItem(item.prev, results) end;
	table.insert(results, item.this);
	if item.next then _AddItem(item.next, results) end;
end

local
function _DoCompare(sorter, a, b)
	local pResult, rVal = pcall(sorter, a, b);
	if pResult then return rVal else return false end;
end

local
function _CompareItems(sorters, sorterIndex, a, b)
	local s = sorters[sorterIndex];
	if s == nil then return false end;
	
	if _DoCompare(s, a, b) == true then return true end;
	if _DoCompare(s, a, b) == true then return false end;
	
	return _CompareItems(sorters, sorterIndex + 1, a, b);
end

local
function _AddToResults(sorters, results)
	if results.this == nil then
		results.this = {};
		for k, v in pairs(currentItem) do
			results.this[k] = v;
		end
	else
		if _CompareItems(sorters, 1, results.this, currentItem) == true then
			results.next = results.next or {};
			_AddToResults(sorters, results.next);
		else
			results.prev = results.prev or {};
			_AddToResults(sorters, results.prev);
		end
	end
end

function SearchCollector:__init(object)
	object = FOO.rawnew(self, object);
	if type(object.filter) ~= "function" then 
		error("Member filter must be initialized to a function", 3)
	end;
	if (type(object.sorters) ~= "table") and (type(object.sorters) ~= "function") then
		error("Member sorters must be initialized to a function or array of functions", 3)
	end;
	object:Reset();
	return object;
end;

--[[
Resets the search by clearing all properties currently assigned, and
any search results previously found.
--]]
function SearchCollector:Reset()
	for key, _ in pairs(currentItem) do
		currentItem[key] = nil;
	end;
	self.results = nil;
	
	if type(self.sorters) == "function" then
		local s = self.sorters;
		self.sorters = {};
		self.sorters[1] = s;
	end
	
	if type(self.filter) ~= "function" then error("Member filter must be initialized to a function", 2) end;
	if type(self.sorters) ~= "table" then error("Member sorters must be initialized to a function or array of functions", 2) end;
end

--[[
Sets a property of the item that will be checked. Properties
remain set until altered or set to nil. Note that the properies
are shared between all instances of SearchCollector, so it
is recommended only to use a single instance of this class
at a time.

Parameters:
	property - the name of the property to set
	value - the value to which to set the property
]]
function SearchCollector:SetProperty(property, value)
	currentItem[property] = value;
end

--[[
Checks the item in the given slot against the filter to see if it should be
included in the result set. If so, it will be inserted into the results
in sorted order.

Parameters:
	slotIndex - integer indicating which slot the item is in
	slotData - table	{
					key - item key
					count - number of items in the stack
					soulbound - true if the item is soulbound, nil otherwise
					lastUpdate - the timestamp when the item was placed in the slot
				}
]]
function SearchCollector:CheckItem(slotIndex, slotData)
	self:SetProperty("slotIndex", slotIndex);
	self:SetProperty("itemKey", slotData.key);
	self:SetProperty("itemCount", slotData.count);
	self:SetProperty("soulbound", slotData.soulbound);
	self:SetProperty("lastUpdate", slotData.lastUpdate);
	
	self:SetProperty("detail", self.itemCache:GetItemDetailWithKey(slotData.key));
	self:SetProperty("itemLink", currentItem.detail.link);
	
	local pResult, rVal = pcall(self.filter, currentItem, self.filterArg);
	if pResult == true then
		if rVal == true then
			self.results = self.results or {};
			_AddToResults(self.sorters, self.results);
		end
	end
	
	self:SetProperty("slotIndex", nil);
	self:SetProperty("itemKey", nil);
	self:SetProperty("itemCount", nil);
	self:SetProperty("soulbound", nil);
	self:SetProperty("lastUpdate", nil);
	
	self:SetProperty("detail", nil);
	self:SetProperty("itemLink", nil);
end

--[[
Returns an array containing the sorted search results. See class
comments for the format of the search results.
]]
function SearchCollector:GetResults()
	local rVal = {};
	
	if self.results == nil then return rVal end;
	
	_AddItem(self.results, rVal);
	
	return rVal;
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

FBoH_UnitTests.SearchCollector = {
	
	testSetProperty = function(env)
		local property = "realm";
		local value = "Test";
		local expected = { [property] = value };
		
		local s = SearchCollector{
			filter = env.filterAll;
			sorters = env.sorter;
		};
		s:Reset();
		s:SetProperty(property, value);
		
		assertEquals(expected, currentItem);
		
		s:Reset();
		
		assertEquals({}, currentItem);
	end;
	
	testSetNumberProperty = function(env)
		local property = "bagIndex";
		local value = 42;
		local expected = { [property] = value };
		
		local s = SearchCollector{
			filter = env.filterAll;
			sorters = env.sorter;
		};
		s:Reset();
		s:SetProperty(property, value);
		
		assertEquals(expected, currentItem);
		
		s:Reset();
		
		assertEquals({}, currentItem);
	end;
	
	testGetEmptyResults = function()
		local s = SearchCollector{
			filter = function() return true end;
			sorters = function() return false end;
		};
		local expected = {};
		
		local results = s:GetResults();
		
		assertEquals(expected, results);
	end;
	
	testGetResults = function()
		local s = SearchCollector{
			filter = function() return true end;
			sorters = function() return false end;
		};
		s.results = {
			prev = {
				this = "Donut";
				next = {
					this = "Bagel";
				};
			};
			this = "Muffin";
			next = {
				prev = {
					this = "Toast";
				};
				this = "Pastry";
			};
		};
		local expected = {
			"Donut",
			"Bagel",
			"Muffin",
			"Toast",
			"Pastry",
		};
		
		local results = s:GetResults();
		
		assertEquals(expected, results);
	end;
	
	setUp = function()
		local rVal = {
			realm = "Realm";
			character = "Character";
			bagType = "Type";
			bagIndex = 1;
		};

		rVal.itemCache = FBoH_Classes.ItemDetailCache{
			sessionStart = 1;
			details = {};
			getItemInfo = function(link)
				error("Should only be using cached data: " .. link, 3);
			end;
		};
		local d = rVal.itemCache.details;
		local function addItem(details, name, key, sorting)
			details[key] = {
				name = name;
				link = "|cff9d9d9d|Hitem:" .. key .. "|h[" .. name .. "]|h|r";
				sorting = sorting;
				lastUpdate = 12345678;
			};
		end;
		
		addItem(d, "ItemA", "1:2:3:4:5:6:7:8", 5);
		addItem(d, "ItemB", "235:1:7:4:1:11:6:87", 4);
		addItem(d, "ItemC", "387645:1:7:56:5:34:7:3", 2);
		addItem(d, "ItemD", "49764:4:32:6:6:5:4:0", 3);
		addItem(d, "ItemE", "598735:4:1:1:5:8:0:0", 1);
		
		rVal.items = {};
		local i = rVal.items;
		local function addItem(items, slot, key, count, soulbound)
			items[slot] = {
				lastUpdate = 12345;
				count = count;
				key = key;
				soulbound = soulbound;
			}
		end;
		
		addItem(i, 4, "1:2:3:4:5:6:7:8", 3, true);
		addItem(i, 5, "235:1:7:4:1:11:6:87", 1, nil);
		addItem(i, 7, "387645:1:7:56:5:34:7:3", 1, true);
		addItem(i, 9, "49764:4:32:6:6:5:4:0", 7, true);
		addItem(i, 1, "598735:4:1:1:5:8:0:0", 2, nil);
		
		function rVal:BuildResult(slotID, slotData)
			local r = {
				realm = self.realm;
				character = self.character;
				bagType = self.bagType;
				bagIndex = self.bagIndex;
				slotIndex = slotID;
				
				lastUpdate = slotData.lastUpdate;
				itemKey = slotData.key;
				itemCount = slotData.count;
				soulbound = slotData.soulbound;
				
				detail = self.itemCache.details[slotData.key];
			};
			
			r.itemLink = r.detail.link;
			
			return r;
		end
		
		rVal.filterAll = function()
			return true;
		end
		
		rVal.filterSoulbound = function(item, arg)
			return (item.soulbound or false) == arg;
		end
		
		rVal.sorter = function(a, b)
			if a.detail.sorting < b.detail.sorting then return true else return false end;
		end
		
		rVal.uselessSorter = function(a, b)
			return false;
		end
		
		rVal.oddEvenSorter = function(a, b)
			local am = a.detail.sorting % 2;
			local bm = b.detail.sorting % 2;
			if am < bm then return true else return false end;
		end
		
		rVal.throwError = function()
			error("Random error");
		end
		
		return rVal;
	end;
	
	testCheckItem = function(env)
		local newSlotIndexA = 4;
		local newItemA = env.items[newSlotIndexA];
		
		local expected = {
			this = env:BuildResult(newSlotIndexA, newItemA);
		};
		
		local s = SearchCollector{
			itemCache = env.itemCache;
			filter = env.filterAll;
			sorters = env.sorter;
		};
		s:Reset();
		s:SetProperty("realm", env.realm);
		s:SetProperty("character", env.character);
		s:SetProperty("bagType", env.bagType);
		s:SetProperty("bagIndex", env.bagIndex);
		
		s:CheckItem(newSlotIndexA, newItemA);
		
		assertEquals(expected, s.results);
		
		s:Reset();
		
		assertEquals({}, currentItem);
	end;
	
	testCheckTwoItems = function(env)
		local newSlotIndexA = 4;
		local newItemA = env.items[newSlotIndexA];
		local newSlotIndexB = 5;
		local newItemB = env.items[newSlotIndexB];
		
		local expected = {
			prev = {
				this = env:BuildResult(newSlotIndexB, newItemB);
			};
			this = env:BuildResult(newSlotIndexA, newItemA);
		};
		
		local s = SearchCollector{
			itemCache = env.itemCache;
			filter = env.filterAll;
			sorters = env.sorter;
		};
		s:Reset();
		s:SetProperty("realm", env.realm);
		s:SetProperty("character", env.character);
		s:SetProperty("bagType", env.bagType);
		s:SetProperty("bagIndex", env.bagIndex);
		
		s:CheckItem(newSlotIndexA, newItemA);
		s:CheckItem(newSlotIndexB, newItemB);
		
		assertEquals(expected, s.results);
		
		s:Reset();
		
		assertEquals({}, currentItem);
	end;
	
	testCheckFiveItems = function(env)
		local newSlotIndexA = 4;
		local newItemA = env.items[newSlotIndexA];
		local newSlotIndexB = 5;
		local newItemB = env.items[newSlotIndexB];
		local newSlotIndexC = 7;
		local newItemC = env.items[newSlotIndexC];
		local newSlotIndexD = 9;
		local newItemD = env.items[newSlotIndexD];
		local newSlotIndexE = 1;
		local newItemE = env.items[newSlotIndexE];
		
		local expected = {
			prev = {
				prev = {
					prev = {
						this = env:BuildResult(newSlotIndexE, newItemE);
					};
					this = env:BuildResult(newSlotIndexC, newItemC);
					next = {
						this = env:BuildResult(newSlotIndexD, newItemD);
					};
				};
				this = env:BuildResult(newSlotIndexB, newItemB);
			};
			this = env:BuildResult(newSlotIndexA, newItemA);
		};
		
		local s = SearchCollector{
			itemCache = env.itemCache;
			filter = env.filterAll;
			sorters = env.sorter;
		};
		s:Reset();
		s:SetProperty("realm", env.realm);
		s:SetProperty("character", env.character);
		s:SetProperty("bagType", env.bagType);
		s:SetProperty("bagIndex", env.bagIndex);
		
		s:CheckItem(newSlotIndexA, newItemA);
		s:CheckItem(newSlotIndexB, newItemB);
		s:CheckItem(newSlotIndexC, newItemC);
		s:CheckItem(newSlotIndexD, newItemD);
		s:CheckItem(newSlotIndexE, newItemE);
		
		assertEquals(expected, s.results);
		
		s:Reset();
		
		assertEquals({}, currentItem);
	end;
	
	testCheckMultipleSorters = function(env)
		local newSlotIndexA = 4;
		local newItemA = env.items[newSlotIndexA];
		local newSlotIndexB = 5;
		local newItemB = env.items[newSlotIndexB];
		local newSlotIndexC = 7;
		local newItemC = env.items[newSlotIndexC];
		local newSlotIndexD = 9;
		local newItemD = env.items[newSlotIndexD];
		local newSlotIndexE = 1;
		local newItemE = env.items[newSlotIndexE];
		
		local expected = {
			prev = {
				prev = {
					this = env:BuildResult(newSlotIndexC, newItemC);
				};
				this = env:BuildResult(newSlotIndexB, newItemB);
				next = {
					prev = {
						this = env:BuildResult(newSlotIndexE, newItemE);
					};
					this = env:BuildResult(newSlotIndexD, newItemD);
				};
			};
			this = env:BuildResult(newSlotIndexA, newItemA);
		};
		
		local s = SearchCollector{
			itemCache = env.itemCache;
			filter = env.filterAll;
			sorters = {
				[1] = env.oddEvenSorter;
				[2] = env.sorter;
			};
		};
		s:Reset();
		s:SetProperty("realm", env.realm);
		s:SetProperty("character", env.character);
		s:SetProperty("bagType", env.bagType);
		s:SetProperty("bagIndex", env.bagIndex);
		
		s:CheckItem(newSlotIndexA, newItemA);
		s:CheckItem(newSlotIndexB, newItemB);
		s:CheckItem(newSlotIndexC, newItemC);
		s:CheckItem(newSlotIndexD, newItemD);
		s:CheckItem(newSlotIndexE, newItemE);
		
		assertEquals(expected, s.results);
		
		s:Reset();
		
		assertEquals({}, currentItem);
	end;
	
	testCheckWithFilter = function(env)
		local newSlotIndexA = 4;
		local newItemA = env.items[newSlotIndexA];
		local newSlotIndexB = 5;
		local newItemB = env.items[newSlotIndexB];
		local newSlotIndexC = 7;
		local newItemC = env.items[newSlotIndexC];
		local newSlotIndexD = 9;
		local newItemD = env.items[newSlotIndexD];
		local newSlotIndexE = 1;
		local newItemE = env.items[newSlotIndexE];
		
		local expected = {
			prev = {
				this = env:BuildResult(newSlotIndexC, newItemC);
				next = {
					this = env:BuildResult(newSlotIndexD, newItemD);
				};
			};
			this = env:BuildResult(newSlotIndexA, newItemA);
		};
		
		local s = SearchCollector{
			itemCache = env.itemCache;
			filter = env.filterSoulbound;
			filterArg = true;
			sorters = env.sorter;
		};
		s:Reset();
		s:SetProperty("realm", env.realm);
		s:SetProperty("character", env.character);
		s:SetProperty("bagType", env.bagType);
		s:SetProperty("bagIndex", env.bagIndex);
		
		s:CheckItem(newSlotIndexA, newItemA);
		s:CheckItem(newSlotIndexB, newItemB);
		s:CheckItem(newSlotIndexC, newItemC);
		s:CheckItem(newSlotIndexD, newItemD);
		s:CheckItem(newSlotIndexE, newItemE);
		
		assertEquals(expected, s.results);
		
		s:Reset();
		
		assertEquals({}, currentItem);
	end;

	testCheckFiveItemsWithBadFilter = function(env)
		local newSlotIndexA = 4;
		local newItemA = env.items[newSlotIndexA];
		local newSlotIndexB = 5;
		local newItemB = env.items[newSlotIndexB];
		local newSlotIndexC = 7;
		local newItemC = env.items[newSlotIndexC];
		local newSlotIndexD = 9;
		local newItemD = env.items[newSlotIndexD];
		local newSlotIndexE = 1;
		local newItemE = env.items[newSlotIndexE];
		
		local expected = nil;
		
		local s = SearchCollector{
			itemCache = env.itemCache;
			filter = env.throwError;
			sorters = env.sorter;
		};
		s:Reset();
		s:SetProperty("realm", env.realm);
		s:SetProperty("character", env.character);
		s:SetProperty("bagType", env.bagType);
		s:SetProperty("bagIndex", env.bagIndex);
		
		s:CheckItem(newSlotIndexA, newItemA);
		s:CheckItem(newSlotIndexB, newItemB);
		s:CheckItem(newSlotIndexC, newItemC);
		s:CheckItem(newSlotIndexD, newItemD);
		s:CheckItem(newSlotIndexE, newItemE);
		
		assertEquals(expected, s.results);
		
		s:Reset();
		
		assertEquals({}, currentItem);
	end;

	testCheckWithBadSorter = function(env)
		local newSlotIndexA = 4;
		local newItemA = env.items[newSlotIndexA];
		local newSlotIndexB = 5;
		local newItemB = env.items[newSlotIndexB];
		local newSlotIndexC = 7;
		local newItemC = env.items[newSlotIndexC];
		local newSlotIndexD = 9;
		local newItemD = env.items[newSlotIndexD];
		local newSlotIndexE = 1;
		local newItemE = env.items[newSlotIndexE];
		
		local expected = {
			prev = {
				prev = {
					this = env:BuildResult(newSlotIndexC, newItemC);
				};
				this = env:BuildResult(newSlotIndexB, newItemB);
				next = {
					prev = {
						this = env:BuildResult(newSlotIndexE, newItemE);
					};
					this = env:BuildResult(newSlotIndexD, newItemD);
				};
			};
			this = env:BuildResult(newSlotIndexA, newItemA);
		};
		
		local s = SearchCollector{
			itemCache = env.itemCache;
			filter = env.filterAll;
			sorters = {
				[1] = env.oddEvenSorter;
				[2] = env.throwError;
				[3] = env.sorter;
			};
		};
		s:Reset();
		s:SetProperty("realm", env.realm);
		s:SetProperty("character", env.character);
		s:SetProperty("bagType", env.bagType);
		s:SetProperty("bagIndex", env.bagIndex);
		
		s:CheckItem(newSlotIndexA, newItemA);
		s:CheckItem(newSlotIndexB, newItemB);
		s:CheckItem(newSlotIndexC, newItemC);
		s:CheckItem(newSlotIndexD, newItemD);
		s:CheckItem(newSlotIndexE, newItemE);
		
		assertEquals(expected, s.results);
		
		s:Reset();
		
		assertEquals({}, currentItem);
	end;

};
