#!/bin/zsh
# Serve GLM-5.3-Flash from the patched oMLX tree with the recipe settings.
#   scripts/serve.sh [model-dir] [port]
# model-dir holds the grafted model folder GLM-5.3-Flash-oQ4e-mtp (default ~/models/mlx). oMLX loads it on first request (~173 GB).
set -euo pipefail
here=${0:A:h}
models=${1:-$HOME/models/mlx}
port=${2:-8000}
omlx=${OMLX_RECIPE_TREE:-$HOME/omlx-glm-m5ultra}

export OMLX_GLM_INDEXER_MLX_MAX_ROWS=8 OMLX_GLM_COMPILE_KDA=1 OMLX_GLM_KDA_FUSED=1 OMLX_GLM_COMPILE_FFN_MAX_S=8 \
       OMLX_GLM_PREFILL_SYNC=cache:4 OMLX_P2_LOOKUP=1
settings=$here/../configs/model_settings.glm.json

mkdir -p ~/.omlx
if [[ -f ~/.omlx/model_settings.json ]] && ! cmp -s $settings ~/.omlx/model_settings.json; then
  cp ~/.omlx/model_settings.json ~/.omlx/model_settings.json.bak.$(date +%s)
fi
cp $settings ~/.omlx/model_settings.json
# --memory-guard-gb: keep oMLX's own guard below the Metal wired limit. Raise that limit first with
#   sudo sysctl iogpu.wired_limit_mb=245760     (240 GiB on a 256 GB machine; see docs/SETUP.md)
# Prefix (KV) cache on SSD, capped: without a cap it grew to its 200 GB default on our box.
ssd=${OMLX_RECIPE_SSD_CACHE:-$HOME/.omlx/ssd-cache}
mkdir -p $ssd
exec $omlx/Contents/MacOS/omlx-cli serve --model-dir $models --host 127.0.0.1 --port $port \
  --max-concurrent-requests 8 --memory-guard-gb 232 \
  --paged-ssd-cache-dir $ssd --paged-ssd-cache-max-size ${OMLX_RECIPE_SSD_CACHE_MAX:-50GB} --log-level info
