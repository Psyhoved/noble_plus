# Система амбиций Battle Brothers — Справочник для Noble Faith

> Версия: 1.0 | Дата: 22.02.2026
> Источник: исходники Legends 19.1.47 + ванильные файлы BB + опыт этапа 3.4
> Применение: разработка амбиций Глав I-III мода **Noble Faith** (mod_noble_plus)

---

## 1. Обзор механики

Амбиции — это **основной механизм нарративного продвижения** игрока в открытом мире Battle Brothers. Они работают как список целей, которые двигают сюжет вперёд, но при этом органично встроены в ванильный UI без необходимости написания кастомных экранов.

**Жизненный цикл с точки зрения игрока:**

1. На рассвете второго игрового дня движок показывает экран выбора амбиции
2. Игрок видит до 4 доступных амбиций из пула (отсортированы по `m.Score`)
3. Игрок выбирает одну; она становится «активной» и отображается в топ-баре
4. Движок каждый тик проверяет условие выполнения через `onUpdateScore()`
5. Когда условие выполнено — показывается окно успеха (`SuccessText`), слот освобождается
6. Игрок снова выбирает из пула

**Ключевое отличие от событий:** амбиции не "стреляют" сами — игрок сам их выбирает. Это значит, что все амбиции Главы I доступны **одновременно с первого дня**. Порядок их выполнения определяет сам игрок.

---

## 2. Жизненный цикл амбиции (порядок вызовов)

```
1. Регистрация  ─── движок сканирует scripts/ambitions/ambitions/ при старте
                     → вызывает create() на каждом найденном классе

2. create()     ─── инициализация текстовых полей (Name, UIText, TooltipText...)
                    ВАЖНО: вызывается ДО начала игры, World.* здесь недоступен

3. onUpdateScore() ─ вызывается движком каждый тик для всех зарегистрированных амбиций
                     → здесь проверяем сценарий, прогресс, выставляем Score
                     → World.* здесь доступен (игра уже идёт)
                     → при завершении: this.m.IsDone = true, Score = 100

4. getList()    ─── вызывается UI для отображения списка прогресс-пунктов
                    → возвращает [{ text, isCompleted }, ...]

5. onSerialize / onDeserialize ─ сохранение/загрузка сохранения
                    → вызывать родительский метод обязательно

6. [Завершение] ─── движок показывает SuccessText + SuccessButtonText
                    → слот амбиции освобождается, игрок выбирает следующую
```

**КРИТИЧНО для отладки:** `create()` вызывается **до** старта кампании (при загрузке движка). Если вы выставляете текстовые поля в `create()` через `this.World.*` — будет краш. Все обращения к `World` должны быть ТОЛЬКО в `onUpdateScore()` и `getList()`.

---

## 3. Авто-сканирование директории

Движок BB авто-сканирует следующие директории при старте:
- `scripts/scenarios/world/` — происхождения (подтверждено)
- `scripts/events/events/` — события (подтверждено в сессии 5)
- `scripts/ambitions/ambitions/` — **предположительно** авто-сканируется (по аналогии)

Если авто-сканирование амбиций НЕ работает, добавить явные `::include` в `mods_queue` callback в `mod_noble_plus.nut`:

```squirrel
::mods_queue(::NoblePlus.ID, "mod_msu, mod_legends", function()
{
    ::NoblePlus.Mod <- ::MSU.Class.Mod(::NoblePlus.ID, ::NoblePlus.Version, ::NoblePlus.Name);
    ::include("scripts/ambitions/ambitions/noble_plus_hire_soldiers_ambition.nut");
    ::include("scripts/ambitions/ambitions/noble_plus_earn_gold_ambition.nut");
    ::include("scripts/ambitions/ambitions/noble_plus_find_allies_ambition.nut");
    ::logInfo("Noble Plus " + ::NoblePlus.Version + " загружен.");
});
```

**Статус:** Требует верификации в игре. Проверить по логу: наши амбиции должны появляться в экране выбора на рассвете 2-го дня.

---

## 4. Базовый класс: поля и методы

### Шаблон класса

