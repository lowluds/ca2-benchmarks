# app-graphics3d gpu_vulkan KTX Safety Patch (2026-02-13)

## Target
Public repo: `https://github.com/ca2/app-graphics3d`

Modified files:
1. `gpu_vulkan/texture.cpp`
2. `gpu_vulkan/texture_ktx.cpp`

Patch file:
`patches/upstream/app-graphics3d-gpu-vulkan-ktx-safety.patch`

## Problem
1. Cubemap KTX upload used `baseWidth >> level` and `baseHeight >> level` without clamping, which can produce zero-sized mip extents for high mip levels.
2. Linear KTX upload path copied `memReqs.size` bytes from KTX source memory, which may exceed `ktxTextureSize`.
3. A redundant `get_ktx_vk_format(...)` retry call occurred even though inputs were unchanged.

## Changes
1. Clamp cubemap mip copy extents to at least 1:
   - `std::max(1u, pktxtexture->baseWidth >> level)`
   - `std::max(1u, pktxtexture->baseHeight >> level)`
2. Copy only `min(ktxTextureSize, memReqs.size)` bytes in linear upload path.
3. Zero-fill any trailing mapped memory range when `memReqs.size > ktxTextureSize`.
4. Remove redundant second format lookup.
5. Replace dynamic copy-region buffers with `std::vector<VkBufferImageCopy>` and pre-reserve capacity to reduce allocation churn during texture upload loops.

## Expected Impact
1. Avoid invalid Vulkan copy regions for tiny mip levels.
2. Prevent out-of-bounds reads from KTX texture data in linear upload path.
3. Reduce avoidable CPU work in format failure branch.
4. Reduce temporary allocation overhead in mip/face copy region collection.
5. Improve reliability and predictability of texture upload behavior.

## Validation Status
1. Code edits applied locally in `C:\Users\kyle-\Desktop\ca2\app-graphics3d`.
2. Full build/run validation not executed yet in this environment (toolchain/dependencies not installed).
