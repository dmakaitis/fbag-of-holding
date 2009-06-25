--Translation by StingerSoft

local L = LibStub("AceLocale-3.0"):NewLocale("FBoH", "ruRU")
if not L then return end;

L["Feithar's Bag of Holding"] = "Feithar's Bag of Holding";	-- Full Title
L["FBoH"] = "FBoH";						-- Short Title
L["fboh"] = "fboh";						-- chat command
L["Undefined"] = "Неопределённый";

L["Bag View"] = "Просмотр сумок";
L["Main Bag"] = "Основная сумка";

L["Bags"] = "Сумки";
L["Bank"] = "Банк";
L["Guild Bank"] = "Банк гильдии";
L["Keyring"] = "Связка ключей";
L["Mailbox"] = "Почта";
L["Wearing"] = "Wearing";

L["Soulbound"] = "Персональный предмет";
L["Quest Item"] = "Предмет, необходимый для задания";

L["FuBar Hint"] = "Совет:\n[Левый клик] - меню обзора.\n[Правый клик] - настройки.";

-- Standard Filters

L["Realm"] = "Мир";

L["Current Character"] = "Текущий персонаж";
L["Current Realm"] = "Текущий мир";
L[" (All)"] = " (Все)";

L["Bag Index"] = "Индекс сумки";
L["Bag Type"] = "Тип сумки";
L["Character"] = "Персонаж";
L["Item Name"] = "название предмета";
L["Tooltip"] = "Подсказка";
L["Quality"] = "Качество";

L["Not Soulbound"] = "Не персональный";

L["Poor"] = "Низкое";
L["Common"] = "Обычное";
L["Uncommon"] = "Необычное";
L["Rare"] = "Редкое";
L["Epic"] = "Превосходное";
L["Legendary"] = "Легендарное";
L["Artifact"] = "Артефакт";

L["Item Type"] = "Тип предмета";
L["- All %s -"] = "- Все %s -";
-- The following values need to match the values returned by Blizzard's GetItemType function:
	L["Armor"] = "Досехи";
	L["Consumable"] = "Расходуемые";
	L["Container"] = "Сумки";
	L["Gem"] = "Самоцветы";
	L["Key"] = "Ключи";
	L["Miscellaneous"] = "Разное";
	L["Reagent"] = "Реагенты";
	L["Recipe"] = "	Рецепты";
	L["Projectile"] = "Боеприпасы";
	L["Quest"] = "Задания";
	L["Quiver"] = "Амуниция";
	L["Trade Goods"] = "Хозяйственные товары";
	L["Weapon"] = "	Оружие";
	
L["Item Subtype"] = "Подтип предмета";

L["Equip Slot"] = "Ячейка снаряжения";
L["Not Equipable"] = "Не одевается";

L["Last Moved"] = "Последнее изменение";
L["Current Session"] = "Текущий сеанс";
L["Today"] = "Сегодня";
L["Yesterday"] = "Вчера";
L["Last 7 Days"] = "Последних 7 дней";
L["Last 30 Days"] = "Последних 30 дней";

-- FBoH Configuration

--[[
L["FuBar options"] = "";
L["Attach to minimap"] = "";
L["Show icon"] = "";
L["Show text"] = "";
L["Position"] = "";
L["Left"] = "";
L["Center"] = "";
L["Right"] = "";
]]
L["Display"] = "Вид";
L["Grid Scale"] = "Масштаб иконки";
L["Grid Scale Desc"] = "Масштаб размера иконки предметов";
L["Enable debug"] = "Включить отладку";
L["Enable printing of debug messages to the chat window."] = "Включение вывода отладочных сообщений в окне чата.";

L["Hide Bank Items"] = "Скрыть предметы банка";
L["Hide bank items when not at the bank."] = "Скрыть предметы банка если вы не в банке.";
L["Hide Guild Bank Items"] = "Скрыть предметы банка гильдии";
L["Hide guild bank items when not at the bank."] = "Скрыть предметы банка если вы не в банке гильдии.";

L["General"] = "Основное";
L["Hook Open All Bags"] = "Открывать все сумки";
L["Opening all bags will open FBoH bags instead."] = "Открывая все сумки будет открываться основной обзор FBoH, вместо стандартного.";
L["Hook Open Backpack"] = "Открывать рюкзак";
L["Opening the backpack will open the FBoH main view instead."] = "Открывая рюкзак будет открываться основной обзор FBoH, вместо стандартного.";
L["- FBoH Main Bag -"] = "- Основная сумка FBoH -";
L["- Blizzard Default -"] = "- Стандартная -";
L["Hook Bag 1"] = "Сумка 1";
L["Opening bag 1 will open the selected bag instead."] = "Открывая сумки #1 будет открываться сумка FBoH, вместо стандартной.";
L["Hook Bag 2"] = "Сумка 2";
L["Opening bag 2 will open the selected bag instead."] = "Открывая сумки #2 будет открываться сумка FBoH, вместо стандартной.";
L["Hook Bag 3"] = "Сумка 3";
L["Opening bag 3 will open the selected bag instead."] = "Открывая сумки #3 будет открываться сумка FBoH, вместо стандартной.";
L["Hook Bag 4"] = "Сумка 4";
L["Opening bag 4 will open the selected bag instead."] = "Открывая сумки #4 будет открываться сумка FBoH, вместо стандартной.";

-- Views

L["Item in bank"] = "Предмет в банке";
L["Item in guild bank"] = "Предмет в банке гильдии";
L["Item on %s"] = "Предмет на %s";
L["Item in %s's bank"] = "Предмет в банке |3-1(%s)";
L["Item in %s's bags"] = "Предмет в сумках |3-1(%s)";
L["Item in %s's mailbox"] = "Предмет на почте |3-1(%s)";
L["Item on %s's keyring"] = "Предмет на связке ключей |3-1(%s)";
L["Item worn by %s"] = "Item worn by %s";

-- View Menu

L["Open All Views"] = "Открыть все";
L["View as List"] = "Просмотр как списка";
L["Configure View"] = "Настройка просмотра";
L["Create New View"] = "Создать новый просмотр";
L["Delete View"] = "Удалить просмотр";

-- View Configure frames

L["Configure Bag View"] = "Настройка просмотра сумок";
L["Filters"] = "Фильтры";
L["Sorting"] = "Сортировка";
L["Name:"] = "Название:";
L["Default Bag Filter"] = "По умолчанию просмотр сумок будет отображать предметы текущего персонажа, в просмотрах других сумок - не отображаются.";
L["Sorters Help"] = "Перетащите свойства слева в эту рамку для применения порядка сортировки предметов в этом окне. Нажмите кнопку для переключения сортировки по возрастанию и убыванию. Предметы, принадлежащие текущему персонажу всегда будут появляться первымы и будут сгруппированы по положению до того как будет настроено применение сортировки.";
L["Ascending"] = "Возрастание";
L["Descending"] = "Убывание";
