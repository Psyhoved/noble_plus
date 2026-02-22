// =============================================================================
// noble_plus_find_allies_ambition — Этап 1.3: "Найти союзников"
// =============================================================================
// Нарративная амбиция Главы I: завоевать 500 очков известности.
// Активна только для "Дворянин +" (scenario.noble_plus).
// Доступна с первого дня одновременно с остальными амбициями Главы I.
//
// Известность = BusinessReputation в BB API (репутация наёмника)
// Прогресс: текущая известность / 500
// Завершение: известность >= 500
//
// ПОЛЯ ОТОБРАЖЕНИЯ:
//   ButtonText — текст на карточке в экране выбора амбиции (читается Legends UI)
//   UIText     — краткий текст в топбаре (читается ambition_manager)

this.noble_plus_find_allies_ambition <- this.inherit("scripts/ambitions/ambition", {
    m = {
        ID              = "ambition.noble_plus.find_allies",
        ButtonText      = "Завоюй 500 очков известности — чтобы о тебе узнали нужные люди.",
        UIText          = "Завоюй 500 очков известности — чтобы о тебе узнали нужные люди.",
        TooltipText     =
            "В одиночку замок не взять. Твоё имя должно звучать достаточно громко, " +
            "чтобы другие бароны захотели встать рядом — или хотя бы не мешать.\n\n" +
            "Побеждай врагов. Защищай деревни. Выполняй контракты для знатных домов. " +
            "Пусть слухи о тебе расходятся быстрее, чем твой отряд.\n\n" +
            "[color=#bcad8c]Задача:[/color] Завоюй не менее " +
            "[color=#bcad8c]500 очков известности[/color].",
        SuccessText     =
            "[img]gfx/ui/events/event_176.png[/img]\n\n" +
            "К тебе приходит гонец. Он из Дома Торнвуд — одного из шести " +
            "домов, что владеют землями вокруг Локвудов.\n\n" +
            "— Мой лорд хочет видеть тебя, — говорит гонец. — Приватно.\n\n" +
            "[color=#bcad8c]Враг моего врага.[/color] " +
            "Пришло время выбирать союзников.",
        SuccessButtonText = "Продолжать.",
        Icon            = "ambition_renown"
    },

    function create()
    {
        this.ambition.create();
        // Задаём поля после вызова родителя — он может сбросить m.
        this.m.ID               = "ambition.noble_plus.find_allies";
        this.m.ButtonText       = "Завоюй 500 очков известности — чтобы о тебе узнали нужные люди.";
        this.m.UIText           = "Завоюй 500 очков известности — чтобы о тебе узнали нужные люди.";
        this.m.TooltipText      =
            "В одиночку замок не взять. Твоё имя должно звучать достаточно громко, " +
            "чтобы другие бароны захотели встать рядом — или хотя бы не мешать.\n\n" +
            "Побеждай врагов. Защищай деревни. Выполняй контракты для знатных домов. " +
            "Пусть слухи о тебе расходятся быстрее, чем твой отряд.\n\n" +
            "[color=#bcad8c]Задача:[/color] Завоюй не менее " +
            "[color=#bcad8c]500 очков известности[/color].";
        this.m.SuccessText      =
            "[img]gfx/ui/events/event_176.png[/img]\n\n" +
            "К тебе приходит гонец. Он из Дома Торнвуд — одного из шести " +
            "домов, что владеют землями вокруг Локвудов.\n\n" +
            "— Мой лорд хочет видеть тебя, — говорит гонец. — Приватно.\n\n" +
            "[color=#bcad8c]Враг моего врага.[/color] " +
            "Пришло время выбирать союзников.";
        this.m.SuccessButtonText = "Продолжать.";
        this.m.Icon             = "ambition_renown";
    }

    function onUpdateScore()
    {
        // Активна только для нашего происхождения
        if (this.World.Assets.getOrigin().getID() != "scenario.noble_plus") return;

        // Не показываем если уже выполнена
        if (this.World.Flags.has("NoblePlus.Stage.FindAllies.Done")) return;

        local rep = this.World.Assets.getBusinessReputation();

        // Score 9999: амбиция всегда доминирует пул — ванильные (Score 30–90) не конкурируют
        this.m.Score = 9999;

        if (rep >= 500)
        {
            this.m.IsDone = true;
            this.World.Flags.set("NoblePlus.Stage.FindAllies.Done", true);
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
        local rep = this.World.Assets.getBusinessReputation();
        return [
            {
                text        = "Известность: " + rep + " / 500",
                isCompleted = (rep >= 500)
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
