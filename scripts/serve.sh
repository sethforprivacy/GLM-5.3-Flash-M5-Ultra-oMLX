#!/bin/zsh
# Serve one model from the patched oMLX tree with the recipe settings.
#   scripts/serve.sh glm|qwen [model-dir] [port]
# model-dir holds the model folders (default ~/models/mlx). oMLX loads the model on first request; serve one model per process
# (GLM oQ4e is ~173 GB and Qwen oQ6e ~147 GB, so both together would exceed 256 GB).
set -euo pipefail
here=${0:A:h}
which=${1:?glm or qwen}
models=${2:-$HOME/models/mlx}
port=${3:-8000}
omlx=${OMLX_RECIPE_TREE:-$HOME/omlx-m5ultra}

case $which in
  glm)
    export OMLX_GLM_INDEXER_MLX_MAX_ROWS=8 OMLX_GLM_COMPILE_KDA=1 OMLX_GLM_KDA_FUSED=1 OMLX_GLM_COMPILE_FFN_MAX_S=8 \
           OMLX_GLM_PREFILL_SYNC=cache:4 OMLX_P2_LOOKUP=1
    settings=$here/../configs/model_settings.glm.json ;;
  qwen)
    export OMLX_P2_LOOKUP=1 OMLX_P2_LOOKUP_MAX_LONG=14
    settings=$here/../configs/model_settings.qwen.json ;;
  *) echo "glm or qwen" >&2; exit 1 ;;
esac

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
