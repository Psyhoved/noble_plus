// =============================================================================
// Хук ванильной амбиции "Знамя отряда" (battle_standard_ambition)
// =============================================================================
// ID амбиции в игре: "ambition.battle_standard"
// Награда: штандарт (работает как пика)
// Условие: потратить 2000 золотых (стандартная стоимость)
//
// Для сценария "Дворянин +" добавляем нарративный текст о том,
// что знамя Дома Локвуд теперь у брата-узурпатора и нам нужен свой символ.
// Также ставим наш флаг при завершении для отслеживания Главы I.
//
// UIText обновляется в onUpdateScore() (а не в create()), потому что
// create() может не вызываться до показа экрана выбора амбиции.

::mods_hookExactClass("ambitions/ambitions/battle_standard_ambition", function(o)
{
    local origCreate = o.create;
    o.create = function()
    {
        origCreate();

        // Для сценария "Дворянин +" добавляем flavor-текст в начало TooltipText.
        // Нельзя проверить сценарий здесь (create вызывается до начала игры),
        // поэтому текст добавляется глобально, но написан универсально.
        local noblePrefix =
            "[color=#bcad8c]Знамя Дома Локвуд теперь у твоего брата.[/color] " +
            "Ты не можешь сражаться под гербом, который он украл. " +
            "Тебе нужен собственный символ — знамя, под которым пойдут твои люди.\n\n";

        this.m.TooltipText = noblePrefix + this.m.TooltipText;
    };

    local origUpdateScore = o.onUpdateScore;
    o.onUpdateScore = function()
    {
        origUpdateScore();

        // Для сценария Noble Plus — задаём UIText с нашим нарративным контекстом.
        // Делается здесь (не в create()), чтобы гарантированно применяться
        // до показа экрана выбора амбиции.
        if (this.World.Assets.getOrigin().getID() == "scenario.noble_plus")
        {
            this.m.UIText = "Знамя Дома Локвуд похищено узурпатором. Закажи собственный штандарт — 2000 крон.";
        }

        // При завершении амбиции для Noble Plus — ставим флаг Главы I
        if (this.m.IsDone &&
            this.World.Assets.getOrigin().getID() == "scenario.noble_plus" &&
            !this.World.Flags.has("NoblePlus.Stage.OwnBanner.Done"))
        {
            this.World.Flags.set("NoblePlus.Stage.OwnBanner.Done", true);
        }
    };
});
