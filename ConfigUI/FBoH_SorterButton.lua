local _SafeCall = FBoH._SafeCall;
local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision$");

function FBoH_SorterButton_DoUpdate(self)
	_SafeCall(function()
		local dragData = FBoH_Configure.dragData;
		if dragData and MouseIsOver(self) then
			dragData.target = self;
				
			if not self.isBeingDragged then
				local topY = self:GetTop();
				local bottomY = self:GetBottom();
				local centerY = (topY + bottomY) / 2;
				
				local _, cursorY = GetCursorPosition();
				cursorY = cursorY / UIParent:GetEffectiveScale();
				
				dragData.target = self;
				
				if cursorY > centerY then
					dragData.insert = "above";
					self.insertTop:Show();			
					self.insertBottom:Hide();
				else
					dragData.insert = "below";
					self.insertTop:Hide();		
					self.insertBottom:Show();
				end
			end
		else
			self.insertTop:Hide();
			self.insertBottom:Hide();
		end
	end);
end

function FBoH_SorterButton_ReceiveDrag(self, dragData)
	_SafeCall(function()
		local parent = self:GetParent();
		
		if dragData.source.type == "property" then
			if parent.sorters then
				local newSorter = {
					name = dragData.source.property;
				};
				
				local target = self.index;
				if dragData.insert == "below" then target = target + 1 end;
				
				table.insert(parent.sorters, target, newSorter);
				parent:SetSorters();
				parent:UpdateView();
			end
		elseif dragData.source.type == "sorter" then
			if parent.sorters then
				local source = dragData.source.index;
				local target = self.index;
				if dragData.insert == "below" then target = target + 1 end;

				if source < target then target = target - 1 end;
				
				if source == target then return end;
				
				local sorter = table.remove(parent.sorters, source);
				table.insert(parent.sorters, target, sorter);
				
				parent:SetSorters();
				parent:UpdateView();
			end
		else
			FBoH:Debug("Sorter received unknown drag type: " .. tostring(dragData.source.type));
		end;
	end);
end

function FBoH_SorterButton_SetSorter(self, sorter, index)
	_SafeCall(function()
		if sorter then
			self.index = index;
		end
		self.sorter = sorter or self.sorter;
		
		local sorterDef = FBoH:GetSorter(self.sorter.name);
		
		self.fontString:SetText(sorterDef.desc or sorterDef.name);
		
		if self.sorter.descending == true then
			self.argButton:SetText(L["Descending"]);
		else
			self.argButton:SetText(L["Ascending"]);
		end
	end);
end

function FBoH_SorterButtonArgBtn_DoClick(self)
	_SafeCall(function()
		local sorter = self:GetParent().sorter;
		if sorter.descending == true then
			sorter.descending = nil;
		else
			sorter.descending = true;
		end
		self:GetParent():SetSorter();
		self:GetParent():UpdateView();
	end);
end
