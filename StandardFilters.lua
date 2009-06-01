local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision$");

-------------------------------------------------------------------------------

local realm = {};

realm.name = "FBoH_Realm";
realm.desc = L["Realm"];
function realm.sortCompare(a, b)
	if a.realm < b.realm then return true else return false end;
end
FBoH:RegisterProperty(realm);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local character = {};

character.name = "Character";
character.desc = L["Character"];
function character.sortCompare(a, b)
	if a.character < b.character then return true else return false end;
end
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

	if FBoH.items and FBoH.items.items and FBoH.items.items.realms then
		local items = FBoH.items.items;
		local realms = {};
		for k, _ in pairs(items.realms) do
			table.insert(realms, k);
		end
		table.sort(realms);
		
		for _, r in ipairs(realms) do
			local subMenu = {
				{
					name = r .. L[" (All)"];
					value = r .. ".*";
				},
			};
			
			local realmChars = items.realms[r].characters;
			local chars = {};
			for k, _ in pairs(realmChars) do
				table.insert(chars, k);
			end
			table.sort(chars);
			
			for _, c in ipairs(chars) do
				table.insert(subMenu, {
					name = c .. " (" .. r .. ")";
					value = r .. "." .. c;
				});
			end
			
			table.insert(rVal, {
				name = r,
				value = subMenu,
			});
		end
	end
	
	return rVal;
end
FBoH:RegisterProperty(character);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local itemName = {};

itemName.name = "Item Name";
itemName.desc = L["Item Name"];
function itemName.sortCompare(a, b)
	if a.detail and a.detail.name and b.detail and b.detail.name then
		if a.detail.name < b.detail.name then return true else return false end;
	else
		if a.itemLink and b.itemLink then
			local _, _, aName = string.find(a.itemLink, "%[(.+)%]");
			local _, _, bName = string.find(b.itemLink, "%[(.+)%]");
			if aName < bName then return true else return false end;
		end
	end
	return false;
end
function itemName.filter(itemProps, name)
	local _, _, itemName = string.find(itemProps.itemLink, "%[(.+)%]");
	if not itemName then
		FBoH:Debug("Failed to get item info for " .. itemProps.itemLink);
		return false;
	end
	
	local n = string.lower(itemName);
	local c = string.lower(name or "");
	
	if string.find(n, c) then
		return true;
	end
	
	return false;
end

FBoH:RegisterProperty(itemName);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local itemTooltip = {};

local tooltip = CreateFrame("GameTooltip", "FBoH_Filter_Tooltip");
tooltip:SetOwner( WorldFrame, "ANCHOR_NONE" );
tooltip:AddFontStrings(
    tooltip:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
    tooltip:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ) );

local
function DoTooltipCompare(line, side, text)
	local mytext = getglobal("FBoH_Filter_TooltipText" .. side .. line);
	if mytext == nil then return false end;
	
	mytext = string.lower(mytext:GetText() or "");
	
	if string.find(mytext, text) then
		return true;
	end
	
	return false;
end

itemTooltip.name = "Tooltip";
itemTooltip.desc = L["Tooltip"];
function itemTooltip.filter(itemProps, text)
	local c = string.lower(text or "");

	tooltip:ClearLines();
	tooltip:SetHyperlink(itemProps.itemLink);

	for line = 1, tooltip:NumLines() do
		if DoTooltipCompare(line, "Left", c) then return true end;
		if DoTooltipCompare(line, "Right", c) then return true end;
	end
	
	return false;
end

FBoH:RegisterProperty(itemTooltip);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local bagIndex = {};

bagIndex.name = "Bag Index";
bagIndex.desc = L["Bag Index"];
function bagIndex.sortCompare(a, b)
	if a.bagIndex < b.bagIndex then return true else return false end;
end
function bagIndex.filter(itemProps, bagIndex)
	bagIndex = tonumber(bagIndex) or 1;
	if itemProps.bagIndex == bagIndex then return true end;
	return false;
end
FBoH:RegisterProperty(bagIndex);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local bagType = {};

bagType.name = "Bag Type";
bagType.desc = L["Bag Type"];
function bagType.sortCompare(a, b)
	if a.bagType < b.bagType then return true else return false end;
