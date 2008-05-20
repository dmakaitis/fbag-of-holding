local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local itemKey = {};

itemKey.name = "Item Key";
itemKey.internal = true;
function itemKey.filter(itemProps, key)
	if itemProps.itemKey == key then
		return true;
	else
		return false;
	end
end

FBoH:RegisterFilter(itemKey);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local character = {};

character.name = "Character";
character.desc = L["Character"];
function character.filter(itemProps, character)
	character = character or ".";
	local rlm, chr = strsplit(".", character);
	
	if (rlm == nil) or (rlm == "") then
		rlm = GetRealmName();
	end
	if (chr == nil) or (chr == "") then
		chr = UnitName("player");
	end
	
	if (chr ~= "*") and (chr ~= itemProps.character) then return false end;
	if (rlm ~= "*") and (rlm ~= itemProps.realm) then return false end;
	
	return true;
end
function character.getOptions()
	local rVal = {
		{
			name = L["Current Character"];
			value = nil;
		},
		{
			name = L["Current Realm"];
			value = ".*";
		},
	};
	
	return rVal;
end
FBoH:RegisterFilter(character);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local itemName = {};

itemName.name = "Item Name";
itemName.desc = L["Item Name"];
function itemName.filter(itemProps, name)
	local _, _, itemName = string.find(itemProps.itemLink, "%[(.+)%]");
	if not itemName then
		FBoH:Print("Failed to get item info for " .. itemProps.itemLink);
		return false;
	end
	
	local n = string.lower(itemName);
	local c = string.lower(name or "");
	
	if string.find(n, c) then
		return true;
	end
	
	return false;
end

FBoH:RegisterFilter(itemName);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local bagIndex = {};

bagIndex.name = "Bag Index";
bagIndex.desc = L["Bag Index"];
function bagIndex.filter(itemProps, bagIndex)
	bagIndex = tonumber(bagIndex) or 1;
	if itemProps.bagIndex == bagIndex then return true end;
	return false;
end
FBoH:RegisterFilter(bagIndex);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local bagType = {};

bagType.name = "Bag Type";
bagType.desc = L["Bag Type"];
function bagType.filter(itemProps, btype)
	btype = btype or "Bags";
	if itemProps.bagType == btype then return true end;
	return false;
end
function bagType.getOptions()
	return {
		{
			name = L["Bags"],
			value = "Bags";
		},
		{
			name = L["Bank"],
			value = "Bank";
		},
		{
			name = L["Keyring"],
			value = "Keyring";
		},
		{
			name = L["Wearing"],
			value = "Wearing";
		},
		{
			name = L["Mailbox"],
			value = "Mailbox";
		},
	};
end
FBoH:RegisterFilter(bagType);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local quality = {};

quality.name = "Quality";
quality.desc = L["Quality"];
function quality.filter(itemProps, quality)
	if not itemProps.detail then return false end;
	quality = tonumber(quality) or 0;
	if itemProps.detail.rarity == quality then return true end;
	return false;
end
function quality.getOptions()
	return {
		{
			name = L["Poor"],
			value = 0;
		},
		{
			name = L["Common"],
			value = 1;
		},
		{
			name = L["Uncommon"],
			value = 2;
		},
		{
			name = L["Rare"],
			value = 3;
		},
		{
			name = L["Epic"],
			value = 4;
		},
		{
			name = L["Legendary"],
			value = 5;
		},
		{
			name = L["Artifact"],
			value = 6;
		},
	};
end
FBoH:RegisterFilter(quality);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- tooltip

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local soulbound = {};

soulbound.name = "Soulbound";
soulbound.desc = L["Soulbound"];
function soulbound.filter(itemProps, bound)
	if bound and itemProps.soulbound then return true end;
	if bound or itemProps.soulbound then return false end;
	return true;
end
function soulbound.getOptions()
	return {
		{
			name = L["Soulbound"],
			value = true;
		},
		{
			name = L["Not Soulbound"],
			value = nil;
		},
	};
end
FBoH:RegisterFilter(soulbound);
