# Plan: Design System — Токены (Итерация 1)

**Created**: 2026-08-01
**Revised**: 2026-08-04 — full deletion of `Core/Constants/Spacing.swift`/`Typography.swift` (was: parallel namespace), see "Ключевое архитектурное решение"
**Status**: pending
**Estimated complexity**: M → M/L (adds full migration of 36 call sites across 10 files)

## Goal

Заложить фундамент дизайн-системы StanisLoveTV на основе HTML-мокапа дизайнера
(`Design System.dc.html`): типобезопасные SwiftUI-токены для Color, Typography (Font),
Spacing, Radius, Shadow и Animation. Это **только токены** — без переиспользуемых
компонентов (кнопки, карточки, бейджи, инпуты, паттерны), они пойдут отдельной
итерацией. Итог: единая точка правды `Color.ds.*`, `Font.ds.*`, `DS.Spacing.*`,
`DS.Radius.*`, `DS.Shadow.*`, `DS.Animation.*`, доступная из любого View в Presentation,
с фирменными шрифтами Nunito/Inter, забандленными в приложение.

Референс использования (не в объёме этой итерации, только для понимания контекста
дальнейшего применения токенов): `Add Playlist Screen.dc.html`.

## Affected Layers

- [ ] Domain — не затрагивается (Domain остаётся framework-free, уже подтверждено: ни один файл в `Domain/` не импортирует SwiftUI и не использует `Spacing`/`Typography`)
- [ ] Data — не затрагивается
- [x] Presentation — потребитель токенов; один экран (`AddPlaylistView` как самый близкий к мокапу-эталону) частично мигрируется как proof-of-concept
- [x] Core — основное место работы: новая директория `Core/DesignSystem/`
- [x] Tests — smoke-тесты на существование и не-крашащесть токенов

## Текущее состояние (уже проверено)

- `Core/Constants/Spacing.swift`: `enum Spacing { xs=8, sm=16, md=24, lg=40, xl=60 }` + `enum TVSize` + `enum Opacity`
- `Core/Constants/Typography.swift`: `enum Typography` — только `CGFloat`, не `Font`
- `App/Media.xcassets` — 0 colorset'ов, цвета нигде не заведены как ассеты
- В `Presentation/` — 15 мест с `Color(...)`/`.foregroundStyle(...)`/`.tint`, из них **все** используют семантические системные модификаторы (`.secondary`, `.tint`, `.white`, `.red`, `.green`, `.tertiary`) — ни одного hex-литерала. Миграционный долг небольшой, но есть debt в виде системных семантических цветов вместо DS-палитры.
- 16 `.font(...)` вызовов в Presentation — не проверялись поштучно, будут собраны в Шаге 9.
- Нет `Core/DesignSystem/`, нет `Resources/Fonts/`, нет зарегистрированных custom fonts в `Info.plist`.
- `.claude/rules/tvos-ui.md` содержит **встроенный пример кода** с текущими значениями `Spacing` (xs=8…xl=60) как канонiчными "Design Constants — use these, no magic numbers". Эта итерация вводит параллельный набор токенов с другими значениями (4/8/16/20/24/32/40/48) — см. риск ниже, решение — не конфликтовать, а расширять.

## Ключевое архитектурное решение (пересмотрено 2026-08-04): полное удаление старых Spacing/Typography

**Решение изменено пользователем**: `Core/Constants/Spacing.swift` и
`Core/Constants/Typography.swift` **удаляются полностью** в рамках этой итерации,
а не остаются как параллельный неймспейс.

Обоснование пересмотра: `Typography.swift` оказался мёртвым кодом — ни одного
использования `Typography.*` в кодовой базе (проверено `grep`). `Spacing.swift`
активно используется (36 call sites в 8 файлах), но всё покрывается новыми DS-токенами
без потери точности (см. таблицу маппинга ниже) — параллельный неймспейс создал бы
только путаницу ("зачем два набора отступов") без реальной пользы.

`Spacing.swift` фактически содержит **три** enum'а, не только `Spacing`:
- `enum Spacing` (xs/sm/md/lg/xl) — мигрирует в `DSSpacing`
- `enum TVSize` (channelCardWidth/channelCardHeight/thumbnailCornerRadius/sheetMaxWidth/gateBlurRadius) — **не является дизайн-токеном** мокапа (это layout-константы конкретных компонентов), но по решению пользователя тоже переносится под DS: card/sheet/blur-размеры → новый `DSSize`, `thumbnailCornerRadius` переиспользует уже существующий `DSRadius.s` (обе равны 12 — совпадение точное, отдельный токен не создаём)
- `enum Opacity` (gateScrim=0.55) — переиспользует уже существующий `Color.ds.background.overlay` (тоже `Color.black.opacity(0.55)` — точное совпадение), отдельного `DSOpacity` не создаём

### Таблица маппинга (полная миграция всех 36 call sites)

