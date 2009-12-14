--[[-----------------------------------------------------------------------------
Name: FBoH_Outfitter.lua
Author(s): DJM
-------------------------------------------------------------------------------]]

if Outfitter then

local outfitter = {};

local outfitterInitialized = false;

outfitter.name = "FBoH_Outfitter";

outfitter.desc = "Outfitter";


function outfitter.filter(itemProps, outfitName)
	if(outfitterInitialized == false) then return false end;
	
	local outfitsForItem = Outfitter:GetOutfitsUsingItem(Outfitter:GetItemInfoFromLink(itemProps.itemLink))
	if outfitsForItem then
		if outfitName == "***ALL***" then return true end
		for _, outfit in ipairs(outfitsForItem) do
			if outfitName == outfit.Name then return true end
		end
	end

	return false
end

function outfitter.getOptions()
	local rVal = {	
		{
			name = "Any Set",
			value = "***ALL***",
		},
	};
	
	if(outfitterInitialized == false) then return rVal end;
	
	local outfits = Outfitter.Settings.Outfits;
	if not outfits then return rVal end;
	
	for name, v in pairs(outfits) do
		for _, outfit in ipairs(v) do
			local entry = {};
			entry.value = outfit.Name;
			table.insert(rVal, entry);
		end
	end
	
	table.sort(rVal, function(a, b)
		return a.value < b.value;
	end);
	
	return rVal;
end

FBoH:RegisterProperty(outfitter);

local
function HandleOutfitterEvent(pEvent, pParameter1, pParameter2)
	FBoH:Debug("Received Outfitter Event: " .. pEvent);
	if(pEvent == "OUTFITTER_INIT") then
		outfitterInitialized = true;
	end;
	FBoH:UpdateBags();
end

Outfitter:RegisterOutfitEvent("OUTFITTER_INIT", HandleOutfitterEvent);
Outfitter:RegisterOutfitEvent("WEAR_OUTFIT", HandleOutfitterEvent);
Outfitter:RegisterOutfitEvent("UNWEAR_OUTFIT", HandleOutfitterEvent);
Outfitter:RegisterOutfitEvent("ADD_OUTFIT", HandleOutfitterEvent);
Outfitter:RegisterOutfitEvent("DELETE_OUTFIT", HandleOutfitterEvent);
Outfitter:RegisterOutfitEvent("EDIT_OUTFIT", HandleOutfitterEvent);

end

