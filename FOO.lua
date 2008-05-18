-- Looks like they removed AceOO with version 3, so this is
-- just to recreate the functionality we want. We'll call it
-- FeitharOO, or just FOO for short... :-)

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
