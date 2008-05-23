local L = LibStub("AceLocale-3.0"):NewLocale("FBoH", "enUS", true)

L["Feithar's Bag of Holding"] = true;	-- Full Title
L["FBoH"] = true;						-- Short Title
L["fboh"] = true;						-- chat command
L["Undefined"] = true;

L["Bag View"] = true;
L["Main Bag"] = true;

L["Bags"] = true;
L["Bank"] = true;
L["Keyring"] = true;
L["Mailbox"] = true;
L["Wearing"] = true;

L["Soulbound"] = true;
L["Quest Item"] = true;

L["FuBar Hint"] = "Hint: Left click to open all view. Right click to configure.";

-- Standard Filters

L["Current Character"] = true;
L["Current Realm"] = true;
L[" (All)"] = true;

L["Bag Index"] = true;
L["Bag Type"] = true;
L["Character"] = true;
L["Item Name"] = true;
L["Quality"] = true;

L["Not Soulbound"] = true;

L["Poor"] = true;
L["Common"] = true;
L["Uncommon"] = true;
L["Rare"] = true;
L["Epic"] = true;
L["Legendary"] = true;
L["Artifact"] = true;

L["Item Type"] = true;
-- The following values need to match the values returned by Blizzard's GetItemType function:
	L["Armor"] = true;
	L["Consumable"] = true;
	L["Container"] = true;
	L["Gem"] = true;
	L["Key"] = true;
	L["Miscellaneous"] = true;
	L["Reagent"] = true;
	L["Recipe"] = true;
	L["Projectile"] = true;
	L["Quest"] = true;
	L["Quiver"] = true;
	L["Trade Goods"] = true;
	L["Weapon"] = true;
	
L["Equip Slot"] = true;
L["Not Equipable"] = true;

-- FBoH Configuration

L["FuBar options"] = true;
L["Attach to minimap"] = true;
L["Show icon"] = true;
L["Show text"] = true;
L["Position"] = true;
L["Left"] = true;
L["Center"] = true;
L["Right"] = true;

L["Display"] = true;
L["Grid Scale"] = "Icon Scale";
L["Grid Scale Desc"] = "Scales the size of item icons in the icon view";

-- Views

L["Item in bank"] = true;
L["Item on "] = true;
L["Item in "] = true;
L["'s bank"] = true;
L["'s bags"] = true;

-- View Menu

L["Open All Views"] = true;
L["View as List"] = true;
L["Configure View"] = true;
L["Create New View"] = true;
L["Delete View"] = true;

-- View Configure frames

L["Configure Bag View"] = true;
L["Filters"] = true;
L["Sorting"] = true;
L["Name:"] = true;
L["Default Bag Filter"] = "The default bag view will display items for the current character not displayed in other bag views.";