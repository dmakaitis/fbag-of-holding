local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision$");

local _SafeCall = FBoH._SafeCall;

--*****************************************************************************
-- Command implementation
--*****************************************************************************

--[[
function FBoH:CmdPurge()
	self.items:Purge();
	self:ScanContainer();
end

function FBoH:CmdScan()
	self:ScanContainer();
end
]]
function FBoH:IsDebugEnabled()
	return self.db.profile.debugMessages;
end

function FBoH:SetDebugEnabled(value)
	self.db.profile.debugMessages = value;
end

local
function _GetGridScale(self)
	return self.db.profile.gridScale;
end

local
function _SetGridScale(self, scale)
	self.db.profile.gridScale = scale;
	
	for _, v in pairs(self.bagViews) do
		v.view:SetGridScale(scale);
	end
end

local
function _IsGuildBankHidden(self)
	return self.db.profile.hideGuildBank;
end

local function _SetGuildBankHidden(self, v)
	self.db.profile.hideGuildBank = v;
	if FBoH_TabModel.defaultTab then
		FBoH_TabModel.defaultTab.filterCache = nil;
		FBoH_TabModel.defaultTab:Update();
		FBoH_TabModel.defaultTab.viewModel:UpdateBag();
	end
end

local
function _IsBankHidden(self)
	return self.db.profile.hideBank;
end

local function _SetBankHidden(self, v)
	self.db.profile.hideBank = v;
	if FBoH_TabModel.defaultTab then
		FBoH_TabModel.defaultTab.filterCache = nil;
		FBoH_TabModel.defaultTab:Update();
		FBoH_TabModel.defaultTab.viewModel:UpdateBag();
	end
end

local
function _IsOpenAllBagsHooked(self)
	return self.db.profile.hookOpenAllBags;
end

local
function _SetOpenAllBagsHooked(self, v)
	self.db.profile.hookOpenAllBags = v;
end

local
function _IsOpenBackpackHooked(self)
	return self.db.profile.hookToggleBackpack;
end

local
function _SetOpenBackpackHooked(self, v)
	self.db.profile.hookToggleBackpack = v;
end

local
function _GetBagHook(self, bagID)
	return self.db.profile.hookToggleBags[bagID] or "blizzard";
end

local
function _SetBagHook(self, bagID, value)
	self.db.profile.hookToggleBags[bagID] = value
end

local
function _GetBagHookChoices(self)
	rVal = {};
	
	rVal["blizzard"] = L["- Blizzard Default -"];
	
	_SafeCall(function()
		for _, v in ipairs(self.db.profile.viewDefs) do
			for _, t in ipairs(v.tabs) do
				if t.filter ~= "default" then
					rVal[tostring(t.id)] = t.name;
				end
			end
		end
	end);
	
	rVal["default"] = L["- FBoH Main Bag -"];
	
	return rVal;
end

--*****************************************************************************
-- Configuration setup
--*****************************************************************************

local function GetFuBarMinimapAttachedStatus(info)
	return FBoH:IsFuBarMinimapAttached() -- or Omen.Options["FuBar.HideMinimapButton"]
end

