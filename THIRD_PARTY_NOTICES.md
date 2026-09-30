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

## Upstream oMLX code (Apache-2.0)

The recommended profile builds oMLX `main` @ a4048eef unmodified except for `patches/omlx-main-glm-on-stack.patch` (this recipe's changes, marked in the files) and `patches/upstream-omlx-4086-glm-toolcall-loop.patch`.
That second patch is open oMLX PR #4086 by Nikita Rodin (N1k1tung), head 07a9e459, unmodified (`git format-patch` output, author and message kept), Apache-2.0 like the rest of oMLX. It touches `omlx/api/tool_calling.py` and `tests/test_tool_calling.py`.
jonathan308's GLM-5.3 PRs, including #4026 (previously shipped here as a pinned patch), are part of that upstream commit, not redistributed separately.

## Ideas credited, no code copied

- [mlx-serve](https://github.com/ddalcu/mlx-serve) (MIT): prompt-lookup-aware MTP (#523, #533) and single-dispatch GDN decode (#517). The implementations here are independent.

## Models (not included)

This repository ships no weights. Check each model's license before use:
`dfp-official/GLM-5.3-Flash-oQ4e-mtp`, `Vontra/GLM-5.3-Flash-MLX-4bit-MTP` (MIT), and the upstream `zai-org/GLM-5.3-Flash`.
