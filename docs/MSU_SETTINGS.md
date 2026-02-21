# MSU Settings — Тестовая интеграция (PoC)

## Задача

Добавить тестовую вкладку "Noble Plus" в меню "Настройки модов" в главном меню игры.

**Цель:** Доказать что мод может корректно интегрироваться в систему MSU Settings.

**Важно:** Это тест/заглушка. Настоящие настройки будут добавлены позже, когда мод будет функционально готов.

---

## Краткая справка: как работает MSU Settings

Когда мод создаётся через `::MSU.Class.Mod`, у него автоматически появляется свойство `ModSettings`:

```squirrel
::NoblePlus.Mod <- ::MSU.Class.Mod(::NoblePlus.ID, ::NoblePlus.Version, ::NoblePlus.Name);

// Теперь доступен:
::NoblePlus.Mod.ModSettings
```

У `ModSettings` есть метод `addPage(id, name)` — он создаёт страницу настроек.

---

## План реализации (3 шага)

### Шаг 1. Создать файл с тестовыми настройками

Файл: `data/mod_noble_plus/settings/mod_settings.nut`

```squirrel
// =============================================================================
// mod_noble_plus — тестовые настройки (PoC)
// =============================================================================

::NoblePlus.ModSettings <- function()
{
    local ms = ::NoblePlus.Mod.ModSettings;

    // Создаём одну страницу с тестовыми заглушками
    local page = ms.addPage("Тест");

    // Заглушка 1: Простая булева настройка
    page.addBooleanSetting(
        "TestBool",
        true,
        "Тестовая настройка",
        "Это заглушка для проверки что вкладка работает."
    );

    // Заглушка 2: Настройка диапазона
    page.addRangeSetting(
        "TestRange",
        50,
        0,
        100,
        5,
        "Тестовый слайдер",
        "Заглушка слайдера."
    );

    // Заглушка 3: Перечисление
    page.addEnumSetting(
        "TestEnum",
        "Вариант 1",
        ["Вариант 1", "Вариант 2", "Вариант 3"],
        "Тестовый выпадающий список",
        "Заглушка выпадающего списка."
    );

    // Кнопка-заглушка
    local btn = page.addButtonSetting(
        "TestButton",
        null,
        "Тестовая кнопка",
        "При нажатии пишет в лог."
    );
    btn.addCallback(function(_data) {
        ::logInfo("Noble Plus: тестовая кнопка нажата!");
    });

}();
```

### Шаг 2. Подключить файл в preload

Редактировать: `data/mod_noble_plus/scripts/!mods_preload/mod_noble_plus.nut`

```squirrel
::mods_queue(::NoblePlus.ID, "mod_msu, mod_legends", function()
{
    ::NoblePlus.Mod <- ::MSU.Class.Mod(::NoblePlus.ID, ::NoblePlus.Version, ::NoblePlus.Name);

    // Подключаем тестовые настройки
    ::include("mod_noble_plus/settings/mod_settings.nut");

    ::logInfo("Noble Plus " + ::NoblePlus.Version + " загружен.");
});
```

### Шаг 3. Протестировать

1. Запустить игру
2. В главном меню зайти в "Настройки модов"
3. Найти вкладку "Noble Plus"
4. Проверить что страница "Тест" отображается
5. Проверить что все 4 заглушки работают
6. Проверить лог на отсутствие ошибок

---

## Ожидаемый результат

В меню "Настройки модов" должна появиться новая вкладка с названием мода "Noble Plus". На вкладке — страница "Тест" с 4 элементами-заглушками.

Если это работает — система MSU Settings функционирует корректно и готова для будущих реальных настроек.

---

## Что делать ПОСЛЕ теста (когда мод будет готов)

Когда функционал мода будет реализован, заменить заглушки на реальные настройки:

```squirrel
// Пример реальных настроек (на будущее)
local mainPage = ms.addPage("Основное");

mainPage.addBooleanSetting(
    "EnableWhiteWolf",
    true,
    "Выдавать белого волка",
    "Если включено, дворянин начнёт игру с легендарным белым волком."
);

mainPage.addRangeSetting(
    "StartingGold",
    2500,
    0,
    10000,
    100,
    "Стартовое золото",
    "Количество золота при старте происхождения."
);
```

Использование в коде:

```squirrel
// В сценарии:
local enableWolf = ::NoblePlus.Mod.ModSettings.getSetting("EnableWhiteWolf").getValue();
if (enableWolf) {
    // выдаём волка
}
```

Но это всё — потом. Сейчас нужен только тест.
