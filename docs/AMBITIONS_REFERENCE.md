# Система амбиций Battle Brothers — Справочник для Noble Faith

> Версия: 1.1 | Дата: 22.02.2026
> Источник: исходники Legends 19.1.47 + ванильные файлы BB + опыт этапов 3.4–3.5
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

## 3. Файловая система мода и загрузка хуков

### Структура VFS (Virtual File System) BB

Движок монтирует содержимое папки `data/` как корень VFS:
- **ZIP-архивы** (`data/*.zip`) — содержимое монтируется с сохранением путей внутри архива
  - Пример: `mod_legends-*.zip` содержит `mod_legends/hooks/...` → VFS путь `mod_legends/hooks/...`
- **Папки** (`data/mod_noble_plus/`) — содержимое монтируется **с именем папки как префиксом**
  - Пример: `data/mod_noble_plus/hooks/...` → VFS путь `mod_noble_plus/hooks/...`
  - Пример: `data/mod_noble_plus/scripts/...` → VFS путь `mod_noble_plus/scripts/...`

### Авто-сканирование

Движок BB авто-сканирует следующие пути VFS при старте:
- `scripts/scenarios/world/` — происхождения (подтверждено сессия 2)
- `scripts/events/events/` — события (подтверждено сессия 5)
- `scripts/ambitions/ambitions/` — амбиции (подтверждено сессия 7 — файлы из `data/scripts/` видны)

**Важно:** автосканирование ищет именно `scripts/...` (без префикса мода). Поэтому скрипты мода в `data/scripts/` подхватываются автоматически, а файлы в `data/mod_noble_plus/scripts/` — нет, пока не примонтированы иначе.

Наш деплой: скрипты копируются как в `data/scripts/ambitions/ambitions/`, так и в `data/mod_noble_plus/scripts/ambitions/ambitions/` (поскольку папка — симлинк на проект). Подхватываются из `data/scripts/`.

### Хуки: ОБЯЗАТЕЛЬНА явная загрузка

Хук-файлы в `data/mod_noble_plus/hooks/` имеют VFS путь `mod_noble_plus/hooks/...`. Движок их НЕ сканирует автоматически. **Требуется явный вызов в `mods_queue`:**

```squirrel
::mods_queue(::NoblePlus.ID, "mod_msu, mod_legends", function()
{
    ::NoblePlus.Mod <- ::MSU.Class.Mod(::NoblePlus.ID, ::NoblePlus.Version, ::NoblePlus.Name);

    // Загрузка всех хуков из нашей папки hooks/
    foreach (file in ::IO.enumerateFiles("mod_noble_plus/hooks"))
    {
        ::include(file);
    }

    ::logInfo("Noble Plus " + ::NoblePlus.Version + " загружен.");
});
```

`::IO.enumerateFiles()` предоставляется MSU/Modern Hooks, доступен внутри `mods_queue`. Рекурсивно обходит все `.nut` файлы по пути. Аналог паттерна Legends: `enumerateFiles("mod_legends/hooks")`.

**Диагностика загрузки хуков:** В логе НЕ должно быть строк `The BB class 'ambitions/ambitions/make_nobles_aware_ambition' was never processed for hooks`. Их отсутствие = хук применён успешно.

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
| `ButtonText` | string | **обязательно** | **Текст на карточке в экране выбора амбиции.** Именно это поле читает UI. НЕ использовать `Name` — оно не является стандартным полем базового класса. Верифицировано по исходникам Legends (`legend_roster_of_6_ambition.nut`) и тестами сессии 7. |
| `UIText` | string | **обязательно** | Краткий текст в топ-баре при активной амбиции. Должна быть одна строка. Верифицировано: `ambition_manager.nut` вызывает `getUIText()` → `m.UIText` |
| `TooltipText` | string | рекомендуется | Описание в окне выбора и при наведении. BB-теги поддерживаются |
| `SuccessText` | string | рекомендуется | Текст в окне завершения. Поддерживает BB-теги `[img]`, `[color]` |
| `SuccessButtonText` | string | рекомендуется | Текст кнопки "ок" в окне завершения. По умолчанию — что-то ванильное |
| `Icon` | string | необязательно | Имя иконки. Пустая строка `""` — без иконки |
| `Score` | int (0–100) | авто | Приоритет в пуле (выше = ближе к верху). Выставляется в `onUpdateScore()` |
| `IsDone` | bool | авто | Флаг завершения. Устанавливать `true` в `onUpdateScore()` при выполнении |