| Старое | Значение | Новое | Точное совпадение? |
|--------|----------|-------|---------------------|
| `Spacing.xs` | 8 | `DSSpacing.xs` | ✅ |
| `Spacing.sm` | 16 | `DSSpacing.s` | ✅ |
| `Spacing.md` | 24 | `DSSpacing.l` | ✅ |
| `Spacing.lg` | 40 | `DSSpacing.xxl` | ✅ |
| `Spacing.xl` | 60 | `DSSpacing.xxxl` (48) | ⚠️ единственное несовпадение — 1 call site (`AddPlaylistView.swift:67`), экран и так мигрируется на мокап-эталонные отступы в этой итерации, регрессия не вне контекста |
| `TVSize.thumbnailCornerRadius` | 12 | `DSRadius.s` | ✅ (переиспользуем существующий токен) |
| `TVSize.channelCardWidth` | 300 | `DSSize.channelCardWidth` (новый) | ✅ |
| `TVSize.channelCardHeight` | 170 | `DSSize.channelCardHeight` (новый) | ✅ |
| `TVSize.sheetMaxWidth` | 700 | `DSSize.sheetMaxWidth` (новый) | ✅ |
| `TVSize.gateBlurRadius` | 20 | `DSSize.gateBlurRadius` (новый) | ✅ |
| `Opacity.gateScrim` | 0.55 | `Color.ds.background.overlay` | ✅ (переиспользуем существующий токен, отдельного `DSOpacity` нет) |

Файлы с call sites для миграции (8 файлов, полный список подтверждён `grep`):
`PlaylistsView.swift`, `AddPlaylistView.swift`, `PlaybackStatsOverlayView.swift`,
`PlayerView.swift`, `ChannelListView.swift`, `CategorySidebarView.swift`,
`ChannelCardView.swift`, `ChannelSearchView.swift` (все — `Spacing`/`TVSize`),
плюс `RootView.swift`, `PlaylistGateOverlayView.swift` (`TVSize`/`Opacity`).

## Файловая структура — почему отдельные файлы, а не один DesignSystem.swift

Один файл на 6 токен-категорий быстро перевалит за ~200 строк с учётом кастомных
`Font`-инициализаторов и цветовых расчётов (hex→Color helper, glow-структуры).
Разбиваем по файлам, один namespace-enum на файл — легко находить, легко ревьюить,
легко расширять компонентами в следующей итерации без раздутия одного файла.

```
StanisLoveTV/Core/DesignSystem/
├── DesignSystem.swift          // корневой enum DS {}, только namespace-контейнер + доки
├── Color+DesignSystem.swift    // Color.ds.* namespace, Color(hex:) helper
├── Font+DesignSystem.swift     // Font.ds.* namespace, регистрация кастомных шрифтов
├── DS+Spacing.swift            // DS.Spacing enum
├── DS+Radius.swift             // DS.Radius enum
├── DS+Size.swift                // DSSize enum — card/sheet/blur layout constants migrated from old TVSize
├── DS+Shadow.swift             // DS.Shadow enum + ShadowStyle struct (color+radius+glow-ready)
├── DS+Animation.swift          // DS.Animation enum
└── DS+Gradient.swift           // LinearGradient.ds.love / .dark / .glow — фирменные градиенты из мокапа (не входят в 6 базовых категорий явно, но без них цветовые токены неполны — см. ниже)

StanisLoveTV/Resources/Fonts/
├── Nunito-Regular.ttf
├── Nunito-SemiBold.ttf   (600 — не используется напрямую в 6 уровнях, но качаем полный набор весов из мокапа: 400;600;700;800)
├── Nunito-Bold.ttf
├── Nunito-ExtraBold.ttf
├── Inter-Regular.ttf
├── Inter-Medium.ttf
├── Inter-SemiBold.ttf
├── Inter-Bold.ttf
└── LICENSE-OFL.txt        // SIL Open Font License текст, обязателен при бандлинге Google Fonts
```

**Примечание про градиенты**: мокап явно перечисляет "Love Gradient", "Dark Gradient",
"Glow Gradient" в блоке ЦВЕТА/ГРАДИЕНТЫ, но в блоке DEV TOKENS они не упомянуты как
`Color.ds.*` — только сплошные цвета и accent'ы. Решение: включаем градиенты как токены
`LinearGradient.ds.*`, потому что без них "Love Gradient" (сплошной айдентика-элемент,
используется даже в заголовке самого мокапа) недостижим для будущих компонентов, и
логичнее завести его сейчас как токен, чем позже как ad-hoc константу в первом же
экране, который его использует.

## Files to Create