```squirrel
this.my_ambition <- this.inherit("scripts/ambitions/ambition", {
    m = {},   // ВСЕГДА пустой — поля задаются через create()

    function create()
    {
        this.ambition.create();   // ОБЯЗАТЕЛЬНО: вызов родительского create()

        // --- ОБЯЗАТЕЛЬНЫЕ поля ---
        this.m.ID     = "ambition.mod_noble_plus.unique_name";  // уникальный строковый ID
        this.m.Name   = "Название амбиции";                     // заголовок в окне выбора
        this.m.UIText = "Краткий текст в топ-баре.";            // одна строка в активном баре

        // --- РЕКОМЕНДУЕМЫЕ поля ---
        this.m.TooltipText      = "Подробное описание при наведении или в окне выбора.";
        this.m.SuccessText      = "Текст в окне успешного завершения. BB-тег [img] работает.";
        this.m.SuccessButtonText = "Продолжать.";   // кнопка закрытия окна успеха
        this.m.Icon              = "ambition_gold"; // имя иконки (см. раздел 12)
    }

    function onUpdateScore()
    {
        // 1. Фильтр по происхождению — ОБЯЗАТЕЛЕН, иначе амбиция появится у всех
        if (this.World.Assets.getOrigin().getID() != "scenario.noble_plus") return;

        // 2. Скрыть уже выполненную амбицию
        if (this.World.Flags.has("NoblePlus.Stage.MyStage.Done")) return;

        // 3. Проверить условие завершения
        local value = this.World.Assets.getMoney();
        if (value >= 2000)
        {
            this.m.IsDone = true;
            this.m.Score  = 100;
            this.World.Flags.set("NoblePlus.Stage.MyStage.Done", true);
            return;
        }

        // 4. Прогрессивный score (чем ближе к цели, тем выше приоритет в пуле)
        this.m.Score = this.Math.min(90, (value / 2000.0 * 80).tointeger() + 30);
        //                                                                    ↑
        //                         base score 30 гарантирует видимость в пуле даже при 0 прогрессе
    }

    function getList()
    {
        // Список пунктов прогресса в UI (показывается при раскрытии амбиции)
        local value = this.World.Assets.getMoney();
        return [
            {
                text        = "Золото: " + value + " / 2000",
                isCompleted = (value >= 2000)
            }
        ];
    }

    function onSerialize( _out )   { this.ambition.onSerialize(_out);   }
    function onDeserialize( _in )  { this.ambition.onDeserialize(_in);  }
});
```

### Описание полей m.*

| Поле | Тип | Обязательность | Описание |
|------|-----|----------------|----------|
| `ID` | string | **обязательно** | Уникальный строковый ID. Формат: `"ambition.mod_id.name"` |
| `Name` | string | **обязательно** | Название в заголовке окна выбора и экрана прогресса |
| `UIText` | string | **обязательно** | Одна строка в активном топ-баре. Должна быть краткой |
| `TooltipText` | string | рекомендуется | Описание в окне выбора и при наведении. BB-теги поддерживаются |
| `SuccessText` | string | рекомендуется | Текст в окне завершения. Поддерживает BB-теги `[img]`, `[color]` |
| `SuccessButtonText` | string | рекомендуется | Текст кнопки "ок" в окне завершения. По умолчанию — что-то ванильное |
| `Icon` | string | необязательно | Имя иконки. Пустая строка `""` — без иконки |
| `Score` | int (0–100) | авто | Приоритет в пуле (выше = ближе к верху). Выставляется в `onUpdateScore()` |
| `IsDone` | bool | авто | Флаг завершения. Устанавливать `true` в `onUpdateScore()` при выполнении |

---

## 5. Ключевые API

Все API доступны только внутри `onUpdateScore()` и `getList()` (не в `create()`).

```squirrel
// --- Происхождение / сценарий ---
this.World.Assets.getOrigin().getID()          // → "scenario.noble_plus"
                                               // ВЕРИФИЦИРОВАНО: используется во всех сценариях Legends

// --- Отряд ---
this.World.getPlayerRoster().getAll().len()    // → int: полный размер ростера
                                               // ВЕРИФИЦИРОВАНО: используется в hire_soldiers_ambition

// --- Ресурсы ---
this.World.Assets.getMoney()                   // → int (в монетах)
                                               // ВЕРИФИЦИРОВАНО: используется в earn_gold_ambition

// --- Репутация ---
this.World.Assets.getBusinessReputation()      // → int: известность компании наёмников
                                               // ВЕРИФИЦИРОВАНО: используется в make_nobles_aware_ambition.nut (Legends)

// --- Флаги (персистентное состояние) ---
this.World.Flags.has("Key")                    // → bool
this.World.Flags.set("Key", value)             // установить флаг
this.World.Flags.get("Key")                    // получить значение (осторожно: краш если нет ключа)

// --- Время ---
this.Time.getVirtualTimeF()                    // → float: виртуальное время в секундах

// --- Амбиции ---
this.World.Ambitions.getAmbition("ambition.battle_standard")  // → объект амбиции по ID
                                               // ВЕРИФИЦИРОВАНО: используется в make_nobles_aware_ambition.nut
```

