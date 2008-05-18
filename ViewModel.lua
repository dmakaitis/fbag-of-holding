--*****************************************************************************
-- View Template.
--*****************************************************************************

FBoH_ViewModel = FOO.Class();

local FBoH_ViewModelID = 1;

function FBoH_ViewModel.prototype:init(viewDef, tabData)
	self.viewDef = viewDef;
	self.tabData = tabData;
	viewDef.activeTab = viewDef.activeTab or 1;
	
	self.id = FBoH_ViewModelID;
	FBoH_ViewModelID = FBoH_ViewModelID + 1;
	
	local frameName = "FBoH_BagViewFrame_" .. self.id;

	self.view = CreateFrame("Frame", "FBoH_BagViewFrame_" .. self.id, UIParent, "FBoH_BagViewTemplate");
	tinsert(UISpecialFrames, frameName);

	if viewDef.framePoints then
		self.view:ClearAllPoints();
		for i, v in ipairs(viewDef.framePoints) do
			self.view:SetPoint(v.point, v.relativeTo, v.relativePoint, v.xOffset, v.yOffset);
		end
	end
	if viewDef.frameWidth then
		self.view:SetWidth(viewDef.frameWidth);
	end
	if viewDef.frameHeight then
		self.view:SetHeight(viewDef.frameHeight);
	end

	self.view:SetGridScale(FBoH.db.profile.gridScale);
	
	self:SelectTab(viewDef.activeTab);
end

function FBoH_ViewModel.prototype:GetTab(tabIndex)
	tabIndex = tabIndex or self.viewDef.activeTab;
	return self.tabData[tabIndex], self.viewDef.tabs[tabIndex];
end

function FBoH_ViewModel.prototype:SelectTab(tabIndex)
	if tabIndex then
		self.topRow = 1;
	end
	tabIndex = tabIndex or self.viewDef.activeTab;
	self.viewDef.activeTab = tabIndex or 1;
	
	self.tabData = self.tabData or {};
	
	-- Make sure we have tab buttons for each of our tabs and they are labeled correctly.
	for i, t in ipairs(self.viewDef.tabs) do
		self.tabData[i] = self.tabData[i] or FBoH_TabModel(self, i);
		local tabData = self.tabData[i];

		tabData.button:ClearAllPoints();
--		if t.filter == "default" then
--			FBoH_ViewModel.defaultView = self;
--			FBoH_ViewModel.defaultTab = i;
--		end
	end
	
	-- Ensure tabs are hidden or displayed, as needed
	local lastTab = nil;
	for i, t in ipairs(self.tabData) do
		t:SetView(self, i);
		t:SetAnchor(lastTab);		
		lastTab = t;
		
		if i <= #(self.viewDef.tabs) then
			t:Show();
		else
			t:Hide();
		end
	end

--	self.bagDef = self.viewDef.tabs[tabIndex];
--	self.tab = self.tabButtons[tabIndex];
	
--	filter = self.bagDef.filter or "default";
--	if filter == "default" then
--		FBoH_ViewModel.defaultBag = self;
--	end
--	self.bagDef.filter = filter;
	
--	self.filterCache[self.viewDef.activeTab] = nil;
--	self.allFilterCache = nil;
--	if FBoH_ViewModel.defaultView then
--		FBoH_ViewModel.defaultView.filterCache[FBoH_ViewModel.defaultTab] = nil;
--	end
	
	self:UpdateBag();
end
--[[
function FBoH_ViewModel.prototype:SetFilter(filter)
	self.bagDef.filter = filter or self.bagDef.filter;
	self.filterCache = nil;
	self.allFilterCache = nil;
	self:UpdateBag();
end
]]
function FBoH_ViewModel.prototype:GetFilter(tabIndex)
	tabIndex = tabIndex or self.viewDef.activeTab;
--	FBoH:Print("Getting filter for tab " .. tabIndex);
	
	if self.tabData[tabIndex] == nil then
