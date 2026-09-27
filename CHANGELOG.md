# Changelog

## 2026-09-27 (night): recommended profile v3

- **The recommended build is now oMLX `main` + jonathan308's open GLM-5.3 PR stack (16 PRs, pinned in `patches/upstream-omlx-glm53-stack.patch`) + a small recipe patch**
  (`patches/omlx-main-glm-on-stack.patch`: prompt-lookup MTP, batched HC mix for 2+ streams). Validated from scratch; the PRs' 424 GLM tests pass.
- Prefill 1,939 · 2,211 · 2,292 · 2,103 · 1,905 tok/s at 2K–256K (v2: 1,255 · 1,335 · 1,412 · 1,375 · 1,268), fresh decode 77–79 (71), agent edit turns 133–144 (119–128), c=8 115 (109).
- v2's HC fusion, KDA no-concat and KDA recurrence patches are dropped: upstream #4026 and #3984 cover the same ground, further along.
- KLD: identical to stock in exact fp32. At MLX defaults the decode-path panel reads 0.0482 against 0.0433, bisected to #3983 computing the HC mix in exact fp32 instead of TF32 (README, Quality).

## 2026-09-27 (evening)

- **Recommended profile v2 (milestone 4):** three more patches on oMLX `main`, all env-gated and validated from scratch:
  two-dispatch HyperConnection pre-mix (`OMLX_P2_HC_FUSED`, bit-exact at one row), KDA prefill reading q/k/v in place (`OMLX_P2_KDA_NOCONCAT`, bit-exact),
  and a faster KDA prefill recurrence (`OMLX_P2_KDA_REC_DKT=16`).
  Prefill 1,255 · 1,335 · 1,412 · 1,375 · 1,268 tok/s at 2K–256K (was 1,219 · 1,213 · 1,245 · 1,265 · 1,196), fresh decode 71.2 (was 68.9), agent edit turns 119–128 (were 114–121), KLD unchanged, all gates pass.
- The DMG alternative is unchanged; these three need oMLX `main`.

## 2026-09-27 (later)

- **New recommended profile (milestone 3):** oMLX `main` @ f0d8428a from source + recipe patch + upstream PRs #3985/#3986/#3988 (pinned patch), built by `scripts/install.sh` and served by `scripts/serve.sh`. Prefill 1,224–1,264 tok/s from 2K to 256K, decode 68.8 / 81.5, all gates pass, KLD identical.
- The 0.7.0rc1 DMG route becomes the no-build alternative: `scripts/install-dmg.sh`, `scripts/serve-dmg.sh`.

## 2026-09-27

- **Vision fixed:** the graft installs the official zai-org chat template (rev eb9eb208). dfp's template is text-only and turned every image into an "unable to process" reminder. All gates pass, vision included.
- **Batched decode:** HyperConnection mix as a batched matvec (MLX GEMM trap at N=24), fused KDA kernel for B≤4 (bit-exact), FFN compile at B·S ≤ 8. Served c=2 64.7 → 75.3, c=8 103.4 → 109.2. KLD neutral.
- Lookup gate fix: the first timed cycle at each new verify width is kept out of the tokens/s EMAs. It pays one-off Metal kernel compilation, and one such cold sample had gated short-match lookups off for most of a request (a Qwen edit task measured 242 vs 275 tok/s with identical output). Gate decisions only; output is unchanged.
- Split out of the combined M5 Ultra recipe into one repository per model (this one is GLM-5.3-Flash).
  Companion: https://github.com/sethforprivacy/Qwen3.8-Flash-Next-M5-Ultra-oMLX
- Patch rebased onto oMLX `main` @ f0d8428a (`patches/omlx-main-f0d8428a-glm.patch`, docs/OMLX-MAIN.md). With upstream's #3944 it gives prefill 1,121 / 1,086 tok/s @8K / 32K. KLD is identical and the gates pass.
- Long-context retrieval repeat test added to VALIDATION.md (2 misses in 15 with MTP on, 0/11 off; not lookup).

## 2026-09-26: first release

- oMLX 0.7.0rc1 patch (5 files): prompt-lookup MTP drafts, DSA indexer short-query routing, compiled FFN/KDA glue at verify shapes,
  bit-exact single-dispatch KDA kernel, and the prefill pool-flush policy.
- MTP-head graft for `dfp-official/GLM-5.3-Flash-oQ4e-mtp` (`scripts/graft_mtp.py`), fixed MTP depth 2.
- Validated from scratch on a Mac Studio M5 Ultra 256 GB (docs/VALIDATION.md).
- Upstream reports: jundot/omlx#3998, #3999, #4000; mlx-serve #533, #517 comments.