**Правило:** использовать `this.World.*`, а не `::World.*`. Оба работают, но `this.World` консистентно с кодобазой BB.

---

## 6. Паттерн: хук ванильной амбиции

Используется для добавления Noble Faith нарратива к существующей ванильной амбиции **без дублирования её механики**.

```squirrel
// Файл: hooks/ambitions/ambitions/battle_standard_ambition.nut
::mods_hookExactClass("ambitions/ambitions/battle_standard_ambition", function(o)
{
    // --- Хук create(): добавляем нарративный текст ---
    local origCreate = o.create;
    o.create = function()
    {
        origCreate();
        // ВНИМАНИЕ: create() вызывается до начала игры.
        // Проверить сценарий (this.World.*) здесь НЕЛЬЗЯ.
        // Текст добавляется глобально. Если нужен сценарно-специфичный текст —
        // выносить в onUpdateScore() или переопределять getTooltipText().
        local prefix = "[color=#bcad8c]Noble Faith prefix.[/color]\n\n";
        this.m.TooltipText = prefix + this.m.TooltipText;
    };

    // --- Хук onUpdateScore(): ставим наш флаг при завершении ---
    local origUpdateScore = o.onUpdateScore;
    o.onUpdateScore = function()
    {
        origUpdateScore();

        if (this.m.IsDone &&
            this.World.Assets.getOrigin().getID() == "scenario.noble_plus" &&
            !this.World.Flags.has("NoblePlus.Stage.OwnBanner.Done"))
        {
            this.World.Flags.set("NoblePlus.Stage.OwnBanner.Done", true);
        }
    };
});
```

**Путь файла-хука:**
- В репозитории: `mod/mod_noble_plus/hooks/ambitions/ambitions/battle_standard_ambition.nut`
- В data/ игры: `data/hooks/ambitions/ambitions/battle_standard_ambition.nut`

**Как проверить что хук применился:** Запустить игру и найти в логе строку `[MSU] Hook applied: ambitions/ambitions/battle_standard_ambition`. Если строки нет — файл хука не найден или путь неправильный.

---

## 7. Паттерн: подавление ванильных амбиций

Ванильные амбиции не знают о нашем сценарии и будут показываться всем игрокам. Чтобы они не появлялись в пуле для "Дворянин +", нужно добавить фильтр в `onUpdateScore()`.

```squirrel
// Файл: hooks/ambitions/ambitions/VANILLA_AMBITION_NAME.nut
::mods_hookExactClass("ambitions/ambitions/VANILLA_AMBITION_NAME", function(o)
{
    local origUpdate = o.onUpdateScore;
    o.onUpdateScore = function()
    {
        // Для нашего сценария — не показывать эту ванильную амбицию
        if (this.World.Assets.getOrigin().getID() == "scenario.noble_plus") return;
        // Для всех остальных сценариев — ванильное поведение
        origUpdate();
    };
});
```

**Ванильные амбиции, которые нужно подавить для Noble Faith (Глава I):**

| Ванильная амбиция | Предполагаемый файл | Статус |
|-------------------|---------------------|--------|
| «Попасться на глаза знатному дому» | `pledge_of_allegiance_ambition.nut` | ⚠️ имя файла не верифицировано |
| «Союз с поселением» | `friend_settlement_ambition.nut` | ⚠️ имя файла не верифицировано |
| «Знамя отряда» | `battle_standard_ambition.nut` | ✅ хук уже есть (добавить подавление конкуренции) |

**Как найти точные имена файлов:** Запустить игру с `only_errors=false`, в логе при загрузке будут сообщения вида `[MSU] Processing hooks for ambitions/ambitions/FILENAME` — это и есть нужные имена.

---

## 8. Score: как рассчитывать приоритет

Движок показывает в окне выбора до **4 амбиций** с наивысшим `Score`. Амбиции со `Score = 0` не появляются.

