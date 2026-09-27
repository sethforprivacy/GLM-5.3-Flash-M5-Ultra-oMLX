# Changelog

## 2026-09-26: first release

- oMLX 0.7.0rc1 patch (5 files): prompt-lookup MTP drafts, GLM DSA indexer short-query routing, compiled FFN/KDA glue at verify shapes,
  bit-exact single-dispatch KDA kernel, and the GLM prefill pool-flush policy.
- GLM-5.3-Flash MTP-head graft (`scripts/graft_mtp.py`), fixed MTP depths (GLM 2, Qwen 3).
- Validated from scratch on a Mac Studio M5 Ultra 256 GB (docs/VALIDATION.md).
- Upstream reports: jundot/omlx#3998, #3999, #4000; mlx-serve #533, #517 comments.
