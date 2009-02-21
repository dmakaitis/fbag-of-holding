local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision: 94 $");

local _SafeCall = FBoH._SafeCall;

--*****************************************************************************
-- Private Methods
--*****************************************************************************

local defaultViewDefinitions = {
	{
		activeTab = 1,
		tabs = {
			{
				name = L["Main Bag"],
				filter = "default"
			},
		},
	},
};

-- Simple shallow copy for copying defaults
local
function _CopyTable(src, dest)
	if type(dest) ~= "table" then dest = {} end
	if type(src) == "table" then
		for k,v in pairs(src) do
			if type(v) == "table" then
				-- try to index the key first so that the metatable creates the defaults, if set, and use that table
				v = _CopyTable(v, dest[k])
			end
			dest[k] = v
		end
	end
	return dest
end

local
function _RenumberViewIDs(self)
	_SafeCall(function()
		for i, v in ipairs(self.bagViews) do
			v.viewIndex = i;
		end
	end);
end

--*****************************************************************************
-- Public interface
--*****************************************************************************

function FBoH:OnProfileChanged()
	_SafeCall(function()
		-- First, if we have existing bag views, hide them all
		if self.bagViews then
			for _, v in pairs(self.bagViews) do
				v:Hide();
			end
		end
		
		FBoH_Configure:Hide();
		
		self.db.profile.viewDefs = self.db.profile.viewDefs or _CopyTable(defaultViewDefinitions);
--		self.db.profile.viewDefs = defaultViewDefinitions;
		self.bagViews = {};
		
		local viewDefs = self.db.profile.viewDefs;
		for k, v in pairs(viewDefs) do
			self.bagViews[k] = FBoH_ViewModel(v);
			if FBoH_TabModel.defaultTab then
				FBoH_TabModel.defaultTab.filterCache = nil;
			end
		end
		_RenumberViewIDs(self);
	end);
end

