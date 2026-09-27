# Credits

This recipe stands on other people's public work. Please credit them when reusing it.

- **oMLX** by Jun Kim and contributors: [jundot/omlx](https://github.com/jundot/omlx), Apache-2.0. This is the engine, and every patch here modifies its files.
  Tested base: v0.7.0rc1. Our change 6 revisits the per-layer pool flush from [#3807](https://github.com/jundot/omlx/pull/3807)
  (williamxyl), keeping its memory bound, which the fix still delivers.
- **jonathan308**, for oMLX PRs [#3985](https://github.com/jundot/omlx/pull/3985), [#3986](https://github.com/jundot/omlx/pull/3986) and [#3988](https://github.com/jundot/omlx/pull/3988): the tensor-unit DSA indexer, the sparse-MLA prefill kernel and 8K prefill chunks. The recommended profile ships them as `patches/upstream-omlx-prs-3985-3986-3988.patch` (PR heads c5413b9a, 8ac5aa9a and d73f689d, merged on f0d8428a).
- **mlx-serve** by ddalcu: [ddalcu/mlx-serve](https://github.com/ddalcu/mlx-serve), MIT.
  - Prompt-lookup-aware MTP ([#523](https://github.com/ddalcu/mlx-serve/pull/523), [#533](https://github.com/ddalcu/mlx-serve/pull/533)): the idea behind change 3.
  - Single-dispatch GDN decode ([#517](https://github.com/ddalcu/mlx-serve/pull/517)): the idea behind change 5.
  - Our implementations are independent Python/Metal code for oMLX.
- **Checkpoints**
  - `dfp-official/GLM-5.3-Flash-oQ4e-mtp` @728cc0d92a: the backbone.
  - `Vontra/GLM-5.3-Flash-MLX-4bit-MTP`: the MTP layer 45 used by the graft.
  - Upstream model: `zai-org/GLM-5.3-Flash`. Check each model's license before redistributing weights; this recipe ships none.
- **Quality reference:** `brandonmusic/GLM-5.3-Flash-BF16-Teacher-Logits` for the KLD panels.
- **MLX** (Apple), which everything runs on.
