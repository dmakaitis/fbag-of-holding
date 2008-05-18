local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBOH_CONFIG_TITLE = L["Configure Bag View"];
FBOH_CONFIG_FILTERS = L["Filters"];
FBOH_CONFIG_SORTING = L["Sorting"];

FBOH_CONFIG_NAMELABEL = L["Name:"];

function FBoH_ConfigureTabTemplate_DoClick(self)
	local tabID = self:GetID();
	local parent = self:GetParent();
	
	PlaySound("UChatScrollButton");
	parent:ShowTab(tabID);
end

function FBoH_Configure_ShowTab(self, tabID)
	PanelTemplates_SetTab(self, tabID);

	local children = { self:GetChildren() }
	local childID = tabID + 1000;
	
	for _, v in pairs(children) do
		local id = v:GetID();
		if id > 1000 then
			if id == childID then
				v:Show();
			else
				v:Hide();
			end
		end
	end
end

function FBoH_Configure_SetModel(self, viewModel)
	self.viewModel = viewModel or self.viewModel

	if self.viewModel then
		self.tabModel, self.tabDef = viewModel:GetTab();
	else
		self.tabModel = nil;
		self.tabDef = nil;
	end
	
	self.baseOptions:Update();
	self.filtersFrame:SetFilters(viewModel:GetTab().tabDef.filter);
end

function FBoH_Configure_DoShow(self)
	PlaySound("UChatScrollButton");
	self:ShowTab(1);
	
	local filters = FBoH:GetFilters();
	
	self.filtersFrame:SetChoices(filters);
end

function FBoH_Configure_ExecuteDrag(self)
	if not self.dragData then
		return false;
	end
	if (not self.dragData.target) or (not MouseIsOver(self.dragData.target)) then
		return false;
	end
	
	self.dragData.target:ReceiveDrag(self.dragData);
	return true;
end

function FBoH_ConfigureBaseTemplate_Update(self)
	local tabDef = self:GetParent().tabDef;
	if tabDef == nil then return end;
	
	self.nameEdit:SetText(tabDef.name);
end

function FBoH_ConfigureLeftWellTemplate_SetChoices(self, choices)
	self.choices = choices or self.choices;
	self.scrollFrame:DoVerticalScroll();
end

function FBoH_ConfigureLeftWellTemplate_DoVerticalScroll(self)
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
end

function FBoH_Configure_OnVerticalScroll()
	FBOH_SCROLL_FRAME:DoVerticalScroll();
end

