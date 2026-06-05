import SwiftUI
import AppKit
import LLMFlexCore

/// Icon for a switchable *target* — the CLI app itself (Codex, Claude Code),
/// as opposed to a provider. Tries to load a real brand PNG from
/// `Resources/TargetIcons/<key>.png` first; if no file is present (or it can't
/// be decoded), falls back to an SF Symbol so the UI always renders. Same
/// resilient bundle resolution as `ProviderBadge` (we deliberately avoid
/// `Bundle.module`, which fatalErrors in a distributed `.app`).
struct TargetBadge: View {
    let iconKey: String
    let fallbackSystemName: String
    var size: CGFloat = 18
    var active: Bool = false

    var body: some View {
        if let bundled = Self.image(named: iconKey) {
            Image(nsImage: bundled)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
        } else {
            Image(systemName: fallbackSystemName)
                .foregroundStyle(active ? Theme.activeAccent : .secondary)
                .font(.system(size: size - 4, weight: .semibold))
                .frame(width: size, height: size)
        }
    }

    private static func image(named key: String) -> NSImage? {
        guard let url = iconBundle?.url(forResource: key, withExtension: "png")
        else { return nil }
        return NSImage(contentsOf: url)
    }

    /// The SPM resource bundle, located resiliently. `.process("Resources")`
    /// flattens the directory tree, so `TargetIcons/codex.png` lands at the
    /// bundle root as `codex.png`.
    private static let iconBundle: Bundle? = {
        let name = "LLMFlex_LLMFlex.bundle"
        var candidates: [URL] = []
        if let res = Bundle.main.resourceURL {
            candidates.append(res.appendingPathComponent(name))
        }
        candidates.append(Bundle.main.bundleURL.appendingPathComponent(name))
        return ResourceBundleLocator.firstExisting(candidates).flatMap(Bundle.init(url:))
    }()
}
