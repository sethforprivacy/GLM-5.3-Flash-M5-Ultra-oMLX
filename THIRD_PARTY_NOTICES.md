# Third-party notices

## oMLX (Apache-2.0)

`patches/omlx-0.7.0rc1-glm.patch` (and the `main` variant) modifies files of [oMLX](https://github.com/jundot/omlx) v0.7.0rc1, Copyright its authors,
licensed under the Apache License 2.0 ([licenses/omlx-Apache-2.0.txt](licenses/omlx-Apache-2.0.txt)). The patch is distributed under the same license.

Files changed by the patch (every change is marked in-code with a "Phase-2" / "p2" comment and sits behind an environment variable):

- `omlx/patches/mlx_lm_mtp/batch_generator.py`: prompt-lookup hook in the MTP chain cycle.
- `omlx/patches/mlx_vlm_glm5_next_compat/vendor/mlx_vlm/models/glm5_next/language.py`: indexer routing, compiled KDA/FFN glue, fused KDA dispatch, prefill pool policy.
- `omlx/patches/mlx_vlm_mtp/glm5_next_vlm_runtime.py`: the same hooks in the MTP runtime's copies of those paths.
- `omlx/patches/p2_lookup.py` (new): prompt-lookup drafts.
- `omlx/patches/p2_kda_fused.py` (new): single-dispatch KDA Metal kernel.

## Ideas credited, no code copied

- [mlx-serve](https://github.com/ddalcu/mlx-serve) (MIT): prompt-lookup-aware MTP (#523, #533) and single-dispatch GDN decode (#517). The implementations here are independent.

## Models (not included)

This repository ships no weights. Check each model's license before use:
`dfp-official/GLM-5.3-Flash-oQ4e-mtp`, `Vontra/GLM-5.3-Flash-MLX-4bit-MTP` (MIT), and the upstream `zai-org/GLM-5.3-Flash`.
