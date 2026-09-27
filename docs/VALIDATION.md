# Validation log

Entries before the milestone-3 one validate the 0.7.0rc1 DMG profile. Its scripts were then called `install.sh`/`serve.sh` and are now `install-dmg.sh`/`serve-dmg.sh`.

## 2026-09-26: from scratch on the M5 Ultra

1. `scripts/install.sh` into a fresh `~/omlx-recipe-validate`, from the installed `/Applications/oMLX.app` 0.7.0rc1.
   The patch applied cleanly, and the tree equals the recipe branch (4 empty dirs aside, which git doesn't track).
2. **Graft:** the documented command failed because the bundled Python needs `PYTHONHOME`/`PYTHONPATH`. Fixed with `scripts/python.sh`. Re-run through it, the graft is **byte-identical** to the one used in every phase-2 run (shard and index `cmp` equal).
3. Full cell through `scripts/serve.sh` (bench suites, prefill to 256K, ladder, reasoning and qualify gates):

| | recipe, from scratch | milestone 2 (dev tree) |
|---|---|---|
| decode fresh greedy | 68.6 | 68.4 |
| prefill 2K · 32K · 256K | 1,051 · 1,037 · 902 | 1,005 · 1,039 · 901 |
| ladder c=1 · 8 | 69.6 · 102.9 | 69.6 · 103.4 |
| gates | 12/12 reasoning; qualify fails **vision-red** (known checkpoint bug) and **long-context** (2 of 3 codes returned) | 12/12; vision-red only |

GLM long-context had passed in all 7 earlier oMLX oQ4e runs, including both patched milestones. **Repeat test** (fresh random codes per trial, T=0, ~127K-token prompt):

| setting | pass |
|---|---|
| recipe (MTP d2 + lookup) | 6/6, plus 0/1 in the validation cell |
| MTP d2, lookup off | 5/6 |
| MTP off | 6/6 |
| earlier cells, MTP on (milestones 1–2) | 2/2 |
| earlier cells, no MTP (stock oQ4e ×4, idx8) | 5/5 |

- **Lookup is not the cause:** it failed with lookup off too.
- Both failures had the grafted MTP head active, and both look the same: the model stops after two codes.
  The count is 13/15 with MTP against 11/11 without (one-sided Fisher p ≈ 0.32).
  - That's consistent with MTP's multi-row verify rounding flipping a near-tie between "third code" and "stop", but not proven.
  - GLM's verify path isn't batch-invariant; Qwen's is, and Qwen passes every time.
- In every configuration (MTP off too) the model sometimes emits `<|assistant|>` plus extra text after the answer. That's stop-token handling in the checkpoint's template, independent of this recipe.

## 2026-09-27: after the split into a GLM-only recipe and the lookup-gate fix

Fresh `scripts/install.sh` → `~/omlx-glm-validate`, served by the new `scripts/serve.sh`. Agent mix at T=0 against MTP-only:
edit 72.8 → 120.1 (1.65×), JSON 79.6 → 121.0 (1.52×), fix 76.0 → 116.0 (1.53×), diff 1.03×, prose 1.00×, new code 0.99×. This reproduces the published gains.

## 2026-09-27: vision fix and batched-decode patches, from scratch

Fresh `scripts/install.sh`, then the graft with `--chat-template` (official zai-org template). Against the development copy, the MTP shard, index and template are all **byte-identical**.
Served by `scripts/serve.sh`:
- **reasoning 12/12**
- **every qualify gate passes, including vision** (it had failed on every earlier run of this checkpoint) and 127K retrieval
- ladder c=1 · 2 · 4 = 68.2 · 75.0 · 92.4 tok/s

## 2026-09-27: long-context retrieval, resolved

Every miss in the 127K three-code test ended on the gate's 128-token cap (`finish_reason=length`): GLM sometimes reasons before answering.
With MTP on and `max_tokens` 512 the test passed **10/10**, all ending on `stop`. The earlier 2-in-15 MTP-on misses weren't a quality problem.

## 2026-09-27: recommended profile (milestone 3), from scratch

1. `scripts/install.sh` into a fresh tree. The first attempt failed: `setup.py` imports `mlx` before it is installed. The script now installs `mlx==0.32.2` with the build deps.
   After the fix, every native kernel loads, and the tree is **identical** to the development branch (empty `git diff` against it).
2. Graft with `--chat-template`: the MTP shard, index and template are **byte-identical** to the development copy.
3. Full cell through `scripts/serve.sh`:

| | from scratch | milestone 3 (dev tree) |
|---|---|---|
| decode fresh greedy · 2K code | 68.9 · 81.6 | 68.8 · 81.5 |
| prefill 2K · 8K · 32K · 128K · 256K | 1,219 · 1,213 · 1,245 · 1,265 · 1,196 | 1,224 · 1,209 · 1,242 · 1,264 · 1,200 |
| warm follow-up 8K · 32K | 0.39 s · 0.51 s | 0.40 s · 0.46 s |
| ladder c=1 · 2 · 4 · 8 | 69.1 · 75.1 · 90.1 · 109.0 | 69 · 73 · 90 · 108 |
| reasoning · qualify gates | 12/12 · all pass (vision, tool, 127K retrieval) | 12/12 · all pass |
| peak RAM | 200.8 GB | |
