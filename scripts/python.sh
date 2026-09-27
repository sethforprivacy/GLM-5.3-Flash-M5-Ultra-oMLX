#!/bin/zsh
# Run Python with the patched oMLX tree's bundled interpreter, mlx and omlx (e.g. for scripts/graft_mtp.py).
#   scripts/python.sh script.py [args]      (OMLX_RECIPE_TREE overrides ~/omlx-m5ultra)
R=${OMLX_RECIPE_TREE:-$HOME/omlx-m5ultra}/Contents/Resources
export PYTHONHOME=$R/Python/cpython-3.11 PYTHONPATH=$R:$R/Python/framework-mlx-base/lib/python3.11/site-packages
exec $PYTHONHOME/bin/python3 "$@"
