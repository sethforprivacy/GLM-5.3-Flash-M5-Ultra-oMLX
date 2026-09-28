# GLM-5.3-Flash on a Mac Studio M5 Ultra: oMLX recipe

A recipe for serving **GLM-5.3-Flash** on one Mac Studio M5 Ultra (80-core GPU, 256 GB) with [oMLX](https://github.com/jundot/omlx):
an MTP-head graft and the official chat template for the checkpoint, plus a pinned build of oMLX `main`.

- **The build:** oMLX `main`, which since 2026-09-28 includes jonathan308's GLM-5.3 prefill PRs (most of the speed). On top go his open decode PR #4026 and a small patch of ours.
- **Quality:** unchanged. KLD against BF16 is identical to stock oMLX computed in exact fp32 ([Quality](#quality)), and every gate passes, **vision included**.

Companion recipe: [Qwen3.8-Flash-Next on the same machine](https://github.com/sethforprivacy/Qwen3.8-Flash-Next-M5-Ultra-oMLX).

## Two profiles

- **Recommended: oMLX `main` built from source** (@ a98d8c8c), in three layers:
  - jonathan308's open decode/verify PR #4026, pinned as one patch;
  - this recipe's patch: prompt-lookup MTP drafts and the batched HC mix for 2+ streams;
  - the MTP graft and the official template.

  It needs git, Xcode and Python 3.11–3.13. The build takes ~10 minutes.
- **Alternative: the oMLX 0.7.0rc1 app (DMG)** plus this recipe's rc1 patch. There's nothing to build, but prefill is about half as fast.

## Results (M5 Ultra 80c / 256 GB, macOS 27.0, `dfp-official/GLM-5.3-Flash-oQ4e-mtp` + grafted MTP head + official template)

| | stock oMLX 0.7.0rc1 | alternative (0.7.0rc1 + patch) | **recommended** |
|---|---|---|---|
| decode, fresh prompt (greedy) | 42.0 tok/s | 68.4 | **79–81 tok/s** |
| decode, 2K-token code prompt | 37.8 | 61–81 | **80** |
| agent edit/copy turns (return a file with a change, T=0 · T=0.6) | 40–43 | 117–123 | **133–145 · 123–143** |
| prefill 2K · 32K · 128K · 256K | 798 · 796 · 778 · 736 | 1,005 · 1,039 · 993 · 901 | **1,990 · 2,233 · 2,183 · 2,024** |
| warm follow-up turn at 8K · 32K | | 0.71 · 0.88 s | **0.42 · 0.55 s** |
| aggregate at 1 · 2 · 4 · 8 streams | 41 · 47 · 75 · 106 | 68 · 75 · 92 · 109 | **83 · 79 · 102 · 114** |
| reasoning / tool / long-context / vision gates | 12/12 · pass · pass · **fail** | 12/12 · all pass | **12/12 · all pass** |

Against stock, the recommended profile gives **decode +88–112 %, agent edit turns ~3.4×, and prefill 2.5–2.8×**, with vision fixed.
A 128K-token prompt is read in ~60 s, against ~168 s on stock.

## Quality

KLD against BF16 teacher logits (`brandonmusic/GLM-5.3-Flash-BF16-Teacher-Logits`), full vocabulary:

| | teacher-forced (top-1) | decode-path, 1-token steps (top-1) |
|---|---|---|
| stock oMLX `main`, MLX defaults (TF32 matmuls) | 0.0347 (0.9416) | 0.0433 (0.9272) |
| stock oMLX `main`, exact fp32 (`MLX_ENABLE_TF32=0`) | 0.0345 (0.9411) | 0.0482 (0.9246) |
| **recommended**, MLX defaults | 0.0361 (0.9405) | 0.0482 (0.9229) |
| **recommended**, exact fp32 | 0.0345 (0.9411) | 0.0482 (0.9246) |

- **In exact fp32 the recommended build and stock are identical.** The one change against stock at MLX defaults comes from upstream PR #3983 (bisected).
- **Why:** #3983 computes the HyperConnection mix in exact fp32. Stock runs that mix as an fp32 matmul, which MLX executes in TF32 on M5, and TF32's rounding happens to sit closer to this BF16 teacher on the decode-path panel.
- **Other checks:** reasoning (12/12) and every qualify gate pass either way.

## What changes, and why

| # | Change | Effect |
|---|---|---|
| 1 | **Graft the missing MTP head.** `dfp-official/GLM-5.3-Flash-oQ4e-mtp` @728cc0d declares one nextn layer but ships none, so oMLX silently decodes without MTP. `scripts/graft_mtp.py` adds layer 45 from `Vontra/GLM-5.3-Flash-MLX-4bit-MTP` by symlinking the backbone, which stays byte-identical. | +56 % decode |
| 2 | **Fixed MTP depth 2.** Each verify row pulls a fresh set of 8-of-288 experts, so depth ≥3 loses at T=0.6. | +8 % on code vs adaptive |
| 3 | **Official chat template** (zai-org, pinned) instead of dfp's text-only one, which breaks every image request. | **vision works** |
| 4 | *(recommended)* **jonathan308's GLM-5.3 performance PRs** ([CREDITS.md](CREDITS.md)). Prefill gets pipelined layers, fused HC prefill kernels, a per-core KDA recurrence, tensor-unit indexer and sparse MLA, 8K chunks, and fused MoE gate/up with NAX gather tiles; these are in oMLX `main` since 2026-09-28. Decode and MTP verify get exact fused kernels from the still-open #4026. | prefill 2.4–2.9× stock; fresh decode 69 → 82 tok/s |
| 5 | **Prompt-lookup drafts in the MTP cycle** (`OMLX_P2_LOOKUP`). When the text being written already appears in the prompt or output, the next cycle verifies that continuation (up to 7 drafts) with exact acceptance, sampling included. The idea comes from mlx-serve #523/#533. | edit/JSON/fix turns +40–53 %, flat elsewhere |
| 6 | **Batched HC mix for 2+ streams** (`OMLX_P2_HC_GEMV`). MLX's fp32 GEMM is 5.5× slower than a matvec at N=24 for 2+ rows. | c=2 +14 %, c=4 +11 % |
| 7 | *(DMG profile only)* The rc1-era decode and prefill patches: indexer routing, compiled glue, a fused KDA kernel, and a prefill pool policy ([docs/ENVS.md](docs/ENVS.md)). On `main` the upstream stack supersedes them. | |

## Setup (recommended profile)

Plan for about 200 GB of disk (the ~182 GB backbone plus 8.6 GB of graft source).

1. **Raise the Metal wired-memory limit** to 240 GiB:
   ```bash
   sudo sysctl iogpu.wired_limit_mb=245760
   ```
2. **Build patched oMLX `main`.** This clones oMLX into `~/omlx-glm-src`, applies #4026 and this recipe's patch, builds the native kernels, and checks that they all load.
   ```bash
   scripts/install.sh
   ```
3. **Download the model and graft it.** [docs/SETUP.md](docs/SETUP.md) has the pinned revisions and exact commands; the graft also installs the official chat template.
4. **Serve:**
   ```bash
   scripts/serve.sh
   ```
   The server is an OpenAI-compatible endpoint at `http://127.0.0.1:8000/v1`.

## Setup (alternative: oMLX 0.7.0rc1 DMG, no build)

1. Install `oMLX-0.7.0rc1-macos26-27.dmg` from the [v0.7.0rc1 release](https://github.com/jundot/omlx/releases/tag/v0.7.0rc1)
   (sha256 `82c1ea4d882153bb2da5cd2793e950620b2d2eb81b2e90695272e878be79b83a`) and raise the wired limit as above.
2. Run `scripts/install-dmg.sh`. It copies the app's `Contents/` to `~/omlx-glm-m5ultra` and applies `patches/omlx-0.7.0rc1-glm.patch`; the installed app is untouched.
3. Download and graft the model as in step 3 above.
4. Serve with `scripts/serve-dmg.sh`.

## Known issues

- **Leave room for a little reasoning:** even at `reasoning_effort: low`, GLM sometimes reasons ~100–250 tokens before answering. With a 128-token cap, a 127K-context recall test occasionally ran out of budget mid-answer. At 512 tokens it passed 10/10 with MTP on. Don't set `max_tokens` very low.
- **Stop token:** the model sometimes emits `<|assistant|>` plus extra text after an answer, with or without this recipe (checkpoint template).
- **Concurrency:** prompt lookup and the fused decode kernels are single-stream. 2+ streams run the batched path, 79–115 tok/s aggregate.
- **Greedy text** is not byte-identical to plain decoding, with or without this recipe, because multi-row MTP verify rounds differently.
- **The recommended profile builds on oMLX `main` plus one unmerged PR** (#4026, pinned in `patches/upstream-omlx-glm53-4026.patch` at the head listed in [CREDITS.md](CREDITS.md)). As it merges, the recipe will move to an oMLX release that contains it.

## Credits and license

See [CREDITS.md](CREDITS.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Evidence tables: [docs/RESULTS.md](docs/RESULTS.md). From-scratch validation: [docs/VALIDATION.md](docs/VALIDATION.md).

The scripts, configs and docs are MIT ([LICENSE](LICENSE)). The patches modify oMLX, which is Apache-2.0, so they are distributed under Apache-2.0
([licenses/omlx-Apache-2.0.txt](licenses/omlx-Apache-2.0.txt)). No model weights are included.
