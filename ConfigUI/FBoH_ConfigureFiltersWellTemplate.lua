local _SafeCall = FBoH._SafeCall;
local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision$");

local FBOH_GROUP_FRAME_ID = 1;

local P = {};

function P.BuildFilterSettings(filterDef, settings, group, index)
	settings = settings or {};
	settings.rows = settings.rows or {};
	settings.groups = settings.groups or {};
	
	if not filterDef then return settings end;
	
	_SafeCall(function()
		if filterDef.name == "And" or filterDef.name == "Or" then
			local newGroup = {};
			
			newGroup.filter = filterDef;
			newGroup.parentID = group;
			newGroup.parentIndex = index;
			newGroup.topRow = #(settings.rows) + 1;
			
			local newGroupID = #(settings.groups) + 1;
			
			settings.groups[newGroupID] = newGroup;
			
			for i, v in ipairs(filterDef.arg) do
				P.BuildFilterSettings(v, settings, newGroupID, i);
			end
			
			newGroup.bottomRow = #(settings.rows);
		elseif filterDef.name == "Not" then
			FBoH:Debug("Found 'not' filter");
		else
			local newRow = {};
			
			newRow.filter = filterDef;
			newRow.parentID = group;
			newRow.parentIndex = index;
			
			settings.rows[#(settings.rows) + 1] = newRow;
		end
	end);
	
	return settings;
end

function P.DisplayFilterButtons(parent, offset)
	_SafeCall(function()
		parent.lastRowButton = nil;
		
		for i = 1, 8 do
			local rowID = i + offset;
			local button = _G[parent:GetName() .. "_Button" .. i];
			local row = parent.filterSettings.rows[rowID];
			
			if row then
				button:Show();
				button:SetFilter(row.filter, row.parentID, row.parentIndex);
				parent.lastRowButton = button;
			else
				button:Hide();
			end
		end
	end);
end

function P.GetFrameAnchor(frame, anchor)
	if frame == nil then error("Nil frame passed to GetFrameAnchor", 2) end;
	
	local numPoints = frame:GetNumPoints();
	for i = 1, numPoints do
		local point, relativeTo, relativePoint = frame:GetPoint(i);
		if anchor == point then
			return relativeTo, relativePoint;
		end
	end
	return;
end

function P.ResetButtonPositions(parent)
	_SafeCall(function()
		local leftFrame = parent;
		local leftRelative = "TOPLEFT";
		
		-- Reset the button positions
		for i = 1, 8 do
			local button = _G[parent:GetName() .. "_Button" .. i];
			button:SetPoint("TOPLEFT", leftFrame, leftRelative);
			leftFrame = button;
			leftRelative = "BOTTOMLEFT";		
		end	
	end);
end

function P.SetupGroupFrames(parent, offset)
	-- Set up group frames
	for i, v in ipairs(parent.filterSettings.groups) do
		_SafeCall(function()
			local groupFrame = parent:GetGroupFrame(i);

			local top = v.topRow - offset;
			local bottom = v.bottomRow - offset;
			
			if P.ShouldDrawGroup(top, bottom) then
				local topClosed, bottomClosed = true, true;
				if top < 1 then
					topClosed = false;
					top = 1;
				end
				if bottom > 8 then
					bottomClosed = false;
					bottom = 8;
				end
				
				groupFrame:SetTopClosed(topClosed);
				groupFrame:SetBottomClosed(bottomClosed);
				
				groupFrame:SetHeight(32 * ((bottom - top) + 1));
				
				local button = _G[parent:GetName() .. "_Button" .. top];
				
				local relTo, relPt = P.GetFrameAnchor(button, "TOPLEFT");
				groupFrame:SetPoint("TOPLEFT", relTo, relPt);
				
				button:SetPoint("TOPLEFT", groupFrame, "TOPRIGHT");
				
				if bottom ~= 8 then
					button = _G[parent:GetName() .. "_Button" .. (bottom + 1)];
					button:SetPoint("TOPLEFT", groupFrame, "BOTTOMLEFT");
				end
				
				groupFrame:SetFilter(v.filter);
				
				groupFrame:Show();
			end
		end);
	end
end

function P.ShouldDrawGroup(top, bottom)
	if top > 8 then return false end;
	if bottom < 1 then return false end;
	return (bottom >= 1) or (top <= 8);
end

function FBoH_ConfigureFiltersWellTemplate_DeleteFilter(self, parentID, parentIndex)
	_SafeCall(function()
--		FBoH:Debug("    deleting from parent " .. tostring(parentID) .. " at " .. tostring(parentIndex));

		-- We never delete the root filter...
		if parentID and parentIndex then
			local group = self.filterSettings.groups[parentID];
			local def = group.filter;
			
			table.remove(def.arg, parentIndex);
		
			self:UpdateView();
			self:SetFilters();	
		end
	end);
end

function FBoH_ConfigureFiltersWellTemplate_DoVerticalScroll(self)
	_SafeCall(function()
		local parent = self:GetParent();
		local visibleEntries = 8;
		
		-- Hide all group frames
		for _, v in pairs(parent.groupFrames) do
			v:Hide();
		end
		
		if not parent.filterSettings then
			FauxScrollFrame_Update(self, 0, visibleEntries, self.rowHeight);
			
			for i = 1, 8 do
				local button = _G[parent:GetName() .. "_Button" .. i];
				button:Hide();
			end
			
			return;
		end
		
		local maxEntries = #(parent.filterSettings.rows);
		
		FauxScrollFrame_Update(self, maxEntries, visibleEntries, self.rowHeight);
		local offset = FauxScrollFrame_GetOffset(self) or 0;

		P.ResetButtonPositions(parent);
		P.SetupGroupFrames(parent, offset);
		P.DisplayFilterButtons(parent, offset);
	end);
end

function FBoH_ConfigureFiltersWellTemplate_GetGroupFrame(self, id)
	if not self.groupFrames[id] then
		_SafeCall(function()
			local name = "FBoH_GroupFrame" .. FBOH_GROUP_FRAME_ID;
			FBOH_GROUP_FRAME_ID = FBOH_GROUP_FRAME_ID + 1;
			
			self.groupFrames[id] = CreateFrame("Frame", name, self, "FBoH_GroupTemplate");
		end);
	end
	
	return self.groupFrames[id];
end

function FBoH_ConfigureFiltersWellTemplate_InsertFilter(self, filter, parentID, parentIndex)
--	FBoH:Debug("    inserting in parent " .. tostring(parentID) .. " at " .. tostring(parentIndex));
	_SafeCall(function()
		if parentID then
			local group = self.filterSettings.groups[parentID];
			local def = group.filter;
			
			if parentIndex then
				table.insert(def.arg, parentIndex, filter);
			else
				table.insert(def.arg, filter);
			end
			
			self:UpdateView();
			self:SetFilters();	
		else
			if self.filterSettings.groups[1] then
				self:InsertFilter(filter, 1);
			else
				self:InsertGroup(filter);
			end
		end
	end);
end

function FBoH_ConfigureFiltersWellTemplate_InsertGroup(self, filter, parentID, parentIndex, insertAbove)
--	FBoH:Debug("    Creating group in parent " .. tostring(parentID) .. " at " .. tostring(parentIndex));
	
	_SafeCall(function()
		if parentID then
			local group = self.filterSettings.groups[parentID];
			local def = group.filter;
				
			local newFilter = {};
			newFilter.name = "And";
			newFilter.arg = {}

			
			if insertAbove then
				newFilter.arg[1] = filter;
				newFilter.arg[2] = def.arg[parentIndex];
			else
				newFilter.arg[2] = filter;
				newFilter.arg[1] = def.arg[parentIndex];
			end
			
			def.arg[parentIndex] = newFilter;
		else
			local row = self.filterSettings.rows[1];
			local def = row.filter;
			
			local newFilter = {}
			newFilter.name = def.name;
			newFilter.arg = def.arg;
			newFilter.isNot = def.isNot;
			
			local pair = {
				newFilter,
				filter,
			}
			
			def.name = "And";
			def.arg = pair;
			def.isNot = nil;
		end
		
		self:UpdateView();
		self:SetFilters();	
	end);
end

function FBoH_ConfigureFiltersWellTemplate_ReceiveDrag(self, dragData)
	_SafeCall(function()
		FBoH:Debug("Filter well receiving drag");
	end);
end

function FBoH_ConfigureFiltersWellTemplate_SetFilters(self, filterDef)
	_SafeCall(function()
		self.filterDef = filterDef or self.filterDef;
		
		if self.filterDef == "default" then
			self.defaultString:SetText(L["Default Bag Filter"]);
			self.filterSettings = nil;
		else
			self.defaultString:SetText("");		
			self.filterSettings = P.BuildFilterSettings(self.filterDef);
		end
		
		self.scrollFrame:DoVerticalScroll();
	end);
end

function FBoH_ConfigureFiltersWellTemplate_UpdateView(self)
	_SafeCall(function()
		local tabModel = self:GetParent():GetParent().tabModel;
		tabModel:SetFilter();
		tabModel.viewModel.view:UpdateViewModel();	
		if FBoH_TabModel.defaultTab then
			FBoH_TabModel.defaultTab.viewModel.view:UpdateViewModel(nil, true);
		end
	end);
end

