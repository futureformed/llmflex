# LLM Flex

macOS menu bar app for switching the Codex CLI / Codex.app between API providers (OpenRouter, Ollama, OpenAI-compatible, custom).

## Status

🚧 **Phase A — scaffolding.** Empty SwiftUI menu bar shell builds and launches. Real functionality lands in Phase B.

## Build

```bash
swift test        # run unit tests
./build.sh        # produce build/LLM Flex.app
open 'build/LLM Flex.app'
```

## Layout

- `Sources/LLMFlexCore/` — pure logic (no UI). Unit-tested.
- `Sources/LLMFlex/` — SwiftUI app.
- `Tests/LLMFlexCoreTests/` — XCTest target.
- `build.sh` — wraps the SPM release build into a code-signed `.app` bundle.

## Requirements

macOS 14.0+, Swift 5.9+.
