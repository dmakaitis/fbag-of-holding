--[[-----------------------------------------------------------------------------
Name: FBoH_ItemRack.lua
Revision: $Revision: 75507 $
Author(s): Feithar
Description: Sample FBoH property definition.
-------------------------------------------------------------------------------]]

--[[-----------------------------------------------------------------------------
This is an example FBoH property, to show how FBoH can be
extended with custom properties. Currently properties are used
for filters, but this will be expanded to allow properties to be
used for sorting, searching, and column views in the future.

Comments will appear throughout to indicate how the property
is being defined.
-------------------------------------------------------------------------------]]
local L = LibStub("AceLocale-3.0"):GetLocale("FBoH_ItemRack")

local itemRack = {};

--[[-----------------------------------------------------------------------------
Every property needs a unique name. The name of the addon would
be a good choice if you're defining a single property to ensure
that it doesn't conflict with a property from another addon.
-------------------------------------------------------------------------------]]
itemRack.name = "FBoH_ItemRack";

--[[-----------------------------------------------------------------------------
The property description is what the user sees when they look at
a list of properties.
-------------------------------------------------------------------------------]]
itemRack.desc = L["ItemRack"];

--[[-----------------------------------------------------------------------------
The filter function is used to determine if an item matches the
filter setting for this property. The filter function will be passed
two parameters, the itemProps, and the user-specified setting.

The itemProps is a table with the following members:

itemProps = {
	realm		- the realm on which the item is located
	character	- the character on which the item is located
	bagtype	- the type of bag ("Bags", "Bank", "Mailbox", etc.)
	bagIndex	- which bag the object is located, starting with 1
	slotIndex	- which slot the object is located, starting with 1
	lastUpdate	- the last time the item was move (as returned by time() ) or nil
	itemKey	- key taken from the item string indicating what the item is
	itemCount	- how many items are in this slot
	soulbound	- true if the item is bound to the player
	itemLink	- item link string for the item (this may go away since it's duplicated in the detail subtable)
	detail = {		- item properties returned by GetItemInfo()
		name		- the item name
		link		- the item link
		rarity		- quality of the item, with 0 indicating "poor"
		level		- the level of the item
		minlevel	- the minimum level to equip the item
		type		- the type of item
		subtype	- the subtype of item
		stackcount	- number of items that can be stacked
		equiploc	- where the item can be equipped
		texture	- texture used for the item icon
	}
}

The second argument is whatever the user has specified for the
value of the filter. If the getOptions function, described below,
is not defined, the argument will be either a string or nil. If the
getOptions function is defined, the argument will be one of the
options returned by that function.

The filter function should return true if the item matches the
filter, or false if it does not.
-------------------------------------------------------------------------------]]
function itemRack.filter(itemProps, setName)
	local searchId = string.match(itemProps.itemLink, "item:%d+:%d+:%d+")
	if not searchId then return false end
	searchId = string.match(searchId, "%d+:%d+:%d+")

	local sets = ItemRackUser["Sets"];
	if not sets then return false end;
	
	for name, set in pairs(sets) do
		if (setName == "***ALL***") or (name == setName) then
			local setItems = set["equip"];
			if setItems then
				for _, item in pairs(setItems) do
					compareId = string.match(item, "%d+:%d+:%d+");
					if compareId == searchId then
						return true;
					end
				end
			end
		end
	end
	
	return false;
end

--[[-----------------------------------------------------------------------------
getOptions is an optional function that returns the available options
for the filter setting. If this function is not provided, the user will
be given a text edit box in which they can type free form text.

The function should return an array of tables, each of which
may have the following entries:

option = {
	name		- what the user sees as the name of the option
	value		- the value of the option that will be passed to the filter function
}

If value is a table rather than a string, then it will be interpretted
as an array of suboptions, defined as above. This can be used to
create submenus for the user to choose from.
-------------------------------------------------------------------------------]]
function itemRack.getOptions()
	local rVal = {	
		{
			name = L["Any Set"],
			value = "***ALL***",
		},
	};
	
	local sets = ItemRackUser.Sets;

	for name, set in pairs(sets) do
		if name:sub(1, 1) ~= "~" then
			local entry = {};
			entry.value = name;
			table.insert(rVal, entry);
		end
	end
	
	table.sort(rVal, function(a, b)
		return a.value < b.value;
	end);
	
	return rVal;
end

--[[-----------------------------------------------------------------------------
When the property is fully defined, it needs to be registered
with FBoH. In this example, we do an additional check to ensure
that ItemRack data (which is stored in the Rack_User global
variable) is available before registering the property.
-------------------------------------------------------------------------------]]
if ItemRackUser then
	FBoH:RegisterProperty(itemRack);
end