function FBoH:CreateNewView()
	_SafeCall(function()
		local newView = {
			tabs = {
				{
					name = "New View",
					filter = {
						name = "Character",
					},
				},
			},
		};
		
		table.insert(self.db.profile.viewDefs, newView);
		table.insert(self.bagViews, FBoH_ViewModel(newView));

		if FBoH_TabModel.defaultTab then
			FBoH_TabModel.defaultTab.filterCache = nil;
		end

		_RenumberViewIDs(self);	

		local view = self.bagViews[#(self.bagViews)];
		
		view:Show();

		FBoH_Configure:SetModel(view);
		FBoH_Configure:Show();
	end);
end

function FBoH:DeleteViewTab(tabModel)
	_SafeCall(function()
		if tabModel.tabDef.filter == "default" then
			FBoH:Print("Can not delete the default view!");
			return;
		end
		
--	FBoH:Print("Deleting tab: " .. tabModel.tabDef.name);
		
		tabModel.tabDef.DELETE_THIS_TAB = true;
		
		local delViewID, delTabID, delTabCount = nil, nil;
		local delView = nil;
		
		for vi, view in ipairs(self.bagViews) do
			for ti, tab in ipairs(view.tabData) do
				if tab.tabDef.DELETE_THIS_TAB then
					delView = view;
					delViewID = vi;
					delTabID = ti;
					delTabCount = #(view.tabData);
					tab.tabDef.DELETE_THIS_TAB = nil;
				end
			end
		end
		
--	FBoH:Print("   Tab " .. delTabID .. " from view " .. delViewID .. " (with " .. delTabCount .. " tabs)");
		
		if delTabCount == 1 then
			table.remove(self.bagViews, delViewID);
			table.remove(self.db.profile.viewDefs, delViewID);
			
			delView:Hide();
			delView.viewDef = nil;
			delView.tabDef = nil;
		else
			table.remove(delView.viewDef.tabs, delTabID);
			table.remove(delView.tabData, delTabID):Hide();
			delView:SelectTab(1);
		end

		_RenumberViewIDs(self);
	end);
end

function FBoH:DockView(sourceView, targetView, targetTab)
	_SafeCall(function()
		if sourceView == targetView then
			self:Debug("Can not dock view " .. sourceView .. " into itself!");
			return;
		end
		
		self:Debug("Docking view " .. sourceView .. " into view " .. targetView .. " after tab " .. targetTab);
		
		FBoH_Configure:Hide();
		
		-- remove the view and definition
		local oldView = table.remove(self.bagViews, sourceView);
		table.remove(self.db.profile.viewDefs, sourceView);
		local wasShown = oldView:IsShown();
		oldView:Hide();
		
		local newView = self.bagViews[targetView];
		
		local newTabs = {};
		local newTabData = {};
		local tabCount = 1;
		
		for i = 1, targetTab do
			table.insert(newTabs, newView.viewDef.tabs[i]);
			table.insert(newTabData, newView.tabData[i]);
			self:Debug("Added tab " .. tabCount .. " from target view");
			tabCount = tabCount + 1;
		end
		
		for i, t in ipairs(oldView.viewDef.tabs) do
			table.insert(newTabs, t);
			table.insert(newTabData, oldView.tabData[i]);
			self:Debug("Added tab " .. tabCount .. " from source view");
			tabCount = tabCount + 1;
		end
		
		for i = targetTab + 1, #(newView.viewDef.tabs) do
			table.insert(newTabs, newView.viewDef.tabs[i]);
			table.insert(newTabData, newView.tabData[i]);
			self:Debug("Added tab " .. tabCount .. " from target view");
			tabCount = tabCount + 1;
		end
		
		oldView.viewDef = nil;
		oldView.tabData = nil;
		
		newView.viewDef.tabs = newTabs;
		newView.tabData = newTabData;
		
		newView:SelectTab(targetTab + 1);
		if wasShown then
			newView:Show();
		else
			newView:Hide();
		end
	end);
end

function FBoH:UndockView(sourceView, sourceTab)
	self:Debug("Undocking tab " .. sourceTab .. " from the view " .. sourceView);

	FBoH_Configure:Hide();
	
	-- Remove the tab from the main bag, and update it.
	local tabDef = table.remove(self.bagViews[sourceView].viewDef.tabs, sourceTab);
	local tabData = table.remove(self.bagViews[sourceView].tabData, sourceTab);
	self.bagViews[sourceView]:SelectTab(1);
	
	self:Debug(#(self.db.profile.viewDefs[sourceView].tabs) .. " tabs remaining in source view");
	
	-- Create a new bag
	local newViewDef = {
		activeTab = 1;
		tabs = {
			tabDef
		}
	};
	local newTabData = {
		tabData;
	};
	
	local newBagView = FBoH_ViewModel(newViewDef, newTabData);
	table.insert(self.bagViews, newBagView);
	table.insert(self.db.profile.viewDefs, newViewDef);

	if FBoH_TabModel.defaultTab then
		FBoH_TabModel.defaultTab.filterCache = nil;
	end
	
	if self.bagViews[sourceView]:IsShown() then
		newBagView:Show();
	else
		newBagView:Hide();
	end
	
	_RenumberViewIDs(self);
	
	return newBagView;
end

function FBoH:GetBagViewByID(bagViewID)
	for k, v in pairs(self.bagViews) do
		if v.bagDef.id == bagViewID then
			return v;
		end
	end
	return nil;
end

function FBoH:GetUniqueTabID()
	local rVal = time();
	local unique = false;
	
	while unique == false do
		unique = true;
		for _, v in ipairs(self.db.profile.viewDefs) do
			for _, t in ipairs(v.tabs) do
				if t.id == rVal then
					unique = false;
					rVal = rVal + 1;
				end
			end
		end
	end
	
	return rVal;
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

FBoH_UnitTests.ViewManagement = {

	testRenumberBagIDs = function()
		local fboh = {
			bagViews = {
				{ a = 'test' },
				{ b = 'test', viewIndex = 3 },
				{ c = 'test' },
				{ d = 'test', viewIndex = 4 },
				{ e = 'test', viewIndex = 57 },
			};
		};
		local expected = {
			bagViews = {
				{ a = 'test', viewIndex = 1 },
				{ b = 'test', viewIndex = 2 },
				{ c = 'test', viewIndex = 3 },
				{ d = 'test', viewIndex = 4 },
				{ e = 'test', viewIndex = 5 },
			};
		};
		
		_RenumberViewIDs(fboh);
		
		assertEquals(expected, fboh);
	end;

	testCreateNewView = function()
		local newView = {
			tabs = {
				{
					name = "New View",
					filter = {
						name = "Character",
					},
				},
			},
		};

		local fboh = {
			db = {
				profile = {
					viewDefs = {};
				};
			};
			bagViews = {};
		};
		local expected = {
			db = {
				profile = {
					viewDefs = {
						{
							tabs = {
								{
									name = "New View";
									filter = {
										name = "Character";
									};
								};
							};
						};
					};
				};
			};
			bagViews = {};
		};
		expected.bagViews[1] = FBoH_ViewModel(expected.db.profile.viewDefs[1]);
		
		FBoH.CreateNewView(fboh);
		fboh.bagViews[1]:Hide();
		FBoH_Configure:Hide();
		
		assertEquals(expected, fboh);
	end;
	
};
