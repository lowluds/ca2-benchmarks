# Continuum CMake Portability Proposal (2026-02-13)

## Scope
Public file: `https://github.com/ca2/app-graphics3d/blob/main/continuum/CMakeLists.txt`

## Problems Observed
1. Vulkan SDK include/lib paths are hardcoded to `C:/VulkanSDK/1.4.313.0/...`, which breaks contributors with different SDK versions or install locations.
2. `SPIRV_OUTPUT_DIR` is used by shader compilation commands but its setup is commented out, which can cause fragile behavior.
3. `glslangValidator` is invoked by name only, without robust resolution from Vulkan tooling variables.

## Proposed Fix
Patch file: `patches/upstream/app-graphics3d-continuum-cmake-portability.patch`

The patch:
1. Removes the hardcoded Vulkan path overrides and keeps `find_package(Vulkan REQUIRED)` as the source of truth.
2. Restores `SPIRV_OUTPUT_DIR` initialization and ensures the output folder is created.
3. Resolves `glslangValidator` via:
   - `Vulkan_GLSLANG_VALIDATOR_EXECUTABLE` when provided by CMake/Vulkan config.
   - `$ENV{VULKAN_SDK}` fallback.
   - `find_program(... REQUIRED)` fallback.

## Why This Helps
1. Improves out-of-box build success across Windows/Linux machines.
2. Reduces environment-specific support churn for public contributors.
3. Makes shader compilation path deterministic and easier to troubleshoot.

## Validation Plan
1. Configure on Windows with a non-default Vulkan SDK version:
   - Expect CMake configure success without editing source.
2. Configure on Linux with distro Vulkan tools:
   - Expect `find_program(glslangValidator)` to resolve binary.
3. Build and verify shader SPIR-V files are emitted into:
   - `../_matter/continuum/_std/_std/shaders/spirV`
