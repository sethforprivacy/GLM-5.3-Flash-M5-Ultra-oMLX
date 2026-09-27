# Changelog

## 2026-09-27

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
