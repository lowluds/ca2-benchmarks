# app-graphics3d gpu_vulkan Renderer Sync Tightening (2026-02-13)

## Target
Public repo: `https://github.com/ca2/app-graphics3d`

Modified file:
1. `gpu_vulkan/renderer.cpp`

Patch file:
`patches/upstream/app-graphics3d-gpu-vulkan-renderer-sync-tightening.patch`

## Problem
1. Active blend helpers used queue-wide idle waits in the draw path.
2. CPU readback path mixed broad device-wide wait and an extra queue-wide pre-wait.

Both patterns can serialize work and reduce throughput/frame pacing.

## Change
1. Removed `vkQueueWaitIdle(...)` from:
   - `_blend_image(...)`
   - `_set_image(...)`
   - `_blend_renderer(...)`
2. In readback send path, replaced `vkDeviceWaitIdle(...)` with graphics-queue scoped `vkQueueWaitIdle(...)`.
3. Removed redundant queue-wide pre-wait from `renderer::sample()` (submission path already waits on synchronization primitives).

## Why This Helps
1. Avoids avoidable global GPU stalls in active rendering helpers.
2. Narrows synchronization scope for readback, reducing unnecessary device-wide blocking.
3. Keeps behavior aligned with existing command submission synchronization flow.

## Validation Status
1. Code edits applied locally in `C:\Users\kyle-\Desktop\ca2\app-graphics3d`.
2. Runtime benchmark validation on ca2 graphics scenarios is pending local Vulkan/toolchain setup.
