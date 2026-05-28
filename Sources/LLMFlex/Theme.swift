import SwiftUI

enum Theme {
    /// Brand accent — teal, sits between the usual menu bar blues and greens
    /// without clashing with either. Used for general affordances:
    /// primary buttons, "+ Add" chips, "Switched to…" confirmation, etc.
    static let accent = Color(red: 48/255, green: 176/255, blue: 199/255)

    /// "What's currently live" highlight — light purple. Reserved for the
    /// active provider's row + the Codex status panel so it visually stands
    /// out from the rest of the teal UI.
    static let activeAccent = Color(red: 167/255, green: 139/255, blue: 250/255)

    enum Metric {
        static let popoverWidth: CGFloat = 340
        static let outerPadding: CGFloat = 14
        static let sectionGap: CGFloat = 12
        static let rowGap: CGFloat = 8
    }

    enum Fonts {
        static func mono(_ size: CGFloat = 11) -> Font {
            .system(size: size, weight: .regular, design: .monospaced)
        }
    }
}

extension View {
    func llmAccentTint() -> some View { tint(Theme.accent) }
}
