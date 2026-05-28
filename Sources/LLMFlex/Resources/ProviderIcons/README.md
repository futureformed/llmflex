# Provider icons

Drop PNG files here, one per provider. When a file matching a provider is
present, `ProviderBadge` loads it instead of the fallback monogram badge.

## File spec

- **Format:** PNG with transparent background. (PDF also works if you have it.)
- **Size:** 64 × 64 pixels (square). Renders crisp at the 16–20pt sizes used
  in the UI.
- **Style:** the official brand mark for that provider — single colour or full
  colour both work. The badge is rendered as-is; no clipping or tinting is
  applied.

## File names

Names must match the `Provider` enum's raw value exactly (case sensitive):

| Provider           | Filename          |
| ------------------ | ----------------- |
| OpenAI             | `openai.png`      |
| Anthropic          | `anthropic.png`   |
| OpenRouter         | `openrouter.png`  |
| LM Studio          | `lm_studio.png`   |
| Ollama             | `ollama.png`      |
| Gemini             | `gemini.png`      |
| Opencode Go        | `opencode_go.png` |
| OpenAI-compatible  | (uses monogram)   |
| Custom             | (uses monogram)   |

## Rebuild

After dropping files in, run:

```bash
./build.sh
```

SPM picks them up via `.process("Resources")` in `Package.swift` and bundles
them into the `.app`'s resources at build time. No code changes needed.

If a file is missing or malformed, `ProviderBadge` falls back to the coloured
monogram automatically — partial coverage is fine.

## Provenance

These are third-party brand marks belonging to their respective owners.
LLM Flex displays them purely to label which provider a profile points at.
Use only the official marks you have a right to display.