--		FBoH:Print("Getting filters for all tabs...");
		
		if self.allFilterCache == nil then
			local b = {};
			for i, v in pairs(self.viewDef.tabs) do
				if v.filter ~= "default" then
					local f = self:GetFilter(i);
					table.insert(b, f);
				end
			end
			
			local f = nil;
			
			if #b > 1 then
				f = {
					filter = FBoH:GetFilter("Or").filter;
					arg = b;
				}
			elseif #b == 1 then
				f = b[1];
			end
			
			self.allFilterCache = f;
		end
		return self.allFilterCache;
	else
		return self.tabData[tabIndex]:GetFilter();
	end
end

function FBoH_ViewModel.prototype:GetItems(tabIndex)
	local tabData = self:GetTab(tabIndex);
	if tabData == nil then
		tabData = self:GetTab(self.viewDef.activeTab);
	end
	if tabData == nil then
		self.viewDef.activeTab = 1;
		tabData = self:GetTab(self.viewDef.activeTab);
	end
	if tabData == nil then
		return {};
	end
	
	
	return tabData:GetItems();
end

function FBoH_ViewModel.prototype:GetSearch()
	return self.searchFilter or "";
end

function FBoH_ViewModel.prototype:SetSearch(filter)
	self.searchFilter = filter;
	for _, t in pairs(self.tabData) do
		t.searchCache = nil;
	end
	self.view:UpdateViewModel();
end

function FBoH_ViewModel.prototype:IsShown()
	return self.view:IsShown();
end

function FBoH_ViewModel.prototype:Show()
	self.view:Show();
end

function FBoH_ViewModel.prototype:Hide()
	self.view:Hide();
end

function FBoH_ViewModel.prototype:IsShownAsList(tabIndex)
	tabIndex = tabIndex or self.viewDef.activeTab;
	if self.tabData[tabIndex] then
		return self.tabData[tabIndex]:IsShownAsList();
	end
end

function FBoH_ViewModel.prototype:ShowAsList(tabIndex)
	tabIndex = tabIndex or self.viewDef.activeTab;
	if self.tabData[tabIndex] then
		self.tabData[tabIndex]:ShowAsList();
	end
end

function FBoH_ViewModel.prototype:ShowAsGrid(tabIndex)
	tabIndex = tabIndex or self.viewDef.activeTab;
	if self.tabData[tabIndex] then
		self.tabData[tabIndex]:ShowAsGrid();
	end
end

function FBoH_ViewModel.prototype:ToggleList(tabIndex)
	tabIndex = tabIndex or self.viewDef.activeTab;
	if self.tabData[tabIndex] then
		self.tabData[tabIndex]:ToggleList();
	end
end

function FBoH_ViewModel.prototype:IsBagTypeVisible(bagType, tabIndex)
	-- Sometimes when docking/undocking, activeTab probably becomes invalidated (or, perhaps it's just viewDef that does)
	tabIndex = tabIndex or self.viewDef.activeTab;
	if self.tabData[tabIndex] then
		return self.tabData[tabIndex]:IsBagTypeVisible(bagType);
	end
end

function FBoH_ViewModel.prototype:UpdateBag()
	for _, v in pairs(self.tabData) do
		v:Update();
	end
	
	self.view:UpdateViewModel(self);
end

function FBoH_ViewModel.prototype:SaveFramePosition()
	local profile = {};
	local np = self.view:GetNumPoints();
	local index = 1;
	for i = 1, np do
		local pt, rt, rp, xOfs, yOfs = self.view:GetPoint(i)
		if rt == nil then
			profile[index] = {
				point = pt,
				relativeTo = rt,
				relativePoint = rp,
				xOffset = xOfs,
				yOffset = yOfs
			}
			index = index + 1;
		end
	end

	if #profile >= 1 then
		self.viewDef.framePoints = profile;
	end
	self.viewDef.frameWidth = self.view:GetWidth();
	self.viewDef.frameHeight = self.view:GetHeight();
end
