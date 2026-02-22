// =============================================================================
// mod_noble_plus — регистрация мода
// =============================================================================
// Этот файл загружается движком самым первым, ещё до старта основной игры.
// Здесь мы объявляем глобальное пространство имён мода, регистрируем его
// в системе модов и ставим в очередь загрузки после наших зависимостей.

::NoblePlus <- {
    ID      = "mod_noble_plus",
    Version = "0.1.0",
    Name    = "Noble Plus"
};

// Регистрируем мод в движке — без этого он невидим для системы очередей.
::mods_registerMod(::NoblePlus.ID, ::NoblePlus.Version, ::NoblePlus.Name);

// Ставим мод в очередь загрузки.
// Ключевое: мы грузимся ПОСЛЕ mod_msu и mod_legends.
// Это гарантирует, что все API Легенд уже доступны когда наш код запускается.
::mods_queue(::NoblePlus.ID, "mod_msu, mod_legends", function()
{
    ::NoblePlus.Mod <- ::MSU.Class.Mod(::NoblePlus.ID, ::NoblePlus.Version, ::NoblePlus.Name);

    // TODO: настройки отключены до исправления MSU Settings API
    // ::include("mod_noble_plus/settings/mod_settings.nut");

    // -------------------------------------------------------------------------
    // tryFireChapterComplete — хелпер для триггера событий между главами.
    // Вызывается из каждой амбиции после выставления Done-флага.
    // Проверяет: все ли флаги _flags выставлены? Если да — ставит _done_flag
    // и запускает событие _event_id (нарративный мост к следующей главе).
    // Идемпотентна: повторные вызовы игнорируются через проверку _done_flag.
    // -------------------------------------------------------------------------
    ::NoblePlus.tryFireChapterComplete <- function(_flags, _done_flag, _event_id)
    {
        if (::World.Flags.has(_done_flag)) return;

        foreach (flag in _flags)
        {
            if (!::World.Flags.has(flag)) return;
        }

        ::World.Flags.set(_done_flag, true);
        ::World.Events.fire(_event_id);
        ::logInfo("[NoblePlus] " + _done_flag + " — глава завершена, событие: " + _event_id);
    };

    // Загружаем хук-файлы из mod_noble_plus/hooks/.
    // Без этого вызова файлы из папки hooks/ остаются в VFS недоступными
    // для движка — он не сканирует hooks/ автоматически, только scripts/.
    foreach (file in ::IO.enumerateFiles("mod_noble_plus/hooks"))
    {
        ::include(file);
    }

    // Логируем успешный запуск — увидим в read_game_log(only_squirrel=true)
    ::logInfo("Noble Plus " + ::NoblePlus.Version + " загружен.");
});
