// =============================================================================
// noble_plus_vanilla_suppressor — подавление амбиций вне allowlist
// =============================================================================
// Важно: enumerateFiles("scripts/ambitions/ambitions") видит только файлы из
// data/scripts, но не все встроенные классы vanilla/DLC. Поэтому используем
// явный список известных ambition-классов.

local blockedClasses = [
    // Vanilla
    "scripts/ambitions/ambitions/allied_civilians_ambition",
    "scripts/ambitions/ambitions/allied_nobles_ambition",
    "scripts/ambitions/ambitions/cart_ambition",
    "scripts/ambitions/ambitions/defeat_orc_location_ambition",
    "scripts/ambitions/ambitions/defeat_undead_ambition",
    "scripts/ambitions/ambitions/defeat_undead_location_ambition",
    "scripts/ambitions/ambitions/find_and_destroy_location_ambition",
    "scripts/ambitions/ambitions/hammer_mastery_ambition",
    "scripts/ambitions/ambitions/have_all_provisions_ambition",
    "scripts/ambitions/ambitions/have_armor_upgrades_ambition",
    "scripts/ambitions/ambitions/have_talent_ambition",
    "scripts/ambitions/ambitions/make_nobles_aware_ambition",
    "scripts/ambitions/ambitions/named_item_set_ambition",
    "scripts/ambitions/ambitions/ranged_mastery_ambition",
    "scripts/ambitions/ambitions/roster_of_12_ambition",
    "scripts/ambitions/ambitions/roster_of_16_ambition",
    "scripts/ambitions/ambitions/roster_of_20_ambition",
    "scripts/ambitions/ambitions/visit_settlements_ambition",
    "scripts/ambitions/ambitions/wagon_ambition",
    "scripts/ambitions/ambitions/weapon_mastery_ambition",
    // Common DLC trade ambition aliases (Blazing Deserts)
    "scripts/ambitions/ambitions/trade_with_southern_city_states_ambition",
    "scripts/ambitions/ambitions/trade_with_southern_city_state_ambition",
    "scripts/ambitions/ambitions/trade_with_southern_cities_ambition",
    // Legends ambitions seen in pool
    "scripts/ambitions/ambitions/legend_have_all_camp_activities_ambition",
    "scripts/ambitions/ambitions/legend_roster_of_6_ambition"
];

local hookedCount = 0;

foreach (p in blockedClasses)
{
    ::mods_hookExactClass(p, function(o)
    {
        local origUpdate = o.onUpdateScore.bindenv(o);

        o.onUpdateScore = function()
        {
            origUpdate();

            if (this.World.Assets.getOrigin().getID() != "scenario.noble_plus") return;
            if (!("NoblePlus" in getroottable()) || !("Ambitions" in ::NoblePlus))
            {
                if (!("__AmbitionsRuntimeMissingLogged" in ::NoblePlus))
                {
                    ::NoblePlus.__AmbitionsRuntimeMissingLogged <- true;
                    ::logError("[NoblePlus][Ambitions] runtime missing in suppressor; stale data/scripts preload likely");
                }
                this.m.Score = 0;
                return;
            }

            local id = ("ID" in this.m) ? this.m.ID : null;
            if (id == null || !::NoblePlus.Ambitions.isAllowed(id))
            {
                this.m.Score = 0;
            }
        };
    });
    hookedCount = hookedCount + 1;
}

::logInfo("[NoblePlus][Ambitions] suppressor targets: " + hookedCount);