**Рекомендации по значениям:**

| Ситуация | Значение Score |
|----------|---------------|
| Амбиция не подходит для текущего состояния игры | `0` (или не трогать, default = 0) |
| Базовый приоритет (видна в пуле с первого дня) | `25–35` |
| Активная амбиция с прогрессом | `35–90` (пропорционально выполнению) |
| Завершена | `100` + `IsDone = true` |

**Формула прогрессивного score:**
```squirrel
// Пример: прогресс от 0 до maxValue, base score = 30
this.m.Score = this.Math.min(90, (currentValue / maxValue.tofloat() * 60).tointeger() + 30);
//                                                                      ↑ диапазон прогресса
//                                                                                      ↑ base score
```

**ВАЖНО:** Если base score слишком мал (5), ванильные амбиции с более высоким score вытеснят наши из видимой четвёрки. Рекомендуем не менее 30.

---

## 9. Известные проблемы и диагностика

Эти проблемы выявлены в процессе тестирования этапа 3.4. Являются открытыми вопросами для этапа 3.5.

### Проблема A: пустые тексты у кастомной амбиции

**Симптом:** Амбиция появляется в пуле (Score > 0), но Name и UIText пусты.

**Вероятные причины:**
1. **Гипотеза A1:** `create()` не вызывается движком до показа UI экрана выбора. Текстовые поля остаются пустыми (значения из `ambition.create()` родителя).
2. **Гипотеза A2:** Поле называется не `m.UIText`, а что-то другое (напр. `m.Text`).

**Диагностика:** Запустить игру, прочитать лог `only_errors=true`. Ошибки вида `the index 'UIText' does not exist` → A2. Нет ошибок, но поля пусты → A1.

**Решение A1:** Перенести инициализацию текстовых полей из `m = {}` напрямую (без create):
```squirrel
this.noble_plus_hire_soldiers_ambition <- this.inherit("scripts/ambitions/ambition", {
    m = {
        ID              = "ambition.noble_plus.hire_soldiers",
        Name            = "Собрать отряд",
        UIText          = "Собери под знамя Дома Локвуд хотя бы 8 бойцов.",
        TooltipText     = "...",
        SuccessText     = "...",
        SuccessButtonText = "Продолжать.",
        Icon            = "ambition_roster_size"
    },
    function create() { this.ambition.create(); }
    // ...
});
```

**Решение A2:** Найти правильное имя поля через исходники Legends (grep по `m\.Text` в папке `ambitions/ambitions/`).

### Проблема B: ванильные амбиции в пуле для нашего сценария

**Симптом:** Вместе с нашими амбициями в пуле показываются ванильные BB амбиции.

**Причина:** Ванильные амбиции не имеют фильтра по сценарию.

**Решение:** Создать хуки подавления по паттерну из раздела 7. Нужно определить точные имена файлов ванильных амбиций (см. раздел 7).

### Проблема C: кастомные амбиции вытесняются ванильными

**Симптом:** При base score = 5 и золото = 0 наши амбиции имеют score 5, а ванильные — выше → наши не попадают в топ-4.

**Решение:** Поднять base score до 30 (см. раздел 8). После подавления ванильных (Проблема B) эта проблема уйдёт сама.

---

## 10. Реализация Noble Faith — Глава I

Четыре амбиции, доступные одновременно с первого дня. Флаги сбрасываются при новой игре (они world-specific).

| # | Название | Файл | Условие | Score логика | Статус |
|---|----------|------|---------|-------------|--------|
| 1.1 | «Собрать отряд» | `scripts/ambitions/ambitions/noble_plus_hire_soldiers_ambition.nut` | 8+ бойцов в ростере | `count × 12 + 5` (нужно поднять base до 30) | ✅ создан, ⚠️ base score низкий |
| 1.2 | «Наполнить казну» | `scripts/ambitions/ambitions/noble_plus_earn_gold_ambition.nut` | 2000+ крон | `gold/2000 × 80 + 5` (нужно поднять base до 30) | ✅ создан, ⚠️ base score низкий |
| 1.3 | «Заявить о себе» | `scripts/ambitions/ambitions/noble_plus_find_allies_ambition.nut` | 500+ известности | `rep/500 × 80 + 5` (нужно поднять base до 30) | ✅ создан, ⚠️ base score низкий |
| 1.4 | «Знамя отряда» | хук `hooks/ambitions/ambitions/battle_standard_ambition.nut` | 2000 крон (ванильная) | ванильная логика | ✅ хук создан |

