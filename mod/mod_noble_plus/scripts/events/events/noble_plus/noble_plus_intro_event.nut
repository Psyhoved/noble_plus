// =============================================================================
// noble_plus_intro_event — Пролог сценария "Дворянин +"
// =============================================================================
// Одноразовое стартовое событие: показывается через ~1 секунду после
// появления отряда на карте. Вызывается из noble_plus_scenario.onSpawnPlayer()
// через this.Time.scheduleEvent().
//
// Паттерн: scripts/events/event (как legend_noble_intro_event в Легендах).
// Авто-сканирование: файл подхватывается движком из scripts/events/events/
// без явного ::include в preload.

this.noble_plus_intro_event <- this.inherit("scripts/events/event", {
    m = {},

    function create()
    {
        this.m.ID = "event.noble_plus_intro";
        this.m.IsSpecial = true;
        this.m.Screens.push({
            ID = "A",
            Text = "[img]gfx/ui/events/event_176.png[/img]\n" +
                   "Три месяца назад ты был наследником Дома Локвуд.\n\n" +
                   "Сегодня ты — беглец.\n\n" +
                   "Ночь. Холодный ветер несёт запах дыма из родового замка. " +
                   "Твоя горстка верных людей стоит на холме, глядя вниз, на пылающие " +
                   "стены дома своего детства. Отец мёртв. Брат предал. Корона — у тебя " +
                   "на голове — теперь у него.\n\n" +
                   "Ты — барон Локвуд. Барон без замка, без титула, без ничего.\n\n" +
                   "Но у тебя есть кое-что, чего нет у твоего брата: ты жив. " +
                   "И ты помнишь. Каждую деталь. Каждую ложь.\n\n" +
                   "Время собирать долги.",
            Image = "",
            Banner = "",
            List = [],
            Characters = [],
            Options = [
                {
                    Text = "Вперёд.",
                    function getResult( _event )
                    {
                        return 0;
                    }
                }
            ],
            function start( _event )
            {
                ::logInfo("[NoblePlus] Пролог: событие показано");
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
