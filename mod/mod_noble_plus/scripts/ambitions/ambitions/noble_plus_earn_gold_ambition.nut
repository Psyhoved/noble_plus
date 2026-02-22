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
    }

    function onUpdateScore()
    {
        // Активна только для нашего происхождения
        if (this.World.Assets.getOrigin().getID() != "scenario.noble_plus") return;

        // Не показываем если уже выполнена
        if (this.World.Flags.has("NoblePlus.Stage.EarnGold.Done")) return;

        local gold = this.World.Assets.getMoney();

        // Score 9999: амбиция всегда доминирует пул — ванильные (Score 30–90) не конкурируют
        this.m.Score = 9999;

        if (gold >= 2000)
        {
            this.m.IsDone = true;
            this.World.Flags.set("NoblePlus.Stage.EarnGold.Done", true);
            ::NoblePlus.tryFireChapterComplete(
                ["NoblePlus.Stage.HireSoldiers.Done",
                 "NoblePlus.Stage.EarnGold.Done",
                 "NoblePlus.Stage.FindAllies.Done",
                 "NoblePlus.Stage.OwnBanner.Done"],
                "NoblePlus.Chapter1.Complete",
                "event.noble_plus_chapter1_complete"
            );
        }
    }

    function getList()
    {
        local gold = this.World.Assets.getMoney();
        return [
            {
                text        = "Золото: " + gold + " / 2000",
                isCompleted = (gold >= 2000)
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
