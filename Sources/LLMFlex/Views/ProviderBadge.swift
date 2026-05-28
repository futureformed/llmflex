import SwiftUI
import LLMFlexCore

/// Small circular monogram badge for a provider — letter + brand-ish colour.
/// Lightweight stand-in for proper SVG/PNG logos: no asset pipeline needed,
/// reads clearly at small sizes, easy to swap later when real artwork lands.
struct ProviderBadge: View {
    let provider: Provider
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            Circle()
                .fill(style.color)
            Text(style.letter)
                .font(.system(size: size * 0.55, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    private var style: (letter: String, color: Color) {
        switch provider {
        case .openai:           return ("O",  Color(red: 16/255,  green: 163/255, blue: 127/255)) // OpenAI green
        case .anthropic:        return ("A",  Color(red: 217/255, green: 119/255, blue: 87/255))  // Anthropic terracotta
        case .openrouter:       return ("R",  Color(red: 96/255,  green: 96/255,  blue: 110/255)) // OpenRouter slate
        case .lmStudio:         return ("LM", Color(red: 41/255,  green: 121/255, blue: 255/255)) // LM Studio blue
        case .ollama:           return ("O",  Color(red: 36/255,  green: 36/255,  blue: 36/255))  // Ollama charcoal
        case .gemini:           return ("G",  Color(red: 36/255,  green: 99/255,  blue: 235/255)) // Google blue
        case .opencodeGo:       return ("Z",  Color(red: 138/255, green: 70/255,  blue: 224/255)) // Opencode Zen purple
        case .openaiCompatible: return ("·",  Color(red: 130/255, green: 130/255, blue: 130/255))
        case .custom:           return ("?",  Color(red: 130/255, green: 130/255, blue: 130/255))
        }
    }
}
