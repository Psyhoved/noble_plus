// =============================================================================
// noble_plus_scenario — Дворянин + (Этап 3.2: полный стартовый отряд)
// =============================================================================
// ПРАВИЛО: НЕ вызывать this.starting_scenario.create() в create() — поля
// задаются напрямую. Это корневая причина краша "the index '0' does not exist".
// ПРАВИЛО: ОБЯЗАТЕЛЬНО вызывать this.starting_scenario.onInit() если onInit() определён.
// Подробнее: TECH.md раздел "Паттерн кастомного сценария".
//
// Состав отряда взят из legends_noble_scenario (Легенды 19.1.47) без изменений.
// Добавления по сравнению с Легендами будут в следующих этапах:
//   - Лютоволк для дворянина (Этап 3.2b)
//   - Кинжал для слуги    (Этап 3.2c)

this.noble_plus_scenario <- this.inherit("scripts/scenarios/world/starting_scenario", {
    m = {},

    function create()
    {
        this.m.ID          = "scenario.noble_plus";
        this.m.Name        = "Дворянин +";
        this.m.Order       = 171;
        this.m.Difficulty  = 2;
        this.m.IsFixedLook = true;
        this.m.StartingRosterTier = this.Const.Roster.getTierForSize(6);
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
        this.starting_scenario.onInit();
    }

    function onSpawnAssets()
    {
        try
        {
            ::logInfo("[NoblePlus] onSpawnAssets: ENTER");

            local roster = this.World.getPlayerRoster();

            // Создаём 6 персонажей разом (паттерн из legends_noble_scenario)
            for (local i = 0; i < 6; i = ++i)
            {
                local bro = roster.create("scripts/entity/tactical/player");
                if (i != 0)
                    bro.fillTalentValues(3);
            }

            local bros = roster.getAll();
            ::logInfo("[NoblePlus] onSpawnAssets: created " + bros.len() + " entities");

            // ------------------------------------------------------------------
            // bros[0] — Дворянин-командир
            // ------------------------------------------------------------------
            bros[0].getFlags().set("IsPlayerCharacter", true);
            bros[0].setStartValuesEx(["legend_noble_commander_background"], false);
            ::Legends.Traits.grant(bros[0], ::Legends.Trait.Player);
            bros[0].setPlaceInFormation(13);
            bros[0].setVeteranPerks(2);
            ::Legends.Traits.grant(bros[0], ::Legends.Trait.Drunkard);
            ::Legends.Traits.grant(bros[0], ::Legends.Trait.LegendNobleKiller);
            ::Legends.Effects.grant(bros[0], ::Legends.Effect.Drunk);
            this.addScenarioPerk(bros[0].getBackground(), this.Const.Perks.PerkDefs.Rotation);
            this.addScenarioPerk(bros[0].getBackground(), this.Const.Perks.PerkDefs.RallyTheTroops);
            ::logInfo("[NoblePlus] onSpawnAssets: bros[0] (commander) OK");

            // ------------------------------------------------------------------
            // bros[1] — Щитоносец 1
            // ------------------------------------------------------------------
            bros[1].setStartValuesEx(["legend_noble_shield"], false);
            local items1 = bros[1].getItems();
            items1.unequip(items1.getItemAtSlot(this.Const.ItemSlot.Offhand));
            local r = this.Math.rand(1, 2);
            local shield;
            if (r == 1)
                shield = this.new("scripts/items/shields/faction_kite_shield");
            else
                shield = this.new("scripts/items/shields/faction_heater_shield");
            items1.equip(shield);
            bros[1].getBackground().m.RawDescription = "Скромный лакей %name% имеет один из самых оптимистичных взглядов на жизнь, с которыми вы когда-либо сталкивались. К сожалению, это распространяется и на чрезмерную самооценку: он ожидает большей оплаты, чем большинство.";
            bros[1].getBackground().buildDescription(true);
            ::Legends.Traits.grant(bros[1], ::Legends.Trait.Optimist);
            ::Legends.Traits.grant(bros[1], ::Legends.Trait.Determined);
            ::Legends.Traits.grant(bros[1], ::Legends.Trait.Greedy);
            this.addScenarioPerk(bros[1].getBackground(), this.Const.Perks.PerkDefs.Rotation);
            bros[1].setPlaceInFormation(3);
            ::logInfo("[NoblePlus] onSpawnAssets: bros[1] (shield1) OK");

            // ------------------------------------------------------------------
            // bros[2] — Двуручник
            // ------------------------------------------------------------------
            bros[2].setStartValuesEx(["legend_noble_2h"], false);
            bros[2].getBackground().m.RawDescription = "%name% - это неуклюжая фигура, с какой стороны ни посмотри. Не очень разговорчивый, но большой любитель поесть.";
            bros[2].getBackground().buildDescription(true);
            ::Legends.Traits.remove(bros[2], ::Legends.Trait.Tiny);
            ::Legends.Traits.grant(bros[2], ::Legends.Trait.Huge);
            ::Legends.Traits.grant(bros[2], ::Legends.Trait.Fat);
            ::Legends.Traits.grant(bros[2], ::Legends.Trait.Gluttonous);
            this.addScenarioPerk(bros[2].getBackground(), this.Const.Perks.PerkDefs.Rotation);
            bros[2].setPlaceInFormation(4);
            ::logInfo("[NoblePlus] onSpawnAssets: bros[2] (2h) OK");

            // ------------------------------------------------------------------
            // bros[3] — Щитоносец 2
            // ------------------------------------------------------------------
            bros[3].setStartValuesEx(["legend_noble_shield"], false);
            local items3 = bros[3].getItems();
            items3.unequip(items3.getItemAtSlot(this.Const.ItemSlot.Offhand));
            r = this.Math.rand(1, 2);
            local shield3;
            if (r == 1)
                shield3 = this.new("scripts/items/shields/faction_kite_shield");
            else
                shield3 = this.new("scripts/items/shields/faction_heater_shield");
            items3.equip(shield3);
            bros[3].getBackground().m.RawDescription = "Оба его родителя служили вашей семье, это у них в крови. С одной стороны, %name% надежен в бою и никогда не подумал бы уйти от вас, с другой стороны, это ограничивает его чаяния и рвение.";
            bros[3].getBackground().buildDescription(true);
            ::Legends.Traits.grant(bros[3], ::Legends.Trait.LegendPragmatic);
            ::Legends.Traits.grant(bros[3], ::Legends.Trait.Loyal);
            ::Legends.Traits.grant(bros[3], ::Legends.Trait.LegendSlack);
            this.addScenarioPerk(bros[3].getBackground(), this.Const.Perks.PerkDefs.Rotation);
            bros[3].setPlaceInFormation(5);
            ::logInfo("[NoblePlus] onSpawnAssets: bros[3] (shield2) OK");

            // ------------------------------------------------------------------
            // bros[4] — Слуга
            // ------------------------------------------------------------------
            bros[4].setStartValuesEx(["servant_background"], false);
            bros[4].getBackground().m.RawDescription = "%name% был слугой в вашей семье уже пять поколений, непонятно, как можно было выжить так долго, но не видно никаких признаков того, что старый болван сдастся в ближайшее время.";
            bros[4].getBackground().buildDescription(true);
            ::Legends.Traits.grant(bros[4], ::Legends.Trait.Old);
            ::Legends.Traits.grant(bros[4], ::Legends.Trait.Loyal);
            ::Legends.Traits.grant(bros[4], ::Legends.Trait.Lucky);
            ::Legends.Traits.grant(bros[4], ::Legends.Trait.Survivor);
            this.addScenarioPerk(bros[4].getBackground(), this.Const.Perks.PerkDefs.Rotation);
            bros[4].setPlaceInFormation(12);
            local items4 = bros[4].getItems();
            items4.equip(this.Const.World.Common.pickArmor([[1, "linen_tunic"]]));
            items4.equip(this.Const.World.Common.pickHelmet([[1, "feathered_hat"]]));
            items4.equip(this.new("scripts/items/supplies/legend_pudding_item"));
            items4.addToBag(this.new("scripts/items/supplies/wine_item"));
            ::logInfo("[NoblePlus] onSpawnAssets: bros[4] (servant) OK");

            // ------------------------------------------------------------------
            // bros[5] — Стрелок
            // ------------------------------------------------------------------
            bros[5].setStartValuesEx(["legend_noble_ranged"], false);
            bros[5].getBackground().m.RawDescription = "%name% уже несколько лет подряд побеждает в соревнованиях по стрельбе из лука... и никогда, никогда не забывает упомянуть об этом. Постоянный поток болтовни делает его прекрасные навыки прицеливания практически бесполезными.";
            bros[5].getBackground().buildDescription(true);
            ::Legends.Traits.grant(bros[5], ::Legends.Trait.LegendSureshot);
            ::Legends.Traits.grant(bros[5], ::Legends.Trait.Teamplayer);
            ::Legends.Traits.grant(bros[5], ::Legends.Trait.LegendPredictable);
            this.addScenarioPerk(bros[5].getBackground(), this.Const.Perks.PerkDefs.Rotation);
            if (bros[5].getBaseProperties().RangedSkill <= 60)
                bros[5].getBaseProperties().RangedSkill += 5;
            bros[5].setPlaceInFormation(14);
            ::logInfo("[NoblePlus] onSpawnAssets: bros[5] (ranged) OK");

            // ------------------------------------------------------------------
            // Инвентарь отряда (stash)
            // ------------------------------------------------------------------
            local stash = this.World.Assets.getStash();
            stash.removeByID("supplies.ground_grains");
            stash.removeByID("supplies.ground_grains");
            stash.add(this.new("scripts/items/supplies/cured_rations_item"));
            stash.add(this.new("scripts/items/supplies/wine_item"));
            stash.add(this.new("scripts/items/loot/signet_ring_item"));
            this.World.Assets.addBusinessReputation(this.m.StartingBusinessReputation);
            this.World.Assets.m.Money = this.World.Assets.m.Money * 3;

            ::logInfo("[NoblePlus] onSpawnAssets: DONE");
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

            for (local i = 0; i < settlements.len(); i = ++i)
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

            // Отношения с ближайшим благородным домом + баннер + табарды
            local f = randomVillage.getFactionOfType(this.Const.FactionType.NobleHouse);
            if (f != null)
            {
                f.addPlayerRelation(-100.0, "Выбрал не ту сторону");
                local banner = f.getBanner();
                local brothers = this.World.getPlayerRoster().getAll();

                local shield1 = brothers[1].getItems().getItemAtSlot(this.Const.ItemSlot.Offhand);
                if (shield1 != null) shield1.setFaction(banner);
                local shield3 = brothers[3].getItems().getItemAtSlot(this.Const.ItemSlot.Offhand);
                if (shield3 != null) shield3.setFaction(banner);

                foreach (bro in brothers)
                {
                    local items = bro.getItems();
                    local armor = items.getItemAtSlot(this.Const.ItemSlot.Body);
                    local tabards = [[0, ""], [1, "tabard/legend_noble_tabard"]];
                    local tabard = this.Const.World.Common.pickLegendArmor(tabards);
                    if (tabard != null && armor != null)
                    {
                        tabard.setVariant(banner);
                        armor.setUpgrade(tabard);
                    }
                }
                ::logInfo("[NoblePlus] onSpawnPlayer: banner/tabards applied");
            }
            else
            {
                ::logInfo("[NoblePlus] onSpawnPlayer: no noble faction found near village, skipping banner");
            }

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

        foreach (bro in roster)
        {
            if (bro.getFlags().get("IsPlayerCharacter"))
                return true;
        }

        return false;
    }

    function onHiredByScenario( _bro )
    {
        if (_bro.getBackground().isBackgroundType(this.Const.BackgroundType.Noble))
        {
            _bro.improveMood(0.5, "Поддерживает ваше дело узурпатора, требуя пониженное жалование.");
        }
        else if (_bro.getBackground().isBackgroundType(this.Const.BackgroundType.Lowborn))
        {
            _bro.worsenMood(0.5, "Недолюбливает дворянство, поэтому будет требовать больше денег.");
        }
        _bro.improveMood(0.5, "Изучил новое умение");
    }

    function onUpdateHiringRoster( _roster )
    {
        local garbage = [];
        local bros = _roster.getAll();
        this.addBroToRoster(_roster, "legend_noble_2h", 4);
        this.addBroToRoster(_roster, "legend_noble_shield", 4);
        this.addBroToRoster(_roster, "legend_noble_ranged", 4);
        this.addBroToRoster(_roster, "adventurous_noble_background", 8);
        this.addBroToRoster(_roster, "disowned_noble_background", 8);

        foreach (i, bro in bros)
        {
            if (bro.getBackground().isBackgroundType(this.Const.BackgroundType.Outlaw))
                garbage.push(bro);
        }

        foreach (g in garbage)
            _roster.remove(g);
    }

    function onGenerateBro( bro )
    {
        if (bro.getBackground().isBackgroundType(this.Const.BackgroundType.Noble))
        {
            bro.m.HiringCost = this.Math.floor(bro.m.HiringCost * 0.75);
            bro.getBaseProperties().DailyWageMult *= 0.75;
            bro.getSkills().update();
        }
        else if (bro.getBackground().isBackgroundType(this.Const.BackgroundType.Lowborn))
        {
            bro.m.HiringCost = this.Math.floor(bro.m.HiringCost * 1.5);
            bro.getBaseProperties().DailyWageMult *= 1.5;
            bro.getSkills().update();
        }
    }

    function onBuildPerkTree( _background )
    {
        this.addScenarioPerk(_background, this.Const.Perks.PerkDefs.Rotation);
    }
});
