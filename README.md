# GLM-5.3-Flash on a Mac Studio M5 Ultra: oMLX recipe

A recipe for serving **GLM-5.3-Flash** on one Mac Studio M5 Ultra (80-core GPU, 256 GB) with [oMLX](https://github.com/jundot/omlx):
a small patch set, an MTP-head graft and the official chat template for the checkpoint.
- Output quality is unchanged: KLD against BF16 is identical, and every gate passes, **vision included**.
- Every change sits behind an environment variable, so each one can be switched off to compare ([docs/ENVS.md](docs/ENVS.md)).

Companion recipe: [Qwen3.8-Flash-Next on the same machine](https://github.com/sethforprivacy/Qwen3.8-Flash-Next-M5-Ultra-oMLX).

## Two profiles

- **Recommended: oMLX `main` built from source** (@ f0d8428a) with this recipe's patch and the upstream GLM-5.3 prefill PRs #3985/#3986/#3988, pinned as a patch.
  It needs git, Xcode and Python 3.11–3.13; the build takes ~10 minutes.
- **Alternative: the oMLX 0.7.0rc1 app (DMG)** plus this recipe's patch. Nothing to build; prefill is ~20–30 % slower and decode ~4 % slower.

## Results (M5 Ultra 80c / 256 GB, macOS 27.0, `dfp-official/GLM-5.3-Flash-oQ4e-mtp` + grafted MTP head + official template)

| | stock oMLX 0.7.0rc1 | alternative (0.7.0rc1 + patch) | **recommended (main + patch + PRs)** |
|---|---|---|---|
| decode, fresh prompt (greedy) | 42.0 tok/s | 68.4 | **71.2 tok/s** |
| decode, 2K-token code prompt | 37.8 | 61–81 | **71–91** |
| agent edit/copy turns (return a file with a change) | 40–43 | 117–123 | **119–128** |
| prefill 2K · 32K · 128K · 256K | 798 · 796 · 778 · 736 | 1,005 · 1,039 · 993 · 901 | **1,255 · 1,412 · 1,375 · 1,268** |
| warm follow-up turn at 32K | | 0.88 s | **0.51 s** |
| aggregate at 2 · 8 streams | 47 · 106 | 75 · 109 | 76 · 109 |
| KLD vs BF16: teacher-forced · decode-path | 0.0347 · 0.0433 | 0.0347 · 0.0433 | 0.0345 · 0.0427 |
| reasoning / tool / long-context / vision gates | 12/12 · pass · pass · **fail** | 12/12 · all pass | **12/12 · all pass** |

Against stock, the recommended profile gives **decode +70 % (+89–141 % on code), agent edit turns ~3×, and prefill +57 % at 2K to +77 % at 32K–128K**, with the same quality and vision fixed.

## What changes, and why

| # | Change | Effect |
|---|---|---|
| 1 | **Graft the missing MTP head.** `dfp-official/GLM-5.3-Flash-oQ4e-mtp` @728cc0d declares one nextn layer but ships none, so oMLX silently decodes without MTP. `scripts/graft_mtp.py` adds layer 45 from `Vontra/GLM-5.3-Flash-MLX-4bit-MTP` by symlinking the backbone, which stays byte-identical. | +56 % decode |
| 2 | **Fixed MTP depth 2.** Each verify row pulls a fresh set of 8-of-288 experts, so depth ≥3 loses at T=0.6. | +8 % on code vs adaptive |
| 3 | **Prompt-lookup drafts in the MTP cycle.** When the text being written already appears in the prompt or output, the next cycle verifies that continuation (up to 7 drafts) with exact acceptance, sampling included. Idea from mlx-serve #523/#533. | 1.5–2.2× on edit turns, flat elsewhere |
| 4 | **DSA indexer short-query routing.** The native scorer pads 1–8 query rows to 64. | +8 % decode @4K, +37 % @128K |
| 5 | **Compiled glue at MTP-verify shapes**: the FFN/MoE half for ≤8 rows, plus the KDA decode glue. | −6 % verify step, −4 % decode step |
| 6 | **KDA as one Metal kernel**, bit-exact against stock. Idea from mlx-serve #517. | −2.3 % decode step |
| 7 | **Prefill: flush MLX's buffer pool only above 4 GB.** oMLX flushes it after every prefill layer (#3807), so every layer re-allocates. | **+33 % @32K, +26 % @256K** on rc1; +10 % @128K on top of the PRs |
| 8 | **Official chat template** (zai-org, pinned) instead of dfp's text-only one, which breaks every image request. | **vision works** |
| 9 | **Batched decode:** HyperConnection mix as a batched matvec (MLX's GEMM is 5.5× slower at N=24 for 2+ rows), fused KDA and FFN compile for B>1. | c=2 +16 %, c=8 +6 % |
| 10 | *(recommended profile)* **Upstream PRs #3985/#3986/#3988** by jonathan308 (open at the time of writing): tensor-unit DSA indexer and sparse-MLA prefill kernels, plus 8K prefill chunks on NAX hosts. | prefill +11–21 %, no taper with context |
| 11 | *(recommended profile)* **HyperConnection pre-mix in two dispatches.** The decoder ran 5–8 small kernels per HC, 90× per step. mlx-vlm's one-dispatch kernel for this rejects GLM's fp32 mix weight; we feed it fp32 and split the mix across 24 threadgroups. Bit-exact at one row. | decode step −5 %, verify step −6 %; agent turns +5–13 % |
| 12 | *(recommended profile)* **KDA prefill reads q/k/v in place.** The prefill copied q/k/v out of the fused in-projection (~400 MB per layer per 8K chunk) only to give a kernel contiguous rows; it now reads them with a row stride. Bit-exact. | prefill +7–14 % |
| 13 | *(recommended profile)* **Faster KDA prefill recurrence:** 16 state elements per thread and 8-lane reductions instead of 4 and 32, so shuffles stop dominating. | recurrence 2.3× faster; prefill +4–6 % more |

## Setup (recommended profile)

Plan for about 200 GB of disk (the ~182 GB backbone plus 8.6 GB of graft source).

1. **Raise the Metal wired-memory limit** to 240 GiB:
   ```bash
   sudo sysctl iogpu.wired_limit_mb=245760
   ```
2. **Build patched oMLX `main`.** This clones oMLX into `~/omlx-glm-src`, applies both patches, builds the native kernels, and checks that they all load.
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
- **Concurrency:** prompt lookup and most kernels are single-stream. Batched decode gets the B>1 fixes (row 9): about 73–75 tok/s at 2 streams and 108 at 8.
- **Greedy text** is not byte-identical to plain decoding, with or without this patch, because oMLX's multi-row verify rounds differently.
- **The recommended profile builds on unmerged upstream PRs.** They're pinned in `patches/upstream-omlx-prs-3985-3986-3988.patch`. When oMLX releases with them merged, the recipe will move to that release.

## Credits and license

See [CREDITS.md](CREDITS.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Evidence tables: [docs/RESULTS.md](docs/RESULTS.md). From-scratch validation: [docs/VALIDATION.md](docs/VALIDATION.md).

The scripts, configs and docs are MIT ([LICENSE](LICENSE)). The patches modify oMLX, which is Apache-2.0, so they are distributed under Apache-2.0
([licenses/omlx-Apache-2.0.txt](licenses/omlx-Apache-2.0.txt)). No model weights are included.
