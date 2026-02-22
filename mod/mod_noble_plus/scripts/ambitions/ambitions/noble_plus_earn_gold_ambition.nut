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
// ВАЖНО: текстовые поля инициализируются в m = {}, а не в create(),
// потому что движок может не вызвать create() до показа экрана выбора амбиции.

this.noble_plus_earn_gold_ambition <- this.inherit("scripts/ambitions/ambition", {
    m = {
        ID              = "ambition.noble_plus.earn_gold",
        Name            = "Наполнить казну",
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
        // Повторно задаём поля на случай, если this.ambition.create() сбросил m
        this.m.ID               = "ambition.noble_plus.earn_gold";
        this.m.Name             = "Наполнить казну";
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

        if (gold >= 2000)
        {
            this.m.IsDone = true;
            this.m.Score  = 100;
            this.World.Flags.set("NoblePlus.Stage.EarnGold.Done", true);
            return;
        }

        // Прогрессивный score: base 30 гарантирует видимость в пуле даже при 0 золоте
        this.m.Score = this.Math.min(90, (gold / 2000.0 * 80).tointeger() + 30);
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
