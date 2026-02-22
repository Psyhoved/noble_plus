// =============================================================================
// noble_plus_hire_soldiers_ambition — Этап 1.1: "Собрать отряд"
// =============================================================================
// Нарративная амбиция Главы I: набрать хотя бы 8 бойцов под знамя Дома Локвуд.
// Активна только для происхождения "Дворянин +" (scenario.noble_plus).
// Не требует завершения предыдущего этапа — доступна с первого дня.
//
// Прогресс: текущий размер отряда / 8
// Завершение: в отряде 8+ бойцов (включая дворянина)
//
// ПОЛЯ ОТОБРАЖЕНИЯ:
//   ButtonText — текст на карточке в экране выбора амбиции (читается Legends UI)
//   UIText     — краткий текст в топбаре (читается ambition_manager)
//   Name       — не является стандартным полем базового класса, не используется

this.noble_plus_hire_soldiers_ambition <- this.inherit("scripts/ambitions/ambition", {
    m = {
        ID              = "ambition.noble_plus.hire_soldiers",
        ButtonText      = "Собери под знамя Дома Локвуд хотя бы 8 бойцов.",
        UIText          = "Собери под знамя Дома Локвуд хотя бы 8 бойцов.",
        TooltipText     =
            "Тебе нужна армия. Без неё ты — просто беглец с мечом.\n\n" +
            "Пройдись по тавернам, поговори с нужными людьми. Предложи серебро " +
            "тем, кому некуда деваться. Не ищи героев — ищи людей, которые не " +
            "сбегут при первом же виде крови.\n\n" +
            "[color=#bcad8c]Задача:[/color] Набери хотя бы 8 бойцов " +
            "под знамя Дома Локвуд.",
        SuccessText     =
            "[img]gfx/ui/events/event_176.png[/img]\n\n" +
            "Первый шаг сделан. Восемь человек смотрят на тебя — и каждый из " +
            "них выбрал быть здесь. Они не рыцари и не аристократы. Но они здесь.\n\n" +
            "[color=#bcad8c]Теперь нужны деньги.[/color] Много денег.",
        SuccessButtonText = "Продолжать.",
        Icon            = "ambition_roster_size"
    },

    function create()
    {
        this.ambition.create();
        // Задаём поля после вызова родителя — он может сбросить m.
        // Используем = (а не <-): базовый класс создаёт стандартные слоты в create().
        this.m.ID               = "ambition.noble_plus.hire_soldiers";
        this.m.ButtonText       = "Собери под знамя Дома Локвуд хотя бы 8 бойцов.";
        this.m.UIText           = "Собери под знамя Дома Локвуд хотя бы 8 бойцов.";
        this.m.TooltipText      =
            "Тебе нужна армия. Без неё ты — просто беглец с мечом.\n\n" +
            "Пройдись по тавернам, поговори с нужными людьми. Предложи серебро " +
            "тем, кому некуда деваться. Не ищи героев — ищи людей, которые не " +
            "сбегут при первом же виде крови.\n\n" +
            "[color=#bcad8c]Задача:[/color] Набери хотя бы 8 бойцов " +
            "под знамя Дома Локвуд.";
        this.m.SuccessText      =
            "[img]gfx/ui/events/event_176.png[/img]\n\n" +
            "Первый шаг сделан. Восемь человек смотрят на тебя — и каждый из " +
            "них выбрал быть здесь. Они не рыцари и не аристократы. Но они здесь.\n\n" +
            "[color=#bcad8c]Теперь нужны деньги.[/color] Много денег.";
        this.m.SuccessButtonText = "Продолжать.";
        this.m.Icon             = "ambition_roster_size";
    }

    function onUpdateScore()
    {
        // Амбиция активна только для нашего происхождения
        if (this.World.Assets.getOrigin().getID() != "scenario.noble_plus") return;

        // Не показываем если эта цель уже выполнена
        if (this.World.Flags.has("NoblePlus.Stage.HireSoldiers.Done")) return;

        local rosterSize = this.World.getPlayerRoster().getAll().len();

        // Score 9999: амбиция всегда доминирует пул — ванильные (Score 30–90) не конкурируют
        this.m.Score = 9999;

        if (rosterSize >= 8)
        {
            this.m.IsDone = true;
            this.World.Flags.set("NoblePlus.Stage.HireSoldiers.Done", true);
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
        local count = this.World.getPlayerRoster().getAll().len();
        return [
            {
                text        = "Бойцов под знаменем: " + count + " / 8",
                isCompleted = (count >= 8)
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
