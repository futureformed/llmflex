import SwiftUI
import AppKit
import LLMFlexCore

/// Visual identifier for a provider. Tries to load a real brand icon from
/// `Resources/ProviderIcons/<provider_raw>.png` first; if no file is present
/// (or it can't be decoded), falls back to a coloured monogram. Partial
/// coverage is fine — every provider works either way.
struct ProviderBadge: View {
    let provider: Provider
    var size: CGFloat = 18

    var body: some View {
        if let bundled = bundledImage {
            Image(nsImage: bundled)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
        } else {
            monogram
        }
    }

    private var bundledImage: NSImage? {
        // Tries the provider's raw value, e.g. "openai", "lm_studio".
        // Note: SPM's .process("Resources") flattens directory structure,
        // so the files live at the bundle root, not under ProviderIcons/.
        //
        // We deliberately do NOT use `Bundle.module` here: its generated
        // accessor fatalErrors when its two hardcoded candidate paths miss,
        // which is exactly what happens in a distributed .app (see
        // ResourceBundleLocator). Resolve the bundle ourselves and degrade to
        // the monogram if it (or the icon) isn't found.
        guard let url = Self.iconBundle?.url(
            forResource: provider.rawValue,
            withExtension: "png"
        ) else { return nil }
        return NSImage(contentsOf: url)
    }

    /// The SPM resource bundle holding provider icons, located resiliently.
    /// `Bundle.main.resourceURL` covers the packaged `.app`
    /// (`Contents/Resources/…`); `bundleURL` covers `swift run`, where the
    /// bundle sits next to the executable. Resolved once.
    private static let iconBundle: Bundle? = {
        let name = "LLMFlex_LLMFlex.bundle"
        var candidates: [URL] = []
        if let res = Bundle.main.resourceURL {
            candidates.append(res.appendingPathComponent(name))
        }
        candidates.append(Bundle.main.bundleURL.appendingPathComponent(name))
        return ResourceBundleLocator.firstExisting(candidates).flatMap(Bundle.init(url:))
    }()

    private var monogram: some View {
        ZStack {
            Circle().fill(style.color)
            Text(style.letter)
                .font(.system(size: size * 0.55, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    private var style: (letter: String, color: Color) {
        switch provider {
        case .openai:           return ("O",  Color(red: 16/255,  green: 163/255, blue: 127/255))
        case .anthropic:        return ("A",  Color(red: 217/255, green: 119/255, blue: 87/255))
        case .openrouter:       return ("R",  Color(red: 96/255,  green: 96/255,  blue: 110/255))
        case .lmStudio:         return ("LM", Color(red: 41/255,  green: 121/255, blue: 255/255))
        case .ollama:           return ("O",  Color(red: 36/255,  green: 36/255,  blue: 36/255))
        case .gemini:           return ("G",  Color(red: 36/255,  green: 99/255,  blue: 235/255))
        case .opencodeGo:       return ("Z",  Color(red: 138/255, green: 70/255,  blue: 224/255))
        case .openaiCompatible: return ("·",  Color(red: 130/255, green: 130/255, blue: 130/255))
        case .custom:           return ("?",  Color(red: 130/255, green: 130/255, blue: 130/255))
        }
    }
}
