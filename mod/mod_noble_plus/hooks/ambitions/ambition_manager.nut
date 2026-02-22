// =============================================================================
// Хук ambition_manager — safety net для сценария "Дворянин +"
// =============================================================================
// Перехватываем setAmbition() чтобы предотвратить активацию любой ванильной
// амбиции в нашем сценарии — даже если она каким-то образом попала в пул
// (например, неизвестная DLC-амбиция без записи в suppressor'е).
//
// Если игрок видит ванильную амбицию и кликает на неё — ничего не происходит,
// экран закрывается и через короткое время появляется снова (только с нашими).
//
// Паттерн: mods_hookNewObject (как у Legends для этого же файла).
// Наш хук добавляется поверх уже применённого Legends-хука — порядок гарантирован
// зависимостью mods_queue("mod_noble_plus", "mod_msu, mod_legends", ...).

::mods_hookNewObject("ambitions/ambition_manager", function(o)
{
    local origSetAmbition = o.setAmbition.bindenv(o);

    o.setAmbition = function( _ambition )
    {
        if (this.World.Assets.getOrigin().getID() == "scenario.noble_plus")
        {
            local id = _ambition.getID();

            // Разрешаем: наши амбиции + ambition.none (пропуск)
            if (id != "ambition.none" && id.find("ambition.noble_plus.") != 0)
            {
                // Ванильная амбиция — отклоняем.
                // setDelay(1) дает 1 час задержки перед следующим показом экрана.
                this.setDelay(1);
                return;
            }
        }

        origSetAmbition(_ambition);
    };
});
