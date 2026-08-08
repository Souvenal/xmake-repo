# AGENTS.md

## Project Overview

Personal xmake package repository — only the C/C++ libraries I need (graphics/rendering/vulkan).

## Package Structure

Each package lives at `packages/<first-letter>/<package-name>/xmake.lua`. Directory and package names must be **lowercase** (enforced by assertion in `scripts/test_packages.lua`).

## Key Skills

- **Creating packages**: See `.agents/skills/xmake-repo-package-creation/SKILL.md`
- **Testing packages**: See `.agents/skills/xmake-repo-package-testing/SKILL.md`

## Known Issues

- `packages/a/assimp` references patch files (`packages/a/assimp/patches/...`) that don't exist in this repo — those versions will fail at install time.
- `packages/v/vulkan-loader` has duplicate `add_versions` for version `1.4.335+0`.
- `packages/i/imgui-club` depends on `imgui master` (bleeding edge) — builds may break.
- No CI/CD pipeline — testing is manual.

## Code Style

- Lua — all package recipes and scripts use 4-space indentation.
- No linter/formatter is configured.