end
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
			name = L["Guild Bank"],
			value = "Guild Bank";
		},
		{
			name = L["Keyring"],
			value = "Keyring";
		},
		{
			name = L["Wearing"],
			value = "Wearing";
		},
--		{
--			name = L["Mailbox"],
--			value = "Mailbox";
--		},
	};
end
FBoH:RegisterProperty(bagType);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local quality = {};

quality.name = "Quality";
quality.desc = L["Quality"];
function quality.sortCompare(a, b)
	if a.detail and b.detail then
		if (a.detail.rarity or 0) < (b.detail.rarity or 0) then return true else return false end;
	end
	if a.detail then return true end;
	return false;
end
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
FBoH:RegisterProperty(quality);

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
function soulbound.sortCompare(a, b)
	if a.soulbound and b.soulbound then return false end;
	if a.soulbound then return false end;
	if b.soulbound then return true end;
	return false;
end
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
FBoH:RegisterProperty(soulbound);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local itemSubType = {};

itemSubType.name = "Item Subtype";
itemSubType.desc = L["Item Subtype"];
function itemSubType.sortCompare(a, b)
	if a.detail and b.detail then
		if (a.detail.subtype or "") < (b.detail.subtype or "") then return true else return false end;
	end
	if a.detail then return true end;
	return false;
end
FBoH:RegisterProperty(itemSubType);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local itemType = {};

itemType.name = "Item Type";
itemType.desc = L["Item Type"];
function itemType.sortCompare(a, b)
	if a.detail and b.detail then
		if (a.detail.type or "") < (b.detail.type or "") then return true else return false end;
	end
	if a.detail then return true end;
	return false;
end
function itemType.filter(itemProps, itemType)
	local parts = { strsplit("|", itemType) };
	local iType = parts[1];
	local sType = parts[2];
	
	if not itemProps.detail then return false end;
	
	if iType ~= itemProps.detail.type then return false end;
	if sType == nil then return true end;
	if sType == itemProps.detail.subtype then return true else return false end;
end
function itemType.getOptions()
	local options = {};
	for k, v in pairs(FBoH_ItemTypes) do
		table.insert(options, k);
	end;
	table.sort(options);
	
	local rVal = {}
	for k, v in ipairs(options) do
		local option = {};
		option.name = v;
		local values = {};
		option.value = values;
		
		local suboptions = {};
		for s, _ in pairs(FBoH_ItemTypes[v]) do
			table.insert(suboptions, s);
		end;
		if getn(suboptions) > 1 then
			table.sort(suboptions);
			
			local suboption = {};
			suboption.name = string.format(L["- All %s -"], v);
			suboption.value = v;
			table.insert(values, suboption);
			
			for _, s in ipairs(suboptions) do
				local suboption = {};
				suboption.name = s;
				suboption.value = v .. "|" .. s;
				table.insert(values, suboption);
			end
		else
			option.value = v;
		end
		
		table.insert(rVal, option);
	end;
	return rVal;
end
FBoH:RegisterProperty(itemType);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local equipSlot = {};

equipSlot.name = "Equip Slot";
equipSlot.desc = L["Equip Slot"];
function equipSlot.filter(itemProps, slot)
	local slots = { strsplit("|", slot or "") };
	for _, v in ipairs(slots) do
		if v == itemProps.detail.equiploc then return true end;
	end
	return false;
