# Third-party notices

## oMLX (Apache-2.0)

`patches/omlx-0.7.0rc1-glm.patch` (DMG profile) and `patches/omlx-main-glm-on-stack.patch` (recommended profile) modify files of [oMLX](https://github.com/jundot/omlx), Copyright its authors,
licensed under the Apache License 2.0 ([licenses/omlx-Apache-2.0.txt](licenses/omlx-Apache-2.0.txt)). The patch is distributed under the same license.

Every change is marked in-code with a "Phase-2" / "p2" comment and sits behind an environment variable.

`patches/omlx-main-glm-on-stack.patch` (applies after the upstream stack below):
- `omlx/patches/mlx_lm_mtp/batch_generator.py`: prompt-lookup hook in the MTP chain cycle.
- `omlx/patches/p2_lookup.py` (new): prompt-lookup drafts.
- `omlx/patches/mlx_vlm_glm5_next_compat/vendor/mlx_vlm/models/glm5_next/language.py`: batched HyperConnection mix for B>1.

`patches/omlx-0.7.0rc1-glm.patch`:
- `omlx/patches/mlx_lm_mtp/batch_generator.py` and `omlx/patches/p2_lookup.py` (new): as above.
- `omlx/patches/mlx_vlm_glm5_next_compat/vendor/mlx_vlm/models/glm5_next/language.py`: indexer routing, compiled KDA/FFN glue, fused KDA dispatch, prefill pool policy, batched HC mix.
- `omlx/patches/mlx_vlm_mtp/glm5_next_vlm_runtime.py`: the same hooks in the MTP runtime's copies of those paths.
- `omlx/patches/p2_kda_fused.py` (new): single-dispatch KDA Metal kernel.

## Upstream oMLX pull requests (Apache-2.0)

`patches/upstream-omlx-glm53-stack.patch` is the combined diff of sixteen open oMLX pull requests by jonathan308, merged onto f0d8428a in this order:
#3970 fba85855, #3974 f4ce2735, #3971 b42d94b2, #3983 7d925bd9, #3984 52c78b1f, #3985 eb59da9b, #3986 8ac5aa9a, #3987 5fbc4927, #3988 d73f689d,
#3993 a68cab68, #3995 97e473ef, #3996 03e9b678, #4022 d6dbc997, #4025 9eeaf899, #4029 498685ba, #4026 e886b410 (contains #3989 and #4019).
They are contributions to oMLX under its Apache-2.0 license and are redistributed unchanged, except for the merge of #4026 with #3971:
both edit the per-layer loop of `Glm5NextModel.__call__` and of the MTP runtime's copy, and the resolution keeps both (the prefill layer pipeline and the decode early-eval / deferred-HC scheduling).

## Ideas credited, no code copied

- [mlx-serve](https://github.com/ddalcu/mlx-serve) (MIT): prompt-lookup-aware MTP (#523, #533) and single-dispatch GDN decode (#517). The implementations here are independent.

## Models (not included)

This repository ships no weights. Check each model's license before use:
`dfp-official/GLM-5.3-Flash-oQ4e-mtp`, `Vontra/GLM-5.3-Flash-MLX-4bit-MTP` (MIT), and the upstream `zai-org/GLM-5.3-Flash`.
