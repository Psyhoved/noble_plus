// =============================================================================
// noble_plus_chapter1_complete_event — Финал Главы I
// =============================================================================
// Нарративный мост между Главой I ("Основать отряд") и Главой II ("Найти союзников").
// Срабатывает когда все четыре амбиции Главы I выполнены:
//   NoblePlus.Stage.HireSoldiers.Done
//   NoblePlus.Stage.EarnGold.Done
//   NoblePlus.Stage.FindAllies.Done
//   NoblePlus.Stage.OwnBanner.Done
//
// Вызывается через ::World.Events.fire() из ::NoblePlus.tryFireChapterComplete().
// IsSpecial = true — показывается немедленно, без ожидания следующего дня.
//
// Паттерн: scripts/events/event (как noble_plus_intro_event).
// Авто-сканирование: файл подхватывается движком из scripts/events/events/.

this.noble_plus_chapter1_complete_event <- this.inherit("scripts/events/event", {
    m = {},

    function create()
    {
        this.m.ID = "event.noble_plus_chapter1_complete";
        this.m.IsSpecial = true;
        this.m.Screens.push({
            ID = "A",
            Text =
                "[img]gfx/ui/events/event_176.png[/img]\n\n" +

                "Первая глава написана.\n\n" +

                "У тебя есть отряд — не рыцари, но люди, которые не побегут при виде крови. " +
                "Есть золото — достаточно, чтобы платить и кормить. Есть имя, которое знают " +
                "в этом краю. И есть знамя — серебряный волк на чёрном поле, объявление войны " +
                "тем, кто думал, что всё уже закончилось.\n\n" +

                "Думали — закончилось.\n\n" +

                "На следующий день в лагерь приходит гонец. Он из Дома Торнвуд — одного из шести " +
                "домов, чьи земли граничат с Локвудами. Держится осторожно, как человек, " +
                "которому есть что терять.\n\n" +

                "— Мой лорд просит о встрече, — говорит он. — Приватно.\n\n" +

                "[color=#bcad8c]Глава I завершена. Началась охота.[/color]",
            Image = "",
            Banner = "",
            List = [],
            Characters = [],
            Options = [
                {
                    Text = "Продолжать.",
                    function getResult( _event )
                    {
                        return 0;
                    }
                }
            ],
            function start( _event )
            {
                ::logInfo("[NoblePlus] Глава I завершена: событие chapter1_complete показано");
            }
        });
    }

    function onUpdateScore()
    {
        return;
    }

    function onPrepare()
    {
        this.m.Title = "Дворянин +";
    }

    function onPrepareVariables( _vars )
    {
    }

    function onClear()
    {
    }

});
