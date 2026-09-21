# CozyLite Shaders

**CozyLite** — лёгкий legacy-шейдерпак GLSL 1.20 для Minecraft 1.12.2–1.21.x, OptiFine, Iris/Sodium и Oculus/Embeddium. Его цель — тёплая кинематографичная картинка на встроенной Intel HD и видеокартах класса GT 730 / GTX 750 Ti без десятка полноэкранных проходов.

## Краткий обзор архитектуры

Пак использует компактный deferred-like конвейер:

1. `gbuffers_*` записывают цвет (`colortex0`), нормаль (`colortex1`) и lightmap/material/wetness (`colortex2`).
2. `shadow` создаёт одну depth-карту. В `composite` применяется 1/4/8-tap PCF в зависимости от профиля.
3. `composite` — основной атмосферный проход: объёмные облака, radial light shafts, тени, туман, optional SSAO/SSR. Объединение эффектов экономит bandwidth.
4. `composite1` пишет в отдельный `colortex4` размером **1/2 × 1/2** и строит только bloom. Это в четыре раза меньше пикселей полного кадра.
5. `final` смешивает bloom, выполняет optional DOF/motion blur, подводное искажение и ACES-коррекцию.

Облака пересекают луч камеры со слоем высотой 145–255 блоков. «3D»-шум получается интерполяцией двух выборок встроенной 2D `noisetex`; четыре октавы движутся с разными скоростями. Ray marching ограничен 4–14 шагами, исполняется только для пикселей неба, пропускает пустые ячейки и прекращается при opacity > 0.96. Поэтому на Balanced атмосфера обычно остаётся заметно ниже 40% GPU-бюджета кадра; это целевой бюджет, а не абсолютная гарантия для любого разрешения/драйвера.

God rays проецируют активное светило в экранные координаты, берут 8–24 jittered-сэмпла к нему, используют depth как маску и карту теней как дополнительную окклюзию листвой.

## Структура

```text
CozyLite/
├── README.md
└── shaders/
    ├── shaders.properties
    ├── block.properties        # материалы листвы, растений и emissive-блоков
    ├── world-1/               # отдельная атмосфера Nether
    ├── world1/                # отдельная атмосфера End
    ├── lib/
    │   ├── settings.glsl       # все compile-time параметры
    │   ├── common.glsl         # ACES, normal encode, hash
    │   └── sky.glsl            # аналитическое уютное небо
    ├── lang/
    │   ├── ru_ru.lang
    │   └── en_us.lang
    ├── gbuffers_basic.*
    ├── gbuffers_textured.*
    ├── gbuffers_textured_lit.*
    ├── gbuffers_terrain.*
    ├── gbuffers_entities.*
    ├── gbuffers_hand.*
    ├── gbuffers_water.*
    ├── gbuffers_skybasic.*
    ├── gbuffers_skytextured.*
    ├── gbuffers_weather.* / clouds.* / beaconbeam.* / ...
    ├── skybasic.* / skytextured.*  # явные совместимые aliases
    ├── water.*                     # документируемый alias water pass
    ├── shadow.*
    ├── deferred.*
    ├── composite.*
    ├── composite1.*
    └── final.*
```

`*.vsh` — vertex shader, `*.fsh` — fragment shader. Реально Minecraft вызывает имена `gbuffers_skybasic` и `gbuffers_water`; файлы `skybasic` и `water` оставлены также отдельно по формату задания и для нестандартных загрузчиков.

## Профили эффектов

| Эффект | Potato | Fast | Balanced | Pretty | Ultra |
|---|:---:|:---:|:---:|:---:|:---:|
| Объёмные облака | — | 4 шага | 8 | 10 | 14 |
| God rays | — | 12 сэмплов | 16 | 20 | 24 |
| PCF-тени | 1 tap, 512 | 1 tap, 512 | 4 tap, 1024 | 8 tap, 1024 | 8 tap, 2048 |
| Bloom 1/2 res | — | Low | Medium | High | High |
| Отражение/преломление воды | Low | Low | Medium | High | High |
| Объёмный туман | — | ✓ | ✓ | ✓ | ✓ |
| Мокрые поверхности | — | ✓ | ✓ | ✓ | ✓ |
| Leaf SSS | — | — | ✓ | ✓ | ✓ |
| SSR | — | — | — | ✓ | ✓ |
| SSAO | — | — | — | ✓ | ✓ High |
| DOF / Motion Blur | — | — | — | — | ✓ |
| Дальность теней | 48 | 64 | 96 | 128 | 160 |