| Path | Назначение |
|------|-----------|
| `StanisLoveTV/Core/DesignSystem/DesignSystem.swift` | Корневой `enum DS {}` — пустой namespace-контейнер с doc-комментарием, объясняющим структуру системы |
| `StanisLoveTV/Core/DesignSystem/Color+DesignSystem.swift` | `Color(hex:)` init (fileprivate/internal helper) + `DSColorPalette` struct + `Color.ds` static-свойство с чистым неймспейсом (см. ниже) |
| `StanisLoveTV/Core/DesignSystem/Font+DesignSystem.swift` | `DSFontPalette` struct + `Font.ds` static-свойство; регистрация кастомных шрифтов `Font.registerDesignSystemFonts()` |
| `StanisLoveTV/Core/DesignSystem/DS+Spacing.swift` | `enum DSSpacing` (8 значений, именованные без коллизий с `Spacing`) |
| `StanisLoveTV/Core/DesignSystem/DS+Radius.swift` | `enum DSRadius` (4 значения) |
| `StanisLoveTV/Core/DesignSystem/DS+Size.swift` | `enum DSSize` — `channelCardWidth`(300)/`channelCardHeight`(170)/`sheetMaxWidth`(700)/`gateBlurRadius`(20), 1:1 значения из старого `TVSize` (не из мокапа — компонентные layout-константы, переносятся без изменений) |
| `StanisLoveTV/Core/DesignSystem/DS+Shadow.swift` | `struct DSShadowStyle` (color, radius, x, y, glowColor?) + `enum DSShadow` со статикой `.card/.hero/.floating` |
| `StanisLoveTV/Core/DesignSystem/DS+Animation.swift` | `enum DSAnimation` со статикой `.fast/.normal/.slow` возвращающей `SwiftUI.Animation` |
| `StanisLoveTV/Core/DesignSystem/DS+Gradient.swift` | `enum DSGradient` со статикой `.love/.dark/.glow` возвращающей `LinearGradient` |
| `StanisLoveTV/Resources/Fonts/*.ttf` (8 файлов) | Скачанные из Google Fonts шрифты Nunito (400/600/700/800) и Inter (400/500/600/700) |
| `StanisLoveTV/Resources/Fonts/LICENSE-OFL.txt` | Текст SIL Open Font License — обязателен при распространении Google Fonts в бандле |
| `StanisLoveTVTests/CoreTests/DesignSystemTokensTests.swift` | Smoke-тесты существования и корректности всех токенов |

## Files to Modify

| Path | Изменение | Причина |
|------|-----------|---------|
| `StanisLoveTV/App/Info.plist` | Добавить ключ `UIAppFonts` (или `Fonts provided by application` в Xcode Target → Info) со списком 8 `.ttf` файлов | tvOS не подхватывает кастомные шрифты без явной регистрации |
| `StanisLoveTV/App/StanisLoveTVApp.swift` | Вызвать `Font.registerDesignSystemFonts()` (если регистрация программная, см. риск ниже — на tvOS обычно достаточно `UIAppFonts`, программная регистрация через `CTFontManagerRegisterFontsForURL` нужна только как fallback) | Гарантировать доступность шрифтов до первого рендера |
| `StanisLoveTV/Presentation/Playlists/AddPlaylistView.swift` | Заменить 2 хардкод-модификатора (`.secondary`, `.red`) на `Color.ds.text.secondary` / `Color.ds.accent.error`; заголовок — на `.font(.ds.largeTitle)`; **плюс** мигрировать все `Spacing.*`/`TVSize.*` на `DSSpacing.*`/`DSSize.*`/`DSRadius.s` (см. таблицу маппинга) | Эталонная миграция экрана — доказать токены в реальном UI + убрать зависимость от удаляемого файла |
| `StanisLoveTV/Presentation/Playlists/PlaylistsView.swift` | `Spacing.*` → `DSSpacing.*` (7 call sites) | Удаляем `Spacing.swift` — все потребители переводим на DS |
| `StanisLoveTV/Presentation/Player/PlaybackStatsOverlayView.swift` | `Spacing.*` → `DSSpacing.*` (4), `TVSize.thumbnailCornerRadius` → `DSRadius.s` (1) | — |
| `StanisLoveTV/Presentation/Player/PlayerView.swift` | `Spacing.md` → `DSSpacing.l` (1) | — |
| `StanisLoveTV/Presentation/Channels/ChannelListView.swift` | `Spacing.*` → `DSSpacing.*` (3), `TVSize.channelCardWidth` → `DSSize.channelCardWidth` (1) | — |
| `StanisLoveTV/Presentation/Channels/CategorySidebarView.swift` | `Spacing.*` → `DSSpacing.*` (6), `TVSize.channelCardWidth` → `DSSize.channelCardWidth` (1) | — |
| `StanisLoveTV/Presentation/Channels/ChannelCardView.swift` | `Spacing.*` → `DSSpacing.*` (3), `TVSize.*` → `DSSize.*`/`DSRadius.s` (4) | — |
| `StanisLoveTV/Presentation/Channels/ChannelSearchView.swift` | `Spacing.*` → `DSSpacing.*` (3), `TVSize.channelCardWidth` → `DSSize.channelCardWidth` (1) | — |
| `StanisLoveTV/App/RootView.swift` | `TVSize.gateBlurRadius` → `DSSize.gateBlurRadius` (1) | — |
| `StanisLoveTV/Presentation/Playlists/PlaylistGateOverlayView.swift` | `TVSize.thumbnailCornerRadius` → `DSRadius.s` (1), `Color.black.opacity(Opacity.gateScrim)` → `Color.ds.background.overlay` (1) | — |
| `StanisLoveTV/Core/Constants/Spacing.swift` | **Удалить файл целиком** (Spacing/TVSize/Opacity enums) | Все потребители мигрированы на DS-эквиваленты, дублирующий неймспейс не нужен |
| `StanisLoveTV/Core/Constants/Typography.swift` | **Удалить файл целиком** | Мёртвый код — 0 использований `Typography.*` в кодовой базе (проверено `grep`) |
| `.claude/rules/tvos-ui.md` | **Требует отдельного явного согласия пользователя** — заменить встроенный пример кода со старым `Spacing`/`TVSize` (который теперь не существует) на актуальный `Core/DesignSystem/*` пример | Rule-файл содержит пример кода, ссылающийся на удаляемые типы — станет некорректным после удаления, но правка делается по отдельному согласованию, не автоматически |

