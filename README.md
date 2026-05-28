# LLM Flex

A simple macOS menu bar app that lets you switch the underlying AI model in
Claude Code and OpenAI Codex. No messing with JSON or env vars — just grab an
API key and run LLM Flex.

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

## Updating the curated model catalog

The "Quick pick" menu in the profile editor is populated from
[`Sources/LLMFlexCore/Models/ModelCatalog.swift`](Sources/LLMFlexCore/Models/ModelCatalog.swift).
When OpenAI / Anthropic / OpenRouter / Opencode Go ship new models:

1. Open `ModelCatalog.swift`.
2. Edit the array for the relevant provider (`openai`, `anthropic`,
   `openrouter`, or `opencodeGo`). Each entry has `id` (the API string),
   `label` (human-friendly), and optional `notes`.
3. `swift test && ./build.sh`
4. Commit.

Doc sources used for the current catalog:

- Anthropic — https://docs.anthropic.com/en/docs/about-claude/models/overview
- OpenAI — https://platform.openai.com/docs/models
- OpenRouter — https://openrouter.ai/models
- Opencode Go — https://opencode.ai/zen/go