Цели 60+/45+/30+ FPS относятся соответственно к Fast/Balanced/Pretty при 1080p в типичной vanilla-сцене; модпаки, render distance, CPU и драйвер способны заметно изменить результат.

## Рекомендации по железу

| Профиль | Рекомендованное железо | Ожидание при 1080p |
|---|---|---|
| Potato | Intel HD 4000/4400, 4 ГБ RAM | Максимальная совместимость, около 60 FPS при 6–8 чанках |
| Fast | Intel HD 520/530, UHD 600/620, GT 710/730, 4–8 ГБ | Цель 60+ FPS, 8–10 чанков |
| Balanced | UHD 630/730, Vega 3/6, GT 730 GDDR5, GTX 750 Ti, 8 ГБ | Цель 45+ FPS, 8–12 чанков |
| Pretty | GTX 750 Ti/950, RX 460/550, Vega 8, 8 ГБ | Цель 30+ FPS; SSR наиболее чувствителен к разрешению |
| Ultra | GTX 1050 Ti/1650, RX 570/6400 и выше, 8–16 ГБ | 30–60 FPS; 2048-тени и post effects |

На ноутбуке обязательно запустите Java на дискретной GPU, если она есть. При нехватке FPS сначала уменьшайте render distance, затем `Cloud Steps`, `Shaft Samples`, shadow resolution и отключайте SSR.

## Установка

1. Установите подходящий загрузчик:
   - **1.12.2–1.16.5:** обычно OptiFine соответствующей версии.
   - **1.16.5–1.21.x:** Iris + Sodium рекомендуется; OptiFine также поддерживается, если выпущен для конкретной версии игры.
   - **Forge/NeoForge-сборки:** Oculus + Embeddium/Rubidium. Не ставьте Oculus одновременно с OptiFine.
2. Заархивируйте папку так, чтобы `shaders/` находилась прямо в корне ZIP, либо используйте папку целиком.
3. Поместите пакет в `.minecraft/shaderpacks/`.
4. В игре откройте `Настройки → Видео → Шейдеры`, выберите CozyLite.
5. Откройте настройки шейдера и сначала выберите `Fast` или `Balanced`. После смены compile-time параметров шейдеры перекомпилируются — это нормально.
6. Отключите vanilla clouds: шейдер уже рисует собственный облачный слой. Для честного сравнения включите VSync off и одинаковую дальность прорисовки.

## Различия версий и совместимость

- Используется legacy GLSL `#version 120`, `texture2D`, стандартные uniforms и `DRAWBUFFERS`, поэтому один набор программ покрывает 1.12.2–1.21.x.
- На 1.12.2 рекомендуются последние OptiFine HD U-сборки и профиль Potato/Fast: старые Intel-драйверы медленнее компилируют динамические ветвления.
- На 1.16.5+ Iris/Sodium обычно быстрее OptiFine. Oculus использует Iris-совместимый формат на Forge/NeoForge и читает те же legacy-программы, properties и профили. Iris читает legacy shaderpack properties и стандартные `colortex/depthtex/shadowtex` attachments.
- Материалы задаются через `block.properties` по registry name, а не старым numeric block ID. Vanilla-листва, растения и emissive-блоки получают отдельное поведение; неизвестные блоки из модов безопасно попадают в generic-материал. Render-layer модов при этом продолжает определять воду и прозрачность.
- Dynamic Lights — функция загрузчика: включается отдельно в OptiFine; в Iris нужен совместимый мод. Это не влияет на компиляцию пакета.
- Half precision (`mediump`) не даёт выигрыша и иногда не принимается старыми desktop GLSL 1.20 драйверами. Поэтому пакет минимизирует промежуточные данные и хранит расчёты короткими; мобильные реализации могут автоматически понизить точность. Явные precision qualifiers намеренно не используются ради Intel HD/старого OpenGL.

