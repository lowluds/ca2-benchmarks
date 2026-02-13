# ca2-benchmarks

Minimal patch repository for public ca2-related optimization proposals.

## What Is Here
- `patches/upstream/` contains patch files ready to review/apply.

Current patch set:
- `patches/upstream/app-graphics3d-gpu-vulkan-ktx-safety.patch`
- `patches/upstream/app-graphics3d-gpu-vulkan-renderer-sync-tightening.patch`
- `patches/upstream/app-graphics3d-continuum-cmake-portability.patch`
- `patches/upstream/app-graphics3d-continuum-skybox-selection-o1.patch`
- `patches/upstream/app-graphics3d-continuum-point-light-sort-vector.patch`

## Apply A Patch
```bash
git apply --check patches/upstream/<patch-name>.patch
git apply patches/upstream/<patch-name>.patch
```

## Notes
- `AGENTS.md` is intentionally local and ignored by git.
- New patches include inline `// NOTE:` comments in changed code to explain optimization intent for reviewers.
