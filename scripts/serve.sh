#!/bin/zsh
# RECOMMENDED: serve GLM-5.3-Flash from the patched oMLX main build (scripts/install.sh) with the recipe settings.
#   scripts/serve.sh [model-dir] [port]
# model-dir holds the grafted model folder GLM-5.3-Flash-oQ4e-mtp (default ~/models/mlx). oMLX loads it on first request (~173 GB).
set -euo pipefail
here=${0:A:h}
models=${1:-$HOME/models/mlx}
port=${2:-8000}
omlx=${OMLX_RECIPE_TREE:-$HOME/omlx-glm-src}

# The upstream stack's prefill and decode kernels switch on by themselves on M5 (NAX) GPUs. This recipe adds prompt-lookup
# drafts in the MTP cycle and the batched HC mix for B>1.
export OMLX_P2_LOOKUP=1 OMLX_P2_HC_GEMV=1
settings=$here/../configs/model_settings.glm.json

mkdir -p ~/.omlx
if [[ -f ~/.omlx/model_settings.json ]] && ! cmp -s $settings ~/.omlx/model_settings.json; then
  cp ~/.omlx/model_settings.json ~/.omlx/model_settings.json.bak.$(date +%s)
fi
cp $settings ~/.omlx/model_settings.json
# --memory-guard-gb: keep oMLX's own guard below the Metal wired limit (sudo sysctl iogpu.wired_limit_mb=245760 on 256 GB).
ssd=${OMLX_RECIPE_SSD_CACHE:-$HOME/.omlx/ssd-cache}
mkdir -p $ssd
exec $omlx/.venv/bin/omlx serve --model-dir $models --host 127.0.0.1 --port $port \
  --max-concurrent-requests 8 --memory-guard-gb 232 \
  --paged-ssd-cache-dir $ssd --paged-ssd-cache-max-size ${OMLX_RECIPE_SSD_CACHE_MAX:-50GB} --log-level info
