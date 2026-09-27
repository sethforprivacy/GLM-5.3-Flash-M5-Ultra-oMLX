# Setup details

## Models (pinned revisions)

Use a Hugging Face token (`hf auth login`) to avoid rate limits. Keep models in a folder Spotlight doesn't index, e.g. `~/models.noindex/mlx`, with a symlink at `~/models/mlx`.

```bash
# GLM-5.3-Flash oQ4e backbone (~182 GB). It ships no MTP head despite its name, so download it outside the served folder.
hf download dfp-official/GLM-5.3-Flash-oQ4e-mtp --revision 728cc0d92aef48d64bd2a7ebfaefec6aeff5921b \
  --local-dir ~/models/src/dfp-GLM-5.3-Flash-oQ4e-mtp

# The MTP layer 45 lives in shards 1-2 of Vontra's 4-bit export (8.6 GB), same quant (4-bit gs64 affine)
hf download Vontra/GLM-5.3-Flash-MLX-4bit-MTP --revision 76add2a341a1cd90ad0e86bb69839ea9c35827c6 \
  model-00001-of-00043.safetensors model-00002-of-00043.safetensors config.json model.safetensors.index.json \
  --local-dir ~/models/src/vontra-mtp

# Graft: symlinks every backbone file, adds one 4.2 GB shard with the 2,641 layer-45 tensors, writes a new index
scripts/python.sh scripts/graft_mtp.py \
  ~/models/src/dfp-GLM-5.3-Flash-oQ4e-mtp ~/models/src/vontra-mtp ~/models/mlx/GLM-5.3-Flash-oQ4e-mtp
```

The graft needs `mlx`, so `scripts/python.sh` runs it with the patched tree's bundled Python and packages.
Keep `~/models/src/dfp-GLM-5.3-Flash-oQ4e-mtp`: the grafted folder links into it.

## Checking that it worked

- **MTP:** each finished request logs `MTP[<id>] finish=… tok/cycle=2.x accept=…/… (7x–8x %)`. That line only appears when the head is live.
  At load, look for `glm5_next sanitize: bound 1 nextn MTP layer(s) as mtp.*`. Sanitize runs more than once, so a
  `no nextn MTP layer in checkpoint` line may also show up and is harmless.
  Without the graft you would instead see `config declares mtp heads but checkpoint ships no mtp.* weights`, and no `MTP[…]` lines.
- **Lookup:** requests that copy text log `P2-LOOKUP[<id>] rounds=… accepted=… (9x %)`.
- **Prefill:** a 32K-token prompt should take ~31 s (stock: ~41 s).

## Memory

Peak system RAM is ~214 GB during a 256K-token prefill. Don't serve a second large model alongside it on a 256 GB machine.
