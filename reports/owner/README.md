# Owner Patch Index

This folder tracks patch candidates prepared for ca2 owner review.

## Current Recommended Patch Set
1. `patches/upstream/app-graphics3d-gpu-vulkan-ktx-safety.patch`
   - Scope: `gpu_vulkan/texture.cpp`, `gpu_vulkan/texture_ktx.cpp`
   - Why: safer KTX upload behavior + lower temporary allocation churn.
2. `patches/upstream/app-graphics3d-gpu-vulkan-renderer-sync-tightening.patch`
   - Scope: `gpu_vulkan/renderer.cpp`
   - Why: remove active-path queue stalls and tighten readback synchronization scope.
3. `patches/upstream/app-graphics3d-continuum-cmake-portability.patch`
   - Scope: `continuum/CMakeLists.txt`
   - Why: improve build portability and shader tool resolution.

## Superseded
1. `patches/upstream/app-graphics3d-gpu-vulkan-renderer-blend-stall-removal.patch`
   - Superseded by `app-graphics3d-gpu-vulkan-renderer-sync-tightening.patch`.

## Reading Order
1. `reports/owner/owner-update-2026-02-13.md`
2. `reports/research/*.md` for technical details per patch
3. `patches/upstream/*.patch` for exact code changes
