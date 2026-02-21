# Noble Plus — Техническая документация

## Игровой движок и язык скриптов

Battle Brothers использует собственный движок с поддержкой скриптового языка **Squirrel** (файлы `.nut`). Squirrel — это динамически типизированный язык в стиле JavaScript/Lua, созданный для встраивания в игры. В контексте Battle Brothers все игровые объекты (персонажи, предметы, сценарии, события) определяются именно через `.nut` файлы.

Ключевые особенности Squirrel, которые важно знать при работе с кодом BB:

Наследование работает через функцию `inherit`: `this.MyClass <- this.inherit("scripts/path/to/parent", { ... })`. Это создаёт новую таблицу (объект), которая наследует всё от родителя и расширяет/переопределяет нужные поля.

Поля объекта хранятся в таблице `m`: `this.m.Name`, `this.m.Value`, `this.m.Script` и т.д. Это соглашение всей кодовой базы Battle Brothers.

Глобальные константы доступны через `this.Const`, игровые системы через `this.World`, `this.Tactical`, `this.Time` и т.д.

---

## Виртуальная файловая система и структура мода

Battle Brothers использует виртуальную файловую систему с корнем в папке `data/`. Все ZIP-архивы модов «распаковываются» виртуально прямо в этот корень. Это ключевое знание — без его понимания мод просто не загрузится.

Поэтому preload-скрипты должны лежать в `data/scripts/!mods_preload/`, а НЕ в `data/mod_название/scripts/!mods_preload/` — движок в подпапки модов не смотрит. Аналогично, файлы сценариев кладутся в `data/scripts/scenarios/world/`.

Текущая структура файлов мода Noble Plus:

```
data/
├── scripts/
│   ├── !mods_preload/
│   │   └── mod_noble_plus.nut           ← регистрация мода (загружается первой)
│   └── scenarios/world/
│       └── noble_plus_scenario.nut      ← файл сценария
└── mod_noble_plus/                      ← папка для будущих хуков и ресурсов
```

---

## Система модинга: MSU и hooks

Моды не изменяют оригинальные файлы игры напрямую. Вместо этого используется система **патчинга через MSU (Modding Standards & Utilities)**.

Есть два основных способа патчинга. Первый — `::mods_hookExactClass("path/to/class", function(o) { ... })`: позволяет перехватить уже существующий класс и изменить или добавить в него методы. Переменная `o` — это оригинальный класс. Чтобы вызвать оригинальную версию метода, нужно сохранить её до переопределения: `local original = o.methodName; o.methodName = function() { original(); /* наш код */ }`.

Второй способ — `::mods_hookNewObject("path/to/class", function(o) { ... })`: перехватывает создание нового объекта этого класса.

Файлы-патчи кладутся в папку `hooks/` внутри папки мода. Новые скрипты (новые классы, которых не было в оригинале) кладутся в папку `scripts/`.

---

## Регистрация мода (рабочий паттерн)

```squirrel
::NoblePlus <- { ID = "mod_noble_plus", Version = "0.1.0", Name = "Noble Plus" };
::mods_registerMod(::NoblePlus.ID, ::NoblePlus.Version, ::NoblePlus.Name);
::mods_queue(::NoblePlus.ID, "mod_msu, mod_legends", function()
{
    ::NoblePlus.Mod <- ::MSU.Class.Mod(::NoblePlus.ID, ::NoblePlus.Version, ::NoblePlus.Name);
    // НЕ вызывать ::include для файла сценария здесь — см. раздел о сценариях ниже
    ::logInfo("Noble Plus " + ::NoblePlus.Version + " загружен.");
});
```

---

## Как движок регистрирует сценарии — критически важно

Движок BB сканирует `scripts/scenarios/world/` при **раннем старте**, ДО запуска очереди `mods_queue`, и создаёт экземпляры всех найденных там классов — именно тогда вызывается `create()`. Список доступных происхождений формируется на этом этапе.

Если дополнительно вызвать `::include(...)` на тот же файл сценария внутри `mods_queue`, файл загружается второй раз и переопределяет класс, но движок уже собрал список сценариев — второй вариант класса игнорируется и сценарий не появляется в меню.

