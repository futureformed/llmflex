import SwiftUI

enum Theme {
    // ─────────────────────────────────────────────────────────────────────
    // Brand palette — Futureformed. Accent moves from the old muted #5E48A8
    // to the true brand purple #6127F5. The green "live" semantics are kept
    // intentionally: they read as ON, distinct from the purple UI accent.
    // ─────────────────────────────────────────────────────────────────────

    /// Brand accent — Futureformed Purple. Drives primary buttons, "+ Add",
    /// the menu-bar icon tint, links, and "Switched to…" confirmations.
    static let accent        = Color(red: 0x61/255, green: 0x27/255, blue: 0xF5/255) // #6127F5

    /// Lighter purple — hover highlights / accents on dark fields.
    static let accentLight   = Color(red: 0x7C/255, green: 0x45/255, blue: 0xF7/255) // #7C45F7

    /// Darker purple — pressed / active button state.
    static let accentPressed = Color(red: 0x4A/255, green: 0x1E/255, blue: 0xC4/255) // #4A1EC4

    /// Selection / hover wash. Use in place of accent.opacity(…) tints for a
    /// flatter, more on-brand fill (e.g. selected rows, the accent divider bg).
    static let tint          = Color(red: 0xF0/255, green: 0xEC/255, blue: 0xFE/255) // #F0ECFE

    /// Near-black ink — dark surfaces and strong text. Matches the icon field.
    static let ink           = Color(red: 0x1A/255, green: 0x1A/255, blue: 0x2E/255) // #1A1A2E

    /// "What's currently live" — green. Distinct from the purple accent so
    /// active state reads as ON instead of just another UI accent. Used on
    /// the active dot, "active" pill, accent bar, and panel background tint.
    static let activeAccent = Color(red: 52/255, green: 168/255, blue: 83/255)  // #34A853
    static let activeBackground = Color(red: 200/255, green: 247/255, blue: 197/255) // #C8F7C5

    enum Metric {
        static let popoverWidth: CGFloat = 380
        static let outerPadding: CGFloat = 16
        static let sectionGap: CGFloat = 14
        static let rowGap: CGFloat = 10
    }

    /// Corner radii — match the brand's 8 / 12 rhythm.
    enum Radius {
        static let control: CGFloat = 8   // rows, buttons, status cards
        static let card: CGFloat = 12     // panels / larger containers
    }

    enum Fonts {
        /// Default body text — bumped from system caption-size for readability.
        static let body: Font = .system(size: 13, weight: .regular)
        static let bodyBold: Font = .system(size: 13, weight: .semibold)
        static let title: Font = .system(size: 15, weight: .semibold)
        static let label: Font = .system(size: 11, weight: .semibold)  // section caps
        static let meta: Font = .system(size: 12, weight: .regular)

        static func mono(_ size: CGFloat = 12) -> Font {
            .system(size: size, weight: .regular, design: .monospaced)
        }
    }
}

extension View {
    func llmAccentTint() -> some View { tint(Theme.accent) }
}
