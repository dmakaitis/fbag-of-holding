FBOH_ITEMS_DB_VERSION = "0.03.00";

FBoH_Items = FBoH_Items or {};
FBoH_ItemDB = {};

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

function FBoH_ItemDB:AreSameItem(oldItem, newItem)
	if oldItem then
		if newItem then
			if oldItem.link ~= newItem.link then return false end;
			if oldItem.count ~= newItem.count then return false end;
			if oldItem.soulbound ~= newItem.soulbound then return false end;
			return true;
		else
			return false;
		end
	else
		if newItem then
			return false;
		else
			return true;
		end
	end
end

function FBoH_ItemDB:CheckVersion()
	self.items = self.items or FBoH_Items;
	self.items.version = self.items.version or "purge";
	
	if self.items.version ~= FBOH_ITEMS_DB_VERSION then
		FBoH:Print("Updating item database: " .. self.items.version .. " -> " .. FBOH_ITEMS_DB_VERSION);
		if self.items.version == "purge" then
			self:Purge();
			return;
		end
		if self.items.version == "0.01.00" then
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
		if self.items.version == "0.02.00" then
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
	end
end

function FBoH_ItemDB:FindItems(filter, filterArg)
	local rTable = {};
	
	local realms = self.items.realms;
	if realms == nil then return rTable end;
	
	self.items.details = self.items.details or {};
	
	for rName, rData in pairs(realms) do
		if rData.characters then
			for cName, cData in pairs(rData.characters) do
				for bType, btData in pairs(cData) do
					for bID, bData in pairs(btData) do
						if bData.content then
							for sID, sData in pairs(bData.content) do
								local itemProps = {
									realm = rName;
									character = cName;
									bagType = bType;
									bagIndex = bID;
									slotIndex = sID;
									itemKey = sData.key;
									itemCount = sData.count;
									detail = self.items.details[sData.key] or {};
									soulbound = sData.soulbound;
								}
								itemProps.itemLink = itemProps.detail.link;
								if not itemProps.itemLink then
									_, itemProps.itemLink = GetItemInfo("item:" .. itemProps.itemKey .. ":0");
								end
								if filter(itemProps, filterArg) then
									table.insert(rTable, itemProps);
								end
							end
						end
					end
				end
			end
		end
	end
--[[
	local charName = UnitName("player");
	local charRealm = GetRealmName();
	local charGuild = GetGuildInfo("player");
	
	if realms[charRealm] and realms[charRealm].guilds and realms[charRealm].guilds[charGuild] then
		gData = realms[charRealm].guilds[charGuild];
		if gData.tabs then
			for tabID, tab in pairs(gData.tabs) do
				if tab.content then
					for sID, sData in pairs(tab.content) do
						local itemProps = {
							realm = charRealm;
							character = charName;
							bagType = "Guild Bank";
							bagIndex = tabID;
							slotIndex = sID;
							itemKey = sData.key;
							itemCount = sData.count;
							detail = self.items.details[sData.key] or {};
						}
						itemProps.itemLink = itemProps.detail.link;
						if not itemProps.itemLink then
							_, itemProps.itemLink = GetItemInfo("item:" .. itemProps.itemKey .. ":0");
						end
						if filter(itemProps, filterArg) then
							table.insert(rTable, itemProps);
						end
					end
				end
			end
		end
	end
]]	
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
		table.sort(v, self.SortEmptySlots);
	end
	
	return rVal;
end

function FBoH_ItemDB.SortEmptySlots(a, b)
	return a.restrictionCode < b.restrictionCode;
end

function FBoH_ItemDB:GetItem(bagType, bagID, slotID, itemLink, itemCount, character, realm)
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
	
	local newItem = nil;
	if itemLink then
		newItem = {
			count = itemCount;
			key = self:GetItemKey(itemLink);
		}
		newItem.soulbound = soulbound;
		
		self.items.details = self.items.details or {};
		if self.items.details[newItem.key] == nil then
			local d = {};
			
			d.name, d.link, d.rarity, d.level, d.minlevel, d.type, d.subtype, d.stackcount, d.equiploc, d.texture = GetItemInfo(itemLink);
			if d.name then
				self.items.details[newItem.key] = d;
			end
		end
	end;
	
	local oldItem = self:GetItem(bagType, bagID, slotID, character, realm)
	
	if self:AreSameItem(oldItem, newItem) == true then return end;
	
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

