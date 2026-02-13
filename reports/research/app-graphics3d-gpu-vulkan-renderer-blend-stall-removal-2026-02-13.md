# app-graphics3d gpu_vulkan Blend Stall Removal (2026-02-13)

## Target
Public repo: `https://github.com/ca2/app-graphics3d`

Modified file:
1. `gpu_vulkan/renderer.cpp`

Patch file:
`patches/upstream/app-graphics3d-gpu-vulkan-renderer-blend-stall-removal.patch`

## Problem
Three blend/render helper paths were calling `vkQueueWaitIdle(...)` immediately after recording draw commands:
1. `_blend_image(...)`
2. `_set_image(...)`
3. `_blend_renderer(...)`

These queue-wide waits can force full GPU stalls in active rendering paths.

## Change
Removed the three `vkQueueWaitIdle(...)` calls and their local queue-variable setup from those functions.

## Why This Is Safer/Faster
1. Queue-wide idle waits serialize GPU work and hurt frame pacing.
2. These functions already operate under command-buffer/frame submission flow where fence/semaphore synchronization exists.
3. Keeping ordering in submit/fence flow avoids unnecessary global stalls.

## Validation Status
1. Code edits applied locally in `C:\Users\kyle-\Desktop\ca2\app-graphics3d`.
2. Full runtime benchmark on ca2 graphics path pending local Vulkan/toolchain setup.
