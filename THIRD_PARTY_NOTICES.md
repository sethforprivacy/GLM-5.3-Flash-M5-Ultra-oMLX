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

## Upstream oMLX pull request (Apache-2.0)

`patches/upstream-omlx-glm53-4026.patch` is jonathan308's open pull request [#4026](https://github.com/jundot/omlx/pull/4026) (head 8e150d98, which contains #3989 and #4019), merged onto oMLX `main` @ a98d8c8c.
It is a contribution to oMLX under its Apache-2.0 license and is redistributed unchanged, except for the merge with #3971, which `main` already has. Both edit the per-layer loop of `Glm5NextModel.__call__` and of the MTP runtime's copy. The resolution keeps both: the prefill layer pipeline, and decode's early eval / deferred HC.

## Ideas credited, no code copied

- [mlx-serve](https://github.com/ddalcu/mlx-serve) (MIT): prompt-lookup-aware MTP (#523, #533) and single-dispatch GDN decode (#517). The implementations here are independent.

## Models (not included)

This repository ships no weights. Check each model's license before use:
`dfp-official/GLM-5.3-Flash-oQ4e-mtp`, `Vontra/GLM-5.3-Flash-MLX-4bit-MTP` (MIT), and the upstream `zai-org/GLM-5.3-Flash`.
