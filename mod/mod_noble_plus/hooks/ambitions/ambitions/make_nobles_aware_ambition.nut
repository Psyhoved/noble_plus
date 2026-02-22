// =============================================================================
// Хук подавления ванильной амбиции "make_nobles_aware_ambition"
// =============================================================================
// Ванильная амбиция: "Попасться на глаза знатному дому"
// Подавляем для сценария "Дворянин +": в нашей нарративной линии эта
// амбиция заменена собственными (hire_soldiers, earn_gold, find_allies,
// battle_standard), и ванильная логика здесь не нужна.

::mods_hookExactClass("ambitions/ambitions/make_nobles_aware_ambition", function(o)
{
    local origUpdate = o.onUpdateScore;
    o.onUpdateScore = function()
    {
        // Для сценария "Дворянин +" — не показывать эту ванильную амбицию
        if (this.World.Assets.getOrigin().getID() == "scenario.noble_plus") return;
        // Для всех остальных сценариев — ванильное поведение
        origUpdate();
    };
});