**Почему `Name` не работает:** В базовом классе `ambition.create()` создаёт `m` как пустую таблицу со стандартными полями (`UIText`, `ButtonText`, `TooltipText`, etc.), но без поля `Name`. Попытка `this.m.Name = "..."` в `create()` даёт ошибку "the index 'Name' does not exist" (если `m.Name` не был предварительно объявлен в `m = {}`). Поле `Name` нигде не читается UI — используйте `ButtonText` для текста на карточке.

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

Ванильные амбиции появятся в пуле выбора для всех игроков, включая Noble Plus. Для подавления используется **единый файл-supressor** вместо N отдельных хуков.

### Единый suppressor (текущий подход — сессия 9)

Файл: `hooks/ambitions/noble_plus_vanilla_suppressor.nut`

```squirrel
local vanillaAmbs = [
    "scripts/ambitions/ambitions/allied_civilians_ambition",
    "scripts/ambitions/ambitions/allied_nobles_ambition",
    // ... (полный список в файле — 22+ записи)
    // При обнаружении новой DLC-амбиции: добавить одну строку сюда
];

foreach (p in vanillaAmbs)
{
    ::mods_hookExactClass(p, function(o)
    {
        local origUpdate = o.onUpdateScore.bindenv(o);
        o.onUpdateScore = function()
        {
            if (::World.Assets.getOrigin().getID() == "scenario.noble_plus")
            {
                this.m.Score = 0;
                return;
            }
            origUpdate();
        };
    });
}
```

**Почему `bindenv(o)` а не просто `= o.onUpdateScore`:** `bindenv` гарантирует правильный `this` при вызове оригинального метода.

**Почему `foreach` безопасен:** inner `function(o)` не ссылается на переменную цикла `p` — closure-проблем нет. Каждый вызов `mods_hookExactClass` получает корректный string.

### Safety net: ambition_manager hook

Файл: `hooks/ambitions/ambition_manager.nut`

Перехватывает `setAmbition()`: если происхождение `noble_plus` и ID не начинается с `ambition.noble_plus.` — активация блокируется. Защита от DLC-амбиций, не вошедших в список suppressor'а.

### Известные ванильные амбиции (22 файла)

Полный список в `noble_plus_vanilla_suppressor.nut`. Источник: хуки Legends 19.1.47 + Legends custom scripts.

**ВАЖНО:** Имена `pledge_of_allegiance_ambition` и `friend_settlement_ambition` в vanilla BB **НЕ СУЩЕСТВУЮТ**. Правильные имена: `make_nobles_aware_ambition` и `allied_civilians_ambition` (подтверждено через data_001.dat).

### TODO: неизвестная DLC-амбиция

Амбиция "В южных городах-государствах деньги текут рекой..." (вероятно Blazing Deserts DLC) не идентифицирована. Найти имя файла через лог при тестировании и добавить в suppressor.

---

## 8. Score: как рассчитывать приоритет

Движок показывает в окне выбора до **4 амбиций** с наивысшим `Score`. Амбиции со `Score = 0` не появляются.

**Рекомендации по значениям:**

| Ситуация | Значение Score |
|----------|---------------|
| Амбиция не подходит / подавлена | `0` |
| Активная амбиция Noble Plus (наш стандарт) | **`9999`** — всегда доминирует пул |
| Завершена (`IsDone = true`) | значение не важно, движок убирает амбицию из пула |

