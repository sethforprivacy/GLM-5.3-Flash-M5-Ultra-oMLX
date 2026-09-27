# Validation log

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
