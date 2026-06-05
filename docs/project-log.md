# Project Log — LLM Flex

Running log of work sessions. Newest entry on top. See [CLAUDE.md](../CLAUDE.md) for
architecture and build/test commands.

---

## 2026-06-01 — First public alpha (v0.1.0) + release pipeline

Shipped the first public alpha and the infrastructure to keep shipping:

- **Versioning** — single-source `VERSION` file (`0.1.0`); `build.sh` bakes it into
  `CFBundleShortVersionString` and uses `git rev-list --count` for a monotonic
  `CFBundleVersion`. Env override `LLMFLEX_VERSION` lets CI pass the tag.
- **DMG packaging** — `scripts/package-dmg.sh` (pure `hdiutil`, no deps): builds the
  app, stages it with an Applications symlink, emits `build/LLM-Flex-<version>.dmg`.
- **GitHub Releases** — `.github/workflows/release.yml` fires on `v*` tags: tests →
  DMG → `gh release create` (pre-release for `0.x`, notes pulled from CHANGELOG).
- **CHANGELOG.md** (Keep a Changelog), seeded with 0.1.0.
- **README** — download/install with the Gatekeeper workaround (ad-hoc signed,
  not notarized) and a releasing guide.
- Verified the full pipeline: built the DMG locally (mounts/verifies clean), then
  tagged `v0.1.0` → CI ran green in 57s →
  [Release published](https://github.com/futureformed/llmflex/releases/tag/v0.1.0)
  with the DMG attached.

**Open items / follow-ups:**

- **arm64-only build.** Both the local Mac and the `macos-latest` CI runner are
  Apple Silicon, so the DMG won't run on Intel Macs. If testers need Intel, make
  the binary universal: `swift build -c release --arch arm64 --arch x86_64`.
- **No notarization** — testers hit a Gatekeeper warning (documented). Needs a paid
  Apple Developer ID to remove; out of scope for alpha.
- CI annotation: `actions/checkout@v4` runs on Node 20 (deprecated June 2026). Bump
  when convenient.
- Possible nicety: surface the app version inside the menu-bar UI so testers can
  report which build they're on (currently only in Info.plist).

## 2026-06-01 — Project docs

- Authored `CLAUDE.md` (architecture, build/test, target write-paths, invariants).
- Created this project log, seeded from git history.
- Pushed the previously-unpushed README-merge commit; `main` synced with `origin`.

---

## History (reconstructed from git, all 2026-05-28)

The project was built and substantially polished in a single day. Phased build:

1. **Scaffold** — SPM project, two targets (`LLMFlexCore` + `LLMFlex`), `build.sh`.
2. **Core logic + tests** — `Target` protocol, `CodexTarget`, snapshot/restore,
   profiles in UserDefaults, API keys in Keychain, TOML block editor.
3. **UI** — SwiftUI menu-bar popover, profile editor, status section.
4. **Codex hardening** — mockable launchd env, orphan `[env]` fix, snapshot cleanup,
   ChatGPT-login block.
5. **Providers + catalog** — added OpenAI, LM Studio, Anthropic, Gemini, Opencode Go,
   OpenRouter (top 20); curated `ModelCatalog` with a Quick Pick picker; compatibility
   chips; base-URL auto-swap on provider change.
6. **Claude Code target** — `ClaudeCodeTarget` (writes `~/.claude/settings.json`),
   target-aware provider compatibility, wired into the UI.
7. **Claude Code / connectivity fixes** — strip `/vN` from `ANTHROPIC_BASE_URL`; set
   only one of `ANTHROPIC_AUTH_TOKEN`/`ANTHROPIC_API_KEY`; trim keys; Test Connection
   uses the provider's real auth scheme and surfaces provider error messages;
   `.withoutEscapingSlashes` on JSON writes.
8. **Visual pass + UX** — dark-purple accent, green active state, larger text, provider
   badges/icons loaded from the bundle root; editor opens in a standalone window that
   survives clicking away; fixed back/cancel buttons.
9. **Repo hygiene** — initial commit, README merge, ignore local Claude Code settings.
