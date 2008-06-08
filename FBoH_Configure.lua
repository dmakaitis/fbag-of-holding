local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")
local Dewdrop = AceLibrary("Dewdrop-2.0");

FBoH_SetVersion("$Revision$");
FBoH_SetVersion = nil;

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
	self.sortersFrame:SetSorters(viewModel:GetTab().tabDef.sort);
end

function FBoH_Configure_DoShow(self)
	PlaySound("UChatScrollButton");
	self:ShowTab(1);
	
	self.filtersFrame:SetChoices(FBoH:GetFilters());
	self.sortersFrame:SetChoices(FBoH:GetSorters());
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
	
	local maxEntries = #(parent.filterSettings.rows);
	
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

local function GetOptionNameHelper(options, value)
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

local function GetOptionName(options, value)
	return GetOptionNameHelper(options, value) or "---";
end

function FBoH_FilterButton_SetFilter(self, filter, parentID, index)
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
end

function FBoH_FilterButton_ReceiveDrag(self, dragData)
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
		end
	else
		FBoH:Print("Unknown drag source type for filter button: " .. tostring(dragData.source.type));
	end
end

function FBoH_FilterButtonArgBtn_SetValue(self, value)
	local parent = self:GetParent();
	parent.filter.arg = value;
	parent:UpdateView();
	parent:SetFilter();
	Dewdrop:Close();
end

local function BuildDewdropMenuTable(self, options)
	local rVal = {};
	
	if type(options) ~= "table" then return rVal end;
	
	for _, v in ipairs(options) do
		local newEntry = {};
		newEntry.text = v.name or v.value;
		newEntry.notCheckable = true;
		
		if type(v.value) == "table" then
			newEntry.hasArrow = true;
			newEntry.subMenu = BuildDewdropMenuTable(self, v.value);
		else
			newEntry.func = FBoH_FilterButtonArgBtn_SetValue;
			newEntry.arg1 = self;
			newEntry.arg2 = v.value;
		end
		
		table.insert(rVal, newEntry);
	end
	
	return rVal;
end

function FBoH_FilterButtonArgBtn_DoClick(self)
	local options = self:GetParent().filterOptions;
	local menu = BuildDewdropMenuTable(self, options);
	
	Dewdrop:Open(self, 
		'children', function()
			Dewdrop:FeedTable(menu);
		end,
		'point', FBoH.DewdropMenuPoint
	);
end

function FBoH_ConfigureSortersWellTemplate_SetSorters(self, sorters)
	self.sorters = sorters or self.sorters;
	
	if #(self.sorters) == 0 then
		self.defaultString:SetText(L["Sorters Help"]);
	else
		self.defaultString:SetText("");		
	end
	
	self.scrollFrame:DoVerticalScroll();
end

function FBoH_ConfigureSortersWellTemplate_DoVerticalScroll(self)
	local parent = self:GetParent();
	local visibleEntries = 8;
	
	if not parent.sorters then
		FauxScrollFrame_Update(self, 0, visibleEntries, self.rowHeight);
		
		for i = 1, 8 do
			local button = _G[parent:GetName() .. "_Button" .. i];
			button:Hide();
		end
		
		return;
	end
	
	local maxEntries = #(parent.sorters);
	
	FauxScrollFrame_Update(self, maxEntries, visibleEntries, self.rowHeight);
	local offset = FauxScrollFrame_GetOffset(self) or 0;
	
	parent.lastRowButton = nil;
	
	-- Go through all the rows and set up groups and positions...
	for i = 1, 8 do
		local rowID = i + offset;
		local button = _G[parent:GetName() .. "_Button" .. i];
		local sorter = parent.sorters[rowID];
		
		if sorter then
			button:Show();
			button:SetSorter(parent.sorters[rowID], rowID);
			parent.lastRowButton = button;
		else
			button:Hide();
		end
	end
end

function FBoH_ConfigureSortersWellTemplate_ReceiveDrag(self, dragData)
	if dragData.source.type == "property" then
		if self.sorters then
			local newSorter = {
				name = dragData.source.property;
			};
			table.insert(self.sorters, newSorter);
			self:SetSorters();
			self:UpdateView();
		end
	elseif dragData.source.type == "sorter" then
		if self.sorters then
			local sorter = table.remove(self.sorters, dragData.source.index);
			table.insert(self.sorters, sorter);
			self:SetSorters();
			self:UpdateView();
		end
	else
		FBoH:Print("Sorter well received unknown drag type: " .. tostring(dragData.source.type));
	end;
end

function FBoH_ConfigureSortersWellTemplate_UpdateView(self)
	local tabModel = self:GetParent():GetParent().tabModel;
	tabModel:SetSorting();
	tabModel.viewModel.view:UpdateViewModel();	
	if FBoH_TabModel.defaultTab then
		FBoH_TabModel.defaultTab.viewModel.view:UpdateViewModel(nil, true);
	end
end

function FBoH_ConfigureSortersWellTemplate_DeleteSorter(self, index)
	if self.sorters then
		table.remove(self.sorters, index);
		self:SetSorters();
		self:UpdateView();
	end
end

function FBoH_ConfigureSortersWellTemplate_InsertSorter(self, sorter, index)
	if self.sorters then
		table.insert(self.sorters, index, sorter);
		self:SetSorters();
		self:UpdateView();
	end
end

function FBoH_SorterButton_DoUpdate(self)
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
end

function FBoH_SorterButton_ReceiveDrag(self, dragData)
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
		FBoH:Print("Sorter received unknown drag type: " .. tostring(dragData.source.type));
	end;
end

function FBoH_SorterButton_SetSorter(self, sorter, index)
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
end

function FBoH_SorterButtonArgBtn_DoClick(self)
	local sorter = self:GetParent().sorter;
	if sorter.descending == true then
		sorter.descending = nil;
	else
		sorter.descending = true;
	end
	self:GetParent():SetSorter();
	self:GetParent():UpdateView();
end
