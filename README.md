# LLM Flex

A simple macOS menu bar app that lets you switch the underlying AI model in
Claude Code and OpenAI Codex. No messing with JSON or env vars — just grab an
API key and run LLM Flex.

> **Alpha.** This is early software (versions `0.x`). Expect rough edges, and
> please file issues — feedback is exactly what this stage is for.

## Download & install

1. Grab the latest `LLM-Flex-x.y.z.dmg` from the
   [Releases page](https://github.com/machomanrandysavageldn/llmflex/releases).
2. Open the DMG and drag **LLM Flex** into your Applications folder.

Builds are **ad-hoc signed**, not notarized by Apple, so Gatekeeper will warn
that the app is from an unidentified developer on first launch. To open it:

- **Right-click** (or Control-click) LLM Flex in Applications → **Open** →
  **Open** again in the dialog. macOS remembers the choice after that.
- If macOS still refuses (it can on recent versions for downloaded apps),
  clear the quarantine flag in Terminal:

  ```bash
  xattr -dr com.apple.quarantine "/Applications/LLM Flex.app"
  ```

This warning is expected for an unsigned alpha — the app is open source, so you
can read or build it yourself below.

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
- `scripts/package-dmg.sh` — builds the app and wraps it in a distributable DMG.

## Requirements

macOS 14.0+, Swift 5.9+.

## Versioning & releases

The version lives in a single [`VERSION`](VERSION) file and is baked into the
app bundle by `build.sh`. Notable changes are tracked in
[`CHANGELOG.md`](CHANGELOG.md). The project follows
[Semantic Versioning](https://semver.org); `0.x` is alpha.

To cut a release:

1. Bump [`VERSION`](VERSION) (e.g. `0.1.0` → `0.2.0`).
2. Move items under `## [Unreleased]` in `CHANGELOG.md` into a new
   `## [0.2.0] - YYYY-MM-DD` section.
3. Commit, then tag and push:

   ```bash
   git tag v0.2.0
   git push origin main --tags
   ```

Pushing the `v*` tag triggers
[`.github/workflows/release.yml`](.github/workflows/release.yml), which runs the
tests, builds the DMG, and publishes a GitHub Release with the DMG attached
(marked as a pre-release for `0.x`). To build a DMG locally instead:

```bash
./scripts/package-dmg.sh   # → build/LLM-Flex-<version>.dmg
```

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
