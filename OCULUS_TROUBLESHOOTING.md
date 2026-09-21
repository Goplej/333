# Oculus: ошибка `m_166612_ is not cancellable`

Ошибка вида:

```text
net.minecraft.server.ChainedJsonException: Invalid shaders/core/lines.json:
The call m_166612_ is not cancellable.
```

возникает **до компиляции файлов шейдерпака**. `shaders/core/lines.json` — внутренний
core shader Minecraft, которого нет в CozyCraft. Это известный класс ошибок Oculus
1.8.0 на Minecraft 1.20.1: аналогичная ошибка зарегистрирована у Oculus для
`moving_block.json` и `terrain_translucent.json`.

## Рабочая диагностика для 1.20.1 Forge

1. Использовать Java 17, а не Java 21.
2. Полностью удалить OptiFine/OptiFabric/Iris из этой Forge-сборки.
3. Оставить для теста только Forge + Embeddium + Oculus совместимых версий.
4. Удалить старый Rubidium, если установлен Embeddium. Не держать их одновременно.
5. Очистить `config/oculus.properties` и кэш шейдеров, затем перезапустить игру.
6. Положить ZIP только в `.minecraft/shaderpacks`, не в `resourcepacks` и не в `mods`.
7. Если чистая связка работает, возвращать render/core-mods по одному. Ошибку вызывает
   конфликт mixin, который пытается отменить не-cancellable вызов загрузчика core shaders.

Если ошибка остаётся на чистой связке, нужен `latest.log` с полным списком модов и
точными версиями Minecraft, Forge, Oculus, Embeddium и Java. Исправить mixin-конфликт
добавлением `lines.json` в шейдерпак нельзя: это только скроет имя ресурса, но не
изменит ошибочный injection Oculus/другого core-mod.
