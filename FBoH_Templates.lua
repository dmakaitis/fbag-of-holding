local Dewdrop = AceLibrary("Dewdrop-2.0");
local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision$");

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

function FBoH_BankItemButton_DoClick(self, button)
	if FBoH:IsBankOpen() == false then return end;

	if ( button == "LeftButton" ) then
		PickupContainerItem(self.containerID, self.slotID);
	else
		UseContainerItem(self.containerID, self.slotID);
	end	
end

function FBoH_BankItemButton_DoEnter(self)
	local x;
	x = self:GetRight();
	if ( x >= ( GetScreenWidth() / 2 ) ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
	
	GameTooltip:SetHyperlink(self.item.itemLink);
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine(L["Item in bank"], 1, 0, 0);
	GameTooltip:Show();
	
	CursorUpdate();	
end

function FBoH_BankItemButton_DoModifiedClick(self, button)
	HandleModifiedItemClick(self.item.itemLink);
end
--[[
function FBoH_GuildBankItemButton_DoClick(self, button)
	if FBoH:IsBankOpen() == false then return end;

	if ( button == "LeftButton" ) then
		PickupContainerItem(self.containerID, self.slotID);
	else
		UseContainerItem(self.containerID, self.slotID);
	end	
end
]]
function FBoH_GuildBankItemButton_DoEnter(self)
	local x;
	x = self:GetRight();
	if ( x >= ( GetScreenWidth() / 2 ) ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
	
	GameTooltip:SetHyperlink(self.item.itemLink);
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine(L["Item in guild bank"], 1, 0, 0);
	GameTooltip:Show();
	
	CursorUpdate();	
end

function FBoH_GuildBankItemButton_DoModifiedClick(self, button)
	HandleModifiedItemClick(self.item.itemLink);
end

function FBoH_EmptyItemButton_DoEnter(self)
	local x;
	x = self:GetRight();
	if ( x >= ( GetScreenWidth() / 2 ) ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end

	if self.item.restrictionCode == 0 then
		GameTooltip:SetText(tostring(self.item.itemCount) .. " Empty General Slots (" .. self.item.bagType .. ")");
	else
		GameTooltip:SetText(tostring(self.item.itemCount) .. " Empty Restricted Slots (" .. self.item.bagType .. ")");
		GameTooltip:AddLine(" ");
		
		if self.itemRestrictions == nil then
			local ir = {};

			if bit.band(self.item.restrictionCode, 1) > 0 then table.insert(ir, "Arrows") end;
			if bit.band(self.item.restrictionCode, 2) > 0 then table.insert(ir, "Bullets") end;
			if bit.band(self.item.restrictionCode, 4) > 0 then table.insert(ir, "Soul Shards") end;
			if bit.band(self.item.restrictionCode, 8) > 0 then table.insert(ir, "Leatherworking Supplies") end;
			if bit.band(self.item.restrictionCode, 16) > 0 then table.insert(ir, "Unknown 16") end;
			if bit.band(self.item.restrictionCode, 32) > 0 then table.insert(ir, "Herbs") end;
			if bit.band(self.item.restrictionCode, 64) > 0 then table.insert(ir, "Enchanting Supplies") end;
			if bit.band(self.item.restrictionCode, 128) > 0 then table.insert(ir, "Engineering Supplies") end;
			if bit.band(self.item.restrictionCode, 256) > 0 then table.insert(ir, "Keyring") end;
			if bit.band(self.item.restrictionCode, 512) > 0 then table.insert(ir, "Gems") end;
			if bit.band(self.item.restrictionCode, 1024) > 0 then table.insert(ir, "Mining Supplies") end;
			if bit.band(self.item.restrictionCode, 2048) > 0 then table.insert(ir, "Unknown 2048") end;
			if bit.band(self.item.restrictionCode, 4096) > 0 then table.insert(ir, "Vanity Pets") end;		
			if bit.band(self.item.restrictionCode, 4096) > 0 then table.insert(ir, "Vanity Pets") end;		

			self.itemRestrictions = ir;
		end
		
		for _, v in ipairs(self.itemRestrictions) do
			GameTooltip:AddLine(v, 1, 0, 0);
		end
	end
	
	GameTooltip:Show();
	
	CursorUpdate();	
end

function FBoH_EmptyItemButton_DoClick(self, button)
	PickupContainerItem(self.containerID, self.slotID);
end

function FBoH_ItemButtonTemplate_OnClick(btn, button)
	if ( button == "LeftButton" ) then
		if ( not IsModifierKeyDown() ) then
			if ( SpellCanTargetItem() ) then
				-- Target the spell with the selected item
				UseContainerItem(btn.fbohBagID, btn.fbohSlotID);
			else
				PickupContainerItem(btn.fbohBagID, btn.fbohSlotID);
			end
			StackSplitFrame:Hide();
		end
	else
		if ( MerchantFrame:IsShown() and MerchantFrame.selectedTab == 2 ) then
			-- Don't sell the item if the buyback tab is selected
			return;
		end
		if ( MerchantFrame:IsShown() and IsShiftKeyDown() ) then
			this.SplitStack = function(button, split)
				SplitContainerItem(button.fbohBagID, button.fbohSlotID, split);
				MerchantItemButton_OnClick("LeftButton");
			end
			OpenStackSplitFrame(this.count, this, "BOTTOMRIGHT", "TOPRIGHT");
		else
			-- Shift-click is used for auto-looting and socketing
			UseContainerItem(btn.fbohBagID, btn.fbohSlotID);
			StackSplitFrame:Hide();
		end
	end
end

function FBoH_ItemButtonTemplate_OnEnter(button)
	local x;
	x = button:GetRight();
	if ( x >= ( GetScreenWidth() / 2 ) ) then
		GameTooltip:SetOwner(button, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
	end

	-- Keyring specific code
	if ( button.fbohBagID == KEYRING_CONTAINER ) then
		GameTooltip:SetInventoryItem("player", KeyRingButtonIDToInvSlotID(button:GetID()));
		CursorUpdate();
		return;
	end

	local hasCooldown, repairCost = GameTooltip:SetBagItem(button.fbohBagID, button.fbohSlotID);
	if ( IsShiftKeyDown() ) then
		GameTooltip_ShowCompareItem();
	end

	if ( hasCooldown ) then
		button.updateTooltip = TOOLTIP_UPDATE_TIME;
	else
		button.updateTooltip = nil;
	end

	if ( InRepairMode() and (repairCost and repairCost > 0) ) then
		GameTooltip:AddLine(REPAIR_COST, "", 1, 1, 1);
		SetTooltipMoney(GameTooltip, repairCost);
		GameTooltip:Show();
	elseif ( IsControlKeyDown() and button.hasItem ) then
		ShowInspectCursor();
	elseif ( MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1 ) then
		ShowContainerSellCursor(button.fbohBagID, button.fbohSlotID);
	elseif ( button.readable ) then
		ShowInspectCursor();
	else
		ResetCursor();
	end
end

function FBoH_ItemButtonTemplate_OnModifiedClick(btn, button)
	if ( button == "LeftButton" ) then
		if ( IsControlKeyDown() ) then
			DressUpItemLink(GetContainerItemLink(btn.fbohBagID, btn.fbohSlotID));
		elseif ( IsShiftKeyDown() ) then
			if ( not ChatEdit_InsertLink(GetContainerItemLink(btn.fbohBagID, btn.fbohSlotID)) ) then
				local texture, itemCount, locked = GetContainerItemInfo(btn.fbohBagID, btn.fbohSlotID);
				if ( not locked ) then
					this.SplitStack = function(button, split)
						SplitContainerItem(btn.fbohBagID, btn.fbohSlotID, split);
					end
					OpenStackSplitFrame(this.count, this, "BOTTOMRIGHT", "TOPRIGHT");
				end
			end
		end
	end
end

function FBoH_ItemButtonTemplate_OnUpdate(btn, elapsed)
	if ( this.updateTooltip ) then
		this.updateTooltip = this.updateTooltip - elapsed;
		if ( this.updateTooltip > 0 ) then
			return;
		end
	end

	if ( GameTooltip:IsOwned(this) ) then
		btn:DoEnter();
	end
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

FBoH_GridAltItemButtonID = 1;

function FBoH_GridItemButton_GetAltItemFrame(self)
	if self.altItemFrame == nil then
		local name = "FBoH_GridAltItemButton_" .. FBoH_GridAltItemButtonID;
		FBoH_GridAltItemButtonID = FBoH_GridAltItemButtonID + 1;
	
		local aFrame = CreateFrame("Button", name, self, "FBoH_AltItemButton");
		aFrame:SetPoint("TOPLEFT");
		aFrame:SetPoint("BOTTOMRIGHT");

		aFrame.tex = _G[name .. "IconTexture"];
		aFrame.tex:SetPoint("TOPLEFT", aFrame);
		aFrame.tex:SetPoint("BOTTOMRIGHT", aFrame);
		
		aFrame.normal_tex = aFrame:GetNormalTexture();
		aFrame.normal_tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		aFrame.normal_tex:SetBlendMode("ADD")
		aFrame.normal_tex:SetAlpha(0.65)
		aFrame.normal_tex:SetPoint("CENTER", aFrame, "CENTER", 1, 0)
		aFrame.normal_tex:Show()
		
		aFrame:Show();
		
		aFrame.highlight = CreateFrame("Model", name .. "Highlighter", aFrame)
		aFrame.highlight:Hide()
		aFrame.highlight:SetModel("Interface\Buttons\UI-AutoCastButton.mdx")
		aFrame.highlight:SetModelScale(1.2)
		aFrame.highlight:SetAllPoints()
		aFrame.highlight:SetSequence(0)
		aFrame.highlight:SetSequenceTime(0, 0)

		self.altItemFrame = aFrame;
	end
	return self.altItemFrame;
end

FBoH_GridBankItemButtonID = 1;

function FBoH_GridItemButton_GetBankItemFrame(self)
	if self.bankItemFrame == nil then
		local name = "FBoH_GridBankItemButton_" .. FBoH_GridBankItemButtonID;
		FBoH_GridBankItemButtonID = FBoH_GridBankItemButtonID + 1;
	
		local bFrame = CreateFrame("Button", name, self, "FBoH_BankItemButton");
		bFrame:SetPoint("TOPLEFT");
		bFrame:SetPoint("BOTTOMRIGHT");

		bFrame.tex = _G[name .. "IconTexture"];
		bFrame.tex:SetPoint("TOPLEFT", bFrame);
		bFrame.tex:SetPoint("BOTTOMRIGHT", bFrame);
		
		bFrame.normal_tex = bFrame:GetNormalTexture();
		bFrame.normal_tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		bFrame.normal_tex:SetBlendMode("ADD")
		bFrame.normal_tex:SetAlpha(0.65)
		bFrame.normal_tex:SetPoint("CENTER", bFrame, "CENTER", 1, 0)
		bFrame.normal_tex:Show()
		
		bFrame:Show();
		
		bFrame.highlight = CreateFrame("Model", name .. "Highlighter", bFrame)
		bFrame.highlight:Hide()
		bFrame.highlight:SetModel("Interface\Buttons\UI-AutoCastButton.mdx")
		bFrame.highlight:SetModelScale(1.2)
		bFrame.highlight:SetAllPoints()
		bFrame.highlight:SetSequence(0)
		bFrame.highlight:SetSequenceTime(0, 0)

		self.bankItemFrame = bFrame;
	end
	return self.bankItemFrame;
end

FBoH_GridGuildBankItemButtonID = 1;

function FBoH_GridItemButton_GetGuildBankItemFrame(self)
	if self.guildBankItemFrame == nil then
		local name = "FBoH_GridGuildBankItemButton_" .. FBoH_GridGuildBankItemButtonID;
		FBoH_GridGuildBankItemButtonID = FBoH_GridGuildBankItemButtonID + 1;
	
		local bFrame = CreateFrame("Button", name, self, "FBoH_GuildBankItemButton");
		bFrame:SetPoint("TOPLEFT");
		bFrame:SetPoint("BOTTOMRIGHT");

		bFrame.tex = _G[name .. "IconTexture"];
		bFrame.tex:SetPoint("TOPLEFT", bFrame);
		bFrame.tex:SetPoint("BOTTOMRIGHT", bFrame);
		
		bFrame.normal_tex = bFrame:GetNormalTexture();
		bFrame.normal_tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		bFrame.normal_tex:SetBlendMode("ADD")
		bFrame.normal_tex:SetAlpha(0.65)
		bFrame.normal_tex:SetPoint("CENTER", bFrame, "CENTER", 1, 0)
		bFrame.normal_tex:Show()
		
		bFrame:Show();
		
		bFrame.highlight = CreateFrame("Model", name .. "Highlighter", bFrame)
		bFrame.highlight:Hide()
		bFrame.highlight:SetModel("Interface\Buttons\UI-AutoCastButton.mdx")
		bFrame.highlight:SetModelScale(1.2)
		bFrame.highlight:SetAllPoints()
		bFrame.highlight:SetSequence(0)
		bFrame.highlight:SetSequenceTime(0, 0)

		self.guildBankItemFrame = bFrame;
	end
	return self.guildBankItemFrame;
end

FBoH_GridEmptyItemButtonID = 1;

function FBoH_GridItemButton_GetEmptyItemFrame(self)
	if self.emptyItemFrame == nil then
		local name = "FBoH_GridEmptyItemButton_" .. FBoH_GridEmptyItemButtonID;
		FBoH_GridEmptyItemButtonID = FBoH_GridEmptyItemButtonID + 1;
	
		local eFrame = CreateFrame("Button", name, self, "FBoH_EmptyItemButton");
		eFrame:SetPoint("TOPLEFT");
		eFrame:SetPoint("BOTTOMRIGHT");

		eFrame.tex = _G[name .. "IconTexture"];
		eFrame.tex:SetPoint("TOPLEFT", eFrame);
		eFrame.tex:SetPoint("BOTTOMRIGHT", eFrame);
		
		eFrame.normal_tex = eFrame:GetNormalTexture();
		eFrame.normal_tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		eFrame.normal_tex:SetBlendMode("ADD")
		eFrame.normal_tex:SetAlpha(0.65)
		eFrame.normal_tex:SetPoint("CENTER", eFrame, "CENTER", 1, 0)
		eFrame.normal_tex:Show()
		
		eFrame:Show();
		
		eFrame.highlight = CreateFrame("Model", name .. "Highlighter", eFrame)
		eFrame.highlight:Hide()
		eFrame.highlight:SetModel("Interface\Buttons\UI-AutoCastButton.mdx")
		eFrame.highlight:SetModelScale(1.2)
		eFrame.highlight:SetAllPoints()
		eFrame.highlight:SetSequence(0)
		eFrame.highlight:SetSequenceTime(0, 0)

		self.emptyItemFrame = eFrame;
	end
	return self.emptyItemFrame;
end

FBoH_GridContainerItemButtonID = 1;

function FBoH_GridItemButton_GetContainerItemFrame(self)
	if self.containerItemFrame == nil then
		local name = "FBoH_GridContainerItemButton_" .. FBoH_GridContainerItemButtonID;
		FBoH_GridContainerItemButtonID = FBoH_GridContainerItemButtonID + 1;
	
		local cFrame = CreateFrame("Button", name, self);
		cFrame:SetPoint("TOPLEFT", self, "TOPLEFT");
		cFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT");
		
		cFrame.bagFrame = CreateFrame("Button", name, cFrame);
		cFrame.bagFrame:SetPoint("TOPLEFT", cFrame, "TOPLEFT");
		cFrame.bagFrame:SetPoint("BOTTOMRIGHT", cFrame, "BOTTOMRIGHT");
		
		cFrame.itemFrame = CreateFrame("Button", name, cFrame.bagFrame, "ContainerFrameItemButtonTemplate");
		cFrame.itemFrame:SetPoint("TOPLEFT", cFrame.bagFrame, "TOPLEFT");
		cFrame.itemFrame:SetPoint("BOTTOMRIGHT", cFrame.bagFrame, "BOTTOMRIGHT");
		
		cFrame.itemFrame.tex = _G[name .. "IconTexture"]
		cFrame.itemFrame.tex:SetPoint("TOPLEFT", cFrame.itemFrame, "TOPLEFT")
		cFrame.itemFrame.tex:SetPoint("BOTTOMRIGHT", cFrame.itemFrame, "BOTTOMRIGHT")
		
		cFrame.itemFrame.normal_tex = cFrame.itemFrame:GetNormalTexture()
		cFrame.itemFrame.normal_tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		cFrame.itemFrame.normal_tex:SetBlendMode("ADD")
		cFrame.itemFrame.normal_tex:SetAlpha(0.65)
		cFrame.itemFrame.normal_tex:SetPoint("CENTER", cFrame.itemFrame, "CENTER", 1, 0)
		cFrame.itemFrame.normal_tex:Show()

		cFrame.itemFrame:Show()
		
		cFrame.highlight = CreateFrame("Model", name .. "Highlighter", cFrame)
		cFrame.highlight:Hide()
		cFrame.highlight:SetModel("Interface\Buttons\UI-AutoCastButton.mdx")
		cFrame.highlight:SetModelScale(1.2)
		cFrame.highlight:SetAllPoints()
		cFrame.highlight:SetSequence(0)
		cFrame.highlight:SetSequenceTime(0, 0)
		
		self.containerItemFrame = cFrame;
	end
	return self.containerItemFrame;
end

function FBoH_GridItemButton_HideChildren(self)
	local children = { self:GetChildren() };
	for _, v in pairs(children) do
		v:Hide();
	end
end

function FBoH_GridItemButton_SetAltItem(aFrame, item)
	aFrame.item = item;
	
	local itemCount = item.itemCount;
	local quality, texture = nil, nil;
	if item.detail then
		quality, texture = item.detail.rarity, item.detail.texture;
	end
	if (quality == nil) or (texture == nil) then
		if item.itemLink then
			local _, _, q, _, _, _, _, _, _, t = GetItemInfo(item.itemLink)
			quality = quality or q;
			texture = texture or t;
		else
			quality = 0;
		end
	end

	SetItemButtonTexture(aFrame, texture);
	SetItemButtonCount(aFrame, itemCount);
	aFrame.hasItem = nil;
	
	if (quality == nil) or (quality < 0) then quality = 0 end
	local r, g, b = GetItemQualityColor(quality);
	
	aFrame.normal_tex:SetVertexColor(r, g, b)
	aFrame.normal_tex:SetAlpha(0.5)
	aFrame.tex:SetAlpha(0.5);
end

function FBoH_GridItemButton_SetBankItem(bFrame, item)
	local bagID, slotID = FBoH:GetItemBagAndSlotIDs(item);
	
	bFrame.containerID = bagID;
	bFrame.slotID = slotID;
	bFrame.item = item;

	local itemCount = item.itemCount;
	local quality, texture = item.detail.rarity, item.detail.texture;
	local _, _, locked, _, readable = GetContainerItemInfo(bagID, slotID)

	SetItemButtonTexture(bFrame, texture);
	SetItemButtonCount(bFrame, itemCount);
	SetItemButtonDesaturated(bFrame, locked, 0.5, 0.5, 0.5);
	if texture then
		bFrame.hasItem = 1;
	else
		bFrame.hasItem = nil;
	end
	
--	FBoH_GridItemButton_SetContainerItem(bFrame, item);
--	local itemFrame = bFrame.itemFrame;
	
	if FBoH:IsBankOpen() then
--		if (quality == nil) or (quality < 0) then quality = 0 end
--		local r = FBoH_QualityColors[quality + 1]
		
--		bFrame.normal_tex:SetVertexColor(r[1], r[2], r[3])
		bFrame.normal_tex:SetVertexColor(1, 1, 0)
		bFrame.tex:SetAlpha(1.0);
	else
		bFrame.normal_tex:SetVertexColor(1, 0, 0);
		bFrame.tex:SetAlpha(0.5);
	end
	
	bFrame.readable = readable
end

function FBoH_GridItemButton_SetGuildBankItem(bFrame, item)
--	local bagID, slotID = FBoH:GetItemBagAndSlotIDs(item);
	
--	bFrame.containerID = bagID;
--	bFrame.slotID = slotID;
	bFrame.item = item;

	local itemCount = item.itemCount;
	local quality, texture = item.detail.rarity, item.detail.texture;
--	local _, _, locked, _, readable = GetContainerItemInfo(bagID, slotID)

	SetItemButtonTexture(bFrame, texture);
	SetItemButtonCount(bFrame, itemCount);
	SetItemButtonDesaturated(bFrame, locked, 0.5, 0.5, 0.5);
	if texture then
		bFrame.hasItem = 1;
	else
		bFrame.hasItem = nil;
	end
	
--	FBoH_GridItemButton_SetContainerItem(bFrame, item);
--	local itemFrame = bFrame.itemFrame;
	
--	if FBoH:IsBankOpen() then
--		if (quality == nil) or (quality < 0) then quality = 0 end
--		local r = FBoH_QualityColors[quality + 1]
		
--		bFrame.normal_tex:SetVertexColor(r[1], r[2], r[3])
--		bFrame.normal_tex:SetVertexColor(1, 1, 0)
--		bFrame.tex:SetAlpha(1.0);
--	else
		bFrame.normal_tex:SetVertexColor(1, 0, 0);
		bFrame.tex:SetAlpha(0.5);
--	end
	
--	bFrame.readable = readable
end

function FBoH_GridItemButton_SetContainerItem(cFrame, item)
	local bagID, slotID = FBoH:GetItemBagAndSlotIDs(item);
		
	local bagFrame = cFrame.bagFrame;
	local itemFrame = cFrame.itemFrame;
	
	bagFrame:SetID(bagID);
	itemFrame:SetID(slotID);

	local itemCount = item.itemCount;
	local quality, texture = item.detail.rarity, item.detail.texture;
	local _, _, locked, _, readable = GetContainerItemInfo(bagID, slotID)
	
	SetItemButtonTexture(itemFrame, texture)
	SetItemButtonCount(itemFrame, itemCount);
	SetItemButtonDesaturated(itemFrame, locked, 0.5, 0.5, 0.5);
	if ( texture ) then
		itemFrame.hasItem = 1
	else
		itemFrame.hasItem = nil
	end

	if (quality == nil) or (quality < 0) then quality = 0 end
	local r, g, b = GetItemQualityColor(quality);
	
	itemFrame.normal_tex:SetVertexColor(r, g, b)
	itemFrame.tex:SetAlpha(1.0)

	itemFrame.readable = readable
end

function FBoH_GridItemButton_SetEmptyItem(eFrame, item)
	local bagID, slotID = FBoH:GetItemBagAndSlotIDs(item);
	
	eFrame.containerID = bagID;
	eFrame.slotID = slotID;
	eFrame.item = item;
	eFrame.itemRestrictions = nil;
	
	local itemCount = item.itemCount;
--	local quality, texture = item.detail.quality, item.detail.texture;
--	local _, _, locked, _, readable = GetContainerItemInfo(bagID, slotID)

--	SetItemButtonTexture(bFrame, texture);
	SetItemButtonCount(eFrame, itemCount);
--	SetItemButtonDesaturated(bFrame, locked, 0.5, 0.5, 0.5);
--	if texture then
--		bFrame.hasItem = 1;
--	else
		eFrame.hasItem = nil;
--	end
	
--	FBoH_GridItemButton_SetContainerItem(bFrame, item);
--	local itemFrame = bFrame.itemFrame;
	
--	if FBoH:IsBankOpen() then
--		if (quality == nil) or (quality < 0) then quality = 0 end
--		local r = FBoH_QualityColors[quality + 1]
		
--		bFrame.normal_tex:SetVertexColor(r[1], r[2], r[3])
--		bFrame.tex:SetAlpha(1.0);
--	else
	if item.restrictionCode == 0 then
		eFrame.normal_tex:SetVertexColor(1, 1, 1);
	else
		eFrame.normal_tex:SetVertexColor(1, 0.8, 0.5);
	end
--		eFrame.tex:SetAlpha(0.5);
--	end
	
--	bFrame.readable = readable
end

function FBoH_GridItemButton_SetItem(self, item)
	self:HideChildren();

	local chr = UnitName("player");
	local rlm = GetRealmName();
	
	if item then
		if item.isEmpty == true then
			local eFrame = self:GetEmptyItemFrame();
			if eFrame == nil then return end;
			
			FBoH_GridItemButton_SetEmptyItem(eFrame, item);
			
			eFrame:Show();
		elseif (chr ~= item.character) or (rlm ~= item.realm) then
			local aFrame = self:GetAltItemFrame();
			if aFrame == nil then return end;
			
			FBoH_GridItemButton_SetAltItem(aFrame, item);
			
			aFrame:Show();
		elseif item.bagType == "Bags" or item.bagType == "Keyring" then
			local cFrame = self:GetContainerItemFrame();
			if cFrame == nil then return end;
		
			FBoH_GridItemButton_SetContainerItem(cFrame, item);
						
			cFrame:Show();
		elseif item.bagType == "Bank" then
			local bFrame = self:GetBankItemFrame();
			if bFrame == nil then return end;
			
			FBoH_GridItemButton_SetBankItem(bFrame, item);
			
			bFrame:Show();
		elseif item.bagType == "Guild Bank" then
			local bFrame = self:GetGuildBankItemFrame();
			if bFrame == nil then return end;
			
			FBoH_GridItemButton_SetGuildBankItem(bFrame, item);
			
			bFrame:Show();
		end
	end
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
