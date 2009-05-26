--[[-----------------------------------------------------------------------------
Name: FBoH_EquipmentManager.lua
Revision: $Revision$
Author(s): Feithar
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
function DoCompare(line, side, itemProps)
	local mytext = getglobal("FBoH_EquipmentManager_TooltipText" .. side .. line)
	local text = mytext:GetText()
	if type(text) == "string" then
		if text == itemProps.detail.name then 
			return true
		end;
	end;
	return false;
end

function equipMgr.filter(itemProps, setName)
	local setCount = GetNumEquipmentSets();
	local name = nil;
	
	for i = 1, setCount do
		name = GetEquipmentSetInfo(i);
		
		if (name == setName) or (setName == "***ALL***") then
			tooltip:ClearLines();
			tooltip:SetEquipmentSet(name);
			
			for line = 1, tooltip:NumLines() do
				if DoCompare(line, "Left", itemProps) then return true end;
				if DoCompare(line, "Right", itemProps) then return true end;
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

