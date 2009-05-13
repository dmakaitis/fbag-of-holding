FBoH_SetVersion("$Revision$");

FBoH_Classes = FBoH_Classes or {};

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

local FOO = LibStub:GetLibrary("LibFOO-1.0");

FBoH_Classes.ItemDetailCache = FOO.class();
local ItemDetailCache = FBoH_Classes.ItemDetailCache;

local
function _GetItemKey(itemLink)
	local _, _, item = strsplit("|", itemLink);
	item = item or itemLink;
	local _, itemID, enchantID, jewelID1, jewelID2, jewelID3, jewelID4, suffixID = strsplit(":", item);
	return itemID .. ":" .. enchantID .. ":" .. jewelID1 .. ":" .. jewelID2 .. ":" .. jewelID3 .. ":" .. jewelID4 .. ":" .. suffixID;
end

function ItemDetailCache:GetItemDetail(itemLink)
	local key = _GetItemKey(itemLink);
	
	self.sessionStart = self.sessionStart or time();
	
	local rVal = self.details[key];
	
	if rVal == nil or rVal.lastUpdate < self.sessionStart then
		self.getItemInfo = self.getItemInfo or GetItemInfo;

		local d = {};		
		d.name, d.link, d.rarity, d.level, d.minlevel, d.type,
			d.subtype, d.stackcount, d.equiploc, d.texture = self.getItemInfo(itemLink);
		
		if d.name ~= nil then
			d.lastUpdate = time();
			self.details[key] = d;
			rVal = d;
		end
	end
	
	return rVal;
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

FBoH_UnitTests.ItemDetailCache = {

	testGetItemKey = function()
		local link = "|cff9d9d9d|Hitem:98264:42:156:26:64:23:733:1|h[Test Item]|h|r";
		local key = "98264:42:156:26:64:23:733";
		
		local test = _GetItemKey(link);
		
		assertEquals(key, test);
	end;
	
	testGetItemKeyFromItemString = function()
		local link = "item:98264:42:156:26:64:23:733:1";
		local key = "98264:42:156:26:64:23:733";
		
		local test = _GetItemKey(link);
		
		assertEquals(key, test);
	end;
	
	testGetItemDetailCached = function()
		local link = "|cffa335ee|Hitem:00000:0:2740:3111:0:0:0:0:13|h[Imaginary Belt of Blasting]|h|r";
		local key = "00000:0:2740:3111:0:0:0";
		local expected = {
			["type"] = "Armor",
			["rarity"] = 4,
			["subtype"] = "Cloth",
			["minlevel"] = 70,
			["equiploc"] = "INVTYPE_WAIST",
			["name"] = "Imaginary Belt of Blasting",
			["lastUpdate"] = 1234020812,
			["link"] = "|cffa335ee|Hitem:00000:0:2740:3111:0:0:0:0:13|h[Imaginary Belt of Blasting]|h|r",
			["level"] = 128,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Belt_13",
		};
		local detailCache = {
			[key] = expected;
		};
		
		local cache = ItemDetailCache{ details = detailCache, sessionStart = 0 };
		
		local test = cache:GetItemDetail(link);
		
		assertEquals(expected, test);
	end;
	
	testGetItemDetailUncached = function()
		local link = "|cffa335ee|Hitem:00000:0:2740:3111:0:0:0:0:13|h[Imaginary Belt of Blasting]|h|r";
		local key = "00000:0:2740:3111:0:0:0";
		local expected = {
			["type"] = "Armor",
			["rarity"] = 4,
			["subtype"] = "Cloth",
			["minlevel"] = 70,
			["equiploc"] = "INVTYPE_WAIST",
			["name"] = "Imaginary Belt of Blasting",
			["lastUpdate"] = 1234020812,
			["link"] = "|cffa335ee|Hitem:00000:0:2740:3111:0:0:0:0:13|h[Imaginary Belt of Blasting]|h|r",
			["level"] = 128,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Belt_13",
		};
		local detailCache = {
		};
		local getItemInfo = function(itemLink)
			if itemLink == link then
				return	"Imaginary Belt of Blasting", 
						"|cffa335ee|Hitem:00000:0:2740:3111:0:0:0:0:13|h[Imaginary Belt of Blasting]|h|r", 
						4, 128, 70, "Armor", "Cloth", 1, "INVTYPE_WAIST",
						"Interface\\Icons\\INV_Belt_13"
			else
				return nil;
			end;
		end;
		
		local cache = ItemDetailCache{ details = detailCache, getItemInfo = getItemInfo };
		
		local test = cache:GetItemDetail(link);
		test.lastUpdate = expected.lastUpdate;
		
		assertEquals(expected, test);
	end;
	
	testGetItemDetailOutdated = function()
		local link = "|cffa335ee|Hitem:00000:0:2740:3111:0:0:0:0:13|h[Imaginary Belt of Blasting]|h|r";
		local key = "00000:0:2740:3111:0:0:0";
		local expected = {
			["type"] = "Armor",
			["rarity"] = 4,
			["subtype"] = "Cloth",
			["minlevel"] = 70,
			["equiploc"] = "INVTYPE_WAIST",
			["name"] = "Imaginary Belt of Blasting",
			["lastUpdate"] = 0,
			["link"] = "|cffa335ee|Hitem:00000:0:2740:3111:0:0:0:0:13|h[Imaginary Belt of Blasting]|h|r",
			["level"] = 128,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Belt_13",
		};
		local detailCache = {
			[key] = expected;
		};
		local getItemInfo = function(itemLink)
			if itemLink == link then
				return	"Imaginary Belt of Blasting", 
						"|cffa335ee|Hitem:00000:0:2740:3111:0:0:0:0:13|h[Imaginary Belt of Blasting]|h|r", 
						4, 128, 70, "Armor", "Cloth", 1, "INVTYPE_WAIST",
						"Interface\\Icons\\INV_Belt_13"
			else
				return nil;
			end;
		end;
		
		local cache = ItemDetailCache{ details = detailCache, getItemInfo = getItemInfo };
		
		local test = cache:GetItemDetail(link);
		
		assert(test.lastUpdate ~= 0, "This data was not refreshed");
		
		test.lastUpdate = expected.lastUpdate;
		
		assertEquals(expected, test);
	end;
	
	testGetItemDetailOutdatedButNotClientCached = function()
		local link = "|cffa335ee|Hitem:00000:0:2740:3111:0:0:0:0:13|h[Imaginary Belt of Blasting]|h|r";
		local key = "00000:0:2740:3111:0:0:0";
		local expected = {
			["type"] = "Armor",
			["rarity"] = 4,
			["subtype"] = "Cloth",
			["minlevel"] = 70,
			["equiploc"] = "INVTYPE_WAIST",
			["name"] = "Imaginary Belt of Blasting",
			["lastUpdate"] = 0,
			["link"] = "|cffa335ee|Hitem:00000:0:2740:3111:0:0:0:0:13|h[Imaginary Belt of Blasting]|h|r",
			["level"] = 128,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Belt_13",
		};
		local detailCache = {
			[key] = expected;
		};
		local getItemInfo = function(itemLink)
			return nil;
		end;
		
		local cache = ItemDetailCache{ details = detailCache, getItemInfo = getItemInfo };
		
		local test = cache:GetItemDetail(link);		
		
		assertEquals(expected, test);
	end;
	
};
