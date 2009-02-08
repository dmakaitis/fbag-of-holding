-- Looks like they removed AceOO with version 3, so this is
-- just to recreate the functionality we want. We'll call it
-- FeitharOO, or just FOO for short... :-)

-- This first bit is to help us keep track of the current revision number

local FBoH_Version = nil;

function FBoH_SetVersion(revision)
	local _, rev = strsplit(" ", revision);
	rev = tonumber(rev);
	
	FBoH_Version = FBoH_Version or rev;
	if rev > FBoH_Version then
		FBoH_Version = rev;
	end
end

function FBoH_GetVersion()
	return FBoH_Version;
end

FBoH_SetVersion("$Revision: 11 $");

-- The rest of this is for FOO propert

FOO = {};

local function FOO_New(self, ...)
	local rVal = {};
	
	for k, v in pairs(self.prototype) do
		rVal[k] = v;
	end
	
	rVal:init(...);
	
	return rVal;
end

function FOO.Class()
	local rVal = {};
	rVal.prototype = {};
	rVal.new = FOO_New;
	setmetatable(rVal, { __call = rVal.new } );
	return rVal;
end