local options = { 
    name = L["Feithar's Bag of Holding"],
    handler = FBoH,
	type = 'group',
    args = {
--[[		test = {
			type = "group",
			name = "Test Commands",
			desc = "Test Commands",
			args = {
				scan = {
					type = 'execute',
					desc = 'Scan inventory',
					name = 'Scan Inventory',
					func = 'CmdScan'
				},
				purge = {
					type = 'execute',
					desc = 'Purge all data',
					name = 'Purge Item Data',
					func = 'CmdPurge'
				},
				viewAsList = {
					type = "toggle",
					name = "Allow View As List",
					desc = "Turn the ability to view as a list on and off.",
					get = function(info)
						return FBoH.canViewAsList;
					end,
					set = function(info, v)
						FBoH.canViewAsList = v;
					end
				},
			}
		},--]]
		fubar = {
			type = "group",
			name = L["FuBar options"],
			desc = L["FuBar options"],
			disabled = function() return FBoH.IsFuBarMinimapAttached == nil end,
			args = {
				attachMinimap = {
					type = "toggle",
					name = L["Attach to minimap"],
					desc = L["Attach to minimap"],
					get = function(info)
						return FBoH:IsFuBarMinimapAttached()
					end,
					set = function(info, v)
						FBoH:ToggleFuBarMinimapAttached()
					end
				},
				showIcon = {
					type = "toggle",
					name = L["Show icon"],
					desc = L["Show icon"],
					get = function(info) return FBoH:IsFuBarIconShown() end,
					set = function(info, v) FBoH:ToggleFuBarIconShown() end,
					disabled = GetFuBarMinimapAttachedStatus
				},
				showText = {
					type = "toggle",
					name = L["Show text"],
					desc = L["Show text"],
					get = function(info) return FBoH:IsFuBarTextShown() end,
					set = function(info, v) FBoH:ToggleFuBarTextShown() end,
					disabled = GetFuBarMinimapAttachedStatus
				},
				position = {
					type = "select",
					name = L["Position"],
					desc = L["Position"],
					values = {LEFT = L["Left"], CENTER = L["Center"], RIGHT = L["Right"]},
					get = function() return FBoH:GetPanel() and FBoH:GetPanel():GetPluginSide(FBoH) end,
					set = function(info, val)
						if FBoH:GetPanel() and FBoH:GetPanel().SetPluginSide then
							FBoH:GetPanel():SetPluginSide(FBoH, val)
						end
					end,
					disabled = GetFuBarMinimapAttachedStatus
				}
			}
		},
		display = {
			type = "group",
			name = L["Display"],
			desc = L["Display"],
			args = {
				gridScale = {
					type = "range",
					name = L["Grid Scale"],
					desc = L["Grid Scale Desc"],
					get = function() return _GetGridScale(FBoH) end,
					set = function(info, value) _SetGridScale(FBoH, value) end,
					step = 0.01,
					bigStep = 0.05,
					min = 0.5,
					max = 2.0,
					isPercent = true,
				},
				debugOutput = {
					type = "toggle",
					name = L["Enable debug"],
					desc = L["Enable printing of debug messages to the chat window."],
					get = function(info) return FBoH:IsDebugEnabled() end,
					set = function(info, v) FBoH:SetDebugEnabled(v) end,
				},
			},
		},
		mainBag = {
			type = "group",
			name = L["Main Bag"],
			desc = L["Main Bag"],
			args = {
				hideBank = {
					type = "toggle",
					name = L["Hide Bank Items"],
					desc = L["Hide bank items when not at the bank."],
					get = function(info) return _IsBankHidden(FBoH) end,
					set = function(info, v) _SetBankHidden(FBoH, v) end,
				},
				hideGuildBank = {
					type = "toggle",
					name = L["Hide Guild Bank Items"],
					desc = L["Hide guild bank items when not at the bank."],
					get = function(info) return _IsGuildBankHidden(FBoH) end,
					set = function(info, v) _SetGuildBankHidden(FBoH, v) end,
				},
			},
		},
		general = {
			type = "group",
			name = L["General"],
			desc = L["General"],
			args = {
				hookAllBags = {
					type = "toggle",
					name = L["Hook Open All Bags"],
					desc = L["Opening all bags will open FBoH bags instead."],
					get = function(info) return _IsOpenAllBagsHooked(FBoH) end,
					set = function(info, v) _SetOpenAllBagsHooked(FBoH, v) end,
				},
				hookBackpack = {
					type = "toggle",
					name = L["Hook Open Backpack"],
					desc = L["Opening the backpack will open the FBoH main view instead."],
					get = function(info) return _IsOpenBackpackHooked(FBoH) end,
					set = function(info, v) _SetOpenBackpackHooked(FBoH, v) end,
				},
				hookBag1 = {
					type = "select",
					name = L["Hook Bag 1"],
					desc = L["Opening bag 1 will open the selected bag instead."],
					get = function(info) return _GetBagHook(FBoH, 1) end,
					set = function(info, v) _SetBagHook(FBoH, 1, v) end,
					style = "dropdown",
					values = function(info) return _GetBagHookChoices(FBoH) end,
				},
				hookBag2 = {
					type = "select",
					name = L["Hook Bag 2"],
					desc = L["Opening bag 2 will open the selected bag instead."],
					get = function(info) return _GetBagHook(FBoH, 2) end,
					set = function(info, v) _SetBagHook(FBoH, 2, v) end,
					style = "dropdown",
					values = function(info) return _GetBagHookChoices(FBoH) end,
				},
				hookBag3 = {
					type = "select",
					name = L["Hook Bag 3"],
					desc = L["Opening bag 3 will open the selected bag instead."],
					get = function(info) return _GetBagHook(FBoH, 3) end,
					set = function(info, v) _SetBagHook(FBoH, 3, v) end,
					style = "dropdown",
					values = function(info) return _GetBagHookChoices(FBoH) end,
				},
				hookBag4 = {
					type = "select",
					name = L["Hook Bag 4"],
					desc = L["Opening bag 4 will open the selected bag instead."],
					get = function(info) return _GetBagHook(FBoH, 4) end,
					set = function(info, v) _SetBagHook(FBoH, 4, v) end,
					style = "dropdown",
					values = function(info) return _GetBagHookChoices(FBoH) end,
				},
			},
		},
	}
}

--FBoH:RegisterChatCommand("/fboh", options);
FBoH.configOptions = options
LibStub("AceConfig-3.0"):RegisterOptionsTable(L["FBoH"], options, L["fboh"]);
