local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

FBoH_SetVersion("$Revision$");

local function GetFuBarMinimapAttachedStatus(info)
	return FBoH:IsFuBarMinimapAttached() -- or Omen.Options["FuBar.HideMinimapButton"]
end

local options = { 
    name = L["Feithar's Bag of Holding"],
    handler = FBoH,
	type = 'group',
    args = {
		test = {
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
		},
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
--						FBoH.Options["FuBar.AttachMinimap"] = FBoH:IsFuBarMinimapAttached()
					end
				},
--				hideIcon = {
--					type = "toggle",
--					name = L["Hide minimap/FuBar icon"],
--					desc = L["Hide minimap/FuBar icon"],
--					get = function(info) return Omen.Options["FuBar.HideMinimapButton"] end,
--					set = function(info, v)
--						Omen.Options["FuBar.HideMinimapButton"] = v
--						if v then
--							FBoH:Hide()
--						else
--							FBoH:Show()
--						end
--					end
--				},
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
					get = function() return FBoH:GetGridScale() end,
					set = function(info, value) FBoH:SetGridScale(value) end,
					step = 0.01,
					bigStep = 0.05,
					min = 0.5,
					max = 2.0,
					isPercent = true,
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
					get = function(info) return FBoH:IsOpenAllBagsHooked() end,
					set = function(info, v) FBoH:SetOpenAllBagsHooked(v) end,
				},
				hookBackpack = {
					type = "toggle",
					name = L["Hook Open Backpack"],
					desc = L["Opening the backpack will open the FBoH main view instead."],
					get = function(info) return FBoH:IsOpenBackpackHooked() end,
					set = function(info, v) FBoH:SetOpenBackpackHooked(v) end,
				},
				hookBag1 = {
					type = "select",
					name = L["Hook Bag 1"],
					desc = L["Opening bag 1 will open the selected bag instead."],
					get = function(info) return FBoH:GetBagHook(1) end,
					set = function(info, v) FBoH:SetBagHook(1, v) end,
					style = "dropdown",
					values = function(info) return FBoH:GetBagHookChoices() end,
				},
				hookBag2 = {
					type = "select",
					name = L["Hook Bag 2"],
					desc = L["Opening bag 2 will open the selected bag instead."],
					get = function(info) return FBoH:GetBagHook(2) end,
					set = function(info, v) FBoH:SetBagHook(2, v) end,
					style = "dropdown",
					values = function(info) return FBoH:GetBagHookChoices() end,
				},
				hookBag3 = {
					type = "select",
					name = L["Hook Bag 3"],
					desc = L["Opening bag 3 will open the selected bag instead."],
					get = function(info) return FBoH:GetBagHook(3) end,
					set = function(info, v) FBoH:SetBagHook(3, v) end,
					style = "dropdown",
					values = function(info) return FBoH:GetBagHookChoices() end,
				},
				hookBag4 = {
					type = "select",
					name = L["Hook Bag 4"],
					desc = L["Opening bag 4 will open the selected bag instead."],
					get = function(info) return FBoH:GetBagHook(4) end,
					set = function(info, v) FBoH:SetBagHook(4, v) end,
					style = "dropdown",
					values = function(info) return FBoH:GetBagHookChoices() end,
				},
			},
		},
	}
}

--FBoH:RegisterChatCommand("/fboh", options);
FBoH.configOptions = options
LibStub("AceConfig-3.0"):RegisterOptionsTable(L["FBoH"], options, L["fboh"]);
