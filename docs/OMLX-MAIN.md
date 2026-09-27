# oMLX `main` from source: how the recommended profile was reached

Step 3 (2026-09-27 evening): three more patches in `patches/omlx-main-f0d8428a-glm.patch` (HC pre-mix, KDA prefill in-place q/k/v, KDA recurrence); see the README rows 11–13 and docs/VALIDATION.md.

The recommended profile (README) is `main` @ f0d8428a + `patches/omlx-main-f0d8428a-glm.patch` + `patches/upstream-omlx-prs-3985-3986-3988.patch`, built by `scripts/install.sh`. This page keeps the step-by-step numbers.

## Step 1: main + recipe patch

oMLX `main` @ [`f0d8428a`](https://github.com/jundot/omlx/commit/f0d8428a) (17 commits after 0.7.0rc1) adds upstream's own GLM-5.3 prefill port
([#3944](https://github.com/jundot/omlx/pull/3944)). The recipe patch is rebased onto it as `patches/omlx-main-f0d8428a-glm.patch`
(same 5 files and toggles). This path is for people comfortable building oMLX from source. The DMG route in the README stays the default until the next oMLX release.

| | 0.7.0rc1 stock | 0.7.0rc1 + recipe | main stock | **main + recipe** |
|---|---|---|---|---|
| decode fresh · code 2K | ~67 · ~60 | 68.6 · 60.8 | 67.1 · 55.2 | **69.4 · 68.8** |
| prefill 8K · 32K | 800 · 796 | 1,050 · 1,037 | 881 · 911 | **1,121 · 1,086** |
| KLD teacher-forced · decode-path | 0.0347 · 0.0433 | 0.0347† · 0.0433 | | **0.0347 · 0.0433** (both measured, identical) |
| gates (reasoning · qualify) | 12/12 · pass* | 12/12 · pass* | | **12/12 · pass*** |

† Not re-measured: every rc1 change is decode/verify-only (≤ 8 rows) or scheduling-only, so teacher-forced windows run the stock code path.

\* Qualify fails only vision-red, the checkpoint's own processor bug on stock too.

All columns use the grafted MTP head at depth 2. Single runs.

## Build

```bash
git clone https://github.com/jundot/omlx.git ~/omlx-src && cd ~/omlx-src && git checkout f0d8428a
git apply /path/to/recipe/patches/omlx-main-f0d8428a-glm.patch
python3.12 -m venv .venv && . .venv/bin/activate
pip install "setuptools>=68" wheel "cmake>=3.27" "nanobind==2.15.0" "mlx==0.32.2"
OMLX_WITH_CUSTOM_KERNEL=1 pip install --no-build-isolation -e .
python -c "from omlx.custom_kernels import native_kernel_status as s; print({k: v['available'] for k, v in s().items()})"
```

- Without `OMLX_WITH_CUSTOM_KERNEL=1`, the install silently builds no native kernels and every kernel reports unavailable.
- `nanobind` must match the ABI MLX 0.32.2 was built with, and `mlx` must be installed before the build, because `setup.py` imports it.

Serve with `OMLX_RECIPE_TREE=~/omlx-src scripts/serve.sh`.

## Step 2: + the open upstream prefill PRs (#3985, #3986, #3988), now part of the recommended profile

jonathan308's open oMLX PRs add a tensor-unit DSA indexer (#3985), a tensor-unit sparse-MLA prefill kernel (#3986) and 8K prefill chunks on NAX hosts (#3988).
They target GLM-5.3's biggest prefill cost: the classic-SIMD sparse-MLA kernel took 224 ms per layer for an 8K chunk at 32K context.
On top of this recipe's `main` patch (same box, our harness):

| served prefill, tok/s | 8K | 32K | 128K |
|---|---|---|---|
| main + recipe patch | 1,093 | 1,094 | 1,038 |
| **+ #3985 #3986 #3988** | **1,218** | **1,245** | **1,256** |

KLD is identical (teacher-forced 0.0347 / top-1 0.9416), and reasoning 12/12 plus every qualify gate, vision included, pass. `scripts/install.sh` applies them from the pinned patch. The manual equivalent:

```bash
cd ~/omlx-src
git fetch origin pull/3985/head:pr-3985 pull/3986/head:pr-3986 pull/3988/head:pr-3988
git merge --no-edit pr-3985 pr-3986 pr-3988   # pure Python/Metal-JIT changes; no rebuild needed
```

They are open PRs, so re-check before relying on them. Once they merge upstream, this step goes away.
