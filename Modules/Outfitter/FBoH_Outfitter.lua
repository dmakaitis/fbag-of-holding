--[[-----------------------------------------------------------------------------
Name: FBoH_Outfitter.lua
Author(s): DJM
-------------------------------------------------------------------------------]]

if Outfitter then

local outfitter = {};

outfitter.name = "FBoH_Outfitter";

outfitter.desc = "Outfitter";


function outfitter.filter(itemProps, outfitName)
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

end

