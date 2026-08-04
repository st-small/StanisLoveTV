# Plan: Design System — Компоненты (Итерация 2)

**Created**: 2026-08-04
**Status**: implemented 2026-08-04 — все 17 Open Questions согласованы и реализованы (см. "Open Questions — Resolved" и "Отклонения после реализации" в конце файла)
**Estimated complexity**: L

## Goal

Итерация 1 (`design-system-tokens.md`, реализована и закоммичена) заложила только
токены (`Color.ds`, `Font.ds`, `DSSpacing`, `DSRadius`, `DSSize`, `DSShadow`,
`DSAnimation`, `DSGradient`) — ни одного переиспользуемого компонента. Эта итерация
строит **компонентный слой** поверх токенов, по приоритету, заданному пользователем:

1. `.dsFocusable()` — универсальный focus-glow модификатор (tvOS Focus Engine) —
   всё остальное от него зависит
2. `DSButton` — стили кнопок (primary/secondary/outline/ghost/icon/loading/disabled)
3. `DSTextField` — кастомные текстовые поля (base/search/dropdown + focused-glow),
   в первую очередь для `AddPlaylistView` — это самый явный визуальный долг
   (скриншот с фиолетовым glow-бордером вокруг "M3U URL плейлиста" — то, что
   пользователь буквально попросил спланировать)
4. `DSCardStyle` + `DSBadge` — стилевая обёртка карточек и бейджи

Все четыре пункта в объёме этой итерации. Паттерны экранного уровня (Hero Banner,
Channel Row, Movie Row, Category Chips) **не входят** — это кандидат итерации 3,
здесь только упоминаются.

Референс: `Design System.dc.html` (секции Buttons/Badges/Inputs/Cards/Focus States —
не входили в Итерацию 1). Мокап есть только у пользователя локально, в git не
закоммичен — все цвета/значения ниже сверены с реальными файлами
`Core/DesignSystem/*`, не с пересказом задачи.

## Affected Layers

- [ ] Domain — не затрагивается
- [ ] Data — не затрагивается
- [x] Presentation — основной потребитель: `AddPlaylistView`, `PlaylistsView`,
      `ChannelCardView`, опционально `ChannelListView` (см. Open Question 15)
- [x] Core — основное место работы: новые файлы в `Core/DesignSystem/`
- [x] Tests — unit-тесты на новые модификаторы/стили (не UI snapshot-тесты —
      инструментарий проекта их не предполагает)

## Текущее состояние (проверено по факту, не по пересказу)

- `DSShadow.focusGlow` уже существует в `DS+Shadow.swift`, помечен как
  "структура, не применяется" — эта итерация впервые его **применяет**, и именно
  на этом шаге всплывают расхождения точных величин с мокапом (см. таблицу ниже).
- `ChannelCardView.swift` — единственный реальный producer focus-эффекта сегодня:
  `.focusable().focused($isFocused).scaleEffect(isFocused ? 1.1 : 1.0).animation(.easeInOut(duration: 0.15), value: isFocused)`.
  Это ad-hoc реализация, не токенизированная (`1.1` и `0.15` — магические литералы,
  не `DSFocusScale`/`DSAnimation`). `.dsFocusable()` должен её заменить.
- `AddPlaylistView.swift` — 3 `TextField` с нулевой кастомной стилизацией (голый
  системный tvOS chrome), кнопки `Button("Cancel")`/`Button("Add Playlist")` —
  вторая через `.buttonStyle(.borderedProminent)`, обе не токенизированы.
- `PlaylistsView.swift` — кнопка "Add" в toolbar (системная), кнопка
  "Add Playlist" в empty state через `.buttonStyle(.borderedProminent)`,
  `PlaylistRowView` — иконки Refresh/Delete через `.labelStyle(.iconOnly)` (не
  44×44 circle из мокапа, обычные toolbar-style icon buttons), `isActive` уже
  рисует `Image(systemName: "checkmark.circle.fill")` inline — это ровно тот
  сценарий, который в мокапе описан как "Selected" focus-state (success-green
  ring + чекмарк-бейдж), но сегодня реализован без ring, просто иконкой.
- `ChannelListView.swift` — search bar: `TextField("Search channels...", text:)`
  с одним `.padding(DSSpacing.s)`, без иконки лупы, без стилизации — прямой
  кандидат под `DSTextField(.search)`, но пользователь явно не называл этот
  файл в приоритете 3 (см. Open Question 15).
- `CategorySidebarView.swift` — вертикальный список категорий (`LazyVStack` +
  `Button.buttonStyle(.plain)`), НЕ горизонтальные pill-чипы из мокапа.
- **Проверено `grep` по всему `Domain/`/`Data/`: у `Channel` НЕТ поля
  `isAdult`/`ageRestricted`/аналога.** Это меняет калибровку задачи: в брифе
  бейдж 18+ описан как "уже имеющий реальный use case" — по факту это неверно
  на уровне домена. `Color.ds.badge.adultBackground/adultText` — токены
  существуют, но ни один экран не может сегодня решить, когда их показывать,
  потому что нет данных для этого решения. Реальный call site для **любого**
  бейджа (включая adult) в приложении сегодня отсутствует — см. Open Question 13.
- Локализации в проекте нет (`grep` по `Localizable`/`NSLocalizedString`/
  `LocalizedStringKey` — 0 совпадений). Весь текущий UI-текст на английском.
  Мокап даёт "Загрузка..." (русский) для Loading-состояния кнопки — расхождение
  с существующей конвенцией all-English UI, см. Open Question 17.
- `.claude/rules/tvos-ui.md`: "Minimum interactive target: 100×100pt" — жёсткое
  правило проекта. Мокап даёт Icon-only кнопку 44×44 circle. Прямой конфликт,
  см. Open Question 6.

## Компонент 1 — `.dsFocusable()` / `.dsSelected()` (Focus States)

### Дизайн API (набросок, не полная реализация)

```swift
enum DSFocusScale {
    static let card: CGFloat = 1.08     // карточки (мокап: transform:scale(1.08))
    static let button: CGFloat = 1.06   // кнопки
    static let chip: CGFloat = 1.05     // "Channel Row" чипы / Mini Card паттерн
}

extension View {
    /// Presentation-only модификатор: НЕ вызывает .focusable()/.focused() сам —
    /// вызывающий View продолжает владеть @FocusState (как сегодня в ChannelCardView),
    /// .dsFocusable() только применяет визуальный эффект по переданному isFocused.
    func dsFocusable(
        _ isFocused: Bool,
        scale: CGFloat = DSFocusScale.card,
        cornerRadius: CGFloat = DSRadius.s
    ) -> some View { ... }

    /// Success-green ring + чекмарк-бейдж top-trailing. Не анимируется по фокусу,
    /// это постоянный индикатор состояния (активный плейлист и т.п.).
    func dsSelected(_ isSelected: Bool, cornerRadius: CGFloat = DSRadius.s) -> some View { ... }
}
```