## Цветовой неймспейс — устраняем коллизии из мокапа

Мокап даёт неоднозначные токены (`Color.ds.primary`/`Color.ds.secondary` — непонятно,
это текст или фон). Предлагаемая чистая структура (два явных под-неймспейса:
`background` и `text`, плюс `accent` без изменений, плюс `border`/`overlay` для
элементов, которые в мокапе встречаются как одноразовые rgba-значения):

```swift
extension Color {
    enum ds {
        enum background {
            static let primary = Color(hex: "#0C0C12")     // ex "Background"
            static let surface = Color(hex: "#171723")
            static let elevated = Color(hex: "#212132")
            static let overlay = Color.black.opacity(0.55) // rgba(0,0,0,.55)
        }
        enum text {
            static let primary = Color(hex: "#FFFFFF")
            static let secondary = Color(hex: "#C7C8D1")
            static let inactive = Color(hex: "#8B8C99")
            static let disabled = Color(hex: "#5A5A66")
        }
        enum accent {
            static let success = Color(hex: "#3ED07F")
            static let warning = Color(hex: "#FFB020")
            static let error = Color(hex: "#FF5757")
            static let info = Color(hex: "#5FB7FF")
        }
        enum badge {
            // Специфичные цвета из мокапа блока БЕЙДЖИ (18+), не входят в основную
            // палитру, но без явного дома превратятся в магические литералы
            static let adultBackground = Color(hex: "#3B2130")
            static let adultText = Color(hex: "#FF8FB8")
        }
        enum border {
            static let hairline = Color.white.opacity(0.08)   // повторяющийся rgba(255,255,255,.08) бордер карточек
        }
    }
}
```

`Color.ds.background.*` vs `Color.ds.text.*` — однозначно снимает коллизию, о которой
предупреждал дизайнер (background secondary vs text secondary). Мокап-токены
`Color.ds.primary`/`Color.ds.secondary` (без под-неймспейса) в этой структуре не
воспроизводятся буквально — это осознанное отклонение от мокапа ради однозначности,
явно фиксируем это в Definition of Done как решённый Open Question.

`Color(hex:)` — internal extension на `Color`, принимает `"#RRGGBB"`, вызывает
`fatalError` только в DEBUG при некорректном hex (палитра статическая и известна на
этапе компиляции — риск рантайм-краша от опечатки в hex-строке отлавливается тестом
из раздела Tests, не в `fatalError` в релизе).

## Типографика — Font, не CGFloat

```swift
extension Font {
    enum ds {
        // Nunito — заголовки
        static let hero = Font.custom("Nunito-ExtraBold", size: 48, relativeTo: .largeTitle)
        static let largeTitle = Font.custom("Nunito-Bold", size: 36, relativeTo: .title)
        static let title = Font.custom("Nunito-Bold", size: 28, relativeTo: .title2)
        // Inter — весь остальной текст (решение пользователя: SF Pro в мокапе фактически Inter)
        static let headline = Font.custom("Inter-SemiBold", size: 22, relativeTo: .headline)
        static let body = Font.custom("Inter-Regular", size: 18, relativeTo: .body)
        static let caption = Font.custom("Inter-Regular", size: 15, relativeTo: .caption)
    }
}
```

- `relativeTo:` включает Dynamic Type scaling поверх фиксированного base size — на tvOS
  Dynamic Type имеет более узкий диапазон, чем iOS, но `Font.custom(_:size:relativeTo:)`
  всё равно корректно работает и не требует доп. кода.
  Пользователь дал точные px из мокапа (48/44/28/22/18/15) — используем design-spec
  значения (48/36/28/22/18/15), а НЕ дублирующиеся в разметке fallback-размеры
  (44/34/27/21/17/14), т.к. fallback-размеры в HTML — это то, как реально отрендерился
  текст в браузере из-за web font fallback до полной загрузки Google Fonts, а не
  дизайн-намерение. Это явное решение — фиксируем в Open Questions на подтверждение.
- Line-height (56/44/36/28/26/20) в SwiftUI `Font` не задаётся напрямую — переносится в
  `.lineSpacing()` модификатор, который применяется к тексту, а не к шрифту. Токены
  Typography НЕ включают line-height как часть `Font.ds.*` (SwiftUI это не поддерживает
  на уровне Font), но line-height значения фиксируются в doc-комментариях
  `DesignSystem.swift` как справочная таблица для будущих компонентов текста, которые
  сами добавят `.lineSpacing()`.

## Spacing — маппинг 8 значений без коллизий с текущим `Spacing`

