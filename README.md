# GLM-5.3-Flash and Qwen3.8-Flash-Next on a Mac Studio M5 Ultra: oMLX recipe

A recipe for serving **GLM-5.3-Flash** or **Qwen3.8-Flash-Next** on one Mac Studio M5 Ultra (80-core GPU, 256 GB) with
[oMLX](https://github.com/jundot/omlx) 0.7.0rc1 plus one small patch (5 files, +491 lines).
- Output quality is unchanged: KLD against BF16 is within noise, and every gate passes.
- Every change sits behind an environment variable, so each one can be switched off to compare ([docs/ENVS.md](docs/ENVS.md)).

## Results (M5 Ultra 80c / 256 GB, macOS 27.0)

**GLM-5.3-Flash** (`dfp-official/GLM-5.3-Flash-oQ4e-mtp` + grafted MTP head):

| | stock oMLX 0.7.0rc1 | this recipe |
|---|---|---|
| decode, fresh prompt (greedy) | 42.0 tok/s | **68.4 tok/s** |
| agent edit/copy turns (return a file with a change) | 40–43 tok/s | **117–123 tok/s** |
| prefill 8K · 32K · 128K · 256K | 800 · 796 · 778 · 736 | **1,055 · 1,039 · 993 · 901** |
| decode at 128K context | 20.5 | 32.2 |
| KLD vs BF16 (decode path) · top-1 | 0.0433 · 0.927 | 0.0433 · 0.926 |
| reasoning / tool / long-context gates | 12/12 | 12/12 |

**Qwen3.8-Flash-Next** (`mlx-community/Qwen3.8-Flash-Next-oQ6e-mtp`):

| | stock oMLX 0.7.0rc1 | this recipe |
|---|---|---|
| decode, fresh prompt (greedy) | 146–150 tok/s | 147 tok/s (unchanged) |
| decode, 2K-token code prompt (T=0.6) | 118–127 tok/s | **166 tok/s** |
| agent edit/copy turns | 164–175 tok/s | **229–275 tok/s**, byte-identical greedy output |
| prefill 32K · 256K | 3,381–3,567 · ~3,310 | 3,579 · 3,321 (unchanged) |
| gates | pass | 12/12 incl. vision |

## What changes, and why

| # | Change | GLM | Qwen |
|---|---|---|---|
| 1 | **Graft GLM's missing MTP head.** `dfp-official/GLM-5.3-Flash-oQ4e-mtp` @728cc0d declares one nextn layer but ships none, so oMLX silently decodes without MTP. `scripts/graft_mtp.py` adds layer 45 from `Vontra/GLM-5.3-Flash-MLX-4bit-MTP` by symlinking the backbone, which stays byte-identical. | +56 % | n/a |
| 2 | **Fixed MTP depth** (GLM 2, Qwen 3). Each GLM verify row pulls a fresh set of 8-of-288 experts, so depth ≥3 loses at T=0.6. | +8 % code vs adaptive | ≈ adaptive (+7 % code) |
| 3 | **Prompt-lookup drafts in the MTP cycle.** When the text being written already appears in the prompt or output, the next cycle verifies that continuation (7 drafts; 14 on Qwen when the match runs ≥32 tokens). Acceptance is exact, sampling included. Idea from mlx-serve #523/#533. | 1.5–2.2× on edits | 1.3–2.2× on edits |
| 4 | **DSA indexer short-query routing.** The native scorer pads 1–8 query rows to 64. | +8 % @4K, +37 % @128K decode | n/a |
| 5 | **Compiled glue at MTP-verify shapes**: the FFN/MoE half for ≤8 rows, plus the KDA decode glue. | −6 % verify step, −4 % decode step | n/a |
| 6 | **KDA as one Metal kernel**, bit-exact against stock. Idea from mlx-serve #517. | −2.3 % decode step | n/a |
| 7 | **Prefill: flush MLX's buffer pool only above 4 GB.** oMLX rc1 flushes it after every layer (#3807), so every layer re-allocates. | **+33 % @32K, +26 % @256K**, lower peak RAM | n/a |

## Setup

Plan for about 350 GB of disk (GLM ~182 GB + 8.6 GB graft source, Qwen ~147 GB) and a 256 GB machine.

1. **Install oMLX 0.7.0rc1:** `oMLX-0.7.0rc1-macos26-27.dmg` from the [v0.7.0rc1 release](https://github.com/jundot/omlx/releases/tag/v0.7.0rc1)
   (sha256 `82c1ea4d882153bb2da5cd2793e950620b2d2eb81b2e90695272e878be79b83a`). Drag it to `/Applications`.
2. **Raise the Metal wired-memory limit** to 240 GiB (it stays set across reboots on macOS 27):
   ```bash
   sudo sysctl iogpu.wired_limit_mb=245760
   ```
3. **Build the patched tree.** This copies the app's `Contents/` to `~/omlx-m5ultra` and applies the patch. The installed app is untouched.
   ```bash
   scripts/install.sh
   ```
4. **Download the model(s)** into one folder, e.g. `~/models/mlx`. [docs/SETUP.md](docs/SETUP.md) has the pinned revisions and exact commands, including the GLM graft.
5. **Serve** one model per process:
   ```bash
   scripts/serve.sh glm
   ```
   Use `scripts/serve.sh qwen` for Qwen. Either way the server is an OpenAI-compatible endpoint at `http://127.0.0.1:8000/v1`.
   For Qwen, send `chat_template_kwargs: {"enable_thinking": false}` when you don't want thinking.

## Known issues

- **GLM vision:** image requests fail with "More images were provided than image tokens" (the checkpoint's processor). This happens on stock oMLX too.
- **Concurrency:** every speedup here is single-stream (B=1). At 2–8 simultaneous streams GLM runs at about stock speed (c=8 ≈ 103 tok/s aggregate).
- **GLM long-context retrieval:** in a 127K-token three-code needle test, runs with MTP on dropped the last code 2 times in 15, while MTP off went 11/11. Lookup is not the cause. Details in [docs/VALIDATION.md](docs/VALIDATION.md). Set `"mtp_enabled": false` if that matters more than speed.
- **GLM stop token:** the model sometimes emits `<|assistant|>` plus extra text after an answer, with or without this recipe (checkpoint template).
- **Greedy text:** GLM's greedy output is not byte-identical to plain decoding, with or without this patch, because oMLX's multi-row verify rounds differently. Qwen's is.

## Credits

See [CREDITS.md](CREDITS.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Evidence tables: [docs/RESULTS.md](docs/RESULTS.md). From-scratch validation: [docs/VALIDATION.md](docs/VALIDATION.md).

## License

The scripts, configs and docs are MIT ([LICENSE](LICENSE)). `patches/omlx-0.7.0rc1-m5ultra-p2.patch` modifies oMLX, which is Apache-2.0,
so the patch is distributed under Apache-2.0 ([licenses/omlx-Apache-2.0.txt](licenses/omlx-Apache-2.0.txt)). No model weights are included.
