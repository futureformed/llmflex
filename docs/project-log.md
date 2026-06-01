# Project Log — LLM Flex

Running log of work sessions. Newest entry on top. See [CLAUDE.md](../CLAUDE.md) for
architecture and build/test commands.

---

## 2026-06-01 — Project docs

- Authored `CLAUDE.md` (architecture, build/test, target write-paths, invariants).
- Created this project log, seeded from git history.
- **State at session start:** branch `main`, clean tree, **1 commit ahead of `origin`**
  (the README merge — still unpushed). All 58 `LLMFlexCore` tests pass.

**Next steps / open items:**

- Push the unpushed commit to `origin` when ready.
- No outstanding bugs or in-progress feature work recorded.

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
