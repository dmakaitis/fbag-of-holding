local Dewdrop = AceLibrary("Dewdrop-2.0");
local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision: 77 $");

FBoH_QualityColors = {
	{157/255, 157/255, 157/255},
	{255/255, 255/255, 255/255},
	{30/255, 255/255, 0/255},
	{0/255, 112/255, 221/255},
	{163/255, 53/255, 238/255},
	{255/255, 128/255, 0/255}
};

function FBoH_GetChildObjectByID(frame, id)
	local children = { frame:GetChildren(); };
	for _, v in ipairs(children) do
		local i = v:GetID() or 0;
		if i == id then
			return v;
		end
	end	
end

function FBoH_ColumnHeaderTemplate_SetText(header, text)
	local child = header:GetRegions();
	child:SetText(text);	
end

function FBoH_ColumnRowTemplate_SetText(row, text)
	local child = row:GetRegions();
	child:SetText(text);
end

function FBoH_ColumnTemplate_GetHeader(column)
	return FBoH_GetChildObjectByID(column, 1);
end

function FBoH_ColumnTemplate_GetResizeGrip(column)
	return FBoH_GetChildObjectByID(column, 2);
end

function FBoH_ColumnTemplate_GetRow(column, row)
	column.rowFrames = column.rowFrames or {}
	return column.rowFrames[row];
end

