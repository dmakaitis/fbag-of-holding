local L = LibStub("AceLocale-3.0"):GetLocale("FBoH_PeriodicTable")
local PT = LibStub("LibPeriodicTable-3.1")

local function AddSetToOptions(options, set)
	local keys = { strsplit(".", set) };
	local opts = options;
	local lastOpt = nil;
	
	local keySoFar = nil;
	
	-- Don't add anything with "nil" in its name...
	for _, k in ipairs(keys) do
		if (not k) or (k == "nil") then
			return;
		end
	end
	
	for _, k in ipairs(keys) do
		if k and k ~= "nil" then
			if keySoFar then
				keySoFar = keySoFar .. "." .. k;
			else
				keySoFar = k;
			end
			
			local found = nil;
			
			if lastOpt and type(opts) == "string" then
				local v = lastOpt.value;
				lastOpt.value = {};
				opts = lastOpt.value;
				
				table.insert(opts, {
					name = "( General )",
					value = v,
				});
			end
			
			for _, o in ipairs(opts) do
				if o.name == k then
					found = o;
				end
			end
			
			if not found then
				found = {
					name = k;
					value = {
						{
							name = string.format(L["- All %s -"], k);
							value = keySoFar;
						}
					};
				}
				table.insert(opts, found);
			end
			
			lastOpt = found;
			opts = lastOpt.value;
		end
	end
	
	if lastOpt then
		lastOpt.value = set;
	end
end

-------------------------------------------------------------------------------

local periodicTable = {};

periodicTable.name = "FBoH_PeriodicTable";
periodicTable.desc = L["Periodic Table"];
function periodicTable.filter(itemProps, set)
	if PT:ItemInSet(itemProps.itemLink, set) then return true end;
	return false;
end
function periodicTable.getOptions()
	if periodicTable.optionsCache and periodicTable.optionsCache[1].value == L["No Values"] then
		periodicTable.optionsCache = nil;
	end
	if not periodicTable.optionsCache then
		periodicTable.optionsCache = {};
		
		local sets = {};
		for k, _ in pairs(PT.sets) do
			table.insert(sets, k);
		end
		table.sort(sets);
		
		for _, v in ipairs(sets) do
			AddSetToOptions(periodicTable.optionsCache, v);
		end
		
		if #(periodicTable.optionsCache) == 0 then
			periodicTable.optionsCache = {
				{
					value = L["No Values"],
				},
			};
		end
	end
	return periodicTable.optionsCache;
end

FBoH:RegisterProperty(periodicTable);
