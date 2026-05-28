import SwiftUI

enum Theme {
    /// Brand accent — teal, sits between the usual menu bar blues and greens
    /// without clashing with either. Used for active dots, primary buttons,
    /// and inline status accents.
    static let accent = Color(red: 48/255, green: 176/255, blue: 199/255)

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
