FBoH_SetVersion("$Revision: 137 $");

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

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

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
		
		-- Simulates a search collector that returns every item in slot 1 of its container.
		env.searchCollector = {
			properties = {};
			results = {};
			Reset = function(self) self.properties = {}; self.results = {}; end;
			SetProperty = function(self, property, value) self.properties[property] = value end;
			CheckItem = function(self, slotIndex, slotData)
				if slotIndex == 1 then
					local newResult = {};
					for k, v in pairs(self.properties) do
						newResult[k] = v;
					end;
					newResult.slotIndex = slotIndex;
					newResult.key = slotData.key;
					table.insert(results, newResult);
				end;
			end;
			GetResults = function(self) return self.results end;
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
	
};
