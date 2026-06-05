# LLM Flex

A simple macOS menu bar app that lets you switch the underlying AI model in
Claude Code and OpenAI Codex. No messing with JSON or env vars — just grab an
API key and run LLM Flex.

> **Alpha.** This is early software (versions `0.x`). Expect rough edges, and
> please send feedback — it's exactly what this stage is for. Use the **envelope
> icon** inside the app to email the team, or file a GitHub issue.

## Download & install

1. Grab the latest `LLM-Flex-x.y.z.dmg` from the
   [Releases page](https://github.com/futureformed/llmflex/releases).
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

## Getting started (step by step)

New to API keys and config files? This is the whole flow, start to finish.

### 1. Get an API key from a provider

An "API key" is a secret password that lets a program use an AI provider on your
behalf (and bills you for what you use). You create one on the provider's website,
copy it once, and paste it into LLM Flex.

Each provider speaks one tool's native API, so pick a provider for the tool you
want to switch — **Codex** or **Claude Code**:

| Provider | Switches | Where to create a key |
| --- | --- | --- |
| **Anthropic** (Claude) | Claude Code | [console.anthropic.com](https://console.anthropic.com) → **Settings → API Keys → Create Key** |
| **Opencode Go** | Claude Code | [opencode.ai/zen](https://opencode.ai/zen) |
| **OpenAI** | Codex | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) → **Create new secret key** |
| **OpenRouter** | Codex | [openrouter.ai/keys](https://openrouter.ai/keys) → **Create Key** (one key, many models) |
| **LM Studio** | Codex | Runs on your own Mac — **no key needed** |

> **Copy the key the moment it's shown.** Most providers only display it once. It
> usually starts with something like `sk-…`. Treat it like a password.

> **Other providers** — Gemini, Ollama, and any OpenAI-compatible or custom
> endpoint also appear in the list. Gemini and Ollama don't match either tool's
> native API yet, so you can save a profile but **Apply won't work directly** —
> the editor shows a compatibility note when that's the case. They're there for
> people routing through a translating proxy.

### 2. Add a profile in LLM Flex

A "profile" is one saved combination of *provider + model* you can switch to.

1. Click the **↔ icon** in your menu bar to open LLM Flex.
2. Under **PROFILES**, click **+ Add**.
3. Fill in the form:
   - **Name** — anything memorable, e.g. "OpenRouter — Sonnet".
   - **Provider** — pick the one you got a key for. The base URL fills in
     automatically.
   - **API key** — paste the key you copied. It's stored only in your macOS
     Keychain, never in a file or log.
   - **Model** — type the model name, or click the **list icon** for a curated
     "Quick pick" of current models.
4. Click **Test connection** to confirm the key and model work.
5. Click **Save**.

### 3. Apply it

Back in the menu, click **Apply** on the profile. LLM Flex rewrites the config for
**Claude Code** and/or **Codex** (whichever the provider supports), and the status
panel at the top lights up green showing the active **endpoint** and **model** for
each. That's it — your next `claude` or `codex` session uses the new model.

To go back to how things were before you ever used LLM Flex, click **Restore
defaults**.

> **Codex tip:** if Codex is signed in with a ChatGPT account, switching is
> blocked (Codex would overwrite the key on its next launch). Sign out of ChatGPT
> in Codex's settings first, then apply.

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
