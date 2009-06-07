local L = LibStub("AceLocale-3.0"):NewLocale("FBoH", "enUS", true)
if not L then return end;

L["Feithar's Bag of Holding"] = true;	-- Full Title
L["FBoH"] = true;						-- Short Title
L["fboh"] = true;						-- chat command
L["Undefined"] = true;

L["Bag View"] = true;
L["Main Bag"] = true;

L["Bags"] = true;
L["Bank"] = true;
L["Guild Bank"] = true;
L["Keyring"] = true;
L["Mailbox"] = true;
L["Wearing"] = true;

L["Soulbound"] = true;
L["Quest Item"] = true;

L["FuBar Hint"] = "Hint: Left click to open view menu. Right click to configure.";

-- Standard Filters

L["Realm"] = true;

L["Current Character"] = true;
L["Current Realm"] = true;
L[" (All)"] = true;

L["Bag Index"] = true;
L["Bag Type"] = true;
L["Character"] = true;
L["Item Name"] = true;
L["Tooltip"] = true;
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
L["- All %s -"] = true;
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
	
L["Item Subtype"] = true;

L["Equip Slot"] = true;
L["Not Equipable"] = true;

L["Last Moved"] = true;
L["Current Session"] = true;
L["Today"] = true;
L["Yesterday"] = true;
L["Last 7 Days"] = true;
L["Last 30 Days"] = true;

-- FBoH Configuration

--[[
L["FuBar options"] = true;
L["Attach to minimap"] = true;
L["Show icon"] = true;
L["Show text"] = true;
L["Position"] = true;
L["Left"] = true;
L["Center"] = true;
L["Right"] = true;
]]
L["Display"] = true;
L["Grid Scale"] = "Icon Scale";
L["Grid Scale Desc"] = "Scales the size of item icons in the icon view";
L["Enable debug"] = true;
L["Enable printing of debug messages to the chat window."] = true;

L["Hide Bank Items"] = true;
L["Hide bank items when not at the bank."] = true;
L["Hide Guild Bank Items"] = true;
L["Hide guild bank items when not at the bank."] = true;

L["General"] = true;
L["Hook Open All Bags"] = true;
L["Opening all bags will open FBoH bags instead."] = true;
L["Hook Open Backpack"] = true;
L["Opening the backpack will open the FBoH main view instead."] = true;
L["- FBoH Main Bag -"] = true;
L["- Blizzard Default -"] = true;
L["Hook Bag 1"] = true;
L["Opening bag 1 will open the selected bag instead."] = true;
L["Hook Bag 2"] = true;
L["Opening bag 2 will open the selected bag instead."] = true;
L["Hook Bag 3"] = true;
L["Opening bag 3 will open the selected bag instead."] = true;
L["Hook Bag 4"] = true;
L["Opening bag 4 will open the selected bag instead."] = true;

-- Views

L["Item in bank"] = true;
L["Item in guild bank"] = true;
L["Item on %s"] = true;
L["Item in %s's bank"] = true;
L["Item in %s's bags"] = true;
L["Item in %s's mailbox"] = true;
L["Item on %s's keyring"] = true;
L["Item worn by %s"] = true;

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
L["Sorters Help"] = "Drag properties from the left into this frame to sort by that property in the order by which they appear in this frame. Click the button for each sorter to toggle between ascending and descending order. Items belonging to the current character will always appear first and be grouped by location before any configured sorting is applied.";
L["Ascending"] = true;
L["Descending"] = true;
