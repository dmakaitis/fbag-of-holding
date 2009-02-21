local _SafeCall = FBoH._SafeCall;
local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision$");

function FBoH_GroupTemplate_SetFilter(self, filter)
	_SafeCall(function()
		self.filter = filter or self.filter;
		
		self.typeButton:SetText(self.filter.name);
		if self.filter.isNot then
			self.notButton:SetText("Not");
		else
			self.notButton:SetText("");
		end
	end);
end

function FBoH_GroupTemplate_UpdateView(self)
	_SafeCall(function()
		self:GetParent():UpdateView();
	end);
end

