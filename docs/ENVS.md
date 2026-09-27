# Environment toggles

Every change is an environment variable read at server start. Unset means stock oMLX 0.7.0rc1 behaviour.

| Variable | Recipe value | Stock | What it does | Evidence |
|---|---|---|---|---|
| `OMLX_GLM_INDEXER_MLX_MAX_ROWS` | `8` | (patch default 8; `0` = stock) | DSA indexer queries of ≤ N rows (decode, MTP verify) use oMLX's own MLX scoring path instead of the native kernel, which pads to 64 rows. | +8 % decode @4K, +37 % @128K; decode-path KLD identical |
| `OMLX_GLM_COMPILE_KDA` | `1` | `0` | Compiles the KDA decode glue around the recurrence. With `OMLX_GLM_KDA_FUSED=1` it only still applies to layers with mixed-bit in-projections (layer 40 on oQ4e). | −4.4 % step |
| `OMLX_GLM_KDA_FUSED` | `1` | `0` | Runs the whole KDA prework + recurrence as one Metal kernel (B=1, ≤8 rows). Bit-exact against stock. | −2.3 % step; KLD 0.0433 = stock |
| `OMLX_GLM_COMPILE_FFN_MAX_S` | `8` | `1` | Compiles the FFN/MoE half for B=1 up to N rows, so it covers MTP verify blocks. | −6.3 % per verify step; verify-block KLD identical |
| `OMLX_P2_LOOKUP` | `1` | `0` | Prompt-lookup drafts in the MTP cycle (8-gram match, up to 7 drafts, exact acceptance, gated against MTP). | 1.5–2.2× on edit/copy turns, flat on prose |
| `OMLX_GLM_PREFILL_SYNC` | `cache:4` | `layer` | Per-layer prefill eval as stock, but the MLX buffer pool is flushed only when it holds > 4 GB. | +33 % prefill @32K, +26 % @256K, lower peak RAM |

Model settings (`configs/model_settings.glm.json`, installed by `scripts/serve.sh`): MTP on, fixed depth 2.

Tuning knobs, left at their defaults: `OMLX_P2_LOOKUP_NGRAM` (8), `OMLX_P2_LOOKUP_MAX` (7; keep ≤7: GLM's indexer cache can undo at most an 8-row verify block), `OMLX_P2_LOOKUP_MAX_LONG` (same as MAX),
`OMLX_P2_LOOKUP_LONG` (32), `OMLX_P2_LOOKUP_GATE` (1).