Мокап даёт `4 · 8 · 16 · 20 · 24 · 32 · 40 · 48`. Текущий `Spacing` (xs/sm/md/lg/xl =
8/16/24/40/60) использует 5 значений с ДРУГИМИ величинами на тех же именах (`md`=24
совпадает, но `lg`=40 совпадает тоже, а `xl`=60 отсутствует в новой шкале — конфликт
имён при одинаковых величинах в двух случаях и полный разнобой в остальных). Чтобы не
получить `Spacing.lg` (40, старый) vs `DSSpacing.???` (40, новый) с разным смыслом,
даём новой шкале **полностью отдельные имена** размерного ряда (`2xs...2xl`):

| px | Имя токена | Обоснование |
|----|-----------|-------------|
| 4  | `DSSpacing.xxs` | минимальный зазор (иконка+текст в бейдже) |
| 8  | `DSSpacing.xs`  | плотные группы (чипы, иконки) |
| 16 | `DSSpacing.s`   | внутренние отступы карточек, gap между related-элементами |
| 20 | `DSSpacing.m`   | паддинг полей ввода (мокап: `padding:20px 24px`) |
| 24 | `DSSpacing.l`   | паддинг карточек/секций (мокап: `padding:32px` округляем — см. ниже), gap в гридах |
| 32 | `DSSpacing.xl`  | паддинг крупных карточек/панелей |
| 40 | `DSSpacing.xxl` | паддинг hero/крупных форм |
| 48 | `DSSpacing.xxxl`| паддинг экрана верхнего уровня (мокап: `padding:48px 56px 96px` на корневом контейнере) |

Названия используют `xxs/xs/s/m/l/xl/xxl/xxxl` — однобуквенные средние (`s/m/l`)
осознанно отличаются от текущего `Spacing.sm/md/lg` (двухбуквенные), чтобы при
код-ревью `DSSpacing.l` и `Spacing.lg` визуально не путались и не создавали иллюзию
эквивалентности (`DSSpacing.l`=24 ≠ `Spacing.lg`=40 — это реально разные величины,
разные имена обязательны).

## Radius / Size / Shadow / Animation — прямой маппинг

```swift
enum DSRadius {
    static let s: CGFloat = 12
    static let m: CGFloat = 18
    static let l: CGFloat = 24
    static let xl: CGFloat = 40
}

// Не из мокапа — 1:1 перенос старых TVSize-констант при удалении Spacing.swift.
// Компонентные layout-размеры (карточка канала, sheet, blur), не часть дизайн-палитры.
enum DSSize {
    static let channelCardWidth: CGFloat = 300
    static let channelCardHeight: CGFloat = 170
    static let sheetMaxWidth: CGFloat = 700
    static let gateBlurRadius: CGFloat = 20
    // thumbnailCornerRadius нарочно не дублируется — используем DSRadius.s (тоже 12)
}

struct DSShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    let glowColor: Color?   // nil для обычных теней; заполняется для focus-glow в будущих компонентах
}

enum DSShadow {
    static let card = DSShadowStyle(color: .black.opacity(0.4), radius: 24, x: 0, y: 8, glowColor: nil)
    static let hero = DSShadowStyle(color: .black.opacity(0.5), radius: 30, x: 0, y: 20, glowColor: nil)
    static let floating = DSShadowStyle(color: .black.opacity(0.6), radius: 60, x: 0, y: 30, glowColor: nil)
    // Заготовка на будущее (не создаём применение сейчас — только структура готова):
    static let focusGlow = DSShadowStyle(color: Color(hex: "#B85CFF").opacity(0.6), radius: 32, x: 0, y: 0, glowColor: Color(hex: "#FF3D9A"))
}

enum DSAnimation {
    static let fast = Animation.easeOut(duration: 0.25)
    static let normal = Animation.easeOut(duration: 0.35)
    static let slow = Animation.easeInOut(duration: 0.6)
}
```

`DSShadowStyle` намеренно допускает `glowColor: Color?` уже сейчас (пункт 6 задачи:
"заложить структуру Shadow-токена, которая допускает color+radius+glow") — конкретное
`View`-расширение `.dsShadow(_:)`, которое реально применяет `shadow()`/`overlay()` с
glow, **не создаём в этой итерации** (это уже граничит с компонентом/модификатором,
не токеном) — только структура данных.

## Implementation Steps

