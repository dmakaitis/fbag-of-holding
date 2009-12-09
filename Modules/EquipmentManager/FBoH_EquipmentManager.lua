--[[-----------------------------------------------------------------------------
Name: FBoH_EquipmentManager.lua
Revision: $Revision$
Author(s): Feithar
Revides: Brandorf
-------------------------------------------------------------------------------]]

local L = LibStub("AceLocale-3.0"):GetLocale("FBoH_EquipmentManager")

local tooltip = CreateFrame("GameTooltip", "FBoH_EquipmentManager_Tooltip");
tooltip:SetOwner( WorldFrame, "ANCHOR_NONE" );
tooltip:AddFontStrings(
    tooltip:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
    tooltip:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ) );

local equipMgr = {};

equipMgr.name = "FBoH_EquipmentManager";

equipMgr.desc = L["Equipment Manager"];

local
function DoCompare(item, itemProps)
	local text, link = GetItemInfo(item);
	if text == itemProps.detail.name then 
		return true
	end
	return false;
end

function equipMgr.filter(itemProps, setName)
	local setCount = GetNumEquipmentSets();
	local name = nil;
	FBoH:Debug("Checking  "..itemProps.detail.name .. " against " .. setCount .. " equipment sets");
	
	for i = 1, setCount do
		name = GetEquipmentSetInfo(i);
		
		if (name == setName) or (setName == "***ALL***") then
			local itemArray = GetEquipmentSetItemIDs(name);
			local numItems = #itemArray
			for line = 1, numItems do
				if DoCompare(itemArray[line], itemProps) then 
					FBoH:Debug("Match found! "..itemArray[line].." in set "..name);
					return true 
				end;
			end
		end
	end

	return false;
end

function equipMgr.getOptions()
	local rVal = {	
		{
			name = L["Any Set"],
			value = "***ALL***",
		},
	};
	
	local setCount = GetNumEquipmentSets();
	local name = nil;
	
	for i = 1, setCount do
		name = GetEquipmentSetInfo(i);
		local entry = {};
		entry.value = name;
		table.insert(rVal, entry);
	end

	table.sort(rVal, function(a, b)
		return a.value < b.value;
	end);

	return rVal;
end

FBoH:RegisterProperty(equipMgr);