**Ключевое архитектурное решение**: `.dsFocusable()` НЕ берёт на себя
`.focusable()`/`.focused($binding)` — только `scaleEffect` + `.overlay(RoundedRectangle().stroke(...))`
(3px кольцо) + `.shadow(...)` (мягкое свечение) + `.animation(DSAnimation.fast, value: isFocused)`.
Причина: у разных компонентов разный источник `isFocused` — `ChannelCardView` держит
свой `@FocusState` вручную, `AddPlaylistView` использует `@FocusState private var focusedField: Field?`
(enum, не Bool) и сравнивает `focusedField == .m3uURL`, `DSButton` будет читать
`@Environment(\.isFocused)` внутри `ButtonStyle`. Единый модификатор, принимающий
голый `Bool`, работает одинаково во всех трёх случаях без навязывания владения
focus-состоянием — это расширяет, а не меняет существующий паттерн `ChannelCardView`.

### Кольцо + свечение — маппинг на `DSShadow.focusGlow`

Мокап: `box-shadow: 0 0 0 3px #FF3D9A, 0 0 24px rgba(184,92,255,0.7)` — это ДВА
разных слоя (сплошное 3px кольцо цвета #FF3D9A + отдельное мягкое размытие
цвета #B85CFF), SwiftUI `.shadow()` не умеет оба в одном вызове — нужен
`.overlay(RoundedRectangle().stroke(...))` для кольца отдельно от `.shadow()` для свечения.

Проверено сопоставление полей `DSShadowStyle` (из Итерации 1) с мокапом:

| Поле `DSShadow.focusGlow` | Значение в токене | Роль в мокапе | Значение в мокапе | Совпадает? |
|---|---|---|---|---|
| `glowColor` | `#FF3D9A` | 3px сплошное кольцо | `#FF3D9A` | ✅ цвет совпадает |
| `color` (сам alpha) | `#B85CFF` @ 0.6 | мягкое свечение | `#B85CFF` @ **0.7** | ⚠️ alpha не совпадает |
| `radius` | 32 | blur-радиус свечения | **24** | ⚠️ не совпадает |
| — (кольцо/stroke width) | нет поля | 3px | 3px | нужно захардкодить в модификаторе (нет токена под line-width) |

**Смысловое сопоставление полей подтверждено верным** (`glowColor` = кольцо,
`color` = свечение) — это то, что бриф просил проверить перед постройкой
модификатора, и оно проверено. Но точные числа `radius`/`alpha` в существующем
токене итерации 1 расходятся с мокапом — это Open Question 1 (менять токен
задним числом vs признать расхождение).

### Selected state

Мокап: `box-shadow: 0 0 0 2px #3ED07F` (`Color.ds.accent.success`) + маленький
чекмарк-бейдж top-right. Кандидат-потребитель уже существует в коде:
`PlaylistRowView.isActive` в `PlaylistsView.swift` сегодня рисует чекмарк
инлайн без ring — `.dsSelected(isActive)` мог бы заменить этот participant,
но пользователь не называл это явно в приоритете 4, только в описании Focus
States — см. Open Question 3.

### Pressed state

Мокап: `scale(0.97)` + `opacity(0.85)`. На tvOS "нажатие" в привычном тач-смысле
не существует — есть только фокус (переместился D-pad'ом) и клик (select-кнопка).
`ButtonStyle.makeBody(configuration:)` даёт `configuration.isPressed`, который на
tvOS отражает именно момент клика select-кнопкой — это естественно ложится на
`DSButton` (см. Компонент 2). Но у "сырых" `.focusable()` элементов без `Button`
(сегодняшний `ChannelCardView`, который использует `.onTapGesture`, а не `Button`)
такого API нет — там пришлось бы городить `.onLongPressGesture(minimumDuration: 0, onPressingChanged:)`,
что является отдельным, не самым надёжным на tvOS паттерном.
**Рекомендация**: pressed state в этой итерации реализуется только для `DSButton`
(через `configuration.isPressed`), НЕ для карточек — см. Open Question 4.

## Компонент 2 — `DSButton`

### Варианты

`DSButtonVariant`: `.primary`, `.secondary`, `.outline`, `.ghost`, `.icon` — 5
случаев, НЕ 7. `.loading` и `.disabled` из мокапа — это не отдельные визуальные
варианты кнопки, а **состояния**, наложенные поверх любого варианта:
- `isLoading: Bool` параметр — подменяет содержимое на `ProgressView` + текст
  (мокап: "Загрузка...", см. Open Question 17 про язык), сохраняя chrome варианта
  `.secondary` (как в мокапе)
- disabled — не отдельный case, читается через `@Environment(\.isEnabled)` внутри
  `ButtonStyle` и переопределяет цвета на `background.surface`/`text.disabled`/
  бордер вне зависимости от выбранного `variant`

```swift
struct DSButtonStyle: ButtonStyle {
    var variant: DSButtonVariant = .primary
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        DSButtonBody(configuration: configuration, variant: variant, isLoading: isLoading)
        // DSButtonBody — приватный View, читает @Environment(\.isFocused) —
        // это единственный способ узнать фокус изнутри ButtonStyle на tvOS,
        // ButtonStyle.Configuration фокус не отдаёт.
    }
}
```

`@Environment(\.isFocused)` внутри `ButtonStyle` — задокументированный tvOS-паттерн
(значение существует в SwiftUI environment на tvOS/watchOS), но малоизвестен —
явно фиксируем в tvOS Considerations, чтобы имплементирующий агент не искал
несуществующий параметр в `ButtonStyleConfiguration`.

### Points, требующие явного решения

| Что | Мокап | Токен-эквивалент | Расхождение |
|---|---|---|---|
| Primary background | `linear-gradient(90deg,#FF3D9A,#B85CFF)` — 2 стопа | `DSGradient.love` — 3 стопа (`#FF3D9A→#B85CFF→#3B82FF`), leading-trailing | Кнопка в мокапе использует только 2 из 3 цветов существующего градиента — см. Open Question 5 |
| Secondary background | `#212132` | `Color.ds.background.elevated` | ✅ точное совпадение |
| Outline border | `rgba(255,255,255,.25)`, padding -1px на сторону для компенсации ширины бордера | нет готового токена на 0.25 alpha | Новый одноразовый литерал `Color.white.opacity(0.25)` или новый `Color.ds.border.*` токен — решение ниже |
| Ghost text | `#8B8C99` | `Color.ds.text.inactive` | ✅ точное совпадение |
| Icon-only size | `44×44` circle, bg `#212132` | — | ⚠️ конфликтует с `tvos-ui.md` "Minimum interactive target: 100×100pt" — Open Question 6 |
| Disabled background | `#171723` | `Color.ds.background.surface` | ✅ |
| Disabled border | `rgba(255,255,255,.06)` | `Color.ds.border.hairline` = `.08` | ⚠️ близко, не идентично — Open Question 8 |
| Disabled text | `#5A5A66` | `Color.ds.text.disabled` | ✅ |
| Focused scale | `1.06` | `DSFocusScale.button` (новый) | — |

### Замена существующих call sites

`AddPlaylistView.swift`: `Button("Cancel")` → `DSButton` variant `.ghost`,
`Button("Add Playlist").buttonStyle(.borderedProminent)` → `DSButton` variant
`.primary` + `isLoading: isAdding`. `PlaylistsView.swift`: toolbar `Button("Add", systemImage: "plus")`
оставить системным (toolbar-кнопки на tvOS имеют свою chrome-конвенцию, трогать
не входит в объём), `Button("Add Playlist")` в empty state → `.primary`,
`PlaylistRowView` Refresh/Delete → кандидаты на `.icon` variant (см. Open Question 6
про 44×44 hit-target).

## Компонент 3 — `DSTextField`

### Варианты

Один компонент `DSTextField(variant:)` с `DSTextFieldVariant`: `.plain`, `.search`
(leading иконка-лупа), `.dropdown` (trailing chevron, label слева/значение справа).
Один компонент, не три отдельных файла — иначе дублирование base-chrome
(padding/radius/background/border/focus) в трёх местах.

```swift
struct DSTextField: View {
    var variant: DSTextFieldVariant = .plain
    let placeholder: String
    @Binding var text: String
    var isFocused: Bool   // прокидывается вызывающим, как у .dsFocusable()
}
```

### Base chrome и расхождения

| Параметр | Мокап | Существующий токен | Расхождение |
|---|---|---|---|
| padding | `14px 18px` | нет точного DSSpacing-совпадения (`DSSpacing.s`=16 близко к 14, `DSSpacing.m`=20 близко к 18) | Ни одно значение шкалы не совпадает 1:1 — нужно решение: округлить до ближайших токенов (16/20) или добавить новую пару? |
| border-radius | `14px` | нет — `DSRadius.s`=12, `DSRadius.m`=18 | Между двумя токенами, не совпадает ни с одним |
| background | `#0C0C12` | `Color.ds.background.primary` | ⚠️ **ПЕРЕСМОТРЕНО 2026-08-04, после реализации**: мокап даёт непрозрачную заливку, но на реальных экранах поле всегда лежит поверх уже непрозрачного/материального контейнера (`.regularMaterial` в `AddPlaylistView`, системный sheet-хром) — второй сплошной тёмный слой поверх первого читался как отдельный серый короб, а не как встроенное поле. Заливка сознательно заменена на `Color.clear`, форму поля держит только hairline-обводка. |
| border (обычное состояние) | `rgba(255,255,255,.1)` | `Color.ds.border.hairline` = `.08` | ⚠️ Open Question 7 |
| placeholder color | `#8B8C99` | `Color.ds.text.inactive` | ✅ |
| Focused border | `2px solid #B85CFF` | нет прямого токена (не то же самое, что `DSShadow.focusGlow`) | Инпут использует ОДНОцветный 2px бордер + один блюр (не двухслойное кольцо+свечение как у карточек/кнопок) |
| Focused glow | `0 0 16px rgba(184,92,255,.5)` | нет точного совпадения с `DSShadow.focusGlow` (32/0.6) | Другой radius и alpha — это НЕ тот же пресет, что `.dsFocusable()` |

**Архитектурное решение**: focus-эффект инпута — это не `.dsFocusable()`
(двухцветное кольцо+свечение), а отдельный, более простой focus-стиль
(один цвет `#B85CFF`, один бордер, один blur). Рекомендация: параметризовать
`.dsFocusable()` достаточно, чтобы инпут мог переиспользовать его внутреннюю
механику двумя разными пресетами (`.standard` для карточек/кнопок, `.input` для
полей), а не писать полностью отдельный модификатор с нуля — это внутренняя
деталь реализации, не меняет видимый результат, поэтому не вынесена в Open
Questions, но фиксируется здесь как решение, которое имплементирующий агент
должен соблюсти, а не изобретать заново.

Padding/radius round-to-existing-token vs new-token — так же, как в примере
из `design-system-tokens.md` (философия: не форсировать ложное совпадение,
заводить новое имя, если значение реально другое) — рекомендация: input-специфичные
`DSSpacing`/`DSRadius` не нужно (уже 8+4 значений в шкалах), округлить до
`DSSpacing.s`(16)/`DSSpacing.m`(20) по горизонтали/вертикали и `DSRadius.m`(18,
ближе к 14, чем `DSRadius.s`=12 — фактически ни один не близко, разница ±4pt в
обе стороны) — **требует явного решения пользователя**, не решается тихо, см.
Open Question 9a (округление spacing/radius для инпутов).

### Call sites

- **Обязательно** (приоритет 3 пользователя, буквально из брифа):
  `AddPlaylistView.swift` — все 3 `TextField` → `DSTextField(.plain)` (m3uURL/epgURL
  можно рассмотреть под `.search`-подобную иконку-URL, но мокап не даёт отдельного
  URL-варианта — оставляем `.plain`).
- **Кандидат, не обязателен**: `ChannelListView.swift` search bar →
  `DSTextField(.search)` — прямое попадание в описанный мокапом search-вариант,
  но пользователь явно называл только `AddPlaylistView` — см. Open Question 15.
- **Без текущего call site**: `.dropdown` вариант — нет ни одного picker-like
  поля в приложении сегодня — см. Open Question 14 (строить спекулятивно?).

## Компонент 4 — `DSCardStyle` + `DSBadge`

### `DSCardStyle` — только стилизация, не layout

**Explicit non-goal**: этот компонент НЕ переносит `ChannelCardView` на
квадратный layout мокапа (лого сверху 65% + текст снизу 35% в текущем коде —
реальный работающий UI, у мокапа для этого нет redline). `DSCardStyle` —
`ViewModifier`, извлекающий только chrome: `cornerRadius: DSRadius.s`,
`DSShadow.card`, `Color.ds.border.hairline` рамка, `.dsFocusable(isFocused, scale: DSFocusScale.card)`.
Применяется поверх существующего `VStack`-layout `ChannelCardView`, заменяя
инлайновые `scaleEffect(1.1)`/`animation(duration: 0.15)` (магические литералы)
на токенизированные эквиваленты. Это буквально Open Question 9 из брифа
(a-вариант, рекомендованный), фиксируется здесь как принятое по умолчанию
направление реализации — **ожидает подтверждения пользователя**, не факт.

Poster Card / Landscape Card (постер 2:3 / шоу 16:9) — в приложении нет каталога
фильмов/шоу (только IPTV-каналы), нет экрана-потребителя ни для одного из двух.
**Рекомендация: OUT OF SCOPE**, не строить — см. Open Question 10.

Playlist Card (иконка+заголовок+подзаголовок) и Mini Card/Category Chips —
оба реальные кандидаты (`PlaylistRowView`, `CategorySidebarView`), но означают
редизайн list→grid / vertical→horizontal, который пользователь не заказывал
явно. **Рекомендация: не строить в этой итерации**, зафиксировать как кандидат
итерации 3 (Patterns) — см. Open Questions 11, 12.

### `DSBadge`

```swift
enum DSBadgeStyle {
    case live, new, hd, fourK, premium, adult, rec
}

struct DSBadge: View {
    let style: DSBadgeStyle
    // padding: 5px 12px → округление до DSSpacing.xxs(4)/DSSpacing.s(16)? см. таблица ниже
    // corner-radius: 8px → между DSRadius.s(12) и не заведённым меньшим значением
    // font-size: 12px, weight: 800 → нет готового Font.ds токена под 12pt/800
}
```

| Бейдж | bg | text | Токен-совпадение |
|---|---|---|---|
| LIVE | `#FF5757` | white bold | `Color.ds.accent.error` ✅ |
| NEW | `#B85CFF` | white bold | нет прямого accent-токена на `#B85CFF` (используется в `DSGradient`/`DSShadow.focusGlow`, но не как отдельный `Color.ds.accent.*`) |
| HD | `#212132` | `#C7C8D1` | `Color.ds.background.elevated` / `Color.ds.text.secondary` ✅ |
| 4K | `#FFB020` | `#171723` (тёмный текст на светлом фоне — единственный такой бейдж) | `Color.ds.accent.warning` / `Color.ds.background.surface` (как text-color — семантически странно использовать background-токен как текст, но значение совпадает) |
| PREMIUM | `DSGradient.love` + звезда | white bold | ✅ градиент уже есть |
| 18+ (adult) | `#3B2130` / `#FF8FB8` | — | `Color.ds.badge.adultBackground/adultText` ✅ уже заведено, но **нет домена**, см. ниже |
| REC | `#212132` | `#FF5757` + красная точка перед текстом | комбинация существующих токенов |

Размерные параметры (`padding: 5px 12px`, `border-radius: 8px`, `font-size: 12px`,
`font-weight: 800`) не совпадают ни с одним существующим `DSSpacing`/`DSRadius`/
`Font.ds` значением — бейдж заведомо требует либо округления до ближайших
токенов (`DSSpacing.xxs`=4/`DSSpacing.s`=16 вместо 5/12 по осям, `DSRadius`
между `s`=12 и ничем меньшим для 8px), либо системного `.font(.system(size: 12, weight: .heavy))`
как разовое исключение из "no raw literals" правила `tvos-ui.md` (бейдж — самый
мелкий текстовый элемент дизайн-системы, накопление на него отдельного
Font-токена может быть избыточным) — **требует решения пользователя**, не
предполагается.

**Главная находка при проверке домена**: `Channel` (Domain entity) не имеет
поля `isAdult`/аналога — ни один бейдж, включая adult (несмотря на
формулировку в брифе "уже имеющий реальный use case"), не имеет сегодня
реального места в UI, которое знает, когда его показывать. Строить `DSBadge`
целиком — чисто визуальный компонент без немедленного потребителя. См. Open
Question 13.

## Files to Create

| Path | Назначение |
|------|-----------|
| `StanisLoveTV/Core/DesignSystem/DS+Focus.swift` | `DSFocusScale` enum + `.dsFocusable(_:scale:cornerRadius:)` + `.dsSelected(_:cornerRadius:)` view-модификаторы |
| `StanisLoveTV/Core/DesignSystem/Components/DSButton.swift` | `DSButtonVariant` enum + `DSButtonStyle: ButtonStyle` + приватный `DSButtonBody` (для доступа к `@Environment(\.isFocused)`) |
| `StanisLoveTV/Core/DesignSystem/Components/DSTextField.swift` | `DSTextFieldVariant` enum + `DSTextField` composite view |
| `StanisLoveTV/Core/DesignSystem/Components/DSCardStyle.swift` | `ViewModifier`, применяющий card-chrome (radius/shadow/border/`.dsFocusable`) без изменения layout содержимого |
| `StanisLoveTV/Core/DesignSystem/Components/DSBadge.swift` | `DSBadgeStyle` enum + `DSBadge` view |
| `StanisLoveTVTests/CoreTests/DSFocusTests.swift` | Тесты на `DSFocusScale` значения и (где технически возможно без snapshot-тестов) на применение модификатора |
| `StanisLoveTVTests/CoreTests/DSButtonStyleTests.swift` | Тесты на `DSButtonVariant` цвета/паддинги через прямое обращение к константам стиля |
| `StanisLoveTVTests/CoreTests/DSTextFieldTests.swift` | Тесты на `DSTextFieldVariant` конфигурацию |
| `StanisLoveTVTests/CoreTests/DSBadgeTests.swift` | Тесты на цвета всех 7 `DSBadgeStyle` кейсов |

## Files to Modify

| Path | Изменение | Причина |
|------|-----------|---------|
| `StanisLoveTV/Presentation/Channels/ChannelCardView.swift` | Заменить `.scaleEffect(isFocused ? 1.1 : 1.0)` + `.animation(.easeInOut(duration: 0.15), value: isFocused)` (магические литералы) на `.dsCardStyle(isFocused: isFocused)` / `.dsFocusable(isFocused, scale: DSFocusScale.card)` | Токенизация существующего focus-эффекта, без изменения layout (см. Open Question 9) |
| `StanisLoveTV/Presentation/Playlists/AddPlaylistView.swift` | 3 `TextField` → `DSTextField`; `Button("Cancel")`/`Button("Add Playlist")` → `DSButton` (`.ghost`/`.primary` + `isLoading: isAdding`) | Приоритет 3 пользователя — буквально то, что он попросил спланировать |
| `StanisLoveTV/Presentation/Playlists/PlaylistsView.swift` | Empty-state `Button("Add Playlist")` → `DSButton(.primary)`; `PlaylistRowView` Refresh/Delete → кандидаты на `DSButton(.icon)` (при условии решения Open Question 6); `isActive`-чекмарк → кандидат на `.dsSelected()` (при условии Open Question 3) | Второй по значимости экран после `AddPlaylistView` |
| `StanisLoveTV/Presentation/Channels/ChannelListView.swift` | Search `TextField` → `DSTextField(.search)` — **условно**, зависит от Open Question 15 | Прямое попадание в описанный мокапом search-вариант, но не названо явно пользователем |
| `StanisLoveTV/Presentation/Debug/DesignSystemShowcaseView.swift` | Добавить секции Focus/Button/TextField/Card/Badge (не обязательно, предложение из брифа) | Существующий debug-каталог токенов — логичное место для каталога компонентов |
| `.claude/rules/tvos-ui.md` | Возможное добавление: "Focus effects — always use `.dsFocusable()`, never raw `.scaleEffect`/`.animation`" рядом с существующим примером `ChannelCardView` (который сейчас сам показывает устаревший raw-паттерн) | Как и в Итерации 1 — правка project-convention файла делается по отдельному согласию, не автоматически |

## Implementation Steps

Каждый шаг — самостоятельный компилируемый коммит, порядок соответствует
приоритету пользователя (Focus → Buttons → Inputs → Cards/Badges).

1. **Согласовать Open Questions 1–17 с пользователем** — блокирующий шаг,
   ничего не реализуется до этого (project convention: см. `design-system-tokens.md`
   "Open Questions — Resolved").
2. Создать `Core/DesignSystem/DS+Focus.swift`: `DSFocusScale` (card/button/chip),
   `.dsFocusable(_:scale:cornerRadius:)` (кольцо через `.overlay(RoundedRectangle().stroke())`
   + свечение через `.shadow()`, оба — цвета из `DSShadow.focusGlow` с учётом
   решения Open Question 1), `.dsSelected(_:cornerRadius:)`.
3. Заменить raw focus-эффект в `ChannelCardView.swift` на `.dsFocusable()`. Собрать,
   визуально проверить в Simulator (scale/glow не должны "прыгать" иначе, чем
   раньше).
4. Создать `Core/DesignSystem/Components/DSButton.swift`: `DSButtonVariant`,
   `DSButtonStyle`, приватный `DSButtonBody` с `@Environment(\.isFocused)` +
   `configuration.isPressed` + `@Environment(\.isEnabled)`.
5. Мигрировать `AddPlaylistView.swift` кнопки на `DSButton`. Собрать, проверить
   визуально фокус/pressed/disabled состояния в Simulator (клик select-кнопкой
   на пульте/клавиатуре Simulator).
6. Мигрировать `PlaylistsView.swift` empty-state кнопку на `DSButton(.primary)`.
7. (Условно, по Open Question 6) Мигрировать `PlaylistRowView` Refresh/Delete на
   `DSButton(.icon)` с расширенным hit-target.
8. Создать `Core/DesignSystem/Components/DSTextField.swift`: `DSTextFieldVariant`
   (`.plain`/`.search`/`.dropdown`), base chrome, focus-стиль (одноцветный
   бордер+blur, отдельный от `.dsFocusable()`, см. решение в разделе Компонент 3).
9. Мигрировать все 3 `TextField` в `AddPlaylistView.swift` на `DSTextField`.
   Собрать, проверить, что фокус-glow визуально совпадает со скриншотом,
   который пользователь показывал раньше.
10. (Условно, по Open Question 15) Мигрировать search bar `ChannelListView.swift`
    на `DSTextField(.search)`.
11. Создать `Core/DesignSystem/Components/DSCardStyle.swift` — `ViewModifier`
    (radius/shadow/border/`.dsFocusable`), применить к `ChannelCardView` вместо
    точечных модификаторов из Шага 3 (объединяет их в переиспользуемый пакет).
12. Создать `Core/DesignSystem/Components/DSBadge.swift` — все 7 `DSBadgeStyle`
    кейсов (при условии решения Open Question 13, если пользователь ограничит
    список — реализовать только согласованное подмножество).
13. (Опционально) Расширить `DesignSystemShowcaseView.swift` секциями для новых
    компонентов.
14. Написать тесты (см. раздел Tests) — прогнать, зафиксировать зелёный прогон.
15. (Опционально, отдельное согласие) Обновить `.claude/rules/tvos-ui.md` —
    заменить пример `ChannelCardView` с raw `scaleEffect`/`animation` на
    `.dsFocusable()`.

## SQLiteData Schema Changes

Нет. Компоненты не персистентны.

## Dependency Registration

Нет новых `DependencyKey`. Все компоненты — stateless `View`/`ViewModifier`/
`ButtonStyle`, управляемые через параметры и `@FocusState`/`@Environment`
вызывающей стороны, не сервисы и не нуждаются в DI (как и токены Итерации 1).

## Tests to Write

`StanisLoveTVTests/CoreTests/DSFocusTests.swift`:
```
@Test func focusScaleTokens_matchMockupValues()
    // card = 1.08, button = 1.06, chip = 1.05 (или согласованные по Open Question 2 значения)

@Test func dsFocusable_appliesScale_whenFocused()
    // рендер через ViewInspector-подобный подход или прямая проверка modifier chain,
    // если тестовая инфраструктура проекта это поддерживает — иначе документируем
    // как ограничение (см. риск ниже)
```

`StanisLoveTVTests/CoreTests/DSButtonStyleTests.swift`:
```
@Test func primaryVariant_usesLoveGradient()
@Test func secondaryVariant_matchesBackgroundElevated()
@Test func disabledState_overridesVariantColors_regardlessOfVariant()
@Test func iconVariant_hasMinimumHitTarget100pt()
    // защита от регрессии Open Question 6 — тест буквально проверяет,
    // что frame width/height >= 100, а не 44
```

`StanisLoveTVTests/CoreTests/DSTextFieldTests.swift`:
```
@Test func plainVariant_hasNoLeadingIcon()
@Test func searchVariant_hasMagnifyingGlassIcon()
@Test func dropdownVariant_hasTrailingChevron()
@Test func focusedBorder_usesGlowPurple_notFocusableRingColors()
    // документирует, что инпут-фокус — отдельный визуальный язык от .dsFocusable()
```

`StanisLoveTVTests/CoreTests/DSBadgeTests.swift`:
```
@Test func allBadgeStyles_haveDistinctColors()
@Test func fourKBadge_usesDarkTextOnLightBackground()
    // единственный бейдж с тёмным текстом — регрессионная защита
@Test func adultBadge_reusesExistingDesignSystemTokens()
    // Color.ds.badge.adultBackground/adultText, не новые литералы
```

**Ограничение тестируемости**: в отличие от токенов Итерации 1 (чистые value-типы,
легко проверяемые напрямую), компоненты — `View`/`ViewModifier`/`ButtonStyle`.
Проект не использует snapshot-тестирование или `ViewInspector` (не в
`Package.swift` зависимостях сегодня) — тесты на визуальный результат
(`.dsFocusable()` реально ли меняет `scaleEffect` в рендер-дереве) ограничены
проверкой конфигурационных констант (`DSFocusScale.card == 1.08`), не
фактического рендера. Полная визуальная регрессия остаётся ручной проверкой в
Simulator на каждом шаге — так же, как в Итерации 1 для шрифтов.

## tvOS Considerations

- **`@Environment(\.isFocused)` внутри `ButtonStyle`** — нестандартный, но рабочий
  tvOS-паттерн: `ButtonStyleConfiguration` не даёт фокус напрямую, читать нужно
  через `@Environment` в приватном `View`, обёрнутом вокруг `configuration.label`.
  Явно фиксируем здесь, чтобы имплементирующий агент не пытался найти это в
  `Configuration` API и не городил отдельный `@FocusState` поверх `Button`
  (что сломало бы встроенный tvOS focus engine для самой кнопки).
- **`.dsFocusable()` не вызывает `.focusable()`/`.focused()`** — вызывающая
  сторона обязана это делать сама (как сегодня в `ChannelCardView`). Если этот
  контракт нарушить (например, применить `.dsFocusable()` к не-focusable view),
  эффект не появится — визуальный, не компилируемый баг, стоит явно
  задокументировать в doc-комментарии модификатора.
- **`DSTextField` focus vs tvOS system keyboard**: на tvOS клик select-кнопкой на
  `TextField` открывает системную полноэкранную клавиатуру — это системный UI,
  не наш. Фокус-glow-стилизация `DSTextField` применяется только к состоянию
  "поле в фокусе, клавиатура ещё не открыта" — после открытия клавиатуры мы не
  управляем её видом. Не баг, но нужно явно проверить в Simulator, что переход
  focus→keyboard не даёт визуального "скачка" (glow резко исчезает при открытии
  клавиатуры — ожидаемое поведение, не регрессия).
  ⚠️ ***Требует отдельной живой tvOS-Simulator проверки перед мержем***, т.к.
  это тот самый сценарий, который пользователь показывал скриншотом.
- **Icon-only 44×44 hit-target** — прямой конфликт с `tvos-ui.md`. Любое решение
  Open Question 6 должно быть проверено фактическим фокусом с пульта в
  Simulator, не только компиляцией — маленький hit-target на реальном ТВ с 3м
  может быть физически труднее сфокусировать, даже если технически "работает".
- **`DSBadge` — не focusable**, бейджи не участвуют в focus engine (не имеют
  `.focusable()`), это чисто декоративные/информационные элементы — не
  требуют `accessibilityLabel`/`.onExitCommand` сами по себе, но должны быть
  включены в `accessibilityLabel` родительского focusable-элемента (например,
  если `ChannelCardView` получит LIVE-бейдж в будущем, "LIVE" должно попасть в
  `accessibilityLabel` карточки, не остаться visual-only).
- **10-foot UI** — `DSBadge` текст 12pt явно ниже минимума `tvos-ui.md` "Body
  text: 17pt minimum" — как и `caption`=15pt в Итерации 1, это осознанное
  исключение (бейдж — не основной текст), но стоит явно подтвердить вместе с
  остальными Open Questions, а не считать автоматически решённым по аналогии.

## Open Questions

Требуют явного решения пользователя ДО начала реализации (согласно конвенции
проекта — см. `design-system-tokens.md`, "Open Questions — Resolved").

1. **`DSShadow.focusGlow` точные значения**: alpha свечения 0.6 (токен) vs 0.7
   (мокап), radius 32 (токен) vs 24 (мокап). Скорректировать существующий
   токен Итерации 1 в рамках этой итерации, или оставить как есть и осознанно
   принять расхождение с мокапом?
2. **Focus scale**: фиксировать раздельные именованные константы по типу
   компонента (`DSFocusScale.card`=1.08/`.button`=1.06/`.chip`=1.05, как
   предложено в этом плане), или один универсальный масштаб для всех
   компонентов?
3. **Selected state (`.dsSelected()`)**: строить в этой итерации и применить к
   `PlaylistRowView.isActive` (реальный, уже существующий call site), или
   отложить — пользователь не называл это явно в 4 приоритетах, только в
   разделе Focus States как справочный материал?
4. **Pressed state**: ограничить реализацию только `DSButton` (через
   `configuration.isPressed`), не строить pressed-эффект для карточек/инпутов
   (у которых на tvOS нет естественного эквивалента без `.onLongPressGesture`
   workaround)?
5. **Primary-кнопка градиент**: использовать полный 3-стоповый `DSGradient.love`
   как есть (кнопка визуально будет чуть отличаться от мокапа, где виден
   только переход pink→purple без синего), или завести отдельный 2-стоповый
   градиент специально под кнопку?
6. **Icon-only кнопка 44×44 vs правило `tvos-ui.md` "Minimum interactive target:
   100×100pt"** — прямой конфликт. Варианты: (a) визуально 44×44, но
   `.contentShape`/невидимый `.frame` расширяет focusable/hit-area до 100×100
   (рекомендуется), (b) увеличить видимый размер кнопки до 100×100 вопреки
   мокапу, (c) явно задокументировать icon-button как исключение из правила в
   `tvos-ui.md`. Какой вариант?
7. **`Color.ds.border.hairline` (.08) vs input-бордер мокапа (rgba(255,255,255,.1))**
   — завести отдельный `Color.ds.border.input` (.1), или унифицировать оба на
   одно значение (какое)?
8. **Disabled-button border (.06 в мокапе) vs `border.hairline` (.08)** — тот же
   вопрос, отдельный токен или округление?
9. **`ChannelCardView` — styling-only extraction (a) vs layout redesign под
   квадратный чип мокапа (b)?** Рекомендация плана — (a), безопасный дефолт
   при отсутствии redline для текущего лого-based layout. Подтвердить.
   9a. **Инпут padding/radius округление**: мокап даёт `14px/18px` padding и
   `14px` radius, ни одно значение не совпадает 1:1 ни с одним `DSSpacing`/
   `DSRadius` токеном. Округлить до `DSSpacing.s`(16)/`DSSpacing.m`(20) и
   `DSRadius.m`(18), или завести точные новые значения в шкалы?
10. **Poster Card / Landscape Card** — подтвердить OUT OF SCOPE (нет
    экрана-каталога фильмов/шоу в приложении, только IPTV-каналы)?
11. **Playlist Card** — оставить `PlaylistRowView` списком (без изменений
    структуры), не переводить в grid карточек?
12. **Mini Card / Category Chips** — не переводить `CategorySidebarView` из
    вертикального списка в горизонтальные пилюли в этой итерации (кандидат
    итерации 3)?
13. **Бейджи за пределами adult (LIVE/NEW/HD/4K/PREMIUM/REC)** — важная
    находка: ни один бейдж, включая adult, не имеет сегодня реального call
    site (`Channel` не имеет поля `isAdult`). Строить весь `DSBadge` набор как
    визуальный компонент без немедленного потребителя (готов к будущему
    подключению), или ограничиться подмножеством (например, только adult +
    HD, у которых проще всего представить реальные данные) в этой итерации?
14. **Dropdown/picker input variant** — нет текущего call site в приложении.
    Строить спекулятивно вместе с `.plain`/`.search`, или отложить до появления
    реального picker-экрана?
15. **`ChannelListView` search bar → `DSTextField(.search)`** — в объёме этой
    итерации (прямое попадание в мокап-вариант) или только `AddPlaylistView`,
    как буквально названо в приоритете 3?
16. **`DSBadge` размерные параметры** (padding 5×12, radius 8px, font 12pt/800) —
    не совпадают ни с одним существующим `DSSpacing`/`DSRadius`/`Font.ds`
    значением. Округлять до ближайших токенов, или ввести точные новые
    значения (расширение шкал), или разрешить разовое исключение через
    `.font(.system(size: 12, weight: .heavy))`?
17. **Loading-состояние кнопки, текст "Загрузка..."** — мокап даёт русский
    текст, но весь остальной UI приложения сегодня на английском (в проекте
    нет локализации). Использовать английское "Loading…" для консистентности
    с существующим UI, или взять русский текст мокапа буквально?

## Open Questions — Resolved (2026-08-04)

1. **`DSShadow.focusGlow` точные значения** — оставить токен как есть (alpha 0.6, radius 32). Осознанно принято расхождение с мокапом (0.7/24); токен уже задокументирован и протестирован в Итерации 1, менять задним числом не будем.
2. **Focus scale** — раздельные именованные константы: `DSFocusScale.card = 1.08`, `.button = 1.06`, `.chip = 1.05`. 1:1 с мокапом по типу компонента.
3. **Selected state** — строим `.dsSelected()` в этой итерации и сразу подключаем к `PlaylistRowView.isActive` (заменяет текущий инлайновый чекмарк без кольца).
4. **Pressed state** — ограничен только `DSButton` через `configuration.isPressed`. Карточки/инпуты pressed-эффект не получают (нет надёжного tvOS-эквивалента без `.onLongPressGesture`-костыля).
5. **Primary-кнопка градиент** — использовать полный `DSGradient.love` (3 стопа) как есть, не заводить отдельный 2-стоповый градиент под кнопку. Кнопка будет визуально чуть отличаться от мокапа (виден синий оттенок) — принято осознанно.
6. **Icon-кнопка 44×44 vs 100×100pt правило** — визуально 44×44 (как в мокапе), hit-area/focusable-область расширена невидимым `.frame`/`.contentShape` до 100×100. Не нарушает `tvos-ui.md`, не меняет визуал мокапа.
7. **Border alpha инпута (.08 vs .1)** — унифицировать на `.08`, использовать существующий `Color.ds.border.hairline` везде, отдельный `Color.ds.border.input` не заводим.
8. **Disabled-button border (.06 vs .08)** — тот же ответ, что и Q7: `Color.ds.border.hairline` (.08) везде, включая disabled-состояние кнопки.
9. **`ChannelCardView` layout** — только стилизация (`DSCardStyle`: radius/shadow/`.dsFocusable`), существующий лого-based layout (65%/35%, 300×170) НЕ редизайнится под квадратный чип мокапа. Это принятый по умолчанию вариант (a) из плана.
   9a. **Input padding/radius округление** — округлить до ближайших существующих токенов: `DSSpacing.s`(16)/`DSSpacing.m`(20) вместо 14px/18px padding, `DSRadius.m`(18) вместо 14px radius. Новых точных значений не заводим.
   **ПЕРЕСМОТРЕНО 2026-08-04, после реализации**: пользователь явно назвал поля ввода приоритетом номер один во всей итерации ("мне поля важнее всего остального") — округление до токенов отменено. `DSTextFieldMetrics` теперь хранит точные значения мокапа (`verticalPadding = 14`, `horizontalPadding = 18`, `cornerRadius = 14`) как выделенные one-off константы, не как записи в `DSSpacing`/`DSRadius` (эти значения не принадлежат 8pt-grid шкале токенов и не должны туда притворно вписываться). `DSTextFieldTests` обновлён под точные значения.
10. **Poster Card / Landscape Card** — подтверждено OUT OF SCOPE. В приложении нет каталога фильмов/шоу (только IPTV-каналы), оба варианта не строятся.
11. **Playlist Card** — `PlaylistRowView` остаётся списком, без перехода на grid карточек в этой итерации. Кандидат итерации 3 (Паттерны).
12. **Mini Card / Category Chips** — `CategorySidebarView` остаётся вертикальным списком, без перехода на горизонтальные pill-чипы в этой итерации. Кандидат итерации 3.
13. **Бейджи за пределами adult** — строим полный набор `DSBadge` (все 7 стилей: live/new/hd/fourK/premium/adult/rec) впрок, как чисто визуальный компонент без немедленного потребителя в домене. Готов к подключению, когда у `Channel` появится соответствующее поле (например `isAdult`).
14. **Dropdown/picker input variant** — откладывается до появления реального picker-экрана в приложении. Не строится спекулятивно в этой итерации (в отличие от `DSBadge`, где решение обратное — см. Q13).
15. **`ChannelListView` search bar** — мигрируется на `DSTextField(.search)` в этой же итерации, не только `AddPlaylistView`.
16. **`DSBadge` размерные параметры** — см. Q13: набор строится полностью. Padding/radius/font округляются до ближайших существующих токенов там, где это не ломает визуал (детали — на усмотрение реализующего агента на Шаге 12, без нового Open Question).
17. **Loading-текст кнопки** — берём русский текст мокапа буквально: **"Загрузка..."**. Отступление от общей all-English конвенции UI принято осознанно для этого конкретного случая (мокап это явно предписывает); не устанавливает прецедент для остального UI без отдельного решения.

## Definition of Done

- [x] Open Questions 1–17 обсуждены с пользователем, решения зафиксированы
      (в этом файле или в коммите) до начала реализации — см. "Open Questions — Resolved (2026-08-04)"
- [x] `Core/DesignSystem/DS+Focus.swift` создан — `.dsFocusable()`/`.dsSelected()`
      реализованы согласно согласованным Open Questions 1–4
- [x] `ChannelCardView.swift` мигрирован на `.dsFocusable()`/`.dsCardStyle()` —
      raw `scaleEffect`/`animation` литералы удалены
- [x] `Core/DesignSystem/Components/DSButton.swift` создан — все 5 вариантов
      (`primary/secondary/outline/ghost/icon`) + `isLoading`/disabled-состояния
      работают через один `ButtonStyle`
- [x] `AddPlaylistView.swift` — кнопки мигрированы на `DSButton`
- [x] `Core/DesignSystem/Components/DSTextField.swift` создан — `.plain`/`.search`
      реализованы (`.dropdown` подтверждён как отложенный по Open Question 14)
- [x] `AddPlaylistView.swift` — все 3 `TextField` мигрированы на `DSTextField`.
      Визуальная проверка в Simulator не выполнена (нет доступа к Xcode в этой
      сессии) — фон/паддинг/шрифт поля донастроены по живой обратной связи
      пользователя постфактум, см. "Отклонения после реализации" ниже.
- [x] `Core/DesignSystem/Components/DSCardStyle.swift` и
      `Core/DesignSystem/Components/DSBadge.swift` созданы согласно решениям по
      Open Questions 9, 13, 16
- [x] Тесты из раздела Tests написаны (не 100% дословно как в черновике —
      логика вынесена в тестируемые non-private функции/enum-свойства вместо
      приватных `View`-computed properties, см. `DSButtonChrome.resolve`,
      `DSBadgeStyle.foreground` и т.д.), прогон в Xcode не выполнен
- [x] Ни один файл в `Domain/` или `Data/` не импортирует
      `Core/DesignSystem/Components/*`
- [x] Явно зафиксировано: паттерны экранного уровня (Hero Banner, Channel Row,
      Movie Row, Category Chips) НЕ входят в эту итерацию — кандидат итерации 3
- [x] Явно зафиксировано: Poster Card / Landscape Card НЕ строятся (нет
      экрана-потребителя в приложении)

## Отклонения после реализации (2026-08-04)

Обнаружены/приняты в процессе имплементации, не были предусмотрены в исходном плане:

1. **`PlaylistRowView` Refresh/Delete НЕ мигрированы на `DSButton(.icon)`.**
   100×100 hit-area (Open Question 6) раздула бы строку списка непропорционально
   высоте List-строки. Оставлены системные `.labelStyle(.iconOnly)` кнопки.
2. **`.dsSelected()` применён только к текстовому блоку строки плейлиста**, не
   ко всей строке — иначе ring + чекмарк-бейдж накладывались бы на кнопки
   Refresh/Delete у правого края.
3. **`DSTextField` фон изменён с `Color.ds.background.primary` на
   `Color.clear`** — уже после первого прохода реализации, по прямой
   обратной связи пользователя ("фон должен быть прозрачный а не серый").
   Мокап даёт непрозрачную заливку `#0C0C12`, но на реальных экранах поле
   всегда лежит поверх уже непрозрачного контейнера (`.regularMaterial` в
   `AddPlaylistView`, системный sheet-хром) — второй сплошной слой читался
   как отдельный серый короб. Форму поля держит только hairline-обводка.
4. **`DSTextFieldMetrics.verticalPadding/horizontalPadding/cornerRadius`
   изменены с округлённых до токенов значений на точные мокап-значения
   (14/18/14)** — пользователь явно расставил приоритет: "мне поля важнее
   всего остального". См. правку Open Question 9a выше.
5. **`DSTextField` не имел явного `.font()`** — упущение первого прохода.
   Без него текст рендерился системным шрифтом tvOS (крупнее ожидаемого),
   что визуально "съедало" паддинг и создавало впечатление отсутствия
   отступов. Добавлен `.font(.ds.caption)` (ближайший существующий токен,
   15pt/Inter-Regular, к мокаповским 14px/Inter-Regular).
6. **`DesignSystemShowcaseView`'s `SectionContainer` не имел собственной
   карточки** (`background.surface` + hairline border + `DSRadius.l` +
   `DSSpacing.xl`) — упущение ещё из Итерации 1, всплывшее только теперь:
   без неё каждая секция каталога лежит прямо на `background.primary` экрана,
   из-за чего прозрачные/primary-цвета в секциях становятся невидимыми.
   Добавлена карточка, 1:1 повторяющая структуру мокапа.
7. **`DSSelectedModifier`'s чекмарк-бейдж получил `.accessibilityHidden(true)`**
   при финальном ревью — упущение в первой версии, глиф декоративный,
   семантика "выбрано" должна попадать в `accessibilityLabel` вызывающей
   стороны, а не озвучиваться отдельно.
