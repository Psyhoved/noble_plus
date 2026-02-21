// =============================================================================
// noble_plus_scenario — Дворянин + (Этап 3.1, финал)
// =============================================================================
// ПРАВИЛО: НЕ вызывать this.starting_scenario.create() в create() — поля
// задаются напрямую. Это корневая причина краша "the index '0' does not exist".
// ПРАВИЛО: ОБЯЗАТЕЛЬНО вызывать this.starting_scenario.onInit() если onInit() определён.
// Подробнее: TECH.md раздел "Паттерн кастомного сценария".

this.noble_plus_scenario <- this.inherit("scripts/scenarios/world/starting_scenario", {
    m = {},

    function create()
    {
        this.m.ID         = "scenario.noble_plus";
        this.m.Name       = "Дворянин +";
        this.m.Order      = 171;
        this.m.Difficulty = 2;
        this.m.StartingRosterTier = this.Const.Roster.getTierForSize(3);
        this.m.StartingBusinessReputation = 1000;
        this.setRosterReputationTiers(this.Const.Roster.createReputationTiers(this.m.StartingBusinessReputation));

        this.m.Description =
            "[p=c][img]gfx/ui/events/event_176.png[/img][/p]" +
            "[p]Вы — опальный дворянин, изгнанный из родового замка завистливыми " +
            "родственниками. Всё, что у вас осталось — верный слуга, горстка монет " +
            "и ваш родовой зверь: легендарный белый волк, с которым вы выросли и " +
            "которого не предали даже в бегстве. Теперь вам предстоит с нуля " +
            "вернуть себе имя, честь и замок.\n\n" +
            "[color=#bcad8c]Родовой зверь:[/color] Дворянин начинает с легендарным " +
            "белым волком в качестве спутника. Волк может быть выпущен в бою.\n" +
            "[color=#bcad8c]Слуга:[/color] Верный слуга начинает вооружённым кинжалом.\n" +
            "[color=#c90000]Честь дворянина:[/color] Если дворянин погибнет — " +
            "игра окончена.[/p]";
    }

    function onInit()
    {
        // Вызываем базовый onInit — Легенды его патчат для добавления
        // StaticRelationsToFaction и других полей
        this.starting_scenario.onInit();
    }

    function onSpawnAssets()
    {
        // try/catch: если что-то упадёт — ловим ошибку и логируем.
        // Это позволяет буферу лога сбросится на диск.
        try
        {
            ::logInfo("[NoblePlus] onSpawnAssets: ENTER");

            local roster = this.World.getPlayerRoster();
            ::logInfo("[NoblePlus] onSpawnAssets: roster OK, len=" + roster.getAll().len());

            local bro = roster.create("scripts/entity/tactical/player");
            ::logInfo("[NoblePlus] onSpawnAssets: bro entity created");

            // БЕЗ false — именно так вызывает addBroToRoster в Легендах
            bro.setStartValuesEx(["disowned_noble_background"]);
            ::logInfo("[NoblePlus] onSpawnAssets: setStartValuesEx OK");

            bro.getFlags().set("IsPlayerCharacter", true);
            ::logInfo("[NoblePlus] onSpawnAssets: IsPlayerCharacter flag set");

            ::Legends.Traits.grant(bro, ::Legends.Trait.Player);
            ::logInfo("[NoblePlus] onSpawnAssets: Player trait granted");

            bro.setPlaceInFormation(13);
            ::logInfo("[NoblePlus] onSpawnAssets: formation set");

            this.World.Assets.addBusinessReputation(this.m.StartingBusinessReputation);
            ::logInfo("[NoblePlus] onSpawnAssets: reputation added, DONE");
        }
        catch (e)
        {
            ::logError("[NoblePlus] *** CRASH in onSpawnAssets: " + e + " ***");
        }
    }

    function onSpawnPlayer()
    {
        try
        {
            ::logInfo("[NoblePlus] onSpawnPlayer: ENTER");

            local settlements = this.World.EntityManager.getSettlements();
            ::logInfo("[NoblePlus] onSpawnPlayer: settlements count=" + settlements.len());

            local randomVillage = null;

            for( local i = 0; i < settlements.len(); i = ++i )
            {
                local s = settlements[i];
                if (s.isMilitary() && !s.isIsolatedFromRoads())
                {
                    randomVillage = s;
                    break;
                }
            }

            if (randomVillage == null)
            {
                ::logError("[NoblePlus] onSpawnPlayer: no military village found, using first settlement");
                randomVillage = settlements[0];
            }

            ::logInfo("[NoblePlus] onSpawnPlayer: village found");

            local randomVillageTile = randomVillage.getTile();
            local navSettings = this.World.getNavigator().createSettings();
            navSettings.ActionPointCosts = this.Const.World.TerrainTypeNavCost_Flat;

            local spawnTile = randomVillageTile;
            local attempts = 0;

            do
            {
                attempts = ++attempts;
                if (attempts > 500)
                {
                    ::logError("[NoblePlus] onSpawnPlayer: spawn search timeout, using village tile");
                    spawnTile = randomVillageTile;
                    break;
                }

                local x = this.Math.rand(
                    this.Math.max(2, randomVillageTile.SquareCoords.X - 7),
                    this.Math.min(this.Const.World.Settings.SizeX - 2, randomVillageTile.SquareCoords.X + 7)
                );
                local y = this.Math.rand(
                    this.Math.max(2, randomVillageTile.SquareCoords.Y - 7),
                    this.Math.min(this.Const.World.Settings.SizeY - 2, randomVillageTile.SquareCoords.Y + 7)
                );

                if (!this.World.isValidTileSquare(x, y)) continue;

                local tile = this.World.getTileSquare(x, y);

                if (tile.Type == this.Const.World.TerrainType.Ocean ||
                    tile.Type == this.Const.World.TerrainType.Shore ||
                    tile.IsOccupied) continue;

                if (tile.getDistanceTo(randomVillageTile) <= 4) continue;

                if (!tile.HasRoad || tile.Type == this.Const.World.TerrainType.Shore) continue;

                local path = this.World.getNavigator().findPath(tile, randomVillageTile, navSettings, 0);

                if (!path.isEmpty())
                {
                    spawnTile = tile;
                    break;
                }
            }
            while (1);

            ::logInfo("[NoblePlus] onSpawnPlayer: spawn point found after " + attempts + " attempts");

            this.World.State.m.Player = this.World.spawnEntity(
                "scripts/entity/world/player_party",
                spawnTile.Coords.X,
                spawnTile.Coords.Y
            );

            this.World.Assets.updateLook(101);
            this.World.getCamera().setPos(this.World.State.m.Player.getPos());

            ::logInfo("[NoblePlus] onSpawnPlayer: DONE");
        }
        catch (e)
        {
            ::logError("[NoblePlus] *** CRASH in onSpawnPlayer: " + e + " ***");
        }
    }

    function onCombatFinished()
    {
        local roster = this.World.getPlayerRoster().getAll();

        foreach( bro in roster )
        {
            if (bro.getFlags().get("IsPlayerCharacter"))
            {
                return true;
            }
        }

        return false;
    }
});