end
function equipSlot.getOptions()
	return {
		{
			name = L["Not Equipable"],
		},
		{
			value = "INVTYPE_AMMO",
			name = _G["INVTYPE_AMMO"];
		},
		{
			value = "INVTYPE_HEAD",
			name = _G["INVTYPE_HEAD"];
		},
		{
			value = "INVTYPE_NECK",
			name = _G["INVTYPE_NECK"];
		},
		{
			value = "INVTYPE_SHOULDER",
			name = _G["INVTYPE_SHOULDER"];
		},
		{
			value = "INVTYPE_BODY",
			name = _G["INVTYPE_BODY"];
		},
		{
			value = "INVTYPE_CHEST|INVTYPE_ROBE",
			name = _G["INVTYPE_CHEST"];
		},
		{
			value = "INVTYPE_WAIST",
			name = _G["INVTYPE_WAIST"];
		},
		{
			value = "INVTYPE_LEGS",
			name = _G["INVTYPE_LEGS"];
		},
		{
			value = "INVTYPE_FEET",
			name = _G["INVTYPE_FEET"];
		},
		{
			value = "INVTYPE_WRIST",
			name = _G["INVTYPE_WRIST"];
		},
		{
			value = "INVTYPE_HAND",
			name = _G["INVTYPE_HAND"];
		},
		{
			value = "INVTYPE_FINGER",
			name = _G["INVTYPE_FINGER"];
		},
		{
			value = "INVTYPE_TRINKET",
			name = _G["INVTYPE_TRINKET"];
		},
		{
			value = "INVTYPE_CLOAK",
			name = _G["INVTYPE_CLOAK"];
		},
		{
			value = "INVTYPE_WEAPON",
			name = _G["INVTYPE_WEAPON"];
		},
		{
			value = "INVTYPE_2HWEAPON",
			name = _G["INVTYPE_2HWEAPON"];
		},
		{
			value = "INVTYPE_WEAPONMAINHAND",
			name = _G["INVTYPE_WEAPONMAINHAND"];
		},
		{
			value = "INVTYPE_WEAPONOFFHAND|INVTYPE_SHIELD",
			name = _G["INVTYPE_WEAPONOFFHAND"];
		},
		{
			value = "INVTYPE_HOLDABLE",
			name = _G["INVTYPE_HOLDABLE"];
		},
		{
			value = "INVTYPE_RANGED|INVTYPE_RANGEDRIGHT",
			name = _G["INVTYPE_RANGED"];
		},
		{
			value = "INVTYPE_THROWN",
			name = _G["INVTYPE_THROWN"];
		},
		{
			value = "INVTYPE_RELIC",
			name = _G["INVTYPE_RELIC"];
		},
		{
			value = "INVTYPE_TABARD",
			name = _G["INVTYPE_TABARD"];
		},
		{
			value = "INVTYPE_BAG",
			name = _G["INVTYPE_BAG"];
		},
		{
			value = "INVTYPE_QUIVER",
			name = _G["INVTYPE_QUIVER"];
		},
	};
end
FBoH:RegisterProperty(equipSlot);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local lastMoved = {};

local lastMoved_SessionTime = nil;
local lastMoved_Today = nil;
local lastMoved_Yesterday = nil;
local lastMoved_Week = nil;
local lastMoved_Month = nil;

lastMoved.name = "Last Moved";
lastMoved.desc = L["Last Moved"];
function lastMoved.sortCompare(a, b)
	if a.lastUpdate and b.lastUpdate then
		if a.lastUpdate < b.lastUpdate then return true else return false end;
	end
	if b.lastUpdate then return true end;
	return false;
end
function lastMoved.filter(itemProps, timeframe)
	if not itemProps.lastUpdate then return false end;

	if lastMoved_SessionTime ~= FBoH.sessionStartTime then
		lastMoved_SessionTime = FBoH.sessionStartTime;
		
		local hour, minute = GetGameTime();
		
		lastMoved_Today = lastMoved_SessionTime - (hour * 60 * 60) - (minute * 60);
		lastMoved_Yesterday = lastMoved_Today - (24 * 60 * 60);
		lastMoved_Week = lastMoved_Today - (7 * 24 * 60 * 60);
		lastMoved_Month = lastMoved_Today - (30 * 24 * 60 * 60);
	end
	
	local compare = FBoH.sessionStartTime;
	
	if timeframe == "today" then
		compare = lastMoved_Today;
	elseif timeframe == "yesterday" then
		compare = lastMoved_Yesterday;
	elseif timeframe == "week" then
		compare = lastMoved_Week;
	elseif timeframe == "month" then
		compare = lastMoved_Month;
	end
	
	if itemProps.lastUpdate > compare then
		return true;
	else
		return false;
	end
end
function lastMoved.getOptions()
	return {
		{
			name = L["Current Session"],
			value = "session",
		},
		{
			name = L["Today"],
			value = "today",
		},
		{
			name = L["Yesterday"],
			value = "yesterday",
		},
		{
			name = L["Last 7 Days"],
			value = "week",
		},
		{
			name = L["Last 30 Days"],
			value = "month",
		},
	};
end
FBoH:RegisterProperty(lastMoved);