**Логика перехода к Главе II:**
Когда все 4 флага установлены → игрок готов к штурму замка (Этап 1.4 нарратива → отдельная задача).

---

## 11. Флаги состояния Noble Faith

Флаги используют `this.World.Flags` (персистентное состояние конкретной кампании).

```
Флаг                                    Когда устанавливается
────────────────────────────────────────────────────────────────────
NoblePlus.Stage.HireSoldiers.Done       8+ бойцов в ростере (амбиция 1.1)
NoblePlus.Stage.EarnGold.Done           2000+ крон (амбиция 1.2)
NoblePlus.Stage.FindAllies.Done         500+ известности (амбиция 1.3)
NoblePlus.Stage.OwnBanner.Done          штандарт куплен (амбиция 1.4, хук battle_standard)

── будущие флаги ──
NoblePlus.Chapter1.Done                 все 4 флага → открывает событие штурма замка
NoblePlus.Chapter1.BrotherFate          "killed" | "spared" | "random" (выбор игрока)
NoblePlus.Chapter1.Choice.OriginIntro   "truth" | "mercenary" | "alias" (пролог)
```

---

## 12. Иконки амбиций

Иконки задаются в `this.m.Icon`. Имена берутся из реестра иконок BB.

| Имя иконки | Что изображает | Статус |
|-----------|----------------|--------|
| `"ambition_roster_size"` | размер ростера / люди | ⚠️ не верифицировано |
| `"ambition_gold"` | золото / казна | ⚠️ не верифицировано |
| `"ambition_renown"` | известность | ⚠️ не верифицировано |
| `""` (пустая строка) | без иконки | ✅ безопасный fallback |

**Диагностика:** При ошибке иконки в логе будет `icon not found: ICON_NAME`. В этом случае — заменить на `""`.

**Как найти правильные имена:** Посмотреть исходники ванильных амбиций в Legends — в них `m.Icon` задан явно. Например, в `ambitions/ambitions/hire_soldiers_ambition.nut` (если он есть в Legends).

---

## 13. Чеклист: добавление новой амбиции

```
[ ] 1. Создать файл scripts/ambitions/ambitions/noble_plus_NNN_ambition.nut
[ ] 2. Унаследовать от "scripts/ambitions/ambition"
[ ] 3. В create(): задать ID (уникальный), Name, UIText, TooltipText, SuccessText, Icon
[ ] 4. В onUpdateScore():
        [ ] Фильтр по сценарию (обязательно!)
        [ ] Проверка флага "уже выполнено" (обязательно!)
        [ ] Логика завершения → IsDone = true, Score = 100, Flags.set(...)
        [ ] Прогрессивный Score с base >= 30
[ ] 5. В getList(): список прогресс-пунктов для UI
[ ] 6. onSerialize / onDeserialize: вызов родительских методов
[ ] 7. Добавить флаг завершения в раздел 11 этого документа
[ ] 8. Если нужно подавить ванильную амбицию — создать хук (раздел 7)
[ ] 9. Тест: рассвет 2-го дня → амбиция видна в пуле с правильным текстом
[?] 10. Тест: иконка отображается без ошибок в логе
```

---

## 14. Структура файлов в репозитории

```
mod/mod_noble_plus/
├── scripts/
│   ├── !mods_preload/
│   │   └── mod_noble_plus.nut                        ← регистрация мода
│   ├── ambitions/
│   │   └── ambitions/
│   │       ├── noble_plus_hire_soldiers_ambition.nut  ← амбиция 1.1
│   │       ├── noble_plus_earn_gold_ambition.nut      ← амбиция 1.2
│   │       └── noble_plus_find_allies_ambition.nut    ← амбиция 1.3
│   ├── events/events/noble_plus/
│   │   └── noble_plus_intro_event.nut                 ← пролог
│   └── scenarios/world/
│       └── noble_plus_scenario.nut                    ← сценарий
└── hooks/
    └── ambitions/
        └── ambitions/
            ├── battle_standard_ambition.nut           ← хук амбиции 1.4 (+ нарратив)
            ├── pledge_of_allegiance_ambition.nut      ← TODO: хук подавления
            └── friend_settlement_ambition.nut         ← TODO: хук подавления
```
