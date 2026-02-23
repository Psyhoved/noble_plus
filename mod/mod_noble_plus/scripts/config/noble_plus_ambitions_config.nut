// =============================================================================
// noble_plus_ambitions_config — единый конфиг амбиций Noble Plus
// =============================================================================
// Source of truth для:
// - порядка наборов (sets)
// - доступности амбиций
// - порогов выполнения
// - текстов UI
// - done-флагов и перехода между главами

::NoblePlus.AmbitionsConfig <- {
    meta = {
        config_version = 1,
        scenario_id = "scenario.noble_plus"
    },

    sets = [
        {
            id = "chapter1_core",
            order = 10,
            enabled = true,
            complete_when = {
                type = "all_flags",
                flags = [
                    "NoblePlus.Stage.HireSoldiers.Done",
                    "NoblePlus.Stage.EarnGold.Done",
                    "NoblePlus.Stage.FindAllies.Done",
                    "NoblePlus.Stage.OwnBanner.Done"
                ]
            },
            on_complete = {
                done_flag = "NoblePlus.Chapter1.Complete",
                event_id = "event.noble_plus_chapter1_complete"
            }
        }
    ],

    ambitions = [
        {
            id = "ambition.noble_plus.hire_soldiers",
            enabled = true,
            set_id = "chapter1_core",
            source = "custom",
            score = 9999,
            condition = {
                type = "roster_size",
                target = 8
            },
            flags = {
                done = "NoblePlus.Stage.HireSoldiers.Done"
            },
            texts = {
                ButtonText = "Собери под знамя Дома Локвуд хотя бы 8 бойцов.",
                UIText = "Собери под знамя Дома Локвуд хотя бы 8 бойцов.",
                TooltipText =
                    "Тебе нужна армия. Без неё ты — просто беглец с мечом.\n\n" +
                    "Пройдись по тавернам, поговори с нужными людьми. Предложи серебро " +
                    "тем, кому некуда деваться. Не ищи героев — ищи людей, которые не " +
                    "сбегут при первом же виде крови.\n\n" +
                    "[color=#bcad8c]Задача:[/color] Набери хотя бы 8 бойцов " +
                    "под знамя Дома Локвуд.",
                SuccessText =
                    "[img]gfx/ui/events/event_176.png[/img]\n\n" +
                    "Первый шаг сделан. Восемь человек смотрят на тебя — и каждый из " +
                    "них выбрал быть здесь. Они не рыцари и не аристократы. Но они здесь.\n\n" +
                    "[color=#bcad8c]Теперь нужны деньги.[/color] Много денег.",
                SuccessButtonText = "Продолжать.",
                Icon = "ambition_roster_size"
            }
        },
        {
            id = "ambition.noble_plus.earn_gold",
            enabled = true,
            set_id = "chapter1_core",
            source = "custom",
            score = 9999,
            condition = {
                type = "money",
                target = 2000
            },
            flags = {
                done = "NoblePlus.Stage.EarnGold.Done"
            },
            texts = {
                ButtonText = "Накопи 2000 золотых крон для подготовки к осаде.",
                UIText = "Накопи 2000 золотых крон для подготовки к осаде.",
                TooltipText =
                    "Армия стоит дорого. Замок стоит ещё дороже.\n\n" +
                    "Выполняй контракты, нападай на лагеря разбойников, продавай трофеи. " +
                    "Деньги — это не цель: они инструмент. Инструмент, без которого " +
                    "ты не дойдёшь до ворот родного замка.\n\n" +
                    "[color=#bcad8c]Задача:[/color] Накопи не менее " +
                    "[color=#bcad8c]2000 золотых крон[/color].",
                SuccessText =
                    "[img]gfx/ui/events/event_176.png[/img]\n\n" +
                    "Казна полна. Достаточно, чтобы вооружить людей получше. Достаточно, " +
                    "чтобы купить чью-то верность — или молчание.\n\n" +
                    "Но золото без союзников — это просто красивые монеты. " +
                    "[color=#bcad8c]Пришло время искать друзей.[/color]",
                SuccessButtonText = "Продолжать.",
                Icon = "ambition_gold"
            }
        },
        {
            id = "ambition.noble_plus.find_allies",
            enabled = true,
            set_id = "chapter1_core",
            source = "custom",
            score = 9999,
            condition = {
                type = "business_reputation",
                target = 500
            },
            flags = {
                done = "NoblePlus.Stage.FindAllies.Done"
            },
            texts = {
                ButtonText = "Завоюй 500 очков известности — чтобы о тебе узнали нужные люди.",
                UIText = "Завоюй 500 очков известности — чтобы о тебе узнали нужные люди.",
                TooltipText =
                    "В одиночку замок не взять. Твоё имя должно звучать достаточно громко, " +
                    "чтобы другие бароны захотели встать рядом — или хотя бы не мешать.\n\n" +
                    "Побеждай врагов. Защищай деревни. Выполняй контракты для знатных домов. " +
                    "Пусть слухи о тебе расходятся быстрее, чем твой отряд.\n\n" +
                    "[color=#bcad8c]Задача:[/color] Завоюй не менее " +
                    "[color=#bcad8c]500 очков известности[/color].",
                SuccessText =
                    "[img]gfx/ui/events/event_176.png[/img]\n\n" +
                    "К тебе приходит гонец. Он из Дома Торнвуд — одного из шести " +
                    "домов, что владеют землями вокруг Локвудов.\n\n" +
                    "— Мой лорд хочет видеть тебя, — говорит гонец. — Приватно.\n\n" +
                    "[color=#bcad8c]Враг моего врага.[/color] " +
                    "Пришло время выбирать союзников.",
                SuccessButtonText = "Продолжать.",
                Icon = "ambition_renown"
            }
        },
        {
            id = "ambition.battle_standard",
            enabled = true,
            set_id = "chapter1_core",
            source = "vanilla_hook",
            score = 9999,
            condition = {
                type = "vanilla_done",
                target = 2000
            },
            flags = {
                done = "NoblePlus.Stage.OwnBanner.Done"
            },
            reward = {
                type = "vanilla_battle_standard",
                money_cost = 2000
            },
            texts = {
                ButtonText = "Знамя Дома Локвуд похищено узурпатором. Закажи собственный штандарт — 2000 крон.",
                UIText = "Знамя Дома Локвуд похищено узурпатором. Закажи собственный штандарт — 2000 крон.",
                TooltipText =
                    "[color=#bcad8c]Знамя Дома Локвуд теперь у твоего брата.[/color] " +
                    "Ты не можешь сражаться под гербом, который он украл. " +
                    "Тебе нужен собственный символ — знамя, под которым пойдут твои люди.\n\n" +
                    "Закажи штандарт у мастера. Это дорого, но без знамени ты останешься " +
                    "просто ещё одним наёмным отрядом.",
                SuccessText =
                    "[img]gfx/ui/events/event_176.png[/img]\n\n" +
                    "Новое знамя Дома Локвуд — не роскошь. Это объявление войны.\n\n" +
                    "Вышивальщица из Торгенхейма работала три недели. На полотне — серебряный волк " +
                    "на чёрном поле, без щита и без цепей. Тот самый зверь, что украшал знамя отца. " +
                    "Тот, что узурпатор присвоил себе.\n\n" +
                    "Когда стяг взвился над лагерем впервые, никто не произнёс ни слова. " +
                    "Люди смотрели на него и понимали: это уже не просто наёмный отряд.\n\n" +
                    "[color=#bcad8c]Это армия претендента.[/color]",
                SuccessButtonText = "К делу."
            }
        }
    ]
};
