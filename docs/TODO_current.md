# TODO: Исправление сценария noble_plus_scenario (Этап 3.1)

## Контекст для агента

Читай этот файл вместе с README.md, TECH.md, JOURNAL.md и ROADMAP.md из этой папки.

Мод загружается без ошибок. Класс `noble_plus_scenario` создаётся (подтверждено логом).
Но при выборе происхождения видна пустая строка вместо названия, а запуск кампании
вызывает бесконечную загрузку карты мира. Ниже — диагноз и пошаговый план исправления.

Файл сценария находится здесь:
`D:\SteamLibrary\steamapps\common\Battle Brothers\data\scripts\scenarios\world\noble_plus_scenario.nut`

Образец для подражания — `legends_noble_scenario.nut` из архива Легенд.
Он уже распакован в `/tmp/msu_check/scripts/scenarios/world/legends_noble_scenario.nut`
и является наиболее близким к нашему по структуре полностью рабочим сценарием.

---

## Диагноз двух багов

**Баг 1 — пустое название.** Наш `create()` вызывает `this.starting_scenario.create()`.
Ни один сценарий Легенд так не делает — они выставляют поля `m` напрямую.
Ванильный `starting_scenario.create()` сбрасывает поля к дефолтам, перезаписывая
наши значения `m.Name`, `m.Description` и т.д. В итоге название остаётся пустым.

**Баг 2 — бесконечная загрузка.** В сценарии отсутствует метод `onSpawnPlayer()`.
Именно он размещает отряд игрока на карте мира через вызов `World.spawnEntity(...)`.
Без него генерация мира завершается, но игрок никогда не появляется на карте —
движок входит в бесконечный цикл ожидания.

---

## Пошаговый план исправления

Все шаги реализуются в одном файле `noble_plus_scenario.nut`.
После каждого шага — перезапуск игры и проверка лога через `read_game_log(only_squirrel=true)`.

### Шаг 1 — Исправить `create()` [исправляет Баг 1]

Убрать вызов `this.starting_scenario.create()` полностью.
Выставить все поля напрямую, как это делает `legends_noble_scenario`.
Обязательные поля:

```squirrel
this.m.ID = "scenario.noble_plus";
this.m.Name = "Дворянин +";
this.m.Description = "..."; // BBCode-текст
this.m.Difficulty = 2;
this.m.Order = 171;         // чуть выше чем у legends_noble (170), чтобы стоять рядом
this.m.IsFixedLook = true;
this.m.StartingRosterTier = this.Const.Roster.getTierForSize(3);
this.m.StartingBusinessReputation = 1000;
this.setRosterReputationTiers(this.Const.Roster.createReputationTiers(this.m.StartingBusinessReputation));
```

Критерий успеха: название "Дворянин +" видно в меню выбора происхождений,
картинка и описание отображаются корректно.

### Шаг 2 — Добавить `onInit()` [стабильность]

Легенды патчат `starting_scenario` и добавляют в него поля через хук.
`onInit` инициализирует эти структуры в рантайме. Все рабочие сценарии Легенд
реализуют его. Без него могут не инициализироваться внутренние данные.

```squirrel
function onInit()
{
    this.starting_scenario.onInit();
}
```

### Шаг 3 — Добавить минимальный `onSpawnAssets()` [нужен для Шага 4]

Создаём одного персонажа — дворянина — чтобы ростер не был пустым
во время выполнения `onSpawnPlayer`. Полный стартовый состав (слуга, волк)
реализуется в Этапе 3.2, здесь нужен только минимум.

```squirrel
function onSpawnAssets()
{
    local roster = this.World.getPlayerRoster();
    local bro = roster.create("scripts/entity/tactical/player");
    bro.setStartValuesEx(["disowned_noble_background"], false);
    bro.getFlags().set("IsPlayerCharacter", true);
    ::Legends.Traits.grant(bro, ::Legends.Trait.Player);
    bro.setPlaceInFormation(13);
    this.World.Assets.addBusinessReputation(this.m.StartingBusinessReputation);
}
```