1. **Создать `Core/DesignSystem/DesignSystem.swift`** — пустой `enum DS {}` с doc-комментарием, описывающим категории. Компилируется сразу, ничего не меняет.
2. ✅ **Скачать шрифты**: `google/fonts` больше не хранит статичные веса для Nunito/Inter — только variable fonts (`Nunito[wght].ttf`, `Inter[opsz,wght].ttf`). Вместо этого: скачаны variable-исходники из `google/fonts` (ветка `main`), 8 статичных инстансов сгенерированы локально через `fonttools varLib.instancer` (wght=400/600/700/800 для Nunito, wght=400/500/600/700 + opsz=14 для Inter), PostScript-имя каждого файла явно выставлено в name table (`name.setName(..., nameID=6, ...)`) так, чтобы 1:1 совпадать с именем файла — устраняет Риск 2 (расхождение PostScript-имени и имени файла) сразу на этом шаге, а не по факту обнаружения в Simulator. `.ttf` лежат в `Resources/Fonts/`, `LICENSE-OFL.txt` собран из двух `OFL.txt` (Nunito + Inter — идентичный текст лицензии, разные copyright-строки, обе включены).
3. **Добавить `Resources/Fonts/` в Xcode target** (Copy Bundle Resources) + зарегистрировать 8 файлов в `Info.plist` под `UIAppFonts`. Собрать проект — убедиться, что шрифты попадают в бандл (`Bundle.main.paths(forResourcesOfType: "ttf", inDirectory: nil)`).
4. **Создать `Core/DesignSystem/Font+DesignSystem.swift`** с `Font.ds.*` статикой (см. выше). Добавить debug-only sanity-check (см. Риски) который логирует, если `UIFont(name:size:)` возвращает `nil` для любого из 8 postscript-имён — не крашит, только warning в консоль в DEBUG.
5. **Создать `Core/DesignSystem/Color+DesignSystem.swift`** — `Color(hex:)` helper + полная палитра `Color.ds.background/text/accent/badge/border` из таблицы выше.
6. **Создать `Core/DesignSystem/DS+Spacing.swift`** — `enum DSSpacing` с 8 значениями и именами из таблицы маппинга.
7. **Создать `Core/DesignSystem/DS+Radius.swift`** — `enum DSRadius` (4 значения).
8. **Создать `Core/DesignSystem/DS+Size.swift`** — `enum DSSize` (channelCardWidth/channelCardHeight/sheetMaxWidth/gateBlurRadius), 1:1 значения из старого `TVSize`.
9. **Создать `Core/DesignSystem/DS+Shadow.swift`** — `DSShadowStyle` + `enum DSShadow` (3 значения + `focusGlow` заготовка).
10. **Создать `Core/DesignSystem/DS+Animation.swift`** — `enum DSAnimation` (3 значения).
11. **Создать `Core/DesignSystem/DS+Gradient.swift`** — `enum DSGradient` (`.love`, `.dark`, `.glow`) как `LinearGradient`.
12. **Собрать проект** — на этом шаге вся инфраструктура токенов существует рядом со старым `Spacing.swift`/`Typography.swift` (ещё не удалены) и компилируется. Контрольная точка.
13. **Мигрировать все 36 call sites** `Spacing.*`/`TVSize.*`/`Opacity.gateScrim` → `DSSpacing.*`/`DSSize.*`/`DSRadius.s`/`Color.ds.background.overlay` по таблице маппинга, файл за файлом: `PlaylistsView`, `PlaybackStatsOverlayView`, `PlayerView`, `ChannelListView`, `CategorySidebarView`, `ChannelCardView`, `ChannelSearchView`, `RootView`, `PlaylistGateOverlayView`. Собирать после каждого файла.
14. **Эталонная миграция `AddPlaylistView.swift`**: заменить 2 хардкода (`.secondary`→`Color.ds.text.secondary`, `.red`→`Color.ds.accent.error`) и заголовок экрана на `.font(.ds.largeTitle)`, плюс мигрировать `Spacing.*`/`TVSize.*` этого файла (включая единственный `Spacing.xl`→`DSSpacing.xxxl` со сдвигом 60→48). Проверить визуально в Simulator, что кастомный шрифт реально применился (не молча упал на системный) и что padding-сдвиг в 12pt не ломает layout.
15. **Удалить `Core/Constants/Spacing.swift` и `Core/Constants/Typography.swift`**. Собрать проект — ноль ссылок на `Spacing`/`TVSize`/`Opacity`/`Typography` должно приводить к чистой компиляции без ошибок (если компилятор нашёл использование — значит миграция на шаге 13/14 неполная).
16. **Написать `DesignSystemTokensTests.swift`** (см. раздел Tests, дополнить тестами на `DSSize`) — прогнать, зафиксировать зелёный прогон.
17. (Опционально, обсудить с пользователем перед выполнением) **Обновить `.claude/rules/tvos-ui.md`** — заменить встроенный пример кода со старым (уже не существующим) `Spacing`/`TVSize` на актуальный `Core/DesignSystem/*` пример. Это правка project convention файла — делать только по прямому запросу пользователя в отдельном шаге, не автоматически в рамках этого фичевого PR.

Каждый шаг 1–16 — самостоятельный компилируемый коммит.

## SQLiteData Schema Changes

Нет. Эта итерация не касается персистентности.

## Dependency Registration

Нет новых `DependencyKey`. Токены — статические value-константы, не сервисы,
не нуждаются в DI (нет сетевого/дискового состояния, нет моков для тестов —
это чистые данные).

## Tests to Write

`StanisLoveTVTests/CoreTests/DesignSystemTokensTests.swift` (Swift Testing, `@MainActor` где нужен `UIFont`/`Color`-рендеринг):