## Настройка и технические примечания

- Для Nether и End используются отдельные composite wrappers: красный дымчатый Nether и тихий фиолетовый End без overworld-облаков и солнечных лучей.
- Растительность одинаково колышется в основном и shadow-pass, поэтому тени не «отрываются» от листьев.
- `CLOUD_SCALE` — визуальный размер облачных масс, `CLOUD_COVERAGE` — заполнение.
- `GODRAY_INTENSITY` и `GODRAY_DECAY` управляют яркостью и длиной radial shafts.
- `shadowMapResolution` доступен как 512/1024/2048, `shadowDistance` — 48–160 блоков.
- Bloom имеет яркостный early exit и не размывает весь кадр. Tone mapping выполняется после смешивания, чтобы сохранить highlights.
- SSR — ограниченный 8-step screen-space поиск с sky fallback. Он не отражает объекты вне экрана, что является нормальным ограничением SSR.
- Вода использует две движущиеся noise-нормали, depth-safe refraction, Fresnel и аналитическое отражение неба; Pretty/Ultra добавляет SSR.
- Если конкретная старая сборка OptiFine игнорирует `size.buffer.colortex4=0.5 0.5`, bloom останется функциональным, но будет полноразмерным. Для максимального FPS отключите Bloom.

Лицензия: свободно используйте и изменяйте пакет в личных проектах; при распространении производной версии укажите CozyLite как основу.


## Проверка сборки

Все 54 root/dimension shader stages проходят раскрытие `#include`, C-preprocessing активного Balanced-профиля и синтаксический разбор GLSL AST. Проверены парность vertex/fragment программ, пути include, структура ZIP и отсутствие конфликт-маркеров. Окончательная проверка изображения всегда выполняется внутри игры, поскольку только загрузчик предоставляет uniforms, attachments и shadow framebuffer.

## Для модпаков

- **Fabric:** Iris + Sodium; Indium нужен только для старых версий Sodium/модов Fabric Rendering API.
- **Forge 1.16–1.20.1:** Oculus + Embeddium (либо совместимая с версией сборки связка Oculus/Rubidium).
- **NeoForge:** используйте актуальный Iris/Oculus-порт, заявляющий поддержку вашей версии игры.
- Не объединяйте два shader loader в одной сборке. OptiFine, Iris и Oculus — альтернативы, а не дополнения друг к другу.
- Для Create, крупной генерации мира и 200+ модов начинайте с Fast/Balanced и 8–10 чанков. Animated contraptions и нестандартные translucent render layers могут не иметь SSR, но сохранят базовое освещение.

## Cinematic HD assets

Release 3.0 includes roughly 77 MiB of deterministic texture data: two 4096² cloud
noise fields, a 4096² RGB weather map, a 2048² water-normal field and a 2048²
blue-noise texture. `HD_ASSETS` is disabled in Potato/Fast/Balanced, so these textures
do not consume VRAM on weak profiles. Pretty and Ultra enable them for less tiling,
more varied cloud fronts, finer water normals and cleaner ray-march jitter.

The large download size comes from actual high-entropy atmospheric data rather than
padding or repeated source. Shader code remains modular because duplicating identical
GLSL thousands of times would increase compile time and reduce performance. Assets can
be reproduced with `tools/generate_assets.py` (Pillow + NumPy).

## 3.1 Oculus line-pipeline compatibility

The explicit `gbuffers_line` override was removed. Oculus 1.8.0 on Minecraft 1.20.1
can enter its broken cancellable core-shader hook when a pack supplies that optional
program, producing `Invalid shaders/core/lines.json`. Lines now use the loader fallback,
while terrain, entities, weather, beacon beam, glint, damage overlay and emissive eyes
retain dedicated non-duplicated programs.
