# Optional: oMLX `main` built from source (GLM prefill +5–7 % more)

oMLX `main` @ [`f0d8428a`](https://github.com/jundot/omlx/commit/f0d8428a) (17 commits after 0.7.0rc1) adds upstream's own GLM-5.3 prefill port
([#3944](https://github.com/jundot/omlx/pull/3944)). The recipe patch is rebased onto it as `patches/omlx-main-f0d8428a-m5ultra-p2.patch`
(same 5 files and toggles). This path is for people comfortable building oMLX from source. The DMG route in the README stays the default until the next oMLX release.

| | 0.7.0rc1 stock | 0.7.0rc1 + recipe | main stock | **main + recipe** |
|---|---|---|---|---|
| GLM decode fresh · code 2K | ~67 · ~60 | 68.6 · 60.8 | 67.1 · 55.2 | **69.4 · 68.8** |
| GLM prefill 8K · 32K | 800 · 796 | 1,050 · 1,037 | 881 · 911 | **1,121 · 1,086** |
| GLM KLD teacher-forced · decode-path | 0.0347 · 0.0433 | 0.0347 · 0.0433 | | **0.0347 · 0.0433** (identical) |
| gates (reasoning · qualify) | 12/12 · pass | 12/12 · pass* | | **12/12 · pass*** |
| Qwen oQ6e decode fresh · code 2K | 146–150 · 112–126 | 146.9 · 122.7 | 142.6 · 118.9 | 140.8 · 117.7 |
| Qwen prefill 8K · 32K | ~3,300 · 3,381–3,567 | 3,300 · 3,579 | 3,286 · 3,785 | 3,293 · **3,879** |

\* GLM qualify fails only vision-red, the checkpoint's own processor bug on stock too. Qwen passes everything, including vision.

GLM rows use the grafted MTP head at depth 2 and Qwen rows use depth 3, in every column. Single runs; Qwen decode varies ±3–4 % run to run.

## Build

```bash
git clone https://github.com/jundot/omlx.git ~/omlx-src && cd ~/omlx-src && git checkout f0d8428a
git apply /path/to/recipe/patches/omlx-main-f0d8428a-m5ultra-p2.patch
python3.12 -m venv .venv && . .venv/bin/activate
pip install "setuptools>=68" wheel "cmake>=3.27" "nanobind==2.15.0"
OMLX_WITH_CUSTOM_KERNEL=1 pip install --no-build-isolation -e .
python -c "from omlx.custom_kernels import native_kernel_status as s; print({k: v['available'] for k, v in s().items()})"
```

- Without `OMLX_WITH_CUSTOM_KERNEL=1`, the install silently builds no native kernels and every kernel reports unavailable.
- `nanobind` must match the ABI MLX 0.32.2 was built with.

Serve with the same flags and environment as `scripts/serve.sh`, replacing the binary with `~/omlx-src/.venv/bin/omlx serve`.
