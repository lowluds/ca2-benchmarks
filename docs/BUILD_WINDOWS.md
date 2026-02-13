# Build Setup (Windows)

This project currently targets Windows-first setup for benchmark and optimization work.

## Required
1. Git for Windows
2. Visual Studio 2022 Build Tools
3. Desktop development with C++ workload
4. Windows 10/11 SDK
5. CMake (3.24+ recommended)

## Optional but Needed for Continuum/Vulkan Paths
1. Vulkan SDK
2. `glslangValidator` in `PATH` (or available under `%VULKAN_SDK%\\Bin`)

## Suggested Install Flow
1. Install Visual Studio Build Tools and include C++ workload + Windows SDK.
2. Install CMake and add it to `PATH`.
3. Install Vulkan SDK if you plan to benchmark Vulkan-related paths.

## Verify
Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/windows/check-prereqs.ps1
```

If prerequisites are missing, the script prints exact next actions.

## Notes
- `cl` may not be visible in a regular terminal.
- Use Developer PowerShell for Visual Studio or run `vcvars64.bat` before build tasks.

