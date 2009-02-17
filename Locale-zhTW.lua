-- Translation by romelden, on the Curse forums.

local L = LibStub("AceLocale-3.0"):NewLocale("FBoH", "zhTW")
if not L then return end;

L["Feithar's Bag of Holding"] = true;	-- Full Title
L["FBoH"] = true;						-- Short Title
L["fboh"] = true;						-- chat command
L["Undefined"] = "żʷٱ";

L["Bag View"] = "ƣƜϥ޹";
L["Main Bag"] = "ƄΉƝ";

L["Bags"] = "ϥ޹";
L["Bank"] = "܈Ǧ";
L["Guild Bank"] = "Ľؼ܈Ǧ";
L["Keyring"] = "ǟэѩ";
L["Mailbox"] = "׬ޣ";
L["Wearing"] = "ŷًԆ";

L["Soulbound"] = "ǆܮ٪ʷ";
L["Quest Item"] = "ƴшʫ̾";

L["FuBar Hint"] = "ԣƜ: Ū¤׽ҒKָƘ࠽. ƫ¤׽Ғԝʷ";

-- Standard Filters

L["Realm"] = "ѽg";

L["Current Character"] = "ӻǢȤǢ";
L["Current Realm"] = "ӻǢѽg";
L[" (All)"] = "ƾӡ";

L["Bag Index"] = "ϥ޹Ƙ࠽";
L["Bag Type"] = "ϥ޹ۘľ";
L["Character"] = "ȤǢ";
L["Item Name"] = "ʫ̾Ǘۙ";
L["Quality"] = "̾ި";

L["Not Soulbound"] = "ģ͏ǆܮ٪ʷ";

L["Poor"] = "ӊ";
L["Common"] = "ԶԱ";
L["Uncommon"] = "uɱ";
L["Rare"] = "۫ɽ";
L["Epic"] = "ƶٖ";
L["Legendary"] = "ׇۡ";
L["Artifact"] = "ϫ޹";

L["Item Type"] = "ʫ̾ľȏ";
-- The following values need to match the values returned by Blizzard's GetItemType function:
	L["Armor"] = "ƀƒ";
	L["Consumable"] = "ϸГ̾";
	L["Container"] = "ϥ޹";
	L["Gem"] = "Нş";
	L["Key"] = "ǟэ";
	L["Miscellaneous"] = "øֵ";
	L["Reagent"] = "ȷφ";
	L["Recipe"] = "ѴŨ";
	L["Projectile"] = "ݵĄ";
	L["Quest"] = "ƴш";
	L["Quiver"] = "ޢԕ";
	L["Trade Goods"] = "ѓ̾";
	L["Weapon"] = "˚޹";
	
L["Equip Slot"] = "ًԆǬ٭";
L["Not Equipable"] = "ģРًԆ";

L["Last Moved"] = "ŗƸҾъ";
L["Current Session"] = "ŻƸԳ޵";
L["Today"] = "ĵő";
L["Yesterday"] = "͑ő";
L["Last 7 Days"] = "Ԍ˱7ő";
L["Last 30 Days"] = "Ԍ˱30ő";

-- FBoH Configuration

L["FuBar options"] = "FuBar࠯ֵ";
L["Attach to minimap"] = "׋ɬŰǡڏ";
L["Show icon"] = "ƣƜڏϗ";
L["Show text"] = "ƣƜťǲ";
L["Position"] = "Ǭ٭";
L["Left"] = "Ū";
L["Center"] = "Ĥ";
L["Right"] = "ƫ";

L["Display"] = "ƣƜ";
L["Grid Scale"] = "ڏϗűɒ";
L["Grid Scale Desc"] = "ԝʷڏϗƣƜʺŪŰűɒ";

L["General"] = "ŀЫ";
L["Hook Open All Bags"] = "Գղƾӡϥ޹";
L["Opening all bags will open FBoH bags instead."] = "Ŵ׽ƾӡϥ޹ω,ؼƈFBoHƾӡϥ޹ƎՀ";
L["Hook Open Backpack"] = "ԳղΉƝ";
L["Opening the backpack will open the FBoH main view instead."] = "Ŵ׽ΉƝω, ƈFBoHƄΉƝƎՀ";
L["- FBoH Main Bag -"] = "- FBoH ƄΉƝ -";
L["- Blizzard Default -"] = true;
L["Hook Bag 1"] = "Գղϥ޹ 1";
L["Opening bag 1 will open the selected bag instead."] = "Ŵ׽ϥ޹ 1ω,ؼƈFBoH࠯ɺϥ޹ƎՀ";
L["Hook Bag 2"] = "Գղϥ޹ 2";
L["Opening bag 2 will open the selected bag instead."] = "Ŵ׽ϥ޹ 2ω,ؼƈFBoH࠯ɺϥ޹ƎՀ";
L["Hook Bag 3"] = "Գղϥ޹ 3";
L["Opening bag 3 will open the selected bag instead."] = "Ŵ׽ϥ޹ 3ω,ؼƈFBoH࠯ɺϥ޹ƎՀ";
L["Hook Bag 4"] = "Գղϥ޹ 4";
L["Opening bag 4 will open the selected bag instead."] = "Ŵ׽ϥ޹ 4ω,ؼƈFBoH࠯ɺϥ޹ƎՀ";

-- Views

L["Item in bank"] = "Ǣ܈Ǧʫ̾";
L["Item in guild bank"] = "ǢĽؼ܈Ǧʫ̾";
L["Item on %s"] = "ʳ %s ʺʫ̾";
L["Item in %s's bank"] = "ʳ %s ܈Ǧʺʫ̾";
L["Item in %s's bags"] = "ʳ %s ϥ޹ʺʫ̾";
L["Item in %s's mailbox"] = "ʳ %s ׬ޣʺʫ̾";
L["Item on %s's keyring"] = "ʳ %s ǟэѩʺʫ̾";
L["Item worn by %s"] = "Ƒ %s ͯ9ʺʫ̾";

-- View Menu

L["Open All Views"] = "׽ҒʒƳKָ";
L["View as List"] = "ƈӍԦKָ";
L["Configure View"] = "Kָԝʷ";
L["Create New View"] = "سݗKָ";
L["Delete View"] = "ȒУKָ";

-- View Configure frames

L["Configure Bag View"] = "ԝʷϥ޹Kָ";
L["Filters"] = "ڌݻ";
L["Sorting"] = "҆ȇ";
L["Name:"] = "Ǘۙ";
L["Default Bag Filter"] = "ڷԝϥ޹ؼƣƜӻǢȤǢ, ǽœɓƳƘӻʳɤƌϥ޹ƣƜʺʫ̾.";
L["Sorters Help"] = "ұŪĤʬʔГʊɬԯָϘ͛,ǢԯϘ͛ĺ̶Гʊ҆ȇƣƜ. É̶҆ȇ׳ɓԝԫֶȇʎ΋ȇ. ӻǢȤǢʺʫ̾, ƃ۷ؼͺƽƣƜ, ʎƩ̶Ǭ٭ŀľɓ҆ȇ.";
L["Ascending"] = "ֶȇ";
L["Descending"] = "΋ȇ";
