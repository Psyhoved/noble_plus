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

    // Подключаем тестовые настройки
    ::include("mod_noble_plus/settings/mod_settings.nut");

    // Логируем успешный запуск — увидим в read_game_log(only_squirrel=true)
    ::logInfo("Noble Plus " + ::NoblePlus.Version + " загружен.");
});