**Почему 9999:** Ванильные амбиции имеют Score 30–90. При Score = 9999 у всех 4 амбиций Noble Plus они всегда занимают все 4 слота пула, ванильные (даже непоавляются при наличии 4+ наших активных) не конкурируют. Критически важно когда из 4 амбиций главы выполнены 3 и осталась 1 — без 9999 ванильные заняли бы освободившиеся 3 слота.

**Паттерн для активной амбиции Noble Plus:**
```squirrel
function onUpdateScore()
{
    if (this.World.Assets.getOrigin().getID() != "scenario.noble_plus") return;
    if (this.World.Flags.has("MyStage.Done")) return;

    this.m.Score = 9999;  // Доминируем пул

    if (condition)
    {
        this.m.IsDone = true;
        this.World.Flags.set("MyStage.Done", true);
        ::NoblePlus.tryFireChapterComplete(...);
    }
}
```

---

## 9. Решённые проблемы (история отладки сессий 3.4–3.5)

### Проблема A: пустые тексты у кастомной амбиции ✅ РЕШЕНА

**Симптом (сессия 7):** Амбиция появляется в пуле (Score > 0, иконка видна), но поле текста пусто.

**Корневая причина:** Использование `m.Name` вместо `m.ButtonText`. Поле `Name` не является стандартным полем базового класса — `ambition.create()` его не создаёт. UI читает `ButtonText` для отображения текста на карточке выбора.

**Решение:** Заменить `Name` на `ButtonText` во всех кастомных амбициях.

### Проблема B: ванильные амбиции в пуле ✅ РЕШЕНА

**Симптом:** Вместе с нашими амбициями в пуле показываются ванильные (make_nobles_aware, allied_civilians).

**Корневые причины (обе важны):**
1. Хуки подавления не загружались — отсутствовал `enumerateFiles` в preload
2. Хуки просто делали `return` без `Score = 0` — ванильная Score из `create()` могла быть > 0

**Решение:** Добавить `enumerateFiles` в preload + добавить `this.m.Score = 0` в хуки подавления.

### Проблема C: кастомные амбиции вытесняются ванильными ✅ РЕШЕНА

**Симптом:** При base score = 5 наши амбиции (earn_gold, find_allies) вытеснялись ванильными.

**Решение:** Поднять base score до 30. После подавления ванильных (Проблема B) вытеснение прекращается.

### Проблема D: хуки не применяются ✅ РЕШЕНА

**Симптом:** battle_standard показывал ванильный текст; make_nobles_aware не подавлялась.

**Корневая причина:** Хук-файлы в `data/mod_noble_plus/hooks/` не загружались автоматически. Движок сканирует только `scripts/`, но не `mod_noble_plus/hooks/`.

**Решение:** Добавить в `mods_queue` callback:
```squirrel
foreach (file in ::IO.enumerateFiles("mod_noble_plus/hooks")) { ::include(file); }
```

---

## 10. Реализация Noble Faith — Глава I

Четыре амбиции, доступные одновременно с первого дня. Все имеют Score = 9999 (доминируют пул). Флаги сбрасываются при новой игре (world-specific).

| # | Название | Файл | Условие | Score | Статус |
|---|----------|------|---------|-------|--------|
| 1.1 | «Собрать отряд» | `scripts/ambitions/ambitions/noble_plus_hire_soldiers_ambition.nut` | 8+ бойцов в ростере | 9999 | ✅ |
| 1.2 | «Наполнить казну» | `scripts/ambitions/ambitions/noble_plus_earn_gold_ambition.nut` | 2000+ крон | 9999 | ✅ |
| 1.3 | «Заявить о себе» | `scripts/ambitions/ambitions/noble_plus_find_allies_ambition.nut` | 500+ известности | 9999 | ✅ |
| 1.4 | «Знамя Дома Локвуд» | хук `hooks/ambitions/ambitions/battle_standard_ambition.nut` | 2000 крон (ванильная механика) | 9999 | ✅ |

