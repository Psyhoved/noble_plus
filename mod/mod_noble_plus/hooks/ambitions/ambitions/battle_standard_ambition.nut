// =============================================================================
// Хук ванильной амбиции "Знамя отряда" (battle_standard_ambition)
// =============================================================================
// ID амбиции в игре: "ambition.battle_standard"
// Награда: штандарт (работает как пика)
// Условие: потратить 2000 золотых (стандартная стоимость)
//
// Для сценария "Дворянин +" поведение управляется конфигом:
// allowlist, тексты и done-флаг берутся из ::NoblePlus.AmbitionsConfig.
// Базовая механика ванили (2000 крон -> штандарт) остаётся неизменной.

::mods_hookExactClass("ambitions/ambitions/battle_standard_ambition", function(o)
{
    local origCreate = o.create;
    o.create = function()
    {
        origCreate();
    };

    local origUpdateScore = o.onUpdateScore;
    o.onUpdateScore = function()
    {
        origUpdateScore();

        if (this.World.Assets.getOrigin().getID() != "scenario.noble_plus") return;
        if (!("NoblePlus" in getroottable()) || !("Ambitions" in ::NoblePlus))
        {
            if (!("__AmbitionsRuntimeMissingLogged" in ::NoblePlus))
            {
                ::NoblePlus.__AmbitionsRuntimeMissingLogged <- true;
                ::logError("[NoblePlus][Ambitions] runtime missing in battle_standard hook; stale data/scripts preload likely");
            }
            this.m.Score = 0;
            return;
        }

        local id = "ambition.battle_standard";
        local spec = ::NoblePlus.Ambitions.getSpec(id);
        if (spec == null || !::NoblePlus.Ambitions.isAllowed(id))
        {
            this.m.Score = 0;
            return;
        }

        ::NoblePlus.Ambitions.applyTexts(this, spec);
        this.m.Score = ::NoblePlus.Ambitions.getScore(id, 9999);

        if (this.m.IsDone)
        {
            local doneFlag = ::NoblePlus.Ambitions.getDoneFlag(id, "NoblePlus.Stage.OwnBanner.Done");
            if (!this.World.Flags.has(doneFlag))
            {
                this.World.Flags.set(doneFlag, true);
                ::NoblePlus.Ambitions.tryCompleteSet(spec.set_id);
            }
        }
    };
});
