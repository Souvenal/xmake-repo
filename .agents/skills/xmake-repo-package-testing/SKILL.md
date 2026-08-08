---
name: xmake-repo-package-testing
description: Test and troubleshoot package definitions in this repository with the copied official xmake-repo test kit. Use when adding, changing, configuring, or validating any packages/*/*/xmake.lua package in this repository.
---

# Xmake Repo Package Testing

Use the repository's official test scripts from the repository root:

```text
scripts/test.lua
scripts/test_packages.lua
scripts/test_templates.lua
scripts/packages.lua
```

Keep this workflow identical to the official xmake-repo workflow. Do not replace it with a custom consumer project or a repository-specific test runner.

## Standard Workflow

1. Identify the package name from `packages/<letter>/<name>/xmake.lua`.
2. Run the smallest normal test first, without verbose diagnostics:

```bash
xmake l scripts/test.lua --shallow <package>
```

3. Treat a successful exit as the normal verification result.
4. Only if the normal test fails, rerun the same command with diagnostics:

```bash
xmake l scripts/test.lua --shallow -vD <package>
```

Do not add `-vD` to the first test run. Use `-vD` only for failure investigation because it produces large command and tool-detection logs.

## Common Variants

Test a shared Debug package:

```bash
xmake l scripts/test.lua --shallow -k shared -m debug <package>
```

Test package configurations:

```bash
xmake l scripts/test.lua --shallow \
    --configs='config_name=true,other_config=false' \
    <package>
```

Test a platform or compiler setting:

```bash
xmake l scripts/test.lua --shallow -p <platform> <package>
xmake l scripts/test.lua --shallow --cxxflags=-fno-exceptions <package>
```

Start every variant without `-vD`; add `-vD` only to a failed variant.

## What the Test Kit Checks

The official runner creates a temporary Xmake test project and registers the current repository as a local package repository. It then:

- loads package metadata and configuration;
- checks supported platforms and architectures;
- runs package checks such as `on_check`;
- resolves the selected package and dependencies;
- downloads, builds, and installs the package;
- runs the package's `on_test` checks, including `check_cxxsnippets()` or `has_cfuncs()`.

The package argument is important for new or uncommitted packages. Without an explicit package, the official runner infers packages from `git diff HEAD^`; uncommitted files may not be discovered.

## Failure Investigation

After a failed normal run, rerun with `-vD` and inspect in this order:

1. package lookup and repository registration;
2. `on_check` errors and unsupported platform or architecture;
3. source download, URL, version, and checksum;
4. dependency resolution;
5. configure, build, and install output;
6. the final `on_test` compile or link command.

Do not change the test command or package definition merely to hide a failure. First identify which phase failed and preserve the diagnostic output.

## Scope

Keep the official test kit files unchanged. Package changes belong in the package's `xmake.lua`. Test-kit changes and package changes should be committed separately when both are present.
