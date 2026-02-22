# Noble Plus — Техдок: Система амбиций Battle Brothers

> Дата последнего обновления: 22.02.2026
> Источник: исходники Legends 19.1.47 + ванильные файлы BB

---

## Обзор механизма

Амбиции — это сюжетные и геймплейные цели, которые движут игрока через открытый мир Battle Brothers. Это **основной механизм нарративного продвижения** в нашем моде.

Ключевые свойства:
- На рассвете второго дня BB запускает событие выбора амбиции
- Игрок видит пул доступных амбиций и выбирает одну
- Когда амбиция выполнена — слот открывается, игрок выбирает следующую
- Приоритет в пуле: `this.m.Score` (0–100). Выше = ближе к верху списка
- Каждая амбиция **регистрируется движком автоматически** из директории `scripts/ambitions/ambitions/`

---

## Базовый класс и обязательные методы

```squirrel
this.my_ambition <- this.inherit("scripts/ambitions/ambition", {
    m = {},   // всегда пустой

    function create()
    {
        this.ambition.create();   // ОБЯЗАТЕЛЬНО вызывать родителя

        // Обязательные поля:
        this.m.ID              = "ambition.mod_name.ambition_name";  // уникальный ID
        this.m.Name            = "Название амбиции";                 // в заголовке
        this.m.UIText          = "Краткое описание для тулбара";     // в топ-баре

        // Рекомендуемые поля:
        this.m.TooltipText     = "Детальное описание при наведении / в окне выбора";
        this.m.SuccessText     = "Текст при успешном завершении";
        this.m.SuccessButtonText = "Продолжать.";                    // кнопка в окне успеха
        this.m.Icon            = "ambition_icon_name";               // иконка (см. ниже)
    }

    function onUpdateScore()
    {
        // Вызывается движком каждый тик для проверки прогресса.
        // Здесь:
        //   1. Фильтровать по сценарию (чтобы амбиция не показывалась в других происхождениях)
        //   2. Проверять условие завершения
        //   3. Устанавливать this.m.Score (0–100) для приоритета в пуле
        //   4. При выполнении: this.m.IsDone = true + this.m.Score = 100

        // Пример фильтра по происхождению:
        if (this.World.Assets.getOrigin().getID() != "scenario.noble_plus") return;

        // Пример скрытия уже выполненной амбиции:
        if (this.World.Flags.has("NoblePlus.Stage.MyStage.Done")) return;

        // Пример проверки условия:
        local value = this.World.Assets.getMoney();
        if (value >= 2000)
        {
            this.m.IsDone = true;
            this.m.Score  = 100;
            this.World.Flags.set("NoblePlus.Stage.MyStage.Done", true);
            return;
        }

        // Прогрессивный score (чем ближе к цели, тем выше приоритет):
        this.m.Score = this.Math.min(90, (value / 2000.0 * 80).tointeger() + 5);
    }

    function getList()
    {
        // Необязательно, но рекомендуется: список пунктов прогресса в UI.
        // Возвращает массив объектов { text, isCompleted }.
        local value = this.World.Assets.getMoney();
        return [
            {
                text        = "Золото: " + value + " / 2000",
                isCompleted = (value >= 2000)
            }
        ];
    }

    function onSerialize( _out )
    {
        this.ambition.onSerialize(_out);   // сохранение состояния
    }

    function onDeserialize( _in )
    {
        this.ambition.onDeserialize(_in);  // загрузка состояния
    }
});
```

---

## Ключевые API для проверки условий

```squirrel
// Сценарий / происхождение
this.World.Assets.getOrigin().getID()          // → "scenario.noble_plus"

// Размер отряда (включая весь ростер)
this.World.getPlayerRoster().getAll().len()    // → int

// Деньги
this.World.Assets.getMoney()                   // → int (в монетах)

// Известность / репутация наёмника
this.World.Assets.getBusinessReputation()      // → int (нужно верифицировать имя метода!)
// Возможные альтернативы: getReputation(), getBattleReputation()

// Флаги (персистентное состояние игры)
this.World.Flags.has("Key")                    // → bool
this.World.Flags.set("Key", value)             // установить флаг
this.World.Flags.get("Key")                    // получить значение

// Время
this.Time.getVirtualTimeF()                    // виртуальное время в секундах
```

