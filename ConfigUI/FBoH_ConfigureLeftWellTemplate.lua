local _SafeCall = FBoH._SafeCall;
local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision: 96 $");

function FBoH_ConfigureLeftWellTemplate_DoVerticalScroll(self)
	_SafeCall(function()
		local parent = self:GetParent();
		
		local maxEntries = #(parent.choices);
		local visibleEntries = 8;
		
		FauxScrollFrame_Update(self, maxEntries, visibleEntries, self.rowHeight);
		local offset = FauxScrollFrame_GetOffset(self) or 0;

		for i = 1, 8 do
			local choice = parent.choices[i + offset];
			local button = _G[parent:GetName() .. "_Button" .. i];
			
			if choice then
				button:SetProperty(choice.label, choice.key);
				button:Show();
			else
				button:SetProperty();
				button:Hide();
			end
		end
	end);
end

function FBoH_ConfigureLeftWellTemplate_SetChoices(self, choices)
	_SafeCall(function()
		self.choices = choices or self.choices;
		self.scrollFrame:DoVerticalScroll();
	end);
end
