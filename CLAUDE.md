# LLM Flex

A macOS menu-bar app (`LSUIElement`) that switches the underlying AI model/provider
for **Claude Code** and **OpenAI Codex** without the user hand-editing JSON, TOML, or
env vars. Pick a profile, hit apply, and LLM Flex rewrites the right config files.

## Build & test

```bash
swift test          # 58 unit tests (LLMFlexCore only — no UI tests)
./build.sh          # SPM release build → build/LLM Flex.app (ad-hoc signed, no Xcode)
open 'build/LLM Flex.app'
```

`build.sh` copies SPM-generated `*.bundle` resource bundles into `Contents/Resources`
so `Bundle.module` resolves provider icons at runtime. Bundle ID `cc.holdtight.llmflex`,
min macOS 14.0, Swift 5.9.

## Architecture

Two SPM targets — keep the boundary clean:

- **`Sources/LLMFlexCore/`** — pure logic, no SwiftUI/AppKit. Everything testable lives
  here. This is the only target with unit tests (`Tests/LLMFlexCoreTests/`).
- **`Sources/LLMFlex/`** — SwiftUI app. `AppModel` (`@Observable`, `@MainActor`) is the
  view model; views observe it and route all mutations through its methods.

### Core concepts

- **`Target`** (protocol) — a switchable CLI/app. Two impls: `CodexTarget`,
  `ClaudeCodeTarget`. Each does `inspect()` (read on-disk state), `policy()` (is apply
  safe right now?), `apply(profile:apiKey:)`, and `restore()` (roll back to pre-LLM-Flex
  snapshot). Add new targets by conforming to this protocol.
- **`Provider`** (enum) — OpenAI, OpenRouter, LM Studio, Anthropic, Gemini, Ollama,
  Opencode Go, OpenAI-compatible, custom. Holds default base URL, auth scheme, and
  **per-target compatibility** (`compatibility(for:)`): Codex needs the OpenAI Responses
  API; Claude Code needs the Anthropic Messages API. Incompatible combos still save (for
  proxy setups) but surface a reason via `incompatibilityReason(for:)`.
- **`Profile`** — name + provider + baseURL + modelName. **The API key is NOT a field** —
  it lives in the Keychain (`KeychainStore`, keyed by profile UUID) and is fetched on
  demand at apply time. Never serialize keys into Profile, UserDefaults, or logs.
- **`ProfileStore`** — UserDefaults-backed CRUD for profiles (safe fields only).
- **`SnapshotStore`** — copies the user's original config files on *first touch*
  (idempotent `captureIfAbsent`) into `~/Library/Application Support/LLMFlex/snapshots`.
  `restore()` reads these back so we can fully undo, no matter what we changed.
- **`ConnectivityTester`** — the "Test Connection" feature; picks the right auth header
  per provider via `Provider.authScheme`.
- **`SwitchCodeCleanup`** — migration that scrubs leftovers from the app's former name
  ("Switch Code"). `legacyCleanupAvailable` drives the UI prompt.

### What each target writes

- **Claude Code** → deep-merges into `~/.claude/settings.json`. Sets top-level `model`
  and an `env` block with `ANTHROPIC_BASE_URL` + exactly one of `ANTHROPIC_AUTH_TOKEN`
  (gateways/Bearer) or `ANTHROPIC_API_KEY` (direct Anthropic). Preserves the user's other
  keys (permissions, hooks, etc.). Covers the `claude` CLI and all IDE extensions (they
  share this file).
- **Codex** → managed block (between `# === LLM Flex managed block ... ===` markers) in
  `~/.codex/config.toml`, plus `OPENAI_API_KEY` + `auth_mode` in `~/.codex/auth.json`,
  plus `launchctl setenv OPENAI_API_KEY` (Codex.app resolves `env_key` from the launchd
  env, not auth.json).

## Gotchas / invariants (don't regress these — each is a fixed bug)

- **`ANTHROPIC_BASE_URL` is the gateway ROOT.** Claude Code appends `/v1/messages`
  itself. Profile base URLs carry `/v1` (for models-list / Test Connection), so
  `ClaudeCodeTarget.strippedGatewayRoot` strips a trailing `/vN[suffix]` on apply.
- **Never set both `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_API_KEY`.** Anthropic's CLI
  warns and they take different server paths. Pick one by `authScheme`; explicitly
  remove the other to clear stale values.
- **Codex blocks switching when signed in via ChatGPT** (`CodexAuthStateDetector` →
  `.chatgptLogin` → `policy()` returns `.blocked`). Codex.app refreshes tokens on launch
  and would overwrite our API key. Don't bypass this.
- **JSON writes use `.withoutEscapingSlashes`** so URLs stay readable
  (`https://...` not `https:\/\/...`).
- **Trim API keys** aggressively at every boundary — stray whitespace breaks auth.
- **Codex requires `wire_api = "responses"`** — chat-completions are no longer accepted.

## Updating the model catalog

Curated "Quick pick" list lives in `Sources/LLMFlexCore/Models/ModelCatalog.swift`. Edit
the per-provider array (each entry: `id`, `label`, optional `notes`), then `swift test &&
./build.sh`. Doc sources are listed in README.md.
