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

FBoH_SetVersion("$Revision$");

-- This bit is to set up unit testing

FBoH_UnitTests = {};

if WoWUnit then

WoWUnit:AddTestSuite("FBoH", FBoH_UnitTests);

end

-- Finally, set our version number

FBoH_SetVersion("$Revision$");
