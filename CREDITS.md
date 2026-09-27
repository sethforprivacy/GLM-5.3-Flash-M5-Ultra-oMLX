# Credits

This recipe stands on other people's public work. Please credit them when reusing it.

- **oMLX** by Jun Kim and contributors: [jundot/omlx](https://github.com/jundot/omlx), Apache-2.0. This is the engine, and every patch here modifies its files.
  Tested base: v0.7.0rc1. Our change 6 revisits the per-layer pool flush from [#3807](https://github.com/jundot/omlx/pull/3807)
  (williamxyl), keeping its memory bound, which the fix still delivers.
- **jonathan308**, whose open oMLX GLM-5.3 pull requests are most of the recommended profile's speed: pipelined prefill layers,
  fused hyper-connection prefill kernels, the per-core KDA prefill recurrence, tensor-unit DSA indexer and sparse-MLA kernels, 8K chunks, fused MoE gate/up
  and NAX gather tiles, and exact fused decode/verify kernels including the MTP verify path. `patches/upstream-omlx-glm53-stack.patch` is their combined
  diff on f0d8428a, at these heads (2026-09-27):
  #3970 fba85855, #3974 f4ce2735, #3971 b42d94b2, #3983 7d925bd9, #3984 52c78b1f, #3985 eb59da9b, #3986 8ac5aa9a, #3987 5fbc4927, #3988 d73f689d,
  #3993 a68cab68, #3995 97e473ef, #3996 03e9b678, #4022 d6dbc997, #4025 9eeaf899, #4029 498685ba, #4026 e886b410 (contains #3989 and #4019).
- **mlx-vlm** by Prince Canuma and contributors: [Blaizzy/mlx-vlm](https://github.com/Blaizzy/mlx-vlm), MIT: the GLM-5.3 model code oMLX vendors.
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
