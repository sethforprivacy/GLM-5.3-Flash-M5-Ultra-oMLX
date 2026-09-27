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
- `omlx/patches/p2_hc_fused.py` (new, `main` patch only): two-dispatch HyperConnection pre-mix (see mlx-vlm below).
- `omlx/patches/glm53_kda_prework.py` (`main` patch only): the KDA prefill prework reads q/k/v in place with a row stride.
- `omlx/patches/mlx_vlm_glm5_next_compat/vendor/mlx_vlm/models/glm5_next/gated_delta.py` (`main` patch only): prefill recurrence variant.

## Upstream oMLX pull requests (Apache-2.0)

`patches/upstream-omlx-prs-3985-3986-3988.patch` is the unmodified combined diff of three open oMLX pull requests by jonathan308, as merged onto f0d8428a:
[#3985](https://github.com/jundot/omlx/pull/3985) @ c5413b9a, [#3986](https://github.com/jundot/omlx/pull/3986) @ 8ac5aa9a and [#3988](https://github.com/jundot/omlx/pull/3988) @ d73f689d.
They are contributions to oMLX under its Apache-2.0 license and are redistributed here unchanged.

## mlx-vlm (MIT)

`omlx/patches/p2_hc_fused.py` calls mlx-vlm's `exact_hc_norm` kernel, and its mix kernel adapts the RMS and dot-product reduction structure of
mlx-vlm's `short_block_hc_normalized_norm` kernel (`mlx_vlm/models/fast_ops.py`, mlx-vlm 0.7.1), so that the results stay bit-identical to it.
[mlx-vlm](https://github.com/Blaizzy/mlx-vlm) is Copyright © 2025 Prince Canuma and its contributors, under the MIT License ([licenses/mlx-vlm-MIT.txt](licenses/mlx-vlm-MIT.txt)).

## Ideas credited, no code copied

- [mlx-serve](https://github.com/ddalcu/mlx-serve) (MIT): prompt-lookup-aware MTP (#523, #533) and single-dispatch GDN decode (#517). The implementations here are independent.

## Models (not included)

This repository ships no weights. Check each model's license before use:
`dfp-official/GLM-5.3-Flash-oQ4e-mtp`, `Vontra/GLM-5.3-Flash-MLX-4bit-MTP` (MIT), and the upstream `zai-org/GLM-5.3-Flash`.
