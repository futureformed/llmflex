# Changelog

All notable changes to LLM Flex are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Versions `0.x` are alpha: things may change and break while feedback comes in.

## [Unreleased]

## [0.1.0] - 2026-06-01

First public alpha. A macOS menu-bar app for switching the model/provider used
by Claude Code and OpenAI Codex without hand-editing config files.

### Added
- **Profiles** — define a provider, base URL, and model; switch between them
  from the menu bar. API keys are stored in the macOS Keychain, never in plain
  config or UserDefaults.
- **Claude Code target** — writes `~/.claude/settings.json` (model + auth env),
  deep-merging so your other settings (permissions, hooks) are preserved.
- **Codex target** — writes a managed block in `~/.codex/config.toml`, updates
  `~/.codex/auth.json`, and sets `OPENAI_API_KEY` in the launchd environment.
  Blocks switching while Codex is signed in via ChatGPT to avoid clobbering.
- **Providers** — OpenAI, OpenRouter, LM Studio, Anthropic, Gemini, Ollama,
  Opencode Go, plus OpenAI-compatible and custom endpoints.
- **Per-target compatibility chips** — flags provider/target combos that won't
  work without a translating proxy (e.g. OpenAI ↔ Claude Code).
- **Curated model catalog** with a Quick Pick picker in the profile editor.
- **Test Connection** — validates a profile against the provider using its
  real auth scheme and surfaces the provider's error message on failure.
- **Snapshot & restore** — captures your original config files on first touch
  so changes can be fully rolled back.
- **DMG packaging** (`scripts/package-dmg.sh`) and tag-triggered GitHub Releases.

[Unreleased]: https://github.com/machomanrandysavageldn/llmflex/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/machomanrandysavageldn/llmflex/releases/tag/v0.1.0
