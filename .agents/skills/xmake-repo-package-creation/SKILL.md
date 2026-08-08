---
name: xmake-repo-package-creation
description: Add new package recipes to this repository using the official xmake-repo conventions. Use when creating package recipes under packages, selecting a build-system adapter, adding versions and checksums, defining package configs, or writing on_install and on_test.
---

# Xmake Repo Package Creation

Add packages using the same layout and conventions as the official xmake-repo:

```text
packages/<first-letter>/<package-name>/xmake.lua
```

Use lowercase package and directory names, four-space indentation, and keep the recipe minimal. Do not add README or other auxiliary files unless the package needs patches or port files.

## Workflow

1. Inspect the upstream repository before editing:
   - repository name, package name, homepage, description, and license;
   - release tags and archive URL format;
   - build system and install target;
   - public headers, libraries, tools, and required dependencies;
   - platform and architecture limitations.
2. For a GitHub or GitLab project, optionally generate a starting recipe with the repository's copied official generator:

```bash
xmake l scripts/new.lua github:owner/repository
xmake l scripts/new.lua gitlab:owner/repository
```

`scripts/new.lua` is a scaffolding tool, not a complete package implementation. It:

- queries repository metadata through `gh` or `glab`;
- obtains the latest release tag when available;
- downloads the release archive and calculates its SHA-256 checksum;
- detects common build systems (`xmake.lua`, CMake, Autoconf, Meson, and Bazel);
- creates `packages/<first-letter>/<package-name>/xmake.lua`.

Before using the generator, authenticate the matching CLI:

```bash
gh auth login
glab auth login
```

Use only the CLI matching the source:

```bash
xmake l scripts/new.lua github:owner/repository
xmake l scripts/new.lua gitlab:group/repository
```

The generator opens the destination recipe for writing, so inspect the target path and preserve any existing recipe before running it. It detects common build systems and writes a package skeleton, but its generic `on_test` must be replaced with a real minimal test.
3. Inspect and correct the generated recipe. Never assume the generated release metadata, build flags, install paths, or test are correct.
4. Add the recipe under the first letter of the final package name.
5. Run the package test workflow from the repository root.

## Recipe Structure

Use only the fields needed by the package. A common recipe order is:

```lua
package("name")
    set_kind("library")
    set_homepage("...")
    set_description("...")
    set_license("...")

    add_urls("...", "...")
    add_versions("version", "sha256")

    add_configs("feature", {
        description = "What the feature changes.",
        default = false,
        type = "boolean"
    })

    add_deps("cmake")

    on_load(function (package)
        -- Add conditional dependencies, defines, links, or environments.
    end)

    on_install(function (package)
        -- Use the matching package.tools adapter.
    end)

    on_test(function (package)
        -- Keep this compile/link test minimal and real.
    end)
```

Use `set_kind("library", {headeronly = true})` only when no library compilation or linking is required. Use the package's actual upstream library name in `package:add("links", "...")` only when automatic detection does not provide it.

## Versions and Sources

Prefer a release archive plus the upstream Git URL:

```lua
add_urls("https://github.com/owner/repository/archive/refs/tags/$(version).tar.gz",
         "https://github.com/owner/repository.git")
add_versions("v1.2.3", "<sha256>")
```

Verify every checksum from the exact archive URL used by the recipe. Handle tag/archive naming differences with an `add_urls()` version transform when necessary. Add only versions that can be tested; do not invent checksums or release tags.

Use `add_patches()` only for a necessary, reproducible upstream fix. Store patches below the package directory and include their checksums.

## Build-System Selection

Use the official package tool matching the upstream build system:

- `CMakeLists.txt`: `add_deps("cmake")` and `import("package.tools.cmake").install(package, configs)`.
- `meson.build`: add `meson` and `ninja`, then use `package.tools.meson`.
- `configure`, `configure.ac`, or `autogen.sh`: use `autoconf`, `automake`, and `libtool` as needed.
- `xmake.lua`: use `package.tools.xmake`.
- `BUILD` or `BUILD.bazel`: use `package.tools.bazel`.
- Header-only sources: copy the upstream include tree directly; do not introduce a build system.

Disable upstream tests, examples, tools, documentation, and benchmarks unless the package itself requires them. Pass `package:config("shared")`, `package:is_debug()`, platform, architecture, and runtime choices into the upstream build system where supported.

## Configurations and Dependencies

Expose a config only when it changes the installed package or consumer-facing compile behavior:

```lua
add_configs("feature", {
    description = "Enable feature.",
    default = false,
    type = "boolean"
})
```

Translate configs into upstream flags in `on_install`. Use `on_load` for conditional dependencies, defines, links, external sources, or environment changes. Validate incompatible configurations with `on_check` and fail with a precise package-scoped message.

Do not expose upstream developer-only switches that only build tests, benchmarks, or internal tools. Do not add dependencies that are not needed for the selected package configuration.

## `on_test`

Add one small test that proves the installed public interface works:

- C++ header/library: `check_cxxsnippets()`;
- C header/library: `check_csnippets()` or `has_cfuncs()`;
- header-only C++: include the public header and instantiate a representative type;
- executable/tool package: check the installed command or a minimal public API.

Keep the test independent of network access, external files, test frameworks, and optional features unless the recipe enables them by default. Test the actual namespace, header path, symbol, and language standard.

## Verification

Run from the repository root, explicitly naming the new package:

```bash
xmake l scripts/test.lua --shallow <package>
```

Start without `-vD`. Only after a failure, rerun:

```bash
xmake l scripts/test.lua --shallow -vD <package>
```

Test relevant variants separately:

```bash
xmake l scripts/test.lua --shallow -k shared -m debug <package>
xmake l scripts/test.lua --shallow --configs='feature=true' <package>
xmake l scripts/test.lua --shallow -p <platform> <package>
```

Use only variants supported by the package. Before finishing, run `git diff --check`, inspect the complete recipe, and confirm that no generated placeholder test or unrelated file remains.