### Шаг 4 — Добавить `onSpawnPlayer()` [исправляет Баг 2]

Спавним отряд рядом с военным поселением (замком) — так же как `legends_noble_scenario`.
Три обязательных вызова: найти тайл, вызвать `spawnEntity`, поставить камеру.

НЕ копировать из `legends_noble_scenario` строки про `setFaction(banner)` и
`brothers[1].getItems()...` — они рассчитаны на 6 персонажей и упадут у нас.
НЕ вызывать событие `event.legend_noble_scenario_intro` — оно не наше.

```squirrel
function onSpawnPlayer()
{
    local randomVillage;

    for (local i = 0; i != this.World.EntityManager.getSettlements().len(); i = ++i)
    {
        randomVillage = this.World.EntityManager.getSettlements()[i];
        if (randomVillage.isMilitary() && !randomVillage.isIsolatedFromRoads())
            break;
    }

    local randomVillageTile = randomVillage.getTile();
    local navSettings = this.World.getNavigator().createSettings();
    navSettings.ActionPointCosts = this.Const.World.TerrainTypeNavCost_Flat;

    do
    {
        local x = this.Math.rand(this.Math.max(2, randomVillageTile.SquareCoords.X - 7), this.Math.min(this.Const.World.Settings.SizeX - 2, randomVillageTile.SquareCoords.X + 7));
        local y = this.Math.rand(this.Math.max(2, randomVillageTile.SquareCoords.Y - 7), this.Math.min(this.Const.World.Settings.SizeY - 2, randomVillageTile.SquareCoords.Y + 7));

        if (!this.World.isValidTileSquare(x, y)) {}
        else
        {
            local tile = this.World.getTileSquare(x, y);
            if (tile.Type == this.Const.World.TerrainType.Ocean || tile.Type == this.Const.World.TerrainType.Shore || tile.IsOccupied) {}
            else if (tile.getDistanceTo(randomVillageTile) <= 4) {}
            else if (!tile.HasRoad) {}
            else
            {
                local path = this.World.getNavigator().findPath(tile, randomVillageTile, navSettings, 0);
                if (!path.isEmpty())
                {
                    randomVillageTile = tile;
                    break;
                }
            }
        }
    }
    while (1);

    this.World.State.m.Player = this.World.spawnEntity("scripts/entity/world/player_party", randomVillageTile.Coords.X, randomVillageTile.Coords.Y);
    this.World.Assets.updateLook(101); // 101 = внешний вид отряда дворянина, как в legends_noble
    this.World.getCamera().setPos(this.World.State.m.Player.getPos());
}
```

Критерий успеха: кампания запускается, отряд появляется на карте мира рядом с замком.

### Шаг 5 — Добавить `onCombatFinished()` [механика game-over]

Паттерн полностью из `legends_noble_scenario`, уже задокументирован в TECH.md.

```squirrel
function onCombatFinished()
{
    local roster = this.World.getPlayerRoster().getAll();
    foreach (bro in roster)
    {
        if (bro.getFlags().get("IsPlayerCharacter"))
            return true;
    }
    return false;
}
```

### Шаг 6 — Добавить заглушки `onHiredByScenario()` и `onUpdateHiringRoster()`

Легенды добавляют эти методы к `starting_scenario` через хук. Явные заглушки
в нашем классе защищают от непредсказуемого поведения, если Легенды изменят
реализацию базового класса в будущей версии.

```squirrel
function onHiredByScenario(_bro) {}
function onUpdateHiringRoster(_roster) {}
```

---

## Критерий завершения Этапа 3.1

Этап считается выполненным когда выполнены все три пункта одновременно:
в логе нет ошибок уровня ERROR с тегом SQ после запуска игры,
в меню выбора происхождений отображается "Дворянин +" с правильным текстом и картинкой,
запуск кампании приводит к появлению отряда на карте мира без зависания.

После завершения: обновить ROADMAP.md (Этап 3.1 → DONE, Этап 3.2 → СЛЕДУЮЩИЙ ШАГ)
и добавить запись в JOURNAL.md.
