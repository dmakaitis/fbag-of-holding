-- Translation by zhltr, on the WoWAce forums.

local L = LibStub("AceLocale-3.0"):NewLocale("FBoH", "deDE")
if not L then return end;

L["Feithar's Bag of Holding"] = true;	-- Full Title
L["FBoH"] = true;						-- Short Title
L["fboh"] = true;						-- chat command
L["Undefined"] = true;

L["Bag View"] = "Taschen Anzeige";
L["Main Bag"] = "Haupttasche";

L["Bags"] = "Taschen";
L["Bank"] = "Bank";
L["Guild Bank"] = "Gilden Bank";
L["Keyring"] = "Schlüsselbund";
L["Mailbox"] = "Briefkasten";
L["Wearing"] = "Angezogen";

L["Soulbound"] = "Seelengebunden";
L["Quest Item"] = "Questgegenstand";

L["FuBar Hint"] = "Tip: Linke Maustaste Ansichtsmenü. Rechte Maustaste Konfiguration.";

-- Standard Filters

L["Realm"] = "Realm";

L["Current Character"] = "Aktueller Charakter";
L["Current Realm"] = "Aktueller Realm";
L[" (All)"] = " (Alle)";

L["Bag Index"] = "Taschen Index";
L["Bag Type"] = "Taschen Typ";
L["Character"] = "Charakter";
L["Item Name"] = "Item Name";
L["Quality"] = "Qualität";

L["Not Soulbound"] = "Nicht Seelengebunden";

L["Poor"] = "Schlecht";
L["Common"] = "Verbreitet";
L["Uncommon"] = "Selten";
L["Rare"] = "Rar";
L["Epic"] = "Episch";
L["Legendary"] = "Legendär";
L["Artifact"] = "Artefakt";

L["Item Type"] = "Item Typ";
-- The following values need to match the values returned by Blizzard's GetItemType function:
	L["Armor"] = "Rüstung";
	L["Consumable"] = "Verbrauchbar";
	L["Container"] = "Behälter";
	L["Gem"] = "Edelstein";
	L["Key"] = "Schlüssel";
	L["Miscellaneous"] = "Verschiedenes";
	L["Reagent"] = "Reagenz";
	L["Recipe"] = "Rezept";
	L["Projectile"] = "Projektil";
	L["Quest"] = "Quest";
	L["Quiver"] = "Köcher";
	L["Trade Goods"] = "Handwerkswaren";
	L["Weapon"] = "Waffe";
	
L["Equip Slot"] = "Equip Slot";
L["Not Equipable"] = "Nicht anlegbar";

L["Last Moved"] = "Zuletzt Verschoben";
L["Current Session"] = "Aktuelle Session";
L["Today"] = "Heute";
L["Yesterday"] = "Gestern";
L["Last 7 Days"] = "Letzten 7 Tage";
L["Last 30 Days"] = "Letzten 30 Tage";

-- FBoH Configuration

--[[
L["FuBar options"] = "FuBar Optionen";
L["Attach to minimap"] = "Befestigen an der Minimap";
L["Show icon"] = "Icon anzeigen";
L["Show text"] = "Text anzeigen";
L["Position"] = "Position";
L["Left"] = "Links";
L["Center"] = "Mitte";
L["Right"] = "Rechts";
]]
L["Display"] = "Display";
L["Grid Scale"] = "Icon Skalierung";
L["Grid Scale Desc"] = "Skaliert die Grö?e der Item Icons in den Fenstern";

L["General"] = "General";
L["Hook Open All Bags"] = "Hook Alle Taschen öffnen";
L["Opening all bags will open FBoH bags instead."] = "FBoH Taschen werden anstatt -Alle Taschen öffnen- geöffnet";
L["Hook Open Backpack"] = "Hook R?cksack öffnen";
L["Opening the backpack will open the FBoH main view instead."] = "Beim Öffnen des Rucksacks wird das FBoH Hauptfenster geöffnet.";
L["- FBoH Main Bag -"] = true;
L["- Blizzard Default -"] = true;
L["Hook Bag 1"] = "Hook Tasche 1";
L["Opening bag 1 will open the selected bag instead."] = "Beim Öffnen der Tasche 1 wird die selektierte Tasche geöffnet.";
L["Hook Bag 2"] = "Hook Tasche 2";
L["Opening bag 2 will open the selected bag instead."] = "Beim Öffnen der Tasche 2 wird die selektierte Tasche geöffnet.";
L["Hook Bag 3"] = "Hook Tasche 3";
L["Opening bag 3 will open the selected bag instead."] = "Beim Öffnen der Tasche 3 wird die selektierte Tasche geöffnet.";
L["Hook Bag 4"] = "Hook Tasche 4";
L["Opening bag 4 will open the selected bag instead."] = "Beim Öffnen der Tasche 4 wird die selektierte Tasche geöffnet.";

-- Views

L["Item in bank"] = "Item in der Bank";
L["Item in guild bank"] = "Item in der Gilden Bank";
L["Item on %s"] = "Item von %s";
L["Item in %s's bank"] = "Item in %s's Bank"
L["Item in %s's bags"] = "Item in %s's Taschen";
L["Item in %s's mailbox"] = "Item in %s's Briefkasten";
L["Item on %s's keyring"] = "Item in %s's Schlüsselring";
L["Item worn by %s"] = "Item getragen von %s";

-- View Menu

L["Open All Views"] = "Öffne alle Fenster";
L["View as List"] = "Fenster als Liste";
L["Configure View"] = "Konfigurationsfenster";
L["Create New View"] = "Erstelle Neues Fenster";
L["Delete View"] = "Lösche Fenster";

-- View Configure frames

L["Configure Bag View"] = "Konfiguriere Tachen Fenster";
L["Filters"] = "Filter";
L["Sorting"] = "Sortierung";
L["Name:"] = "Name:";
L["Default Bag Filter"] = "The default bag view will display items for the current character not displayed in other bag views.";
L["Sorters Help"] = "Drag properties from the left into this frame to sort by that property in the order by which they appear in this frame. Click the button for each sorter to toggle between ascending and descending order. Items belonging to the current character will always appear first and be grouped by location before any configured sorting is applied.";
L["Ascending"] = "Aufwärts";
L["Descending"] = "Abwärts";