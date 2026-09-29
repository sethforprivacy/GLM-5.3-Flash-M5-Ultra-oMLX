# Credits

This recipe stands on other people's public work. Please credit them when reusing it.

- **oMLX** by Jun Kim and contributors: [jundot/omlx](https://github.com/jundot/omlx), Apache-2.0. This is the engine, and every patch here modifies its files.
  Tested base: v0.7.0rc1. Our change 6 revisits the per-layer pool flush from [#3807](https://github.com/jundot/omlx/pull/3807)
  (williamxyl), keeping its memory bound, which the fix still delivers.
- **jonathan308** (Jonathan Spangler, [@spangler3000](https://x.com/spangler3000)), whose oMLX GLM-5.3 pull requests are most of the recommended profile's speed. All of the following are merged into oMLX `main`, which the recipe builds on at 65515c3c (prefill on 2026-09-28, decode on 2026-09-29):
  - pipelined prefill layers (#3971), fused hyper-connection prefill kernels (#3983), the per-core KDA prefill recurrence (#3984);
  - tensor-unit DSA indexer and sparse-MLA kernels (#3985, #3986, #3996), 8K prefill chunks (#3988), dense-prefix row blocks (#4025);
  - fused MoE gate/up with NAX gather tiles (#3993, #3995, #4022, #4029).

  - the exact fused decode/verify kernels, including the MTP verify path (#3989, #4019, #4026).
- **jundot** (oMLX's maintainer), for merging and following up that stack.
- **yoyoIU**, for the MTP late-join hand-off fix (#4031) the lane build picks up with `main`.
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
