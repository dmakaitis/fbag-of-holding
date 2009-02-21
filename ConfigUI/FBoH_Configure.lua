local _SafeCall = FBoH._SafeCall;
local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

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

function FBoH_Configure_OnVerticalScroll()
	FBOH_SCROLL_FRAME:DoVerticalScroll();
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
		FBoH:Debug("Sorter well received unknown drag type: " .. tostring(dragData.source.type));
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
