# Судьба благородных (Noble Faith) — мод для Battle Brothers

Мод добавляет новое происхождение **"Дворянин +"** для игры Battle Brothers (требуются Legends + MSU).

## Концепция

Вы — опальный дворянин, изгнанный из родового замка. Всё, что осталось — верный слуга, горстка монет и родовой зверь: легендарный белый волк. Теперь предстоит с нуля вернуть имя, честь и замок.

**Особенности:**
- 🐺 **Родовой зверь** — легендарный белый волк с первого дня
- 🪨 **Верный слуга** — начинает с пращой, а старый кинжал держит в суме как запасной довод
- ☠️ **Честь дворянина** — гибель дворянина = конец игры

## Зависимости

- [Battle Brothers](https://store.steampowered.com/app/365360/Battle_Brothers/)
- [Legends](https://www.nexusmods.com/battlebrothers/mods/360)
- [MSU](https://www.nexusmods.com/battlebrothers/mods/306)

## Установка

Скопировать папку `mod/mod_noble_plus/` в `data/` папки игры.

## Структура репозитория

```
noble_plus/
├── mod/
│   └── mod_noble_plus/   ← файлы мода (кладутся в data/ игры)
│       ├── scripts/
│       └── settings/
├── docs/                 ← документация разработки (начать с docs/README.md)
├── tools/                ← утилиты разработки/деплоя (например deploy_live_scripts.sh)
└── README.md
```

## Для разработчика

Главный технический стандарт проекта находится в `docs/MODDING_BB_LEGENDS_GUIDE.md`.
Режим проекта: single runtime-source (Вариант B).
Роль реализации: Senior разработчик модов к Battle Brothers с базовым Legends.

1. Разовая настройка: `./tools/setup_single_source_runtime.sh`
2. Перед каждым тестом: `./tools/preflight_live.sh`

## Статус

🚧 В разработке — Этап 3: базовый сценарий

---

*Мод разрабатывается с помощью [Claude](https://claude.ai)*
