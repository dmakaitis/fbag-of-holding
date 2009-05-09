FBOH_ITEMS_DB_VERSION = "0.03.02";

FBoH_SetVersion("$Revision$");

-- FBoH_Items is where item data is persisted between sessions
FBoH_Items = FBoH_Items or {};

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

local FOO = LibStub:GetLibrary("LibFOO-1.0");

local ItemDetailCache = FOO.class();

local
function _ItemDetailCache_GetItemKey(itemLink)
	local _, _, item = strsplit("|", itemLink);
	item = item or itemLink;
	local _, itemID, enchantID, jewelID1, jewelID2, jewelID3, jewelID4, suffixID = strsplit(":", item);
	return itemID .. ":" .. enchantID .. ":" .. jewelID1 .. ":" .. jewelID2 .. ":" .. jewelID3 .. ":" .. jewelID4 .. ":" .. suffixID;
end

function ItemDetailCache:GetItemDetail(itemLink)
	local key = _ItemDetailCache_GetItemKey(itemLink);
	
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

FBoH_ItemDB = {};
FBoH_ItemTypes = FBoH_ItemTypes or {};

--[[

Item DB Structure:

items = {
	version = "0.00.00";
	realms = {
		[realm] = {
			characters = {
				[character] = {
					Bags = {
						[0] = {
							content = {
								[0] = {
									link = itemLink
									count = itemCount
									key = itemKey
								}
								...
							}
							size = {
								total = 0
								free = 0
							}
						}
						...
					}
					Bank = ...
					Equipped = ...
					Mailbox = ...
				}
				...
			}
		}
		...
	}
}

]]

------------------------ Private functions -----------------------------

local
function _CopyItemProps(src, dest)
	dest = dest or {};
	for k, v in pairs(src) do
		dest[k] = v;
	end
	return dest;
end

local
function _TestFilter(filter, filterArg, itemProps)
	local pResult, rVal = pcall(filter, itemProps, filterArg);
	if pResult == true then return rVal else return false end;
end

local
function _UpgradeFrom0_01_00(self)
	-- Move all item details out of the inventory section and into the details section.
	self.items.details = {};
	local details = self.items.details;
	-- Go through and transfer all item details...
	if self.items.realms then
		for _, r in pairs(self.items.realms) do
			if r.characters then
				for _, c in pairs(r.characters) do
					for _, t in pairs(c) do
						for _, b in pairs(t) do
							if b.content then
								for _, i in pairs(b.content) do
									details[i.key] = i.detail;
									i.detail = nil;
								end
							end
						end
					end
				end
			end
		end
	end
	self.items.version = "0.02.00";
end