function FBoH_ColumnTemplate_HeightChanged(column, newHeight)
	local minWidth, _ = column:GetMinResize();
	local maxWidth, _ = column:GetMaxResize();
	column:SetMinResize(minWidth, arg2);
	column:SetMaxResize(maxWidth, arg2);

	local oldRowCount = column.rowCount or 0;
	column.rowFrames = column.rowFrames or {};
	local rowFrames = column.rowFrames;
	local columnName = column:GetName();
	
	-- Count how many full rows are left, accounting for 30 pixel header
	local newRowCount = math.floor((newHeight - 30) / 20);
	
	column.rowCount = newRowCount;
	
	for i = (#rowFrames + 1), newRowCount do
		rowFrames[i] = CreateFrame("Frame", nil, column, column.rowTemplate);
--		FBoH_ColumnRowTemplate_SetText(rowFrames[i], "Value " .. i);
		rowFrames[i]:SetText("Value " .. i);
		local relativeTo = nil;
		if i == 1 then
			relativeTo = column:GetHeader();
		else
			relativeTo = rowFrames[i - 1];
		end
		rowFrames[i]:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT");
		rowFrames[i]:SetPoint("TOPRIGHT", relativeTo, "BOTTOMRIGHT");
	end
	
	for i, v in ipairs(rowFrames) do
		if i <= newRowCount then
			v:Show();
		else
			v:Hide();
		end
	end
end

function FBoH_ColumnTemplate_SetColumnAttributes(column, attributes)
	attributes = attributes or {};
	
	column:GetHeader():SetText(arributes.name or "Untitled");
end

function FBoH_AltItemButton_DoEnter(self)
	local x;
	x = self:GetRight();
	if ( x >= ( GetScreenWidth() / 2 ) ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
	
	GameTooltip:SetHyperlink(self.item.itemLink);
	
	local alt = self.item.character;
	if self.item.realm ~= GetRealmName() then
		alt = alt .. " (" .. self.item.realm .. ")";
	end
	local line = nil;
	if self.item.bagType == "Bags" then
		line = L["Item in %s's bags"];
	elseif self.item.bagType == "Bank" then
		line = L["Item in %s's bank"];
	elseif self.item.bagType == "Mailbox" then
		line = L["Item in %s's mailbox"];
	elseif self.item.bagType == "Keyring" then
		line = L["Item on %s's keyring"];
	elseif self.item.bagType == "Wearing" then
		line = L["Item worn by %s"];
	else
		line = L["Item on %s"];
	end
	
	line = string.format(line, alt);
	
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine(line, 1, 1, 0);
	GameTooltip:Show();
	
	CursorUpdate();	
end

function FBoH_ListTemplate_ResizeColumnsToFit(list)
	local attribs = list.columnAttributes;
	if attribs == nil then return end;
	
	local width = list:GetWidth();
	
end

function FBoH_ListTemplate_SetColumns(list, columns)
	local numCols = #columns;
	
	local lastColumn = nil;
	
	for i, v in ipairs(columns) do
		local newColumn = list:GetColumn(i) or CreateFrame("Frame", nil, list, "FBoH_ColumnTemplate");
		
		newColumn:GetHeader():SetText(v.name or "Untitled");
		newColumn:SetWidth(v.width or 100);
		newColumn:SetID(i);
		newColumn:GetResizeGrip():Show();
		newColumn.rowTemplate = v.rowTemplate or "FBoH_ColumnRowTemplate";
		
		if i == numCols then
			if lastColumn then
				newColumn:SetPoint("TOPLEFT", lastColumn, "TOPRIGHT");
				newColumn:SetPoint("BOTTOMRIGHT");
			else
				newColumn:SetPoint("TOPLEFT");
				newColumn:SetPoint("BOTTOMRIGHT");
			end
			newColumn:GetResizeGrip():Hide();
		elseif lastColumn then
			newColumn:SetPoint("TOPLEFT", lastColumn, "TOPRIGHT");
			newColumn:SetPoint("BOTTOMLEFT", lastColumn, "BOTTOMRIGHT");
		else
			newColumn:SetPoint("TOPLEFT");
			newColumn:SetPoint("BOTTOMLEFT");
		end
		
		newColumn:Show();
		
		lastColumn = newColumn;
	end
	
	list.columnAttributes = columns;
	list:UpdateColumnResizeLimits();
end

function FBoH_ListTemplate_UpdateColumnResizeLimits(list)
	local totalSize = 0;
	for i, v in ipairs(list.columnAttributes) do
		if i ~= #(list.columnAttributes) then
			totalSize = totalSize + list:GetColumn(i):GetWidth();
		else
			totalSize = totalSize + (v.minWidth or 100);
		end
	end
	
	local listWidth = list:GetWidth();
	
	for i, v in ipairs(list.columnAttributes) do
		local maxWidth = listWidth - (totalSize - list:GetColumn(i):GetWidth());
		
		local column = list:GetColumn(i);
		if column then
			local _, minHeight = column:GetMinResize();
			local _, maxHeight = column:GetMaxResize();
			column:SetMinResize((v.minWidth or 100), minHeight);
			column:SetMaxResize(maxWidth, maxHeight);
		end
	end
end

FBoH_GridItemButtonID = 1;

function FBoH_GridTemplate_CreateItemButton(self)
	local slot = CreateFrame("Button", name, self, "FBoH_GridItemButton");

	slot:Hide()
		
	return slot;
end

function FBoH_GridTemplate_RedrawGrid(self)
	local childIndex = 1;
	local emptyRow = {};
	local viewModel = self:GetViewModel();
	if viewModel == nil then
		return;
	end
	local topRow = viewModel.topRow;
	local bottomRow = topRow + self.gridHeight - 1;

	-- Hide all item buttons...
	for _, v in pairs({ self:GetChildren() }) do
		if v:GetID() ~= 10000 then
			v:Hide();
		end
	end
	
	-- Build row data
	local firstLastRow = nil;
	local firstThisRow = nil;
	local previousButton = nil;
	local button = nil;
	
	for row = topRow, bottomRow do
		local thisRow = self.rowData[row] or emptyRow;
		firstThisRow = nil;
		previousButton = nil;

		for i = 1, self.gridWidth do
			if thisRow[i] then
				button = self:GetItemButton(childIndex) or self:CreateItemButton();
				button:SetID(childIndex);

				if previousButton then
					button:SetPoint("TOPLEFT", previousButton, "TOPRIGHT", self.gridSpacing, 0);					
				else
					if firstLastRow then
						button:SetPoint("TOPLEFT", firstLastRow, "BOTTOMLEFT", 0, -self.gridSpacing);
					else
						button:SetPoint("TOPLEFT", self, "TOPLEFT", 6, -4);
					end
					firstThisRow = button;
				end

				if type(thisRow[i]) == "table" then
					button:SetItem(thisRow[i]);
					button:Show();
				else
					if thisRow[i] > 0 then
						button:SetItem(self.items[thisRow[i]]);
						button:Show();
					else
						button:Hide();
					end
				end
					
				previousButton = button;
			else
				button = self:GetItemButton(childIndex);
				if button then button:Hide() end;
			end

			childIndex = childIndex + 1;
		end

		firstLastRow = firstThisRow;
	end
end

function FBoH_GridTemplate_ResizeGrid(self)
--	FBoH:Print("Sizing grid: " .. self:GetName());

	local width, height = self:GetWidth(), self:GetHeight();
	local buttonWidth, buttonHeight = 37, 37;
	
	self.gridWidth = math.floor((width - 6) / (buttonWidth + self.gridSpacing));
	self.gridHeight = math.floor((height - 4) / (buttonHeight + self.gridSpacing));
	
	self.rowData = {};
	
	local model = self:GetViewModel();
--	FBoH:Print("   Clearing items");
	self.items = {};
	if model then 
--		FBoH:Print("   Retrieving items");
		self.items = model:GetItems();
--		FBoH:Print("   Retrieved " .. #(self.items) .. " items");
		model.topRow = 1;
	end;

	local emptySlots = FBoH:GetEmptySlots();
	
	local row, item = 0, 0;
	local itemIndex = 1;
	local lastBagType, lastChr, lastRlm = nil;
	local chr = UnitName("player");
	local rlm = GetRealmName();
	
	while self.items[itemIndex] do
		local bagType = self.items[itemIndex].bagType;
		
		if (chr ~= self.items[itemIndex].character) or (rlm ~= self.items[itemIndex].realm) then
			bagType = "alt";
		end
		
		if bagType ~= lastBagType then
--			if (chr == lastChr) and (rlm == lastRlm) then
				if model:IsBagTypeVisible(lastBagType) then
					if (lastBagType ~= "Bank") or (FBoH:IsBankOpen() == true) then
						local empty = emptySlots[lastBagType];
						if empty then
							for _, v in ipairs(empty) do
								local newEmpty = {};
								
								newEmpty.isEmpty = true;
								newEmpty.bagType = lastBagType;
								newEmpty.bagIndex = v.firstBagID;
								newEmpty.slotIndex = v.firstSlotID;
								newEmpty.itemCount = v.slotCount;
								newEmpty.restrictionCode = v.restrictionCode;
								
								self.rowData[row] = self.rowData[row] or {};
								self.rowData[row][item] = newEmpty;
								
								item = item + 1;
								if item > self.gridWidth then
									row = row + 1;
									item = 1;
								end
							end
						end
					end
				end
--			end

			if item ~= 1 then
				row = row + 1;
				item = 1;
			end
			lastBagType = bagType;
		end
		lastChr = self.items[itemIndex].character;
		lastRlm = self.items[itemIndex].realm;
		
		if bagType == "alt" or model:IsBagTypeVisible(bagType) then
			self.rowData[row] = self.rowData[row] or {};
			self.rowData[row][item] = itemIndex;
			
			item = item + 1;
			if item > self.gridWidth then
				row = row + 1;
				item = 1;
			end
		else
--			FBoH:Print("Skipping " .. bagType .. " item: " .. self.items[itemIndex].itemLink);
		end
		
		itemIndex = itemIndex + 1;
	end
	
	-- Add empty bag slots for the final bag type.
	if model and model:IsBagTypeVisible(lastBagType) then
		if (lastBagType ~= "Bank") or (FBoH:IsBankOpen() == true) then
			local empty = emptySlots[lastBagType];
			if empty then
				for _, v in ipairs(empty) do
					local newEmpty = {};
					
					newEmpty.isEmpty = true;
					newEmpty.bagType = lastBagType;
					newEmpty.bagIndex = v.firstBagID;
					newEmpty.slotIndex = v.firstSlotID;
					newEmpty.itemCount = v.slotCount;
					newEmpty.restrictionCode = v.restrictionCode;
					
					self.rowData[row] = self.rowData[row] or {};
					self.rowData[row][item] = newEmpty;
					
					item = item + 1;
					if item > self.gridWidth then
						row = row + 1;
						item = 1;
					end
				end
			end
		end
	end
	
--	FBoH:Print("   " .. #(self.rowData) .. " rows to display");
	
	self:DoVerticalScroll();
end

function FBoH_GridTemplate_DoVerticalScroll(self)
	local gridFrame = self:GetParent();
	
	local maxEntries = #(gridFrame.rowData);
	local visibleEntries = gridFrame.gridHeight;
	
	FauxScrollFrame_Update(self, maxEntries, visibleEntries, self:GetRowHeight());
	
	local model = gridFrame:GetViewModel();
	if model then
		local offset = FauxScrollFrame_GetOffset(self) or 0;
--		FBoH:Print("Setting top row offset to " .. offset .. " of " .. maxEntries .. " (" .. visibleEntries .. " visible)");
		model.topRow = 1 + offset;
	end
	
	gridFrame:RedrawGrid();	
end

function FBoH_GridTemplate_OnVerticalScroll()
	FBOH_SCROLL_GRID:DoVerticalScroll();
end

function FBoH_GridListTemplate_GetViewModel(self)
	local view = self:GetParent():GetParent();
	return view.viewModel;
end

function FBoH_BagViewTemplate_UpdateViewModel(self, model, noConfig)
	self.viewModel = model or self.viewModel;
	local tab = self.viewModel.viewDef.activeTab;
	
	local items = FBoH_GetChildObjectByID(self, 1);
	local search = FBoH_GetChildObjectByID(self, 2);
	local list = FBoH_GetChildObjectByID(items, 1);
	local grid = FBoH_GetChildObjectByID(items, 2);

	search:SetText(self.viewModel:GetSearch());
	
	if self.viewModel.viewDef.tabs[tab].viewAsList then
		list:Show();
		grid:Hide();
	else
		list:Hide();
		grid:Show();
	end

	if not noConfig then
		FBoH_Configure:SetModel(self.viewModel);
	end
	
	grid:ResizeGrid();
end

function FBoH_BagViewTemplate_SetScale(self, scale)
	local items = FBoH_GetChildObjectByID(self, 1);
	if items == nil then return end;
	
	local grid = FBoH_GetChildObjectByID(items, 2);
	if grid == nil then return end;
	
	grid:SetScale(scale);
end

function FBoH_ViewTabTemplate_UpdateTabModel(self, model)
	self.tabModel = model or self.tabModel;
	self:SetText(self.tabModel.tabDef.name);
	
--	local text = getglobal(self:GetName().."Text");
--	text:SetText(self.tabModel.tabDef.name);
--	text:SetTextColor(1.0, 1.0, 1.0);
	
--	self.label:SetText(self.tabModel.tabDef.name);
	
	self.dockRegion:ClearAllPoints();
	self.dockRegion:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT");
	
--	PanelTemplates_TabResize(5, self);
	
	-- Is this tab active...
	local tabTexture = nil;
	if self.tabModel.tabIndex == self.tabModel.viewModel.viewDef.activeTab then
--		self:SetTextColor(1, 0.8, 0);
		tabTexture = "Interface\\HelpFrame\\HelpFrameTab-Active";
	else
--		self:SetTextColor(0.7, 0.7, 0.7);
		tabTexture = "Interface\\HelpFrame\\HelpFrameTab-Inactive";
	end
	
	local tabName = self:GetName();
	_G[tabName .. "Left"]:SetTexture(tabTexture);
	_G[tabName .. "Right"]:SetTexture(tabTexture);
	_G[tabName .. "Middle"]:SetTexture(tabTexture);
	
	-- Is this the last tab...
	local nextTab = self.tabModel.viewModel.tabData[self.tabModel.tabIndex + 1];
	if nextTab then
		self.dockRegion:SetPoint("BOTTOMRIGHT", nextTab.button, "BOTTOMLEFT");
	else
		self.dockRegion:SetPoint("BOTTOMRIGHT", self.tabModel.viewModel.view, "TOPRIGHT");
	end
end

function FBoH_ViewTabTemplate_OpenMenu(self)
	local disabled = true;
	if FBoH:CanViewAsList() then disabled = nil end;
	
	Dewdrop:Open(self, 
		'children', function()
			Dewdrop:AddLine(
				'text', L["View as List"],
				'checked', self.tabModel.tabDef.viewAsList,
				'func', function()
					self.tabModel:ToggleList();
					Dewdrop:Close();
				end,
				'disabled', disabled
			);
			Dewdrop:AddLine(
				'text', L["Configure View"] .. ": " .. self:GetText(),
				'func', function()
					FBoH_Configure:SetModel(self.tabModel.viewModel);
					FBoH_Configure:Show();
					Dewdrop:Close();
				end
			);
			Dewdrop:AddSeparator();
			Dewdrop:AddLine(
				'text', L["Create New View"],
				'func', function()
					Dewdrop:Close();
					FBoH:CreateNewView();
				end
			);
			if self.tabModel.tabDef.filter ~= "default" then
				Dewdrop:AddLine(
					'text', L["Delete View"] .. ": " .. self:GetText(),
					'textR', 1, 'textG', 0.2, 'textB', 0.2,
					'func', function()
						Dewdrop:Close();
						FBoH:DeleteViewTab(self.tabModel);
					end
				);
			end
		end,
		'point', FBoH.DewdropMenuPoint
	);
end
