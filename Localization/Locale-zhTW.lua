-- Translation by romelden, on the Curse forums.

local L = LibStub("AceLocale-3.0"):NewLocale("FBoH", "zhTW")
if not L then return end;

L["Feithar's Bag of Holding"] = true;	-- Full Title
L["FBoH"] = true;						-- Short Title
L["fboh"] = true;						-- chat command
L["Undefined"] = "未定義";

L["Bag View"] = "顯示容器";
L["Main Bag"] = "主背包";

L["Bags"] = "容器";
L["Bank"] = "銀行";
L["Guild Bank"] = "公會銀行";
L["Keyring"] = "鑰匙圈";
L["Mailbox"] = "郵箱";
L["Wearing"] = "已裝備";

L["Soulbound"] = "靈魂綁定";
L["Quest Item"] = "任務物品";

L["FuBar Hint"] = "提示: 左鍵開啟檢視目錄. 右鍵開啟設定";

-- Standard Filters

L["Realm"] = "陣營";

L["Current Character"] = "現在角色";
L["Current Realm"] = "現在陣營";
L[" (All)"] = "全部";

L["Bag Index"] = "容器目錄";
L["Bag Type"] = "容器種類";
L["Character"] = "角色";
L["Item Name"] = "物品名稱";
L["Quality"] = "品質";

L["Not Soulbound"] = "不是靈魂綁定";

L["Poor"] = "粗糙";
L["Common"] = "普通";
L["Uncommon"] = "優秀";
L["Rare"] = "精良";
L["Epic"] = "史詩";
L["Legendary"] = "傳說";
L["Artifact"] = "神器";

L["Item Type"] = "物品類別";
-- The following values need to match the values returned by Blizzard's GetItemType function:
	L["Armor"] = "護甲";
	L["Consumable"] = "消耗品";
	L["Container"] = "容器";
	L["Gem"] = "珠寶";
	L["Key"] = "鑰匙";
	L["Miscellaneous"] = "雜項";
	L["Reagent"] = "材料";
	L["Recipe"] = "配方";
	L["Projectile"] = "彈藥";
	L["Quest"] = "任務";
	L["Quiver"] = "箭袋";
	L["Trade Goods"] = "商品";
	L["Weapon"] = "武器";
	
L["Equip Slot"] = "裝備位置";
L["Not Equipable"] = "不能裝備";

L["Last Moved"] = "上次移動";
L["Current Session"] = "本次連線";
L["Today"] = "今天";
L["Yesterday"] = "昨天";
L["Last 7 Days"] = "最近7天";
L["Last 30 Days"] = "最近30天";

-- FBoH Configuration

--[[
L["FuBar options"] = "FuBar選項";
L["Attach to minimap"] = "貼到小地圖";
L["Show icon"] = "顯示圖案";
L["Show text"] = "顯示文字";
L["Position"] = "位置";
L["Left"] = "左";
L["Center"] = "中";
L["Right"] = "右";
]]
L["Display"] = "顯示";
L["Grid Scale"] = "圖案比例";
L["Grid Scale Desc"] = "設定圖案顯示的大小比例";

L["General"] = "一般";
L["Hook Open All Bags"] = "連結全部容器";
L["Opening all bags will open FBoH bags instead."] = "打開全部容器時,會以FBoH全部容器代替";
L["Hook Open Backpack"] = "連結背包";
L["Opening the backpack will open the FBoH main view instead."] = "打開背包時, 以FBoH主背包代替";
L["- FBoH Main Bag -"] = "- FBoH 主背包 -";
L["- Blizzard Default -"] = true;
L["Hook Bag 1"] = "連結容器 1";
L["Opening bag 1 will open the selected bag instead."] = "打開容器 1時,會以FBoH選取容器代替";
L["Hook Bag 2"] = "連結容器 2";
L["Opening bag 2 will open the selected bag instead."] = "打開容器 2時,會以FBoH選取容器代替";
L["Hook Bag 3"] = "連結容器 3";
L["Opening bag 3 will open the selected bag instead."] = "打開容器 3時,會以FBoH選取容器代替";
L["Hook Bag 4"] = "連結容器 4";
L["Opening bag 4 will open the selected bag instead."] = "打開容器 4時,會以FBoH選取容器代替";

-- Views

L["Item in bank"] = "在銀行物品";
L["Item in guild bank"] = "在公會銀行物品";
L["Item on %s"] = "於 %s 的物品";
L["Item in %s's bank"] = "於 %s 銀行的物品";
L["Item in %s's bags"] = "於 %s 容器的物品";
L["Item in %s's mailbox"] = "於 %s 郵箱的物品";
L["Item on %s's keyring"] = "於 %s 鑰匙圈的物品";
L["Item worn by %s"] = "由 %s 穿戴的物品";

-- View Menu

L["Open All Views"] = "開啟所有檢視";
L["View as List"] = "以清單檢視";
L["Configure View"] = "檢視設定";
L["Create New View"] = "新增檢視";
L["Delete View"] = "刪除檢視";

-- View Configure frames

L["Configure Bag View"] = "設定容器檢視";
L["Filters"] = "過慮";
L["Sorting"] = "排序";
L["Name:"] = "名稱";
L["Default Bag Filter"] = "預設容器會顯示現在角色, 但又沒有出現於其他容器顯示的物品.";
L["Sorters Help"] = "從左邊拖拉特性到這視框架,在這框架內按特性排序顯示. 點按排序鈕來設換順序或倒序. 現在角色的物品, 永遠會首先顯示, 或可按位置分類來排序.";
L["Ascending"] = "順序";
L["Descending"] = "倒序";
