// =============================================================================
// noble_plus_earn_gold_ambition — Этап 1.2: "Накопить золото"
// =============================================================================
// Нарративная амбиция Главы I: накопить 2000 золотых крон.
// Активна только для "Дворянин +" (scenario.noble_plus).
// Доступна с первого дня одновременно с остальными амбициями Главы I.
//
// Прогресс: текущее золото / 2000
// Завершение: World.Assets.getMoney() >= 2000
//
// ПОЛЯ ОТОБРАЖЕНИЯ:
//   ButtonText — текст на карточке в экране выбора амбиции (читается Legends UI)
//   UIText     — краткий текст в топбаре (читается ambition_manager)

this.noble_plus_earn_gold_ambition <- this.inherit("scripts/ambitions/ambition", {
    m = {
        ID              = "ambition.noble_plus.earn_gold",
        ButtonText      = "Накопи 2000 золотых крон для подготовки к осаде.",
        UIText          = "Накопи 2000 золотых крон для подготовки к осаде.",
        TooltipText     =
            "Армия стоит дорого. Замок стоит ещё дороже.\n\n" +
            "Выполняй контракты, нападай на лагеря разбойников, продавай трофеи. " +
            "Деньги — это не цель: они инструмент. Инструмент, без которого " +
            "ты не дойдёшь до ворот родного замка.\n\n" +
            "[color=#bcad8c]Задача:[/color] Накопи не менее " +
            "[color=#bcad8c]2000 золотых крон[/color].",
        SuccessText     =
            "[img]gfx/ui/events/event_176.png[/img]\n\n" +
            "Казна полна. Достаточно, чтобы вооружить людей получше. Достаточно, " +
            "чтобы купить чью-то верность — или молчание.\n\n" +
            "Но золото без союзников — это просто красивые монеты. " +
            "[color=#bcad8c]Пришло время искать друзей.[/color]",
        SuccessButtonText = "Продолжать.",
        Icon            = "ambition_gold"
    },

    function create()
    {
        this.ambition.create();
        // Задаём поля после вызова родителя — он может сбросить m.
        this.m.ID               = "ambition.noble_plus.earn_gold";
        this.m.ButtonText       = "Накопи 2000 золотых крон для подготовки к осаде.";
        this.m.UIText           = "Накопи 2000 золотых крон для подготовки к осаде.";
        this.m.TooltipText      =
            "Армия стоит дорого. Замок стоит ещё дороже.\n\n" +
            "Выполняй контракты, нападай на лагеря разбойников, продавай трофеи. " +
            "Деньги — это не цель: они инструмент. Инструмент, без которого " +
            "ты не дойдёшь до ворот родного замка.\n\n" +
            "[color=#bcad8c]Задача:[/color] Накопи не менее " +
            "[color=#bcad8c]2000 золотых крон[/color].";
        this.m.SuccessText      =
            "[img]gfx/ui/events/event_176.png[/img]\n\n" +
            "Казна полна. Достаточно, чтобы вооружить людей получше. Достаточно, " +
            "чтобы купить чью-то верность — или молчание.\n\n" +
            "Но золото без союзников — это просто красивые монеты. " +
            "[color=#bcad8c]Пришло время искать друзей.[/color]";
        this.m.SuccessButtonText = "Продолжать.";
        this.m.Icon             = "ambition_gold";

        if ("NoblePlus" in getroottable() && "Ambitions" in ::NoblePlus)
        {
            local spec = ::NoblePlus.Ambitions.getSpec(this.m.ID);
            if (spec != null) ::NoblePlus.Ambitions.applyTexts(this, spec);
        }
    }

    function onUpdateScore()
    {
        if (this.World.Assets.getOrigin().getID() != "scenario.noble_plus") return;
        if (!("NoblePlus" in getroottable()) || !("Ambitions" in ::NoblePlus))
        {
            this.m.Score = 0;
            return;
        }

        local id = "ambition.noble_plus.earn_gold";
        local spec = ::NoblePlus.Ambitions.getSpec(id);
        if (spec == null || !::NoblePlus.Ambitions.isAllowed(id))
        {
            this.m.Score = 0;
            return;
        }

        ::NoblePlus.Ambitions.applyTexts(this, spec);
        local doneFlag = ::NoblePlus.Ambitions.getDoneFlag(id, "NoblePlus.Stage.EarnGold.Done");
        if (this.World.Flags.has(doneFlag)) return;

        local target = ::NoblePlus.Ambitions.getTarget(id, 2000);
        local gold = this.World.Assets.getMoney();
        this.m.Score = ::NoblePlus.Ambitions.getScore(id, 9999);

        if (gold >= target)
        {
            this.m.IsDone = true;
            this.World.Flags.set(doneFlag, true);
            ::NoblePlus.Ambitions.tryCompleteSet(spec.set_id);
        }
    }

    function getList()
    {
        local id = "ambition.noble_plus.earn_gold";
        local target = ::NoblePlus.Ambitions.getTarget(id, 2000);
        local gold = this.World.Assets.getMoney();
        return [
            {
                text        = "Золото: " + gold + " / " + target,
                isCompleted = (gold >= target)
            }
        ];
    }

    function onSerialize( _out )
    {
        this.ambition.onSerialize(_out);
    }

    function onDeserialize( _in )
    {
        this.ambition.onDeserialize(_in);
    }
});
