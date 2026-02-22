// =============================================================================
// noble_plus_vanilla_suppressor — единый файл подавления ванильных амбиций
// =============================================================================
// Для сценария "Дворянин +" (scenario.noble_plus) все ванильные амбиции должны
// быть исключены из пула выбора. Вместо отдельного хук-файла на каждую амбицию
// используем один цикл: итерируем список всех известных ванильных амбиций
// и хукаем их onUpdateScore() — ставим Score = 0 для нашего сценария.
//
// При обнаружении новой ванильной амбиции (например, из DLC) — достаточно
// добавить одну строку в список vanillaAmbs ниже.
//
// Паттерн без closure-проблем: внутренний function(o) не ссылается на переменную
// цикла, поэтому каждый вызов mods_hookExactClass получает корректный origUpdate.

local vanillaAmbs = [
    // ---- Базовые ванильные амбиции (хукаются Legends, но активны для всех сценариев) ----
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
    // ---- Кастомные амбиции Legends (тоже должны быть подавлены) ----
    "scripts/ambitions/ambitions/legend_have_all_camp_activities_ambition",
    "scripts/ambitions/ambitions/legend_roster_of_6_ambition",
    // ---- TODO: DLC Blazing Deserts ----
    // Идентифицировать файл амбиции "В южных городах-государствах деньги текут рекой..."
    // и добавить сюда. Найти через лог "never processed for hooks" после запуска теста.
];

foreach (p in vanillaAmbs)
{
    ::mods_hookExactClass(p, function(o)
    {
        local origUpdate = o.onUpdateScore.bindenv(o);

        o.onUpdateScore = function()
        {
            if (::World.Assets.getOrigin().getID() == "scenario.noble_plus")
            {
                this.m.Score = 0;
                return;
            }
            origUpdate();
        };
    });
}
