#!/bin/zsh
# Run Python with the patched oMLX tree's interpreter and packages (e.g. for scripts/graft_mtp.py).
#   scripts/python.sh script.py [args]
# Uses the source build (~/omlx-glm-src, scripts/install.sh) if present, else the DMG copy (~/omlx-glm-m5ultra). OMLX_RECIPE_TREE overrides.
T=${OMLX_RECIPE_TREE:-}
[[ -z $T ]] && { [[ -d $HOME/omlx-glm-src/.venv ]] && T=$HOME/omlx-glm-src || T=$HOME/omlx-glm-m5ultra; }
if [[ -x $T/.venv/bin/python ]]; then exec $T/.venv/bin/python "$@"; fi
R=$T/Contents/Resources
export PYTHONHOME=$R/Python/cpython-3.11 PYTHONPATH=$R:$R/Python/framework-mlx-base/lib/python3.11/site-packages
exec $PYTHONHOME/bin/python3 "$@"
