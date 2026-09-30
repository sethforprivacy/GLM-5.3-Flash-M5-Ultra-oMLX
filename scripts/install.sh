#!/bin/zsh
# RECOMMENDED profile: oMLX main @ a4048eef built from source (it contains the upstream GLM-5.3 prefill and decode stacks,
# including jonathan308's fused decode/verify #3989/#4019/#4026), plus open PR #4086 (GLM tool-call loop fix) and this
# recipe's patch on top. Native kernels included.
set -euo pipefail
here=${0:A:h}
dest=${1:-$HOME/omlx-glm-src}
py=""
for c in python3.12 python3.13 python3.11; do command -v $c >/dev/null && { py=$c; break; }; done
[[ -n $py ]] || { echo "need python 3.11, 3.12 or 3.13 on PATH" >&2; exit 1; }
xcrun -f metal >/dev/null 2>&1 || { echo "need Xcode's Metal toolchain (xcrun metal)" >&2; exit 1; }
[[ -e $dest ]] && { echo "$dest exists; remove it first" >&2; exit 1; }
git clone -q https://github.com/jundot/omlx.git $dest
cd $dest
git checkout -q a4048eef
git apply $here/../patches/omlx-main-glm-on-stack.patch
git add -A && git -c user.name=recipe -c user.email=recipe@localhost commit -q -m "mac-studio-m5-ultra recipe patch"
# Open upstream PR #4086 (N1k1tung, head 07a9e459): stops GLM-5.3's unterminated tool-call marker from looping.
git -c user.name=recipe -c user.email=recipe@localhost am -q $here/../patches/upstream-omlx-4086-glm-toolcall-loop.patch
$py -m venv .venv
. .venv/bin/activate
python -m pip install -q --upgrade pip
# The kernel build imports mlx (for its CMake extension helper) and must match its ABI: mlx 0.32.2 is the pin in pyproject.toml.
# setuptools-scm: --no-build-isolation also applies to oMLX's git dependencies. Without it mlx-lm builds as version 0.0.0
# with no _version.py (dependency conflict with dflash-mlx, then ImportError at startup).
python -m pip install -q "setuptools>=68" "setuptools-scm>=8" wheel "cmake>=3.27" "nanobind==2.15.0" "mlx==0.32.2"
# Without OMLX_WITH_CUSTOM_KERNEL=1 the install silently builds no native kernels.
OMLX_WITH_CUSTOM_KERNEL=1 python -m pip install -q --no-build-isolation -e .
python - <<'PY'
from omlx.custom_kernels import native_kernel_status
s = {k: v["available"] for k, v in native_kernel_status().items()}
print("native kernels:", s)
import mlx_lm
print("mlx-lm", mlx_lm.__version__)
raise SystemExit(0 if all(s.values()) else 1)
PY
echo "patched oMLX main ready at $dest"
