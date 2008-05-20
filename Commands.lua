local L = LibStub("AceLocale-3.0"):GetLocale("FBoH")

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
				bags = {
					type = 'execute',
					desc = 'display default bag items',
					name = 'List Bag Contents',
					func = 'CmdShowBags'
				},
				create = {
					type = 'execute',
					desc = 'create new bag view',
					name = 'Create New View',
					func = 'CreateNewView',
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
	}
}

--FBoH:RegisterChatCommand("/fboh", options);
FBoH.configOptions = options
LibStub("AceConfig-3.0"):RegisterOptionsTable(L["FBoH"], options, L["fboh"]);
