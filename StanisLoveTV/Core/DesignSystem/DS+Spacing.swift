import CoreFoundation

/// Design-system spacing scale (4·8·16·20·24·32·40·48), from `Design System.dc.html`.
/// Deliberately named `xxs/xs/s/m/l/xl/xxl/xxxl` — single-letter mid values (`s/m/l`)
/// distinguish this scale visually from the old `Spacing.sm/md/lg` it replaces, since
/// the values at similarly-named tiers don't match (e.g. `DSSpacing.l` is 24, not 40).
enum DSSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 16
    static let m: CGFloat = 20
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48
}
