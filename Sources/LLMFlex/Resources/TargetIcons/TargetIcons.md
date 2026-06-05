# Target app icons

Brand icons for the switchable **targets** (the CLI apps themselves), shown on
each status card in the popover. These are separate from `ProviderIcons/` — those
identify a *provider* (OpenAI, Anthropic, …); these identify the *app*.

Drop a PNG here named exactly after the target's key. `TargetBadge` loads
`<key>.png` and clips it to a rounded square (cornerRadius = size × 0.22), just
like `ProviderBadge`. If a file is missing, the UI falls back to an SF Symbol —
so partial coverage is fine.

| Target      | Filename          | Fallback SF Symbol |
|-------------|-------------------|--------------------|
| Codex       | `codex.png`       | `terminal`         |
| Claude Code | `claude_code.png` | `sparkles`         |

**Requirements**

- **Format:** PNG with transparency.
- **Square**, ideally **128×128 or larger** (it renders at 18pt, but a larger
  master stays crisp on Retina). Non-square art will be letterboxed to fit.
- The art may carry its own background — it's clipped to a rounded square, so a
  full-bleed square icon looks correct (it won't be force-rounded otherwise).

After adding files: `./build.sh && open 'build/LLM Flex.app'`. No code change
needed — `TargetBadge` picks them up automatically.