local function BuildFilterSettings(filterDef, settings, group, index)
	settings = settings or {};
	settings.rows = settings.rows or {};
	settings.groups = settings.groups or {};
	
	if not filterDef then return settings end;
	
	if filterDef.name == "And" or filterDef.name == "Or" then
		local newGroup = {};
		
		newGroup.filter = filterDef;
		newGroup.parentID = group;
		newGroup.parentIndex = index;
		newGroup.topRow = #(settings.rows) + 1;
		
		local newGroupID = #(settings.groups) + 1;
		
		settings.groups[newGroupID] = newGroup;
		
		for i, v in ipairs(filterDef.arg) do
			BuildFilterSettings(v, settings, newGroupID, i);
		end
		
		newGroup.bottomRow = #(settings.rows);
	elseif filterDef.name == "Not" then
		FBoH:Print("Found 'not' filter");
	else
		local newRow = {};
		
		newRow.filter = filterDef;
		newRow.parentID = group;
		newRow.parentIndex = index;
		
		settings.rows[#(settings.rows) + 1] = newRow;
	end
	
	return settings;
end

local FBOH_GROUP_FRAME_ID = 1;

function FBoH_ConfigureFiltersWellTemplate_GetGroupFrame(self, id)
	if not self.groupFrames[id] then
		local name = "FBoH_GroupFrame" .. FBOH_GROUP_FRAME_ID;
		FBOH_GROUP_FRAME_ID = FBOH_GROUP_FRAME_ID + 1;
		
		self.groupFrames[id] = CreateFrame("Frame", name, self, "FBoH_GroupTemplate");
	end
	
	return self.groupFrames[id];
end

function FBoH_ConfigureFiltersWellTemplate_SetFilters(self, filterDef)
	self.filterDef = filterDef or self.filterDef;
	
	if self.filterDef == "default" then
		self.defaultString:SetText(L["Default Bag Filter"]);
		self.filterSettings = nil;
	else
		self.defaultString:SetText("");		
		self.filterSettings = BuildFilterSettings(self.filterDef);
	end
	
	self.scrollFrame:DoVerticalScroll();
end

local function GetFrameAnchor(frame, anchor)
	local numPoints = frame:GetNumPoints();
	for i = 1, numPoints do
		point, relativeTo, relativePoint = frame:GetPoint(i);
		if anchor == point then
			return relativeTo, relativePoint;
		end
	end
	return
end

function FBoH_ConfigureFiltersWellTemplate_DoVerticalScroll(self)
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
	
	local maxEntries = #(parent.filterSettings.rows) + 1;
	
	FauxScrollFrame_Update(self, maxEntries, visibleEntries, self.rowHeight);
	local offset = FauxScrollFrame_GetOffset(self) or 0;

	local leftFrame = parent;
	local leftRelative = "TOPLEFT";
	
	-- Reset the button positions
	for i = 1, 8 do
		local button = _G[parent:GetName() .. "_Button" .. i];
		button:SetPoint("TOPLEFT", leftFrame, leftRelative);
		leftFrame = button;
		leftRelative = "BOTTOMLEFT";		
	end
	
	-- Set up group frames
	for i, v in ipairs(parent.filterSettings.groups) do
		local groupFrame = parent:GetGroupFrame(i);

		local top = v.topRow - offset;
		local bottom = v.bottomRow - offset;
		
		if (bottom >= 1) or (top <= 8) then
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
			
			local relTo, relPt = GetFrameAnchor(button, "TOPLEFT");
			groupFrame:SetPoint("TOPLEFT", relTo, relPt);
			
			button:SetPoint("TOPLEFT", groupFrame, "TOPRIGHT");
			
			if bottom ~= 8 then
				button = _G[parent:GetName() .. "_Button" .. (bottom + 1)];
				button:SetPoint("TOPLEFT", groupFrame, "BOTTOMLEFT");
			end
			
			groupFrame:SetFilter(v.filter);
			
			groupFrame:Show();
		end
	end
	
	parent.lastRowButton = nil;
	
	-- Go through all the rows and set up groups and positions...
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
end

function FBoH_ConfigureFiltersWellTemplate_ReceiveDrag(self, dragData)
	FBoH:Print("Filter well receiving drag");
end

function FBoH_ConfigureFiltersWellTemplate_DeleteFilter(self, parentID, parentIndex)
--	FBoH:Print("    deleting from parent " .. tostring(parentID) .. " at " .. tostring(parentIndex));

	-- We never delete the root filter...
	if parentID and parentIndex then
		local group = self.filterSettings.groups[parentID];
		local def = group.filter;
		
		table.remove(def.arg, parentIndex);
	
		self:UpdateView();
		self:SetFilters();	
	end
end

function FBoH_ConfigureFiltersWellTemplate_InsertFilter(self, filter, parentID, parentIndex)
--	FBoH:Print("    inserting in parent " .. tostring(parentID) .. " at " .. tostring(parentIndex));
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
end

function FBoH_ConfigureFiltersWellTemplate_InsertGroup(self, filter, parentID, parentIndex, insertAbove)
--	FBoH:Print("    Creating group in parent " .. tostring(parentID) .. " at " .. tostring(parentIndex));
	
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
end

function FBoH_ConfigureFiltersWellTemplate_UpdateView(self)
	local tabModel = self:GetParent():GetParent().tabModel;
	tabModel:SetFilter();
	tabModel.viewModel.view:UpdateViewModel();	
	if FBoH_TabModel.defaultTab then
		FBoH_TabModel.defaultTab.viewModel.view:UpdateViewModel(nil, true);
	end
end

function FBoH_GroupTemplate_SetFilter(self, filter)
	self.filter = filter or self.filter;
	
	self.typeButton:SetText(self.filter.name);
	if self.filter.isNot then
		self.notButton:SetText("Not");
	else
		self.notButton:SetText("");
	end
end

function FBoH_GroupTemplate_UpdateView(self)
	self:GetParent():UpdateView();
end

function FBoH_FilterButton_SetFilter(self, filter, parentID, index)
	if filter then
		self.parentID = parentID;
		self.parentIndex = index;
	end
	self.filter = filter or self.filter;
	
	self.fontString:SetText(self.filter.name);
	self.argEdit:SetText(self.filter.arg or "");
	
	if self.filter.isNot then
		self.notButton:SetText("Not");
	else
		self.notButton:SetText("");
	end
end

function FBoH_FilterButton_UpdateView(self)
	self:GetParent():UpdateView();
end

function FBoH_FilterButton_DoUpdate(self)
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
					self.argEdit:Show();
					self.notButton:Show();
				else
					dragData.insert = "group above";
					
					self.insertTop:Hide();
					self.insertGroup:Show();
					self.insertGroup:SetInsertTop(true);
			
					self.fontString:Hide();
					self.argEdit:Hide();
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
					self.argEdit:Show();
					self.notButton:Show();
				else
					dragData.insert = "group below";
					
					self.insertBottom:Hide();
					self.insertGroup:Show();
					self.insertGroup:SetInsertTop(false);
			
					self.fontString:Hide();
					self.argEdit:Hide();
					self.notButton:Hide();
				end
			end
		end
	else
		self.insertTop:Hide();
		self.insertBottom:Hide();
		self.insertGroup:Hide();
		
		self.fontString:Show();
		self.argEdit:Show();
		self.notButton:Show();
	end
end

function FBoH_FilterButton_ReceiveDrag(self, dragData)
	if dragData.source.type == "property" then
		local newFilter = {
			name = dragData.source.property;
		};
		
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
			FBoH:Print("Unknown insert location after drag to filter button: " .. tostring(dragData.insert));
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
				FBoH:Print("Unknown insert location after drag to filter button: " .. tostring(dragData.insert));
			end			
		else
			FBoH:Print("Moved self to self - nothing to do");
		end
	else
		FBoH:Print("Unknown drag source type for filter button: " .. tostring(dragData.source.type));
	end
end