**Вывод:** файл сценария должен просто лежать в `data/scripts/scenarios/world/` — движок подхватит его сам. `::include` в preload для файлов сценариев — ошибка.

---

## Паттерн кастомного сценария — нерушимые правила

Для создания нового происхождения нужно наследовать от `starting_scenario`. Именно от него наследуют все кастомные сценарии Легенд (`legends_free_company_scenario`, `legends_mage_scenario` и др.).

### Шесть нерушимых правил

| # | Правило |
|---|---------|
| 1 | **НЕ вызывать `this.starting_scenario.create()`** в `create()` — поля задаются напрямую. Это КОРНЕВАЯ ПРИЧИНА краша `the index '0' does not exist` |
| 2 | **ОБЯЗАТЕЛЬНО вызывать `this.starting_scenario.onInit()`** если `onInit()` определён в сценарии |
| 3 | **`setStartValuesEx()` принимает ОДИН аргумент** — массив строк с именами фонов |
| 4 | **`m = {}`** всегда пустой в определении класса |
| 5 | **6 обязательных полей в `create()`:** `ID`, `Name`, `Description`, `Difficulty`, `Order`, `StartingRosterTier` |
| 6 | **`onSpawnPlayer()` завершается триадой:** `spawnEntity` → `setCamera` → `scheduleEvent` |

### Правильный шаблон

```squirrel
this.my_scenario <- this.inherit("scripts/scenarios/world/starting_scenario", {
    m = {},  // всегда пустой

    function create()
    {
        // НИКОГДА не вызывать this.starting_scenario.create() !
        // Поля задаются напрямую.
        this.m.ID          = "scenario.mod_name.scenario_name"; // уникальный ID
        this.m.Name        = "Название";
        this.m.Description = "[p=c][img]gfx/ui/events/event_XX.png[/img][/p][p]Текст[/p]";
        this.m.Difficulty  = 2;          // 1–4
        this.m.Order       = 100;        // порядок в меню
        this.m.StartingRosterTier = this.Const.Roster.getTierForSize(3);
        // опционально:
        this.m.StartingBusinessReputation = 1000;
        this.setRosterReputationTiers(this.Const.Roster.createReputationTiers(this.m.StartingBusinessReputation));
    }

    function onInit()
    {
        this.starting_scenario.onInit(); // ОБЯЗАТЕЛЕН если onInit() определён
    }

    function onSpawnAssets()
    {
        local roster = this.World.getPlayerRoster();
        local bro = roster.create("scripts/entity/tactical/player");
        bro.m.HireTime = this.Time.getVirtualTimeF();
        bro.setStartValuesEx(["background_name"]); // ТОЛЬКО один аргумент — массив строк
        bro.getFlags().set("IsPlayerCharacter", true);       // если персонаж-игрок
        ::Legends.Traits.grant(bro, ::Legends.Trait.Player); // если персонаж-игрок
        this.World.Assets.addBusinessReputation(this.m.StartingBusinessReputation);
    }

    function onSpawnPlayer()
    {
        // 1. Найти деревню
        local settlements = this.World.EntityManager.getSettlements();
        local village = null;
        foreach (s in settlements) { if (s.isMilitary() && !s.isIsolatedFromRoads()) { village = s; break; } }
        if (village == null) village = settlements[0];
        // 2. Найти тайл рядом с деревней
        local tile = village.getTile(); // упрощённо, на практике — поиск через цикл
        // 3. Триада завершения (обязательно!)
        this.World.State.m.Player = this.World.spawnEntity("scripts/entity/world/player_party", tile.Coords.X, tile.Coords.Y);
        this.World.Assets.updateLook(101);
        this.World.getCamera().setPos(this.World.State.m.Player.getPos());
        this.Time.scheduleEvent(this.TimeUnit.Real, 1000, function(_tag) {
            this.World.Events.fire("event.my_intro");
        }, null);
    }

    function onCombatFinished()
    {
        foreach (bro in this.World.getPlayerRoster().getAll())
            if (bro.getFlags().get("IsPlayerCharacter")) return true;
        return false; // game over если никого не осталось
    }
});
```

---

## MSU Settings API — статус: требует уточнения

