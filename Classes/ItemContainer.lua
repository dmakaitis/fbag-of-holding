FBoH_SetVersion("$Revision: 132 $");

FBoH_Classes = FBoH_Classes or {};

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

--[[

This is an example of how the data should be structured within the object:

{
	["content"] = {
		{
			["lastUpdate"] = 1236525958,		<- The time the item was placed into this slot
			["count"] = 1,				<- How many in the stack
			["key"] = "10360:0:0:0:0:0:0",		<- The item key
		}, -- [1]    						<-  This should be the slot ID within the container
		{
			["lastUpdate"] = 1236525958,
			["soulbound"] = true,			<- True if the item is soulbound (false if not present)
			["count"] = 1,
			["key"] = "10360:0:0:0:0:0:0",
		}, -- [2]
		{
			["lastUpdate"] = 1236525958,
			["count"] = 1,
			["key"] = "10392:0:0:0:0:0:0",
		}, -- [3]
	},
	["size"] = {
		["restrictionCode"] = 0,				<- Any restriction on the container contents (defaults to 0)
		["total"] = 16,					<- How many slots are in the container
		["general"] = true,					<- True if there are no restrictions 
		["free"] = 13,					<- How many slots are empty
	},
}

--]]		

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------
						
local FOO = LibStub:GetLibrary("LibFOO-1.0");

FBoH_Classes.ItemContainer = FOO.class();
local ItemContainer = FBoH_Classes.ItemContainer;

function ItemContainer:SetItem(slotID, itemKey, count, soulbound)
	count = count or 1;
	soulbound = soulbound or nil;
	
	self.content = self.content or {};
	
	if itemKey == nil then
		if self.content[slotID] ~= nil then
			self.size.free = self.size.free + 1;
			self.content[slotID] = nil;
		end
	else
		if self.content[slotID] == nil then
			self.size.free = self.size.free - 1;
		end
		
		local doUpdate = false;

		if self.content[slotID] == nil then
			doUpdate = true;
		else
			local s = self.content[slotID];
			
			if s.key ~= itemKey then doUpdate = true end;
			if s.count ~= count then doUpdate = true end;
			if s.soulbound ~= soulbound then doUpdate = true end;
		end
		
		if doUpdate then
			self.content[slotID] = {
				key = itemKey,
				count = count,
				soulbound = soulbound,
				lastUpdate = time();
			};
		end
	end	
end

function ItemContainer:GetUsage()
	local s = self.size or {};
	
	if s.general == true then
		return s.total or 0, s.free or 0, s.total or 0, s.free or 0
	else
		return 0, 0, s.total or 0, s.free or 0
	end
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------
						
FBoH_UnitTests.ItemContainer = {

	testSetItem = function()
		local slot = 3;
		local itemKey = "abcde";
		local count = 1;
		local soulbound = true;
		
		local expectedSize = { total=16; free=15; general=true };
		local expectedContent = { [3] = { key=itemKey, count=count, soulbound=soulbound } };
		
		local container = ItemContainer{
			size={ total=16, free=16, general=true };
		};
		
		container:SetItem(slot, itemKey, count, soulbound);
		
		assertEquals(expectedSize, container.size);
		assert(type(container.content[slot].lastUpdate) == "number", "Last update time for slot should be an integer");
		container.content[slot].lastUpdate = nil;
		assertEquals(expectedContent, container.content);
	end;
	
	testReplaceItem = function()
		local slot = 4;
		local itemKey = "abcde";
		local count = 1;
		local soulbound = true;
		
		local expectedSize = { total=16; free=15; general=true };
		local expectedContent = { [4] = { key=itemKey, count=count, soulbound=soulbound } };
		
		local container = ItemContainer{
			content={ [4]={ key="xyz", count=3, lastUpdate=6789 } };
			size={ total=16, free=15, general=true };
		};
		
		container:SetItem(slot, itemKey, count, soulbound);
		
		assertEquals(expectedSize, container.size);
		assert(type(container.content[slot].lastUpdate) == "number", "Last update time for slot should be an integer");
		container.content[slot].lastUpdate = nil;
		assertEquals(expectedContent, container.content);
	end;
	
	testRemoveItem = function()
		local slot = 4;
		local itemKey = nil;
		
		local expectedSize = { total=16; free=16; general=true };
		local expectedContent = {};
		
		local container = ItemContainer{
			content={ [4]={ key="xyz", count=3, lastUpdate=6789 } };
			size={ total=16, free=15, general=true };
		};
		
		container:SetItem(slot, itemKey);
		
		assertEquals(expectedSize, container.size);
		assertEquals(expectedContent, container.content);
	end;
	
	testReplaceWithSameItem = function()
		local slot = 4;
		local itemKey = "abcde";
		local count = 1;
		local soulbound = true;
		local lastUpdate = 927753;
		
		local expectedSize = { total=16; free=15; general=true };
		local expectedContent = { [4] = { key=itemKey, count=count, soulbound=soulbound, lastUpdate=lastUpdate } };
		
		local container = ItemContainer{
			content={ [4]={ key=itemKey, count=count, soulbound=soulbound, lastUpdate=lastUpdate } };
			size={ total=16, free=15, general=true };
		};
		
		container:SetItem(slot, itemKey, count, soulbound);
		
		assertEquals(expectedSize, container.size);
		assertEquals(expectedContent, container.content);
	end;
	
}