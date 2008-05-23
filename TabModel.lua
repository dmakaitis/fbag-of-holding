--*****************************************************************************
-- Tab Template.
--*****************************************************************************

FBoH_TabModel = FOO.Class();

local FBoH_TabButtonID = 1;

function FBoH_TabModel.prototype:init(viewModel, tabIndex)
	self.viewModel = viewModel
	self.tabIndex = tabIndex;
	self.tabDef = viewModel.viewDef.tabs[tabIndex];
	
--	FBoH:Print("Initializing tab model: " .. self.tabDef.name);
	
	self.button = CreateFrame("Button", "FBoH_BagViewTab_" .. FBoH_TabButtonID, viewModel.view, "FBoH_ViewTabTemplate");
	self.id = FBoH_TabButtonID;
	FBoH_TabButtonID = FBoH_TabButtonID + 1;

	self.tabDef.filter = self.tabDef.filter or "default";
	if self.tabDef.filter == "default" then
		FBoH_TabModel.defaultTab = self;
--		FBoH:Print(self.tabDef.name .. " is the default tab");
	end
	
	if FBoH_TabModel.defaultTab then
--		FBoH:Print("Clearing filter cache for " .. FBoH_TabModel.defaultTab.tabDef.name);
		FBoH_TabModel.defaultTab.filterCache = nil;
	end
	
	self.button:UpdateTabModel(self);
end

function FBoH_TabModel.prototype:SetView(viewModel, tabIndex)
	self.viewModel = viewModel;
	self.tabIndex = tabIndex;
	self.button:SetParent(viewModel.view);
	
	self.button:UpdateTabModel(self);
end

function FBoH_TabModel.prototype:SetAnchor(tabModel)
	self.button:ClearAllPoints();
	if tabModel then
		self.button:SetPoint("BOTTOMLEFT", tabModel.button, "BOTTOMRIGHT", 2, 0);
	else
		self.button:SetPoint("BOTTOMLEFT", self.viewModel.view, "TOPLEFT", 2, -2);
	end
	self.button:SetFrameLevel(self.viewModel.view:GetFrameLevel());		
end

local function BuildFilter(filter)
	local f, a = filter.name, filter.arg;
	local rVal = {};
	
--	FBoH:Print("Building filter...");
	
	rVal.filter = FBoH:GetFilter(f).filter;
	
	if (f == "And") or (f == "Or") then
		rVal.arg = {};
		for i, v in ipairs(a) do
			table.insert(rVal.arg, BuildFilter(v));
		end
	elseif f == "Not" then
		FBoH:Print("*** WARNING *** Not filter shouldn't be used directly");
		rVal.arg = self:BuildFilter(a);
	else
		rVal.arg = a;
	end

	if filter.isNot then
		local r = rVal;
		rVal = {};
		rVal.filter = FBoH:GetFilter("Not").filter;
		rVal.arg = r;
	end
	
	return rVal;
end

function FBoH_TabModel.prototype:SimplifyFilter(filter)
	if filter == "default" then return end;
	
	if filter.name == "Not" then
--		FBoH:Print("Simplifying 'Not' filter");
		-- Replace not filters with their child, and set its isNot property appropriately
		
		local child = filter.arg;
		
		filter.name = child.name;
		filter.arg = child.arg;
		filter.isNot = true;
		self:SimplifyFilter(filter);
	elseif (filter.name == "And") or (filter.name == "Or") then
--		FBoH:Print("Simplifying '" .. filter.name .. "' filter");
		if #(filter.arg) == 0 then
			FBoH:Print("   No children found: This should have already been deleted!");
		elseif #(filter.arg) == 1 then
