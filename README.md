# GLM-5.3-Flash on a Mac Studio M5 Ultra: oMLX recipe

A recipe for serving **GLM-5.3-Flash** on one Mac Studio M5 Ultra (80-core GPU, 256 GB) with [oMLX](https://github.com/jundot/omlx) 0.7.0rc1,
one small patch (5 files) and an MTP-head graft for the checkpoint.
- Output quality is unchanged: KLD against BF16 is identical, and every gate that passes on stock passes here.
- Every change sits behind an environment variable, so each one can be switched off to compare ([docs/ENVS.md](docs/ENVS.md)).

Companion recipe: [Qwen3.8-Flash-Next on the same machine](https://github.com/sethforprivacy/Qwen3.8-Flash-Next-M5-Ultra-oMLX).

## Results (M5 Ultra 80c / 256 GB, macOS 27.0, `dfp-official/GLM-5.3-Flash-oQ4e-mtp` + grafted MTP head)

| | stock oMLX 0.7.0rc1 | this recipe |
|---|---|---|
| decode, fresh prompt (greedy) | 42.0 tok/s | **68.4 tok/s** |
| agent edit/copy turns (return a file with a change) | 40–43 tok/s | **117–123 tok/s** |
| prefill 8K · 32K · 128K · 256K | 800 · 796 · 778 · 736 | **1,055 · 1,039 · 993 · 901** |
| decode at 128K context | 20.5 | 32.2 |
| KLD vs BF16: teacher-forced · decode-path | 0.0347 · 0.0433 | 0.0347 · 0.0433 |
| reasoning / tool / long-context gates | 12/12 | 12/12 |

On oMLX `main` built from source, prefill reaches 1,121 / 1,086 tok/s at 8K / 32K ([docs/OMLX-MAIN.md](docs/OMLX-MAIN.md)).

## What changes, and why

| # | Change | Effect |
|---|---|---|
| 1 | **Graft the missing MTP head.** `dfp-official/GLM-5.3-Flash-oQ4e-mtp` @728cc0d declares one nextn layer but ships none, so oMLX silently decodes without MTP. `scripts/graft_mtp.py` adds layer 45 from `Vontra/GLM-5.3-Flash-MLX-4bit-MTP` by symlinking the backbone, which stays byte-identical. | +56 % decode |
| 2 | **Fixed MTP depth 2.** Each verify row pulls a fresh set of 8-of-288 experts, so depth ≥3 loses at T=0.6. | +8 % on code vs adaptive |
| 3 | **Prompt-lookup drafts in the MTP cycle.** When the text being written already appears in the prompt or output, the next cycle verifies that continuation (up to 7 drafts) with exact acceptance, sampling included. Idea from mlx-serve #523/#533. | 1.5–2.2× on edit turns, flat elsewhere |
| 4 | **DSA indexer short-query routing.** The native scorer pads 1–8 query rows to 64. | +8 % decode @4K, +37 % @128K |
| 5 | **Compiled glue at MTP-verify shapes**: the FFN/MoE half for ≤8 rows, plus the KDA decode glue. | −6 % verify step, −4 % decode step |
| 6 | **KDA as one Metal kernel**, bit-exact against stock. Idea from mlx-serve #517. | −2.3 % decode step |
| 7 | **Prefill: flush MLX's buffer pool only above 4 GB.** oMLX rc1 flushes it after every layer (#3807), so every layer re-allocates. | **+33 % @32K, +26 % @256K**, lower peak RAM |

## Setup

Plan for about 200 GB of disk (the ~182 GB backbone plus 8.6 GB of graft source).

1. **Install oMLX 0.7.0rc1:** `oMLX-0.7.0rc1-macos26-27.dmg` from the [v0.7.0rc1 release](https://github.com/jundot/omlx/releases/tag/v0.7.0rc1)
   (sha256 `82c1ea4d882153bb2da5cd2793e950620b2d2eb81b2e90695272e878be79b83a`). Drag it to `/Applications`.
2. **Raise the Metal wired-memory limit** to 240 GiB:
   ```bash
   sudo sysctl iogpu.wired_limit_mb=245760
   ```
3. **Build the patched tree.** This copies the app's `Contents/` to `~/omlx-glm-m5ultra` and applies the patch. The installed app is untouched.
   ```bash
   scripts/install.sh
   ```
4. **Download and graft the model.** [docs/SETUP.md](docs/SETUP.md) has the pinned revisions and exact commands.
5. **Serve:**
   ```bash
   scripts/serve.sh
   ```
   The server is an OpenAI-compatible endpoint at `http://127.0.0.1:8000/v1`.

## Known issues

- **Vision:** image requests fail with "More images were provided than image tokens" (the checkpoint's processor). This happens on stock oMLX too.
- **Long-context retrieval with MTP:** in a 127K-token three-code needle test, runs with MTP on dropped the last code 2 times in 15, while MTP off went 11/11. Prompt lookup is not the cause. Details in [docs/VALIDATION.md](docs/VALIDATION.md). Set `"mtp_enabled": false` if that matters more than speed.
- **Stop token:** the model sometimes emits `<|assistant|>` plus extra text after an answer, with or without this recipe (checkpoint template).
- **Concurrency:** every speedup here is single-stream (B=1). At 2–8 simultaneous streams it runs at about stock speed (c=8 ≈ 103 tok/s aggregate).
- **Greedy text** is not byte-identical to plain decoding, with or without this patch, because oMLX's multi-row verify rounds differently.

## Credits and license

See [CREDITS.md](CREDITS.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Evidence tables: [docs/RESULTS.md](docs/RESULTS.md). From-scratch validation: [docs/VALIDATION.md](docs/VALIDATION.md).

The scripts, configs and docs are MIT ([LICENSE](LICENSE)). The patches modify oMLX, which is Apache-2.0, so they are distributed under Apache-2.0
([licenses/omlx-Apache-2.0.txt](licenses/omlx-Apache-2.0.txt)). No model weights are included.