local
function _UpgradeFrom0_02_00(self)
	-- Move the item link out of the inventory section and into the details section.
	-- Update item keys to use new format
	-- Wipe the guild bank data (since nobody should have anything there yet except me since it hasn't been published yet).
	local oldDetails = self.items.details;
	self.items.details = {};
	local details = self.items.details;
	if self.items.realms then
		for _, r in pairs(self.items.realms) do
			r.guilds = nil;
			if r.characters then
				for _, c in pairs(r.characters) do
					for _, t in pairs(c) do
						for _, b in pairs(t) do
							if b.content then
								for _, i in pairs(b.content) do
									local oldKey = i.key;
									local newKey = self:GetItemKey(i.link);
									details[newKey] = oldDetails[i.key];
									if details[newKey] then
										details[newKey].link = i.link;
									end
									i.link = nil;
									i.key = newKey;
								end
							end
						end
					end
				end
			end
		end
	end			
	self.items.version = "0.03.00";
end

local
function _UpgradeFrom0_03_00(self)
	if self.items.realms then
		for _, r in pairs(self.items.realms) do
			if r.characters then
				for _, c in pairs(r.characters) do
					for _, t in pairs(c) do
						for _, b in pairs(t) do
							if b.content then
								for _, i in pairs(b.content) do
									i.lastUpdate = i.lastUpdate or time();
								end
							end
						end
					end
				end
			end
		end
	end			
	self.items.version = "0.03.01";
end

local
function _UpgradeFrom0_03_01(self)
	FBoH_ItemTypes = {};
	self.items.version = "0.03.02";
end

local
function _CleanDatabase(self)
	local details = self.items.details;
	for k, v in pairs(details) do
		FBoH_ItemTypes[v.type] = FBoH_ItemTypes[v.type] or {};
		FBoH_ItemTypes[v.type][v.subtype] = 1;
		
		local used = false;
		if self.items.realms then
			for _, r in pairs(self.items.realms) do
				if r.characters then
					for _, c in pairs(r.characters) do
						for _, t in pairs(c) do
							for _, b in pairs(t) do
								if b.content then
									for _, s in pairs(b.content) do
										if s.key == k then
											used = true;
										end
									end
								end
							end
						end
					end
				end
				if r.guilds then
					for _, g in pairs(r.guilds) do
						if g.tabs then
							for _, t in pairs(g.tabs) do
								if t.content then
									for _, s in pairs(t.content) do
										if s.key == k then
											used = true;
										end
									end
								end
							end
						end
					end
				end
			end
		end
		if used == false then
			details[k] = nil;
		end
	end
end

local
function _SortEmptySlots(a, b)
	return a.restrictionCode < b.restrictionCode;
end

local
function _GetItem(self, bagType, bagID, slotID, character, realm)
	realm = realm or GetRealmName();
	character = character or UnitName("player");
	
	local realms = self.items.realms;
	if realms == nil then return end;
	
	local server = realms[realm];
	if server == nil then return end;
	
	local chars = server.characters;
	if chars == nil then return end;
	
	local chr = chars[character];
	if chr == nil then return end;
	
	local bType = chr[bagType];
	if bType == nil then return end;
	
	local bag = bType[bagID];
	if bag == nil then return end;
	
	local content = bag.content;
	if content == nil then return end;
	
	return content[slotID];
end

local
function _UpdateItemDetail(self, itemLink)
	local d = {};
	
	d.name, d.link, d.rarity, d.level, d.minlevel, d.type, d.subtype, d.stackcount, d.equiploc, d.texture = GetItemInfo(itemLink);
	d.lastUpdate = time();
	if d.name then
		self.items.details[self:GetItemKey(d.link)] = d;
		FBoH_ItemTypes[d.type] = FBoH_ItemTypes[d.type] or {};
		FBoH_ItemTypes[d.type][d.subtype] = 1;
	end
	
	return d;
end

local
function _GetItemDetail(self, key)
	if key == nil then return nil end;
	
	local detail = self.items.details[key];
	if detail and detail.link then
		if detail.lastUpdate and (detail.lastUpdate >= FBoH.sessionStartTime) then
			return detail;
		end
	end
	
	local item = "item:" .. key .. ":0";
	_UpdateItemDetail(self, item);
	
	detail = self.items.details[key];
	if detail and detail.link then
		return detail;
	end

	return nil;
end

------------------ Public Interface ---------------------------

function FBoH_ItemDB:CheckVersion()
	self.items = self.items or FBoH_Items;
	self.items.version = self.items.version or "purge";
	
	if self.items.version ~= FBOH_ITEMS_DB_VERSION then
		if self.items.version == "purge" then
			self:Purge();
			return;
		end
		FBoH:Print("Updating item database: " .. self.items.version .. " -> " .. FBOH_ITEMS_DB_VERSION);
		if self.items.version == "0.01.00" then
			_UpgradeFrom0_01_00(self);
		end
		if self.items.version == "0.02.00" then
			_UpgradeFrom0_02_00(self);
		end
		if self.items.version == "0.03.00" then
			_UpgradeFrom0_03_00(self);
		end
		if self.items.version == "0.03.01" then
			_UpgradeFrom0_03_01(self);
		end
	end
	
	_CleanDatabase(self);
end

local FindItemProps = {};

function FBoH_ItemDB:FindItems(filter, filterArg, subset)
	-- Subset can be one of:
	--	char - returns current character items
	--	alt - returns alt items
	--	both - return items for current character and alts (default)
	--	gbank - returns items for the guild bank
	
	subset = subset or "both";
	
	local rTable = {};
	local itemProps = FindItemProps;
	
	local charName = UnitName("player");
	local charRealm = GetRealmName();

	local realms = self.items.realms;
	if realms == nil then return rTable end;
	
	self.items.details = self.items.details or {};
	
	if subset == "char" or subset == "alt" or subset == "both" then
		for rName, rData in pairs(realms) do
			if rData.characters then
				for cName, cData in pairs(rData.characters) do
					if subset == "both" or 
						(subset == "char" and cName == charName and rName == charRealm) or
						(subset == "alt" and (cName ~= charName or rName ~= charRealm)) then
						for bType, btData in pairs(cData) do
							if bType ~= "Wearing" or cName ~= charName then 
								for bID, bData in pairs(btData) do
									if bData.content then
										for sID, sData in pairs(bData.content) do
											local detail = _GetItemDetail(self, sData.key);
											if detail and detail.link then
												itemProps.realm = rName;
												itemProps.character = cName;
												itemProps.bagType = bType;
												itemProps.bagIndex = bID;
												itemProps.slotIndex = sID;
												
												itemProps.lastUpdate = sData.lastUpdate;
												itemProps.itemKey = sData.key;
												itemProps.itemCount = sData.count;
												itemProps.soulbound = sData.soulbound;
												
												itemProps.detail = detail;
												itemProps.itemLink = detail.link;
												
												if _TestFilter(filter, filterArg, itemProps) then
													table.insert(rTable, _CopyItemProps(itemProps));
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	if subset == "gbank" then
		local charGuild = GetGuildInfo("player");
		if realms[charRealm] and realms[charRealm].guilds and realms[charRealm].guilds[charGuild] then
			gData = realms[charRealm].guilds[charGuild];
			if gData.tabs then
				for tabID, tab in pairs(gData.tabs) do
					if tab.content then
						for sID, sData in pairs(tab.content) do
							local detail = _GetItemDetail(self, sData.key);
							if detail then
								itemProps.realm = charRealm;
								itemProps.character = charName;
								itemProps.bagType = "Guild Bank";
								itemProps.bagIndex = tabID;
								itemProps.slotIndex = sID;
								
								itemProps.lastUpdate = sData.lastUpdate;
								itemProps.itemKey = sData.key;
								itemProps.itemCount = sData.count;
								itemProps.soulbound = nil;
								
								itemProps.detail = detail;
								itemProps.itemLink = itemProps.detail.link;
								
								if _TestFilter(filter, filterArg, itemProps) then
									table.insert(rTable, _CopyItemProps(itemProps));
								end							
							end
						end
					end
				end
			end
		end
	end
	
	return rTable;
end

function FBoH_ItemDB:GetBagUsage(bagType, bagID, character, realm)
	local total, free = 0, 0;
	local gtotal, gfree = 0, 0;
	
	realm = realm or GetRealmName();
	character = character or UnitName("player");

	local realms = self.items.realms;
	if realms == nil then return 0, 0 end;
	
	for rName, rData in pairs(realms) do
		if rName == realm then
			local chars = rData.characters;
			if chars then
				for cName, cData in pairs(chars) do
					if cName == character then
						for bType, btData in pairs(cData) do
							if (bagType == nil) or (bagType == bType) then
								for bagIndex, bag in pairs(btData) do
									if (bagID == nil) or (bagID == bagIndex) then
										local size = bag.size;
										if size then
											total = total + (size.total or 0);
											free = free + (size.free or 0);
											
											if size.general ~= false then
												gtotal = gtotal + (size.total or 0);
												gfree = gfree + (size.free or 0);
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	
	return gtotal, gfree, total, free;
end

function FBoH_ItemDB:GetEmptySlots(bagType, bagID, character, realm)
	local rVal = {};
	
	realm = realm or GetRealmName();
	character = character or UnitName("player");

	local realms = self.items.realms;
	if realms == nil then return rVal end;
	
	for rName, rData in pairs(realms) do
		if rName == realm then
			local chars = rData.characters;
			if chars then
				for cName, cData in pairs(chars) do
					if cName == character then
						for bType, btData in pairs(cData) do
							if (bagType == nil) or (bagType == bType) then
								for bagIndex, bag in pairs(btData) do
									if (bagID == nil) or (bagID == bagIndex) then
										local size = bag.size;
										if size and size.free > 0 then
											rVal[bType] = rVal[bType] or {};
											local entry = nil
											for _, v in pairs(rVal[bType]) do
												if v.restrictionCode == (size.restrictionCode or 0) then
													entry = v;
												end
											end
											if entry == nil then
												entry = {};
												table.insert(rVal[bType], entry);
												entry.restrictionCode = size.restrictionCode or 0;
												entry.slotCount = 0;
												entry.firstBagID = bagIndex;
												entry.firstSlotID = nil;
												if bag.content then
													for index = 1, size.total do
														if bag.content[index] == nil then
															entry.firstSlotID = entry.firstSlotID or index;
														end
													end
												else
													entry.firstSlotID = 1;
												end
											end
											
											entry.slotCount = entry.slotCount + size.free;
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	
	-- Sort the values...
	for _, v in pairs(rVal) do
		table.sort(v, _SortEmptySlots);
	end
	
	return rVal;
end

function FBoH_ItemDB:GetItemKey(itemLink)
	if itemLink == nil then return end;
	
	local _, _, item = strsplit("|", itemLink);
	if item == nil then return end;

	local _, itemID, enchantID, jewelID1, jewelID2, jewelID3, jewelID4, suffixID = strsplit(":", item);
	if itemID == nil then return end;
	if enchantID == nil then return end;
	if jewelID1 == nil then return end;
	if jewelID2 == nil then return end;
	if jewelID3 == nil then return end;
	if jewelID4 == nil then return end;
	if suffixID == nil then return end;
	
	local _, _, name = string.find(itemLink, "%[(.+)%]")
	if name == nil then return end;
	
	return itemID .. ":" .. enchantID .. ":" .. jewelID1 .. ":" .. jewelID2 .. ":" .. jewelID3 .. ":" .. jewelID4 .. ":" .. suffixID;
end

function FBoH_ItemDB:Purge()
	FBoH_Items = {};
	FBoH_Items.version = FBOH_ITEMS_DB_VERSION;
	self.items = FBoH_Items;
end

function FBoH_ItemDB:SetItem(bagType, bagID, slotID, itemLink, itemCount, soulbound, character, realm)
	realm = realm or GetRealmName();
	character = character or UnitName("player");
	
	local oldItem = _GetItem(self, bagType, bagID, slotID, character, realm)
	
	local newKey = nil;
	if itemLink then
		newKey = self:GetItemKey(itemLink);
	end
	
	local newItemTimestamp = time();
	
	local sameItem = true;
	if oldItem then
		if oldItem.key ~= newKey then sameItem = false
		elseif oldItem.soulbound ~= soulbound then sameItem = false
		elseif oldItem.count ~= itemCount then 
			sameItem = false;
			if itemCount < oldItem.count then
				newItemTimestamp = oldItem.lastUpdate or newItemTimestamp;
			end
		end
	else
		if itemLink ~= nil then sameItem = false end;
	end
	
	if sameItem then
		return
	end;
	
	local newItem = nil;
	if itemLink then
		newItem = {
			count = itemCount;
			key = self:GetItemKey(itemLink);
			lastUpdate = newItemTimestamp;
		}
		newItem.soulbound = soulbound;
		
		self.items.details = self.items.details or {};
		if self.items.details[newItem.key] == nil then
			_UpdateItemDetail(self, itemLink);
		end
	end;
	
	self.items.realms = self.items.realms or {};
	local realms = self.items.realms;
	
	realms[realm] = realms[realm] or {};
	local server = realms[realm];

	server.characters = server.characters or {};
	local chars = server.characters;
	
	chars[character] = chars[character] or {};
	local chr = chars[character];

	chr[bagType] = chr[bagType] or {};
	local bType = chr[bagType];

	bType[bagID] = bType[bagID] or {};
	local bag = bType[bagID];

	bag.content = bag.content or {};
	local content = bag.content;

	content[slotID] = newItem;
end

function FBoH_ItemDB:SetGuildItem(tabID, slotID, itemLink, itemCount)
--	FBoH:Print("Adding " .. tostring(itemCount) .. "x" .. tostring(itemLink) .. " at (" .. tostring(tabID) .. ", " .. tostring(slotID) ..")");
	local newItem = nil;
	if itemLink then
		newItem = {
			count = itemCount;
			key = self:GetItemKey(itemLink);
		}
		
		self.items.details = self.items.details or {};
		if self.items.details[newItem.key] == nil then
			local d = {};
			
			d.name, d.link, d.rarity, d.level, d.minlevel, d.type, d.subtype, d.stackcount, d.equiploc, d.texture = GetItemInfo(itemLink);
			if d.name then
				self.items.details[newItem.key] = d;
			end
		end		
	end
	
	local realm = GetRealmName();
	local guildName = GetGuildInfo("player");
	if not guildName then return end;
	
	self.items.realms = self.items.realms or {};
	local realms = self.items.realms;
	
	realms[realm] = realms[realm] or {};
	local server = realms[realm];

	server.guilds = server.guilds or {};
	local guilds = server.guilds;
	
	guilds[guildName] = guilds[guildName] or {};
	local guild = guilds[guildName];
	
	guild.tabs = guild.tabs or {};
	local tabs = guild.tabs;
	
	tabs[tabID] = tabs[tabID] or {};
	local tab = tabs[tabID];
	
	tab.content = tab.content or {};
	local content = tab.content;
	
	content[slotID] = newItem;
end

function FBoH_ItemDB:UpdateBagUsage(bagType, bagID, character, realm)
	local bID = FBoH:GetBagID(bagType, bagID);
	if bID == nil then return end;
	
	realm = realm or GetRealmName();
	character = character or UnitName("player");
	
	self.items.realms = self.items.realms or {};
	local realms = self.items.realms;
	
	realms[realm] = realms[realm] or {};
	local server = realms[realm];

	server.characters = server.characters or {};
	local chars = server.characters;
	
	chars[character] = chars[character] or {};
	local chr = chars[character];

	chr[bagType] = chr[bagType] or {};
	local bType = chr[bagType];

	bType[bagID] = bType[bagID] or {};
	local bag = bType[bagID];

	bag.size = bag.size or {};
	local size = bag.size;
	
	size.total = GetContainerNumSlots(bID);
	size.free = GetContainerNumFreeSlots(bID);
	
	size.general = true;
--	size.restrictionCode = 0;
	
	if (bID ~= 0) and (bID ~= BANK_CONTAINER) then
		local bt = GetItemFamily(GetBagName(bID));
		size.restrictionCode = bt;
		if bt ~= 0 then
			size.general = false;
		end
	end
end

FBoH_UnitTests = {};

if WoWUnit then

WoWUnit:AddTestSuite("FBoH", FBoH_UnitTests);

end

local ItemDB_0_03_01 = {
	["details"] = {
		["00000:0:2740:3111:0:0:0"] = {
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
		},
		["2589:0:0:0:0:0:0"] = {
			["type"] = "Trade Goods",
			["rarity"] = 1,
			["subtype"] = "Cloth",
			["minlevel"] = 0,
			["equiploc"] = "",
			["name"] = "Linen Cloth",
			["lastUpdate"] = 1234020812,
			["link"] = "|cffffffff|Hitem:2589:0:0:0:0:0:0:0:13|h[Linen Cloth]|h|r",
			["level"] = 5,
			["stackcount"] = 20,
			["texture"] = "Interface\\Icons\\INV_Fabric_Linen_01",
		},
		["11000:0:0:0:0:0:0"] = {
			["type"] = "Key",
			["rarity"] = 1,
			["subtype"] = "Key",
			["minlevel"] = 0,
			["equiploc"] = "",
			["name"] = "Shadowforge Key",
			["lastUpdate"] = 1234020812,
			["link"] = "|cffffffff|Hitem:11000:0:0:0:0:0:0:0:13|h[Shadowforge Key]|h|r",
			["level"] = 1,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Misc_Key_08",
		},
		["24490:0:0:0:0:0:0"] = {
			["type"] = "Key",
			["rarity"] = 1,
			["subtype"] = "Key",
			["minlevel"] = 0,
			["equiploc"] = "",
			["name"] = "The Master's Key",
			["lastUpdate"] = 1234020812,
			["link"] = "|cffffffff|Hitem:24490:0:0:0:0:0:0:0:13|h[The Master's Key]|h|r",
			["level"] = 1,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Misc_Key_07",
		},
		["27886:0:0:0:0:0:0"] = {
			["type"] = "Armor",
			["rarity"] = 3,
			["subtype"] = "Idols",
			["minlevel"] = 68,
			["equiploc"] = "INVTYPE_RELIC",
			["name"] = "Idol of the Emerald Queen",
			["lastUpdate"] = 1234020812,
			["link"] = "|cff0070dd|Hitem:27886:0:0:0:0:0:0:0:13|h[Idol of the Emerald Queen]|h|r",
			["level"] = 112,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\Spell_Nature_NatureResistanceTotem",
		},
		["28348:0:0:0:0:0:0"] = {
			["type"] = "Armor",
			["rarity"] = 3,
			["subtype"] = "Leather",
			["minlevel"] = 70,
			["equiploc"] = "INVTYPE_HEAD",
			["name"] = "Moonglade Cowl",
			["lastUpdate"] = 1234020812,
			["link"] = "|cff0070dd|Hitem:28348:0:0:0:0:0:0:0:13|h[Moonglade Cowl]|h|r",
			["level"] = 115,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Helmet_15",
		},
		["30038:0:2740:3111:0:0:0"] = {
			["type"] = "Armor",
			["rarity"] = 4,
			["subtype"] = "Cloth",
			["minlevel"] = 70,
			["equiploc"] = "INVTYPE_WAIST",
			["name"] = "Belt of Blasting",
			["lastUpdate"] = 1234020812,
			["link"] = "|cffa335ee|Hitem:30038:0:2740:3111:0:0:0:0:13|h[Belt of Blasting]|h|r",
			["level"] = 128,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Belt_13",
		},
		["30623:0:0:0:0:0:0"] = {
			["type"] = "Key",
			["rarity"] = 1,
			["subtype"] = "Key",
			["minlevel"] = 0,
			["equiploc"] = "",
			["name"] = "Reservoir Key",
			["lastUpdate"] = 1234020812,
			["link"] = "|cffffffff|Hitem:30623:0:0:0:0:0:0:0:13|h[Reservoir Key]|h|r",
			["level"] = 0,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Misc_Key_13",
		},
		["33445:0:0:0:0:0:0"] = {
			["type"] = "Consumable",
			["rarity"] = 1,
			["subtype"] = "Food & Drink",
			["minlevel"] = 75,
			["equiploc"] = "",
			["name"] = "Honeymint Tea",
			["lastUpdate"] = 1234020812,
			["link"] = "|cffffffff|Hitem:33445:0:0:0:0:0:0:0:13|h[Honeymint Tea]|h|r",
			["level"] = 85,
			["stackcount"] = 20,
			["texture"] = "Interface\\Icons\\INV_Drink_25_HoneyTea",
		},
		["37149:3820:3623:3488:0:0:0"] = {
			["type"] = "Armor",
			["rarity"] = 3,
			["subtype"] = "Leather",
			["minlevel"] = 80,
			["equiploc"] = "INVTYPE_HEAD",
			["name"] = "Helm of Anomalus",
			["lastUpdate"] = 1234020812,
			["link"] = "|cff0070dd|Hitem:37149:3820:3623:3488:0:0:0:0:13|h[Helm of Anomalus]|h|r",
			["level"] = 200,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Helmet_104",
		},
		["39878:0:0:0:0:0:0"] = {
			["type"] = "Consumable",
			["rarity"] = 1,
			["subtype"] = "Consumable",
			["minlevel"] = 70,
			["equiploc"] = "",
			["name"] = "Mysterious Egg",
			["lastUpdate"] = 1234020812,
			["link"] = "|cffffffff|Hitem:39878:0:0:0:0:0:0:0:13|h[Mysterious Egg]|h|r",
			["level"] = 1,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Egg_02",
		},
		["43348:0:0:0:0:0:0"] = {
			["type"] = "Armor",
			["rarity"] = 4,
			["subtype"] = "Miscellaneous",
			["minlevel"] = 0,
			["equiploc"] = "INVTYPE_TABARD",
			["name"] = "Tabard of the Explorer",
			["lastUpdate"] = 1234020812,
			["link"] = "|cffa335ee|Hitem:43348:0:0:0:0:0:0:0:13|h[Tabard of the Explorer]|h|r",
			["level"] = 1,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Chest_Cloth_30",
		},
		["44228:0:0:0:0:0:0"] = {
			["type"] = "Consumable",
			["rarity"] = 1,
			["subtype"] = "Food & Drink",
			["minlevel"] = 0,
			["equiploc"] = "",
			["name"] = "Baby Spice",
			["lastUpdate"] = 1234020812,
			["link"] = "|cffffffff|Hitem:44228:0:0:0:0:0:0:0:13|h[Baby Spice]|h|r",
			["level"] = 1,
			["stackcount"] = 20,
			["texture"] = "Interface\\Icons\\INV_Misc_Powder_Green",
		},
	},
	["version"] = "0.03.01",
	["realms"] = {
		["Spirestone"] = {
			["characters"] = {
				["Feithar"] = {
					["Bank"] = {
						{
							["content"] = {
								{
									["lastUpdate"] = 1212116014,
									["key"] = "28348:0:0:0:0:0:0",
									["count"] = 1,
								}, -- [1]
							},
							["size"] = {
								["total"] = 28,
								["general"] = true,
								["free"] = 0,
							},
						}, -- [1]
						{
							["content"] = {
								{
									["lastUpdate"] = 1229815277,
									["count"] = 1,
									["key"] = "30038:0:2740:3111:0:0:0",
									["soulbound"] = true,
								}, -- [1]
							},
							["size"] = {
								["restrictionCode"] = 0,
								["total"] = 20,
								["general"] = true,
								["free"] = 0,
							},
						}, -- [2]
						{
							["content"] = {
								{
									["lastUpdate"] = 1229689777,
									["key"] = "43348:0:0:0:0:0:0",
									["soulbound"] = true,
									["count"] = 1,
								}, -- [1]
							},
							["size"] = {
								["restrictionCode"] = 0,
								["total"] = 18,
								["general"] = true,
								["free"] = 0,
							},
						}, -- [3]
					},
					["Wearing"] = {
						{
							["content"] = {
								{
									["lastUpdate"] = 1233001829,
									["count"] = 1,
									["key"] = "37149:3820:3623:3488:0:0:0",
								}, -- [1]
							},
						}, -- [1]
					},
					["Bags"] = {
						{
							["content"] = {
								{
									["lastUpdate"] = 1233808438,
									["soulbound"] = true,
									["count"] = 1,
									["key"] = "39878:0:0:0:0:0:0",
								}, -- [1]
							},
							["size"] = {
								["total"] = 16,
								["general"] = true,
								["free"] = 2,
							},
						}, -- [1]
						{
							["content"] = {
								{
									["lastUpdate"] = 1233834239,
									["count"] = 18,
									["key"] = "33445:0:0:0:0:0:0",
								}, -- [1]
							},
							["size"] = {
								["restrictionCode"] = 0,
								["total"] = 22,
								["general"] = true,
								["free"] = 2,
							},
						}, -- [2]
						{
							["content"] = {
								{
									["lastUpdate"] = 1233748873,
									["key"] = "44228:0:0:0:0:0:0",
									["soulbound"] = true,
									["count"] = 15,
								}, -- [1]
							},
							["size"] = {
								["restrictionCode"] = 0,
								["total"] = 20,
								["general"] = true,
								["free"] = 4,
							},
						}, -- [3]
						{
							["content"] = {
								nil, -- [1]
							},
							["size"] = {
								["restrictionCode"] = 0,
								["total"] = 22,
								["general"] = true,
								["free"] = 5,
							},
						}, -- [4]
						{
							["content"] = {
								{
									["lastUpdate"] = 1233748873,
									["key"] = "27886:0:0:0:0:0:0",
									["soulbound"] = true,
									["count"] = 1,
								}, -- [1]
							},
							["size"] = {
								["restrictionCode"] = 0,
								["total"] = 22,
								["general"] = true,
								["free"] = 3,
							},
						}, -- [5]
					},
					["Keyring"] = {
						{
							["content"] = {
								{
									["lastUpdate"] = 1212116014,
									["count"] = 1,
									["key"] = "30623:0:0:0:0:0:0",
								}, -- [1]
								{
									["lastUpdate"] = 1212116014,
									["count"] = 1,
									["key"] = "24490:0:0:0:0:0:0",
								}, -- [2]
								{
									["lastUpdate"] = 1212116014,
									["count"] = 1,
									["key"] = "11000:0:0:0:0:0:0",
								}, -- [3]
							},
							["size"] = {
								["total"] = 32,
								["general"] = false,
								["free"] = 0,
							},
						}, -- [1]
					},
				},
			},
			["guilds"] = {
				["Heros of the Horde"] = {
					["tabs"] = {
						{
							["content"] = {
								{
									["count"] = 20,
									["key"] = "2589:0:0:0:0:0:0",
								}, -- [1]
								{
									["count"] = 20,
									["key"] = "2589:0:0:0:0:0:0",
								}, -- [2]
								{
									["count"] = 20,
									["key"] = "2589:0:0:0:0:0:0",
								}, -- [3]
							},
						}, -- [1]
					},
				},
			},
		},
	},
};
--[[
FBoH_UnitTests.OldItemDB = {
	mocks = {
		FBoH = FBoH;
		
		FBoH_ItemDB = FBoH_ItemDB;
		ItemDB_0_03_01 = ItemDB_0_03_01;
		
		GetRealmName = function() return "Spirestone" end;
		UnitName = function() return "Feithar" end;
	};
	
	testCreateNewItemDatabase = function()
		FBoH_ItemDB.items = nil;
		FBoH_ItemDB:CheckVersion();
		assert(FBOH_ITEMS_DB_VERSION == FBoH_Items.version, "Item DB version should be " .. FBOH_ITEMS_DB_VERSION .. " (was " .. FBoH_Items.version .. ")");
	end;
	
	testUpgradeItemDatabaseFrom0_01_00 = function()
		FBoH_ItemDB.items = {};
		FBoH_ItemDB.items.version = "0.01.00";
		_UpgradeFrom0_01_00(FBoH_ItemDB);
		assertEquals("0.02.00", FBoH_ItemDB.items.version);
	end;
	
	testUpgradeItemDatabaseFrom0_02_00 = function()
		FBoH_ItemDB.items = {};
		FBoH_ItemDB.items.version = "0.02.00";
		_UpgradeFrom0_02_00(FBoH_ItemDB);
		assertEquals("0.03.00", FBoH_ItemDB.items.version);
	end;
	
	testUpgradeItemDatabaseFrom0_03_00 = function()
		FBoH_ItemDB.items = {};
		FBoH_ItemDB.items.version = "0.03.00";
		_UpgradeFrom0_03_00(FBoH_ItemDB);
		assertEquals("0.03.01", FBoH_ItemDB.items.version);
	end;
	
	testTestFilterForPass = function()
		local filter = function() return true; end;
		local filterArg = nil;
		local itemProps = nil;
		
		local result = _TestFilter(filter, filterArg, itemProps);
		
		assertEquals(true, result);
	end;
	
	testTestFilterForFail = function()
		local filter = function() return false; end;
		local filterArg = nil;
		local itemProps = nil;
		
		local result = _TestFilter(filter, filterArg, itemProps);
		
		assertEquals(false, result);
	end;
	
	testTestFilterForError = function()
		local filter = function() error("This test should fail"); end;
		local filterArg = nil;
		local itemProps = nil;
		
		local result = _TestFilter(filter, filterArg, itemProps);
		
		assertEquals(false, result);
	end;
	
	testSortEmptySlotsTrue = function()
		local a = { restrictionCode = 1 };
		local b = { restrictionCode = 2 };
		assertEquals(true, _SortEmptySlots(a, b));
	end;
	
	testSortEmptySlotsFalse = function()
		local a = { restrictionCode = 2 };
		local b = { restrictionCode = 1 };
		assertEquals(false, _SortEmptySlots(a, b));
	end;
	
	testSortEmptySlotsEqual = function()
		local a = { restrictionCode = 1 };
		local b = { restrictionCode = 1 };
		assertEquals(false, _SortEmptySlots(a, b));
	end;
	
	testCopyItemProps = function()
		local src = { a = 1, b = 2, c = 3 };
		local dst = nil;
		local target = { a = 1, b = 2, c = 3 };
		assertEquals(target, _CopyItemProps(src, dst));
	end;
	
	testCopyItemPropsMerge = function()
		local src = { a = 1, b = 2, c = 3 };
		local dst = { a = 4, b = 5, c = 6, d = 7 };
		local target = { a = 1, b = 2, c = 3, d = 7 };
		assertEquals(target, _CopyItemProps(src, dst));
	end;
	
	testGetItem = function()
		local realm = "Spirestone";
		local character = "Feithar";
		local bagType = "Bags";
		local bagID = 1;
		local slotID = 1;
		
		local expected = {
			["lastUpdate"] = 1233808438,
			["soulbound"] = true,
			["count"] = 1,
			["key"] = "39878:0:0:0:0:0:0",
		};
		
		FBoH_ItemDB.items = ItemDB_0_03_01;

		local rVal = _GetItem(FBoH_ItemDB, bagType, bagID, slotID, character, realm);
		
		assertEquals(expected, rVal);
	end;
	
	testGetItemDefaultCharRealm = function()
		local bagType = "Bags";
		local bagID = 1;
		local slotID = 1;
		
		local expected = {
			["lastUpdate"] = 1233808438,
			["soulbound"] = true,
			["count"] = 1,
			["key"] = "39878:0:0:0:0:0:0",
		};
		
		FBoH_ItemDB.items = ItemDB_0_03_01;

		local rVal = _GetItem(FBoH_ItemDB, bagType, bagID, slotID);
		
		assertEquals(expected, rVal);
	end;
	
	testGetItemDetail = function()
		local key = "30038:0:2740:3111:0:0:0";
		local expected = {
			["type"] = "Armor",
			["rarity"] = 4,
			["subtype"] = "Cloth",
			["minlevel"] = 70,
			["equiploc"] = "INVTYPE_WAIST",
			["name"] = "Belt of Blasting",
			["lastUpdate"] = 1234020812,
			["link"] = "|cffa335ee|Hitem:30038:0:2740:3111:0:0:0:0:13|h[Belt of Blasting]|h|r",
			["level"] = 128,
			["stackcount"] = 1,
			["texture"] = "Interface\\Icons\\INV_Belt_13",
		};

		FBoH_ItemDB.items = ItemDB_0_03_01;

		FBoH.sessionStartTime = 1234020000;		-- Ensure we use the cached data

		assertEquals("Session start time reset", 1234020000, FBoH.sessionStartTime);
		assertEquals("Not using test item database", ItemDB_0_03_01, FBoH_ItemDB.items);
		
		local result = _GetItemDetail(FBoH_ItemDB, key);

		assertEquals("Last update time changed - not using cached value", expected.lastUpdate, result.lastUpdate);
		assertEquals(expected, result);
	end;
	
	testGetImaginaryItemDetail = function()
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

		FBoH_ItemDB.items = ItemDB_0_03_01;

		FBoH.sessionStartTime = 1234020000;		-- Ensure we use the cached data

		assertEquals("Session start time reset", 1234020000, FBoH.sessionStartTime);
		assertEquals("Not using test item database", ItemDB_0_03_01, FBoH_ItemDB.items);
		
		local result = _GetItemDetail(FBoH_ItemDB, key);

		assertEquals("Last update time changed - not using cached value", expected.lastUpdate, result.lastUpdate);
		assertEquals(expected, result);
	end;
	
	testGetImaginaryItemDetailCacheDefault = function()
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

		FBoH_ItemDB.items = ItemDB_0_03_01;

		FBoH.sessionStartTime = 1234030000;		-- Ensure we attempt to read from client cache

		assertEquals("Not using test item database", ItemDB_0_03_01, FBoH_ItemDB.items);
		
		local result = _GetItemDetail(FBoH_ItemDB, key);

		assertEquals("Last update time changed - not using cached value", expected.lastUpdate, result.lastUpdate);
		assertEquals(expected, result);
	end;
	
	testUpdateImaginaryItemDetail = function()
		local link = "item:00000:0:2740:3111:0:0:0:0";
		local expected = {};
		
		FBoH_ItemDB.items = ItemDB_0_03_01;

		local result = _UpdateItemDetail(FBoH_ItemDB, link);
		
		expected.lastUpdate = result.lastUpdate;
		assertEquals(expected, result);
	end;
	
};
]]
FBoH_UnitTests.ItemDetailCache = {

	testGetItemKey = function()
		local link = "|cff9d9d9d|Hitem:98264:42:156:26:64:23:733:1|h[Test Item]|h|r";
		local key = "98264:42:156:26:64:23:733";
		
		local test = _ItemDetailCache_GetItemKey(link);
		
		assertEquals(key, test);
	end;
	
	testGetItemKeyFromItemString = function()
		local link = "item:98264:42:156:26:64:23:733:1";
		local key = "98264:42:156:26:64:23:733";
		
		local test = _ItemDetailCache_GetItemKey(link);
		
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
