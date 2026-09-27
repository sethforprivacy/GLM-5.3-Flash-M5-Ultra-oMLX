# Results and evidence

Hardware: Mac Studio M5 Ultra, 80-core GPU, 256 GB, macOS 27.0, `iogpu.wired_limit_mb=245760`. Engine: oMLX 0.7.0rc1 (bundled MLX 0.32.2).
Unless noted, decode tok/s comes from the wall-time difference between 32- and 512-token completions, which cancels prefill, TTFT and oMLX's burst streaming. Requests run one at a time.

## Quality

- **KLD:** full-vocabulary KL divergence against BF16 teacher logits. The decode-path mode prefills 32 tokens, then scores 1 token per step through the real cache, which exercises decode-only code.
  - GLM stock: 0.0433 (top-1 0.927).
  - GLM with the recipe: 0.0433 at 1-token steps, and 0.0430–0.0441 at 3-token verify blocks, the same spread as stock (0.0430) on this 6,048-position panel.
- **Gates:** 12 reasoning checks, plus tool calls, a ~127K-token three-code retrieval and a vision request. Everything passes except as noted in the README's known issues.
- **Exactness:**
  - Lookup drafts use the engine's own acceptance, with a one-hot draft distribution when sampling, so the output distribution is unchanged.
  - Greedy text already differs between MTP and plain decode on stock oMLX, because multi-row verify rounds differently, and lookup doesn't change that.

## GLM-5.3-Flash

**MTP depth (grafted head)**, tok/s, fresh · 2K-token code prompt:

| MTP | T=0 | T=0.6 |
|---|---|---|
| off (what stock oMLX effectively runs on this checkpoint) | 43.9 · 41.4 | 43.8 · 41.2 |
| depth 1 | 59.2 · 54.3 | 58.1 · 50.8 |
| **depth 2** | **68.7 · 64.5** | **63.6 · 55.1** |
| depth 3 | 69.1 · 65.3 | 60.3 · 46.9 |
| depth 4 | 63.4 · 58.7 | 55.3 · 42.2 |
| adaptive | 68.9 · 59.5 | 63.7 · 54.0 |

**Prompt lookup** (MTP depth 2 on both sides), tok/s:

| task | T=0: off → on | T=0.6: off → on |
|---|---|---|
| return a 140-line file with one rename | 72.8 → 119.3 (1.64×) | 56.5 → 123.0 (2.18×) |
| reproduce a JSON config with one change | 79.6 → 122.6 (1.54×) | 74.2 → 121.1 (1.63×) |
| add docstrings, return the code | 76.0 → 117.0 (1.54×) | 63.6 → 108.4 (1.70×) |
| write a unified diff | 62.4 → 61.4 | 49.9 → 58.5 |
| prose / new code (controls) | flat | 0.94–0.98× |

**Prefill policy** (served, tok/s):

| per-layer policy during prefill | 8K | 32K | 128K | 256K | peak RAM @256K |
|---|---|---|---|---|---|
| stock rc1: eval + flush every layer | 790 | 788 | 778 | 716 | |
| eval, never flush | 1,072 | 1,040 | 993 | 898 | 217.3 GB |
| **eval, flush only when the pool > 4 GB (recipe)** | | 1,047 | | 904 | 213.7 GB |

**Decode step** (unsynced, 4K context): L=1 28.9 → 25.0 ms and L=3 verify ~40 → 37.4 ms, across indexer routing, compiled glue, the fused KDA kernel and FFN compile.
At 128K context L=1 goes 37.5 → 27.4 ms (indexer routing). One decode token reads 13.3 GB of weights (≈14.8 ms at 0.9 TB/s).


**Batched decode** (served ladder, aggregate tok/s; decode-path KLD with 2 and 4 duplicate sequences: 0.0434, 0.0439, against 0.0433 at 1):

| streams | before the B>1 fixes | with them |
|---|---|---|
| 1 | 68.7 | 67.8 |
| 2 | 64.7 | 75.3 |
| 4 | 87.7 | 91.8 |
| 8 | 103.4 | 109.2 |