```
@Test func allColorTokensAreDistinctAndNonNil()
    // Убедиться, что background/text/accent/badge палитры не совпадают друг с другом
    // там, где не должны (напр. text.primary != background.primary)

@Test func hexColorInitializer_parsesKnownValues()
    // Color(hex: "#FF3D9A") не крашит и не возвращает .clear по ошибке парсинга

@Test func hexColorInitializer_malformedHex_doesNotCrash()
    // Явно проверяем поведение на невалидном hex (fallback-цвет, не fatalError в релизной сборке)

@Test func customFontsAreRegisteredInBundle()
    // Для каждого из 8 postscript-имён: UIFont(name:, size: 12) != nil
    // Это единственный тест, который реально ловит "забыли зарегистрировать в Info.plist"

@Test func fontDSTokens_fallBackGracefully_whenFontMissing()
    // Симулируем отсутствие шрифта (мокаем имя, которого нет) — Font.custom не крашит,
    // SwiftUI сам фолбэчится на системный шрифт — тест документирует это поведение

@Test func spacingTokens_areMonotonicallyIncreasing()
    // xxs < xs < s < m < l < xl < xxl < xxxl — защита от опечатки при рефакторинге

@Test func radiusTokens_matchDesignMockValues()
    // s=12, m=18, l=24, xl=40

@Test func shadowTokens_haveExpectedRadiusAndOpacity()
    // card/hero/floating соответствуют px/alpha из мокапа

@Test func animationTokens_haveExpectedDurations()
    // fast=0.25, normal=0.35, slow=0.6 (сравнение через Mirror/duration, где Animation API это позволяет)

@Test func gradientTokens_containExpectedStopColors()
    // love содержит #FF3D9A/#B85CFF/#3B82FF в правильном порядке
```

Coverage — не про % (это не use case/ViewModel), а про то, чтобы каждый публичный
токен был явно упомянут хотя бы в одном тесте — предотвращает "тихую" порчу значения
при будущем рефакторинге файла.

## tvOS Considerations

- **Focus-glow токен (`DSShadow.focusGlow`) — только структура данных в этой итерации.**
  Реальное применение (`.focused($isFocused)` + `.scaleEffect(1.05–1.1)` +
  `.shadow(color: DSShadow.focusGlow.glowColor, radius: DSShadow.focusGlow.radius)`)
  откладывается в следующую итерацию (компоненты), когда будет создан переиспользуемый
  `.dsFocusable()` view-modifier. Явно фиксируем это здесь, чтобы не потерять контекст
  между итерациями — пользователь сам обозначил, что это должно попасть в
  Animation/Shadow токены "или как отдельная заметка на будущее" — выбрана заметка +
  структура данных, без поведения.
- **Dynamic Type на tvOS** уже входит в `Font.custom(_:size:relativeTo:)` — не требует
  доп. кода, но диапазон масштабирования на tvOS уже, чем на iOS; не тестируем отдельно
  в этой итерации (нет UI, который использует токены достаточно, чтобы это увидеть).
- **10-foot UI минимумы** (`tvos-ui.md`: Body 17pt минимум, Titles 28pt минимум) —
  новые токены `body`=18pt и `title`=28pt **проходят** этот минимум. `caption`=15pt —
  **не проходит** заявленный в rules минимум 17pt для основного текста, но `caption`
  по определению вспомогательный текст, не основной — явно не блокирует, но стоит
  явно обсудить с пользователем (см. Open Questions), т.к. `tvos-ui.md` формулирует
  правило как "Body text: 17pt minimum" без явного исключения для caption/вспомогательного текста.
- Токены сами по себе не создают фокусируемых элементов — `.onExitCommand`/`focusSection()`
  не применимы к этой итерации (нет экранов с навигацией).

## Риски

1. **Nunito — не системный шрифт.** Если `.ttf` не попадёт в бандл (забыли добавить в
   Copy Bundle Resources) или `Info.plist`/`UIAppFonts` не обновится, `Font.custom(...)`
   молча фолбэчится на системный шрифт без ошибки компиляции и без крэша — баг будет
   визуальным, не обнаружится тестами на CI без явного `UIFont(name:)` теста (см. Tests,
   `customFontsAreRegisteredInBundle`). Это главный риск итерации — единственная
   защита — тест + ручная визуальная проверка в Simulator на Шаге 12.
2. ✅ **Устранено на Шаге 2.** Постскрипт-имена были явно выставлены через `fontTools`
   name table при генерации статичных инстансов из variable-исходников — подтверждены
   `fontTools.ttLib` (`getDebugName(6)`) равными именам файлов 1:1 для всех 8 шрифтов
   до попадания в проект. Остаточный риск: если шрифты когда-либо будут заменены
   вручную (не через этот пайплайн), нужно повторно проверить PostScript-имя.
3. **Единственный визуальный сдвиг: `Spacing.xl` (60) → `DSSpacing.xxxl` (48) в `AddPlaylistView`.**
   -12pt на padding одного sheet-экрана — риск минимальный (1 call site), но требует
   визуальной проверки в Simulator на Шаге 14, не только компиляции.
4. **Полная миграция 36 call sites — риск пропустить одно использование при ручном
   рефакторинге.** Смягчение: удаление `Spacing.swift`/`Typography.swift` на Шаге 15
   происходит ПОСЛЕ миграции (Шаги 13-14) — если что-то пропущено, компилятор
   немедленно укажет на нерезолвленный символ, это не тихий риск.
