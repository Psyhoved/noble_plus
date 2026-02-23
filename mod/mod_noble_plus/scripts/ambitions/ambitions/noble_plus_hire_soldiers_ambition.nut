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

        local id = "ambition.noble_plus.hire_soldiers";
        local spec = ::NoblePlus.Ambitions.getSpec(id);
        if (spec == null || !::NoblePlus.Ambitions.isAllowed(id))
        {
            this.m.Score = 0;
            return;
        }

        ::NoblePlus.Ambitions.applyTexts(this, spec);
        local doneFlag = ::NoblePlus.Ambitions.getDoneFlag(id, "NoblePlus.Stage.HireSoldiers.Done");
        if (this.World.Flags.has(doneFlag)) return;

        local target = ::NoblePlus.Ambitions.getTarget(id, 8);
        local rosterSize = this.World.getPlayerRoster().getAll().len();
        this.m.Score = ::NoblePlus.Ambitions.getScore(id, 9999);

        if (rosterSize >= target)
        {
            this.m.IsDone = true;
            this.World.Flags.set(doneFlag, true);
            ::NoblePlus.Ambitions.tryCompleteSet(spec.set_id);
        }
    }

    function getList()
    {
        local id = "ambition.noble_plus.hire_soldiers";
        local target = ::NoblePlus.Ambitions.getTarget(id, 8);
        local count = this.World.getPlayerRoster().getAll().len();
        return [
            {
                text        = "Бойцов под знаменем: " + count + " / " + target,
                isCompleted = (count >= target)
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