При попытке использовать `::NoblePlus.Mod.Settings` для добавления панели настроек мода получена ошибка: `the index 'Settings' does not exist`. Это означает что либо API называется иначе в версии MSU 1.7.2, либо нужна дополнительная инициализация. Нужно изучить исходники MSU на GitHub (https://github.com/MSUTeam/MSU) или посмотреть как настройки добавлены в других модах из установленного набора.

---

## Ключевые паттерны из Легенд

### Система компаньонов-животных (Accessory Companion)

Компаньон-животное — это предмет в accessory slot персонажа. Иерархия классов в Легендах:

```
accessory (базовый класс предметов)
    └── legend_accessory_dog   ← базовый класс для всех животных-компаньонов
            ├── legend_wardog_item          (обычный пёс, дешёвый)
            ├── legend_warhound_item        (волкодав, сильнее)
            ├── legend_wolf_item            (ручной волк, 600 золота)
            └── legend_white_wolf_item      (легендарный белый волк, 6000 золота) ← МЫ ИСПОЛЬЗУЕМ ЭТОТ
```

Ключевая механика: когда хозяин погибает в бою (`onActorDied`), животное автоматически материализуется на поле боя рядом с трупом. У живого хозяина есть активный скилл для ручного выпуска животного в свой ход.

**Белый волк / Лютоволк** (`legend_white_wolf_item`):
- ID: `accessory.legend_white_warwolf`
- Энтити в бою: `scripts/entity/tactical/legend_white_warwolf`
- Активный скилл выпуска: `::Legends.Active.LegendUnleashWhiteWolf`
- Стоимость: 6000 золота
- Файл предмета: `scripts/items/accessory/legend_white_wolf_item.nut`
- Имя по умолчанию: `"<случайное из WardogNames>, белый волк"` (например "Клык, белый волк")

Чтобы выдать персонажу волка с кастомным именем:
```squirrel
local wolf = this.new("scripts/items/accessory/legend_white_wolf_item");
wolf.m.Name = "Лютоволк"; // переопределяет случайное имя
bro.getItems().equip(wolf);
```

**Важно:** поля `m` предмета доступны напрямую после `this.new()` — никаких хуков не нужно.

### Механика game over при гибели персонажа (из Lone Wolf)

Реализована через переопределение метода `onCombatFinished` в сценарии. Метод возвращает `true` если игра продолжается, `false` если поражение:

```squirrel
o.onCombatFinished <- function()
{
    local roster = this.World.getPlayerRoster().getAll();
    foreach (bro in roster)
    {
        if (bro.getFlags().get("IsPlayerCharacter"))
        {
            return true; // дворянин жив — продолжаем
        }
    }
    return false; // дворянина нет — поражение
}
```

Флаг `IsPlayerCharacter` ставится на персонажа при создании:
```squirrel
bro.getFlags().set("IsPlayerCharacter", true);
::Legends.Traits.grant(bro, ::Legends.Trait.Player);
```

### Создание персонажа в сценарии (паттерн из Lone Wolf)

```squirrel
local roster = this.World.getPlayerRoster();
local bro = roster.create("scripts/entity/tactical/player");
bro.setStartValuesEx(["название_background"]);
bro.getBackground().buildDescription(true);
bro.setTitle("Сэр");
bro.getFlags().set("IsPlayerCharacter", true);
::Legends.Traits.grant(bro, ::Legends.Trait.Player);
bro.m.Level = 1;
bro.m.PerkPoints = 0;
```

---

## Лог игры

Игра пишет лог в `C:\Users\Aleksander\Documents\Battle Brothers\log.html`. Инструмент `read_game_log` в BB MCP Server парсит этот файл с фильтрами `only_errors=true` и `only_squirrel=true`.

Exe игры находится в `D:\SteamLibrary\steamapps\common\Battle Brothers\win32\BattleBrothers.exe` (не в корне папки игры, а в подпапке `win32`).

---

## Установленные моды и зависимости

Все моды лежат как ZIP-архивы в `D:\SteamLibrary\steamapps\common\Battle Brothers\data\`. Ключевые зависимости нашего мода: `mod_legends-19.1.47-russian.zip`, `mod_msu-1.7.2-russian.zip`. Также установлены: `mod_stronghold_2-russian.zip` (для будущих механик замка), `mod_modern_hooks.zip`.