5. **`.claude/rules/tvos-ui.md` содержит устаревающий пример** — после удаления
   `Spacing`/`TVSize` встроенный в rule-файл пример кода ссылается на несуществующие
   типы. Смягчение — Шаг 17 (по согласованию с пользователем), делать сразу после
   имплементации, не откладывать надолго, т.к. пример уже некорректен, не просто устарел.
6. **Glow-эффекты (box-shadow с blur) не имеют 1:1 аналога в SwiftUI `.shadow()`.**
   SwiftUI `.shadow()` не поддерживает `spread`/множественные тени в одном модификаторе
   как CSS `box-shadow: 0 0 0 3px X, 0 0 24px Y` (кольцо + свечение — это два разных
   визуальных слоя). `DSShadowStyle` в этой итерации умышленно упрощён до одного
   color+radius+offset — многослойный glow потребует `.overlay()` с отдельной
   `RoundedRectangle().stroke()` для кольца, что уже относится к будущему компоненту
   `.dsFocusable()`, не к токену.

## Open Questions — Resolved (2026-08-01)

1. **Line-height** — фиксируется только как doc-комментарий-справка в `DesignSystem.swift`, без `.lineSpacing()` в токене. Подтверждено (без возражений).
2. **Размеры типографики** — используем design-spec (48/36/28/22/18/15), не web-fallback (44/34/27/21/17/14). Подтверждено пользователем.
3. **`caption` = 15pt** — принят как осознанное исключение из правила `tvos-ui.md` "Body text: 17pt minimum" (caption — вспомогательный текст, не основной body). Подтверждено пользователем.
4. **Судьба текущих `Spacing`/`Typography`** — ПЕРЕСМОТРЕНО 2026-08-04: оба файла удаляются полностью в этой же итерации (не отложено). `Typography.swift` — мёртвый код (0 использований). `Spacing.swift` (включая `TVSize`/`Opacity`) — все 36 call sites мигрируют на `DSSpacing`/`DSSize`/`DSRadius.s`/`Color.ds.background.overlay`, см. таблицу маппинга и Шаги 13-15.
5. **Правка `.claude/rules/tvos-ui.md`** — отложена. Шаг 17 не выполняется автоматически в этой итерации (нужно отдельное согласие), но т.к. пример в rule-файле после удаления `Spacing`/`TVSize` станет некорректным (не просто устаревшим), рекомендуется выполнить сразу после этой итерации, не откладывать надолго.
6. **`Color.ds.badge.*`** — заводится уже в этой итерации (решение пользователя: цвета переиспользуемы вне контекста конкретного компонента-бейджа).
7. **Источник `.ttf`** — скачивание с `github.com/google/fonts` подтверждено как приемлемое для имплементационного агента.

## Definition of Done

- [ ] `Core/DesignSystem/` создана с 9 файлами из раздела "Files to Create" (включая `DS+Size.swift`); проект собирается без предупреждений
- [ ] 8 `.ttf`-файлов (Nunito ×4, Inter ×4) лежат в `Resources/Fonts/`, включены в Copy Bundle Resources, зарегистрированы в `Info.plist` под `UIAppFonts`; `LICENSE-OFL.txt` присутствует
- [ ] `customFontsAreRegisteredInBundle` тест зелёный — все 8 PostScript-имён резолвятся через `UIFont(name:)`
- [ ] `Color.ds.background/text/accent/badge/border` содержат все цвета из мокапа без коллизий имён
- [ ] `Font.ds.hero/largeTitle/title/headline/body/caption` возвращают `Font.custom` с подтверждёнными (Open Question #2) размерами
- [ ] `DSSpacing`, `DSRadius`, `DSSize`, `DSShadow`, `DSAnimation`, `DSGradient` заведены и покрыты тестами один-к-одному со значениями из мокапа/старого `TVSize`
- [ ] `DesignSystemTokensTests.swift` — все тесты из раздела Tests написаны и зелёные
- [ ] `AddPlaylistView.swift` мигрирован как эталон (минимум 1 цвет + 1 шрифтовый токен применены и визуально проверены в Simulator)
- [ ] Все 36 call sites `Spacing.*`/`TVSize.*`/`Opacity.gateScrim` в 10 файлах мигрированы на `DSSpacing`/`DSSize`/`DSRadius.s`/`Color.ds.background.overlay` — 0 совпадений на старые типы
- [ ] `Core/Constants/Spacing.swift` и `Core/Constants/Typography.swift` удалены; проект собирается без ошибок
- [ ] Ни один файл в `Domain/` или `Data/` не импортирует `Core/DesignSystem/*`
- [ ] Открытые вопросы (1–7) обсуждены с пользователем; ответы зафиксированы (в этом файле или в коммите) до начала имплементации
- [ ] Явно зафиксировано и коммуникировано: следующая итерация — переиспользуемые UI-компоненты (кнопки, карточки, бейджи, инпуты, паттерны из мокапа), не планируется в деталях сейчас