**Логика перехода к Главе II:**
Все 4 Done-флага → `tryFireChapterComplete` → флаг `NoblePlus.Chapter1.Complete` + событие `event.noble_plus_chapter1_complete`.

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
NoblePlus.Chapter1.Complete             все 4 Done-флага → tryFireChapterComplete → событие chapter1_complete

── будущие флаги ──
NoblePlus.Chapter2.Complete             завершение Главы II
NoblePlus.Chapter1.BrotherFate          "killed" | "spared" | "random" (выбор игрока)
NoblePlus.Chapter1.Choice.OriginIntro   "truth" | "mercenary" | "alias" (пролог)
```

---

## 11.5. Прогрессия глав: tryFireChapterComplete

Хелпер определён в `scripts/!mods_preload/mod_noble_plus.nut` внутри `mods_queue` callback.

```squirrel
::NoblePlus.tryFireChapterComplete <- function(_flags, _done_flag, _event_id)
{
    if (::World.Flags.has(_done_flag)) return;           // идемпотентность

    foreach (flag in _flags)
    {
        if (!::World.Flags.has(flag)) return;            // не все выполнены — выходим
    }

    ::World.Flags.set(_done_flag, true);
    ::World.Events.fire(_event_id);                      // нарративный мост к следующей главе
};
```

**Вызов из каждой амбиции** (после Done-флага):
```squirrel
this.World.Flags.set("NoblePlus.Stage.HireSoldiers.Done", true);
::NoblePlus.tryFireChapterComplete(
    ["NoblePlus.Stage.HireSoldiers.Done",
     "NoblePlus.Stage.EarnGold.Done",
     "NoblePlus.Stage.FindAllies.Done",
     "NoblePlus.Stage.OwnBanner.Done"],
    "NoblePlus.Chapter1.Complete",
    "event.noble_plus_chapter1_complete"
);
```

**Логика событий-мостов (между главами):**
- Событие `event.noble_plus_chapter1_complete` — финал Главы I: нарратив + переход к Главе II
- Файл: `scripts/events/events/noble_plus/noble_plus_chapter1_complete_event.nut`
- IsSpecial = true → показывается немедленно, не ждёт следующего дня

**Амбиции Главы II** (будущее) — в `onUpdateScore` проверяют:
```squirrel
if (!this.World.Flags.has("NoblePlus.Chapter1.Complete")) return;  // Глава I не завершена
if (this.World.Flags.has("NoblePlus.Chapter2.Complete")) return;   // Глава II уже сделана
this.m.Score = 9999;
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
│   │   └── mod_noble_plus.nut              ← регистрация + tryFireChapterComplete + enumerateFiles
│   ├── ambitions/
│   │   └── ambitions/
│   │       ├── noble_plus_hire_soldiers_ambition.nut  ← амбиция 1.1 (Score=9999)
│   │       ├── noble_plus_earn_gold_ambition.nut      ← амбиция 1.2 (Score=9999)
│   │       └── noble_plus_find_allies_ambition.nut    ← амбиция 1.3 (Score=9999)
│   ├── events/events/noble_plus/
│   │   ├── noble_plus_intro_event.nut              ← пролог (сессия 5)
│   │   └── noble_plus_chapter1_complete_event.nut  ← финал Главы I (сессия 9)
│   └── scenarios/world/
│       └── noble_plus_scenario.nut         ← сценарий
└── hooks/                                  ← ЗАГРУЖАЕТСЯ через enumerateFiles в preload
    └── ambitions/
        ├── noble_plus_vanilla_suppressor.nut   ← единый файл подавления всех ванильных (22+ амбиции)
        ├── ambition_manager.nut                ← safety net: блокировка ванильных при клике
        └── ambitions/
            └── battle_standard_ambition.nut    ← хук 1.4: Score=9999 + нарратив Noble Plus
```

**Деплой:** скрипты (`scripts/`) копируются в `data/scripts/`. Хуки (`hooks/`) через junction с проектом доступны напрямую как `data/mod_noble_plus/hooks/` → VFS `mod_noble_plus/hooks/...` → загружаются через `enumerateFiles`.
