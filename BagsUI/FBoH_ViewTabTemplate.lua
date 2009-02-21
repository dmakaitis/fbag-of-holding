local _SafeCall = FBoH._SafeCall;


local Dewdrop = AceLibrary("Dewdrop-2.0");
local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision$");

function FBoH_ViewTabTemplate_OpenMenu(self)
	_SafeCall(function()
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
	end);
end

function FBoH_ViewTabTemplate_UpdateTabModel(self, model)
	_SafeCall(function()
		local text = getglobal(self:GetName().."Text");

		self.tabModel = model or self.tabModel;
		self:SetText(self.tabModel.tabDef.name);
		
		self.dockRegion:ClearAllPoints();
		self.dockRegion:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT");
		
		PanelTemplates_TabResize(self, 10);
		
		-- Is this tab active...
		local tabTexture = nil;
		if self.tabModel.tabIndex == self.tabModel.viewModel.viewDef.activeTab then
			text:SetTextColor(1, 0.8, 0);
			tabTexture = "Interface\\HelpFrame\\HelpFrameTab-Active";
		else
			text:SetTextColor(0.7, 0.7, 0.7);
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
	end);
end

