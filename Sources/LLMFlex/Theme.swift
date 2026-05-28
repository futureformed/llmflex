import SwiftUI

enum Theme {
    /// Brand accent — deep purple. Pops against both light and dark
    /// system materials. Drives primary buttons, "+ Add", the menu bar
    /// icon, and "Switched to…" confirmations.
    static let accent = Color(red: 94/255, green: 72/255, blue: 168/255)        // #5E48A8

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
