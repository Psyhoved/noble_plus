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

        if (this.World.Assets.getOrigin().getID() == "scenario.noble_plus")
        {
            // Score 9999: амбиция всегда доминирует пул — ванильные не конкурируют
            this.m.Score = 9999;

            // Нарративный текст для карточки выбора и топбара
            local text = "Знамя Дома Локвуд похищено узурпатором. Закажи собственный штандарт — 2000 крон.";
            this.m.UIText     = text;
            this.m.ButtonText = text;

            // Нарративный текст экрана завершения (вместо ванильного про "кровожадное отребьё")
            this.m.SuccessText =
                "[img]gfx/ui/events/event_176.png[/img]\n\n" +
                "Новое знамя Дома Локвуд — не роскошь. Это объявление войны.\n\n" +
                "Вышивальщица из Торгенхейма работала три недели. На полотне — серебряный волк " +
                "на чёрном поле, без щита и без цепей. Тот самый зверь, что украшал знамя отца. " +
                "Тот, что узурпатор присвоил себе.\n\n" +
                "Когда стяг взвился над лагерем впервые, никто не произнёс ни слова. " +
                "Люди смотрели на него и понимали: это уже не просто наёмный отряд.\n\n" +
                "[color=#bcad8c]Это армия претендента.[/color]";
            this.m.SuccessButtonText = "К делу.";

            // При завершении — ставим флаг Главы I и проверяем завершение главы
            if (this.m.IsDone && !this.World.Flags.has("NoblePlus.Stage.OwnBanner.Done"))
            {
                this.World.Flags.set("NoblePlus.Stage.OwnBanner.Done", true);
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
    };
});
