# 30-Second Patch Review

## Start Here (Single Patch)
`patches/upstream/app-graphics3d-gpu-vulkan-renderer-sync-tightening.patch`

## What It Changes
1. File: `gpu_vulkan/renderer.cpp`
2. Size: 1 file, 6 insertions, 19 deletions
3. Main effect: removes broad GPU wait-idle calls from active rendering helpers and tightens readback synchronization scope.

## Why It Matters
1. `vkQueueWaitIdle` / `vkDeviceWaitIdle` in hot paths can stall frame pacing.
2. This patch reduces avoidable global stalls while keeping existing submit/fence flow.

## Risk Level
Low to medium:
1. Small, isolated edit in one file.
2. Synchronization-related, so runtime validation is still required.

## If Approved
Apply this first patch, then review:
1. `patches/upstream/app-graphics3d-gpu-vulkan-ktx-safety.patch`
