local _SafeCall = FBoH._SafeCall;
local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")
local Dewdrop = AceLibrary("Dewdrop-2.0");

FBoH_SetVersion("$Revision$");

local P = {};

function P:BuildDewdropMenuTable(options)
	local rVal = {};
	
	if type(options) ~= "table" then return rVal end;

	_SafeCall(function()
		for _, v in ipairs(options) do
			local newEntry = {};
			newEntry.text = v.name or v.value;
			newEntry.notCheckable = true;
			
			if type(v.value) == "table" then
				newEntry.hasArrow = true;
				newEntry.subMenu = P.BuildDewdropMenuTable(self, v.value);
			else
				newEntry.func = FBoH_FilterButtonArgBtn_SetValue;
				newEntry.arg1 = self;
				newEntry.arg2 = v.value;
			end
			
			table.insert(rVal, newEntry);
		end
	end);
	
	return rVal;
end

local
function GetOptionNameHelper(options, value)
	if type(options) ~= "table" then return nil end;
	
	for _, v in ipairs(options) do
		if type(v.value) == "table" then
			local rVal = GetOptionNameHelper(v.value, value);
			if rVal then return rVal end;
		else
			if v.value == value then
				return v.name or v.value;
			end
		end
	end
	
	return nil;
end

local
function GetOptionName(options, value)
	return GetOptionNameHelper(options, value) or "---";
end

function FBoH_FilterButton_SetFilter(self, filter, parentID, index)
	_SafeCall(function()
		if filter then
			self.parentID = parentID;
			self.parentIndex = index;
		end
		self.filter = filter or self.filter;
		
		local filterDef = FBoH:GetFilter(self.filter.name);
		
		self.fontString:SetText(filterDef.desc or filterDef.name);
		
		local getOptions = filterDef.getOptions;
		if getOptions then
			self.argEdit:Hide();
			self.argButton:Show();
			self.filterOptions = getOptions();
			
			local opt = GetOptionName(self.filterOptions, self.filter.arg);
			self.argButton:SetText(opt);
		else
			self.argEdit:Show();
			self.argButton:Hide();
			self.filterOptions = nil;
			
			self.argEdit:SetText(self.filter.arg or "");
			
			if filterDef.undefined then
				self.argEdit:EnableKeyboard(false);
			else
				self.argEdit:EnableKeyboard(true);
			end
		end
		
		if self.filter.isNot then
			self.notButton:SetText("Not");
		else
			self.notButton:SetText("");
		end
	end);
end

function FBoH_FilterButton_UpdateView(self)
	_SafeCall(function()
		self:GetParent():UpdateView();
	end);
end

function FBoH_FilterButton_DoUpdate(self)
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
					-- cursor is in top half
					self.insertBottom:Hide();

					if (topY - cursorY) < 5 then
						dragData.insert = "above";
						
						self.insertTop:Show();
						self.insertGroup:Hide();
				
						self.fontString:Show();
						if self.filterOptions then
							self.argEdit:Hide();
							self.argButton:Show();
						else
							self.argEdit:Show();
							self.argButton:Hide();
						end
						self.notButton:Show();
					else
						dragData.insert = "group above";
						
						self.insertTop:Hide();
						self.insertGroup:Show();
						self.insertGroup:SetInsertTop(true);
				
						self.fontString:Hide();
						self.argEdit:Hide();
						self.argButton:Hide();
						self.notButton:Hide();
					end
				else
					-- cursor is in bottom half
					self.insertTop:Hide();

					if (cursorY - bottomY) < 5 then
						dragData.insert = "below";
						
						self.insertBottom:Show();
						self.insertGroup:Hide();
				
						self.fontString:Show();
						if self.filterOptions then
							self.argEdit:Hide();
							self.argButton:Show();
						else
							self.argEdit:Show();
							self.argButton:Hide();
						end
						self.notButton:Show();
					else
						dragData.insert = "group below";
						
						self.insertBottom:Hide();
						self.insertGroup:Show();
						self.insertGroup:SetInsertTop(false);
				
						self.fontString:Hide();
						self.argEdit:Hide();
						self.argButton:Hide();
						self.notButton:Hide();
					end
				end
			end
		else
			self.insertTop:Hide();
			self.insertBottom:Hide();
			self.insertGroup:Hide();
			
			self.fontString:Show();
			if self.filterOptions then
				self.argEdit:Hide();
				self.argButton:Show();
			else
				self.argEdit:Show();
				self.argButton:Hide();
			end
			self.notButton:Show();
		end
	end);
end

function FBoH_FilterButton_ReceiveDrag(self, dragData)
	_SafeCall(function()
		if dragData.source.type == "property" then
			local newFilter = {
				name = dragData.source.property;
			};
			
			local f = FBoH:GetFilter(newFilter.name);
			if f.getOptions then
				local opts = f.getOptions();
				while type(opts[1].value) == "table" do
					opts = opts[1].value;
				end
				newFilter.arg = opts[1].value;
			end
			
			if dragData.insert == "above" then
				self:GetParent():InsertFilter(newFilter, self.parentID, self.parentIndex);
			elseif dragData.insert == "below" then
				local index = nil
				if self.parentIndex then index = self.parentIndex + 1 end;
				self:GetParent():InsertFilter(newFilter, self.parentID, index);
			elseif dragData.insert == "group above" then
				self:GetParent():InsertGroup(newFilter, self.parentID, self.parentIndex, true);
			elseif dragData.insert == "group below" then
				self:GetParent():InsertGroup(newFilter, self.parentID, self.parentIndex, false);
			else
				FBoH:Debug("Unknown insert location after drag to filter button: " .. tostring(dragData.insert));
			end
		elseif dragData.source.type == "filter" then
			if not self.isBeingDragged then
				local filter = dragData.source.filter;
				
				local newFilter = {
					name = filter.name;
					arg = filter.arg;
					isNot = filter.isNot;
				}
				
				filter.delete = true;
				
				if dragData.insert == "above" then
					self:GetParent():InsertFilter(newFilter, self.parentID, self.parentIndex);
				elseif dragData.insert == "below" then
					local index = nil
					if self.parentIndex then index = self.parentIndex + 1 end;
					self:GetParent():InsertFilter(newFilter, self.parentID, index);
				elseif dragData.insert == "group above" then
					self:GetParent():InsertGroup(newFilter, self.parentID, self.parentIndex, true);
				elseif dragData.insert == "group below" then
					self:GetParent():InsertGroup(newFilter, self.parentID, self.parentIndex, false);
				else
					FBoH:Debug("Unknown insert location after drag to filter button: " .. tostring(dragData.insert));
				end			
			end
		else
			FBoH:Debug("Unknown drag source type for filter button: " .. tostring(dragData.source.type));
		end
	end);
end

function FBoH_FilterButtonArgBtn_DoClick(self)
	_SafeCall(function()
		local options = self:GetParent().filterOptions;
		local menu = P.BuildDewdropMenuTable(self, options);
		
		Dewdrop:Open(self, 
			'children', function()
				Dewdrop:FeedTable(menu);
			end,
			'point', FBoH.DewdropMenuPoint
		);
	end);
end

function FBoH_FilterButtonArgBtn_SetValue(self, value)
	_SafeCall(function()
		local parent = self:GetParent();
		parent.filter.arg = value;
		parent:UpdateView();
		parent:SetFilter();
		Dewdrop:Close();
	end);
end