**Важно:** использовать `this.World.*` (через контекст объекта), а НЕ `::World.*` (через глобальный неймспейс). Технически оба работают, но `this.World` консистентно с остальным кодом BB.

---

## Паттерн хука для ванильной амбиции

Чтобы добавить Noble Plus специфичный текст к ванильной амбиции:

```squirrel
::mods_hookExactClass("ambitions/ambitions/banner_ambition", function(o)
{
    local origCreate = o.create;
    o.create = function()
    {
        origCreate();
        // Текст меняется для ВСЕХ сценариев (create() вызывается до начала игры)
        // Для сценарно-специфичного текста — переопределяй getTooltipText() или
        // обновляй поле в onUpdateScore() при наличии активной игры
    };

    local origUpdateScore = o.onUpdateScore;
    o.onUpdateScore = function()
    {
        origUpdateScore();
        // Здесь можно добавить сценарно-специфичную логику:
        if (this.m.IsDone &&
            this.World.Assets.getOrigin().getID() == "scenario.noble_plus")
        {
            this.World.Flags.set("NoblePlus.Stage.OwnBanner.Done", true);
        }
    };
});
```

Файл хука кладётся в: `mod/mod_noble_plus/hooks/ambitions/ambitions/banner_ambition.nut`
Деплоится в: `data/mod_noble_plus/hooks/ambitions/ambitions/banner_ambition.nut`

---

## Авто-сканирование директории

По аналогии с:
- `scripts/scenarios/world/` — сканируется при старте движка
- `scripts/events/events/` — авто-сканирование (подтверждено в сессии 5)
- `scripts/ambitions/ambitions/` — **предположительно авто-сканируется** (нужно верифицировать)

Если авто-сканирование не работает — добавить явные `::include(...)` в `mods_queue` callback:
```squirrel
::include("scripts/ambitions/ambitions/noble_plus_hire_soldiers_ambition.nut");
::include("scripts/ambitions/ambitions/noble_plus_earn_gold_ambition.nut");
::include("scripts/ambitions/ambitions/noble_plus_find_allies_ambition.nut");
```

---

## Примеры из Legends (хуки существующих амбиций)

Legends расширяет ванильные амбиции через хуки в `hooks/ambitions/ambitions/`:

- `have_talent_ambition.nut` — хук `create()` для изменения TooltipText
- `named_item_set_ambition.nut` — хук `create()` для SuccessText
- `defeat_undead_ambition.nut` — хук `onUpdateScore()` с проверкой происхождения
- `have_all_provisions_ambition.nut` — сложный хук `getTooltipText()` с динамическим списком
- `visit_settlements_ambition.nut` — условный хук `onUpdateScore()`

Паттерн: сохранить оригинальный метод в `local orig = o.method`, затем переопределить через closure.

---

## Известные имена иконок (нужно верифицировать)

Иконки задаются в поле `this.m.Icon`. Имена берутся из игрового реестра иконок.
Предположительные значения (верифицировать по логу при первом запуске):
- `"ambition_roster_size"` — иконка размера ростера
- `"ambition_gold"` — иконка золота
- `"ambition_renown"` — иконка известности

При ошибке `"icon not found"` — использовать пустую строку `""` как fallback.

---

## Флаги состояния Noble Plus (этап 3.4)

```
NoblePlus.Stage.HireSoldiers.Done  — выполнена амбиция 1.1 (8+ бойцов)
NoblePlus.Stage.EarnGold.Done      — выполнена амбиция 1.2 (2000 золота)
NoblePlus.Stage.FindAllies.Done    — выполнена амбиция 1.3 (500 известности)
NoblePlus.Stage.OwnBanner.Done     — выполнена амбиция 1.4 (Знамя отряда)
```

Когда все 4 флага установлены → игрок готов к Главе I (штурм замка).
Отслеживание завершения Главы I — задача этапа 3.5.
