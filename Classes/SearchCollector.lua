FBoH_SetVersion("$Revision: 132 $");

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

--[[
Sets the realm that is currently being searched.

Parameters:
	realm - the name of the realm
]]
function SearchCollector:SetRealm(realm)
	currentItem.realm = realm;
end

--[[
Sets the character currently being searched.

Parameters:
	character - the name of the character
]]
function SearchCollector:SetCharacter(character)
	currentItem.character = character;
end

--[[
Sets the type of container currently being searched.

Parameters:
	character - the name of the container type
]]
function SearchCollector:SetContainerType(containerType)
	currentItem.bagType = containerType;
end

--[[
Sets the index of the container currently being searched.

Parameters:
	character - the container index
]]
function SearchCollector:SetContainerIndex(containerIndex)
	currentItem.bagIndex = containerIndex;
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
					lastUpdated - the timestamp when the item was placed in the slot
				}
]]
function SearchCollector:CheckItem(slotIndex, slotData)
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
	
	testSetRealm = function()
		local realm = "Test";
		local expected = { realm=realm };
		
		local s = SearchCollector{};		
		s:SetRealm(realm);
		
		assertEquals(expected, currentItem);
		
		s:SetRealm(nil);
		
		assertEquals({}, currentItem);
	end;
	
	testSetCharacter = function()
		local character = "Test";
		local expected = { character=character };
		
		local s = SearchCollector{};		
		s:SetCharacter(character);
		
		assertEquals(expected, currentItem);
		
		s:SetCharacter(nil);
		
		assertEquals({}, currentItem);
	end;
	
	testSetCharacter = function()
		local containerType = "Test";
		local expected = { bagType=containerType };
		
		local s = SearchCollector{};		
		s:SetContainerType(containerType);
		
		assertEquals(expected, currentItem);
		
		s:SetContainerType(nil);
		
		assertEquals({}, currentItem);
	end;
	
	testSetCharacter = function()
		local containerIndex = 42;
		local expected = { bagIndex=containerIndex };
		
		local s = SearchCollector{};		
		s:SetContainerIndex(containerIndex);
		
		assertEquals(expected, currentItem);
		
		s:SetContainerIndex(nil);
		
		assertEquals({}, currentItem);
	end;
	
	testGetEmptyResults = function()
		local s = SearchCollector{};
		local expected = {};
		
		local results = s:GetResults();
		
		assertEquals(expected, results);
	end;
	
	testGetEmptyResults = function()
		local s = SearchCollector{
			results = {
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
	
	testSetItem = function()
		local realm = "Realm";
		local character = "Character";
		local bagType = "Type";
		local bagIndex = 1;
		
		local itemCache = {
			sessionStart = 0;
			details = {
			
			};
		};

		local s = SearchCollector{};
		s:SetRealm(realm);
		s:SetCharacter(character);
		s:SetContainerType(bagType);
		s:SetContainerIndex(bagIndex);
		
		s:SetRealm(nil);
		s:SetCharacter(nil);
		s:SetContainerType(nil);
		s:SetContainerIndex(nil);		
	end
	
};
