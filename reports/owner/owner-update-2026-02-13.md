# Owner Update - 2026-02-13

## Goal
Provide small, upstream-friendly C++ fixes in active public ca2 graphics code (`app-graphics3d`).

## Changes Delivered
1. **KTX texture upload safety + allocation cleanup**
   - Patch: `patches/upstream/app-graphics3d-gpu-vulkan-ktx-safety.patch`
   - Files:
     - `gpu_vulkan/texture.cpp`
     - `gpu_vulkan/texture_ktx.cpp`
   - Why:
     - Prevent invalid tiny-mip copy extents.
     - Prevent potential over-read in linear KTX memory copy path.
     - Reduce temporary allocations when building Vulkan copy regions.

2. **Renderer blend-path stall removal**
   - Patch: `patches/upstream/app-graphics3d-gpu-vulkan-renderer-blend-stall-removal.patch`
   - File:
     - `gpu_vulkan/renderer.cpp`
   - Why:
     - Remove queue-wide `vkQueueWaitIdle(...)` calls from active blend helpers.
     - Reduce avoidable GPU stalls and improve frame pacing potential.

3. **Renderer synchronization tightening (latest renderer patch)**
   - Patch: `patches/upstream/app-graphics3d-gpu-vulkan-renderer-sync-tightening.patch`
   - File:
     - `gpu_vulkan/renderer.cpp`
   - Why:
     - Includes blend-path stall removal.
     - Narrows a readback `vkDeviceWaitIdle(...)` into queue-scoped synchronization.
     - Removes redundant pre-wait in `renderer::sample()`.
   - Note:
     - This patch supersedes the earlier blend-only renderer patch for current review.

## Notes
1. Changes are intentionally small and isolated for easier review.
2. Runtime benchmark validation is pending local Vulkan/toolchain setup.
3. Next target: replace remaining broad wait-idle usage with fence/semaphore-scoped synchronization where safe.
