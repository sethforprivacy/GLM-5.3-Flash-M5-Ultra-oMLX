#!/usr/bin/env python3
"""Graft a nextn MTP layer from one MLX checkpoint onto another that ships without one.

dfp-official/GLM-5.3-Flash-oQ4e-mtp @728cc0d92a declares num_nextn_predict_layers=1 but its tensors stop at layer 44,
so oMLX skips the MTP head (plain decode, despite the "Lightning MTP ... active" log line). This builds a new model dir:
every file of the target is symlinked (backbone byte-identical, so KLD is unchanged), plus one extra shard holding the
donor's layer-<num_hidden_layers> tensors verbatim, and an index that lists them. oMLX's glm5_next sanitize then binds
them as mtp.0.* exactly as it does for the donor checkpoint.

The donor's quant must match the target's default quant (both 4-bit gs64 affine here), since the grafted paths carry
no per-path override in the target's config.json.

usage: graft_mtp.py TARGET_DIR DONOR_DIR OUT_DIR [--chat-template FILE]   (run with an interpreter that has mlx)

--chat-template replaces the symlinked chat_template.jinja with FILE. dfp's template is text-only: it turns image parts into an
"unable to process this image" reminder, so oMLX fails with "More images were provided than image tokens". Pass the upstream
zai-org/GLM-5.3-Flash template to restore vision.
"""
import json, os, sys
from pathlib import Path
import mlx.core as mx

args = sys.argv[1:]
template = None
if "--chat-template" in args:
    i = args.index("--chat-template"); template = Path(os.path.expanduser(args[i + 1])); del args[i:i + 2]
target, donor, out = (Path(os.path.expanduser(p)) for p in args[:3])
tcfg = json.loads((target / "config.json").read_text())
dcfg = json.loads((donor / "config.json").read_text())
tq = tcfg.get("quantization") or tcfg.get("quantization_config")
dq = dcfg.get("quantization") or dcfg.get("quantization_config")
for k in ("bits", "group_size"):
    assert tq[k] == dq[k], f"default quant mismatch on {k}: target {tq[k]} donor {dq[k]}"
text = tcfg.get("text_config", tcfg)
n_main = text["num_hidden_layers"]
assert text.get("num_nextn_predict_layers", 0) == 1, "target config must declare one nextn layer"
marker = f".layers.{n_main}."

tidx = json.loads((target / "model.safetensors.index.json").read_text())
assert not any(marker in k for k in tidx["weight_map"]), "target already ships the nextn layer"
didx = json.loads((donor / "model.safetensors.index.json").read_text())["weight_map"]
shards = sorted({v for k, v in didx.items() if marker in k})
graft = {}
for s in shards:
    w = mx.load(str(donor / s))
    graft.update({k: v for k, v in w.items() if marker in k})
    del w
assert graft, "donor has no nextn tensors"
print(f"{len(graft)} nextn tensors from {shards}, {sum(v.nbytes for v in graft.values())/1e9:.2f} GB")

out.mkdir(parents=True, exist_ok=True)
for f in target.iterdir():
    if f.name in ("model.safetensors.index.json",):
        continue
    dst = out / f.name
    if not dst.exists():
        dst.symlink_to(f)
gname = "model-mtp-graft.safetensors"
mx.save_safetensors(str(out / gname), graft, metadata={"format": "mlx"})
wm = dict(tidx["weight_map"])
wm.update({k: gname for k in graft})
meta = dict(tidx.get("metadata", {}))
meta["total_size"] = int(meta.get("total_size", 0)) + sum(v.nbytes for v in graft.values())
meta["mtp_graft"] = f"layer {n_main} from {donor.name} ({', '.join(shards)})"
(out / "model.safetensors.index.json").write_text(json.dumps({"metadata": meta, "weight_map": wm}, indent=2))
if template is not None:
    dst = out / "chat_template.jinja"
    if dst.is_symlink() or dst.exists():
        dst.unlink()
    dst.write_text(template.read_text())
    print("chat template replaced from", template)
print("wrote", out)