--			FBoH:Print("   One child found: Collapsing...");

			local child = filter.arg[1];
			
			filter.name = child.name;
			filter.arg = child.arg;
			
			if filter.isNot and child.isNot then
				filter.isNot = nil;
			elseif filter.isNot or child.isNot then
				filter.isNot = true;
			end
			
			self:SimplifyFilter(filter);
		else
			-- Check for empty and/or filters in the children
			local i = 1;
			while i <= #(filter.arg) do
				local child = filter.arg[i];
				if (child.delete) or (((child.name == "And") or (child.name == "Or")) and (#(child.arg) == 0)) then
--					FBoH:Print("Removing empty/deleted '" .. child.name .. "' filter from index " .. i);
					table.remove(filter.arg, i);
					i = i - 1;
				end
				i = i + 1;
			end
			
			for k, v in ipairs(filter.arg) do
				self:SimplifyFilter(v);
			end
		end
	end
end

function FBoH_TabModel.prototype:SetFilter(filter)
	self.tabDef.filter = filter or self.tabDef.filter;
	self.filterCache = nil;
	self.viewModel.allFilterCache = nil;
	
	self:SimplifyFilter(self.tabDef.filter);
	
	if FBoH_TabModel.defaultTab then
		FBoH_TabModel.defaultTab.filterCache = nil;
		FBoH_TabModel.defaultTab.viewModel.allFilterCache = nil;
	end
	
	self:Update();
end

function FBoH_TabModel.prototype:GetFilter()
--	FBoH:Print("Getting filters for tab '" .. self.tabDef.name .. "'...");
		
	if self.filterCache == nil then
		self.itemCache = nil;
		if FBoH_TabModel.defaultTab	then
			FBoH_TabModel.defaultTab.filterCache = nil;
		end
		
		local f = nil;
	
		if self.tabDef.filter == "default" then
--			FBoH:Print("Building the default bag filter");
			-- build default bag filter
			local b = {};
--			FBoH:Print(#(FBoH.bagViews) .. " bags to check");
			for i, v in pairs(FBoH.bagViews) do
--				FBoH:Print("Checking bag " .. i);
				local bf = v:GetFilter("all");
				if bf then
					table.insert(b, bf)
				end
			end
			
			if #b > 0 then
				f = {
					filter = FBoH:GetFilter("And").filter;
					arg = {
						{
							filter = FBoH:GetFilter("Character").filter;
						},
						{
							filter = FBoH:GetFilter("Not").filter;
							arg = {
								filter = FBoH:GetFilter("Or").filter;
								arg = b
							}
						}
					}
				}
			else
				f = {
					filter = FBoH:GetFilter("Character").filter;
				}
			end
		else
			f = BuildFilter(self.tabDef.filter);
		end
		
		self.filterCache = f;
	end
	return self.filterCache;
end

function FBoH_TabModel.prototype:GetItems()
	if self.filterCache == nil then
		self.itemCache = nil
	end
	
	if self.itemCache == nil then
		self.searchCache = nil;
		local f = self:GetFilter();
		local rVal = FBoH.items:FindItems(f.filter, f.arg);
		-- Set up sorting paramters
		table.sort(rVal, FBoH.Sort_Items);
		self.itemCache = rVal;
	end
	if self.searchCache == nil then
		if self.viewModel.searchFilter then
			self.searchCache = {};
			for _, v in ipairs(self.itemCache) do
				local _, _, itemName = string.find(v.itemLink, "%[(.+)%]")
				local n = string.lower(itemName);
				local c = string.lower(self.viewModel.searchFilter);
				
				if string.find(n, c) then
					table.insert(self.searchCache, v);
				end
			end
		else
			self.searchCache = self.itemCache;
		end
	end
	return self.searchCache;
end

function FBoH_TabModel.prototype:Update()
	self.button:UpdateTabModel(self);
	
	self.itemCache = nil;
	if FBoH_TabModel.defaultTab then
		FBoH_TabModel.defaultTab.itemCache = nil;
	end
end

function FBoH_TabModel.prototype:IsShown()
	return self.button:IsShown();
end

function FBoH_TabModel.prototype:Show()
	self.button:Show();
end

function FBoH_TabModel.prototype:Hide()
	self.button:Hide();
end

function FBoH_TabModel.prototype:IsShownAsList(tabIndex)
	return self.tabDef.viewAsList
end

function FBoH_TabModel.prototype:ShowAsList()
	self.tabDef.viewAsList = true;
	self.viewModel.view:UpdateViewModel();
end

function FBoH_TabModel.prototype:ShowAsGrid()
	self.tabDef.viewAsList = nil;
	self.viewModel.view:UpdateViewModel();
end

function FBoH_TabModel.prototype:ToggleList()
	if self.tabDef.viewAsList then
		self:ShowAsGrid();
	else
		self:ShowAsList();
	end
end

function FBoH_TabModel.prototype:IsBagTypeVisible(bagType)
	if bagType == "Bags" then return true end;
	if bagType == "Bank" then return true end; -- Remember to make visible when at bank
	return false;
end

