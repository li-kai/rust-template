# my-project

Rust project template with [dylint] lints, Nix flake, direnv, clippy, and rustfmt pre-configured.

## Quick start

1. **Clone this template**, keeping git history for clean merges later:
   ```sh
   git clone <template-repo-url> my-project
   cd my-project
   git remote rename origin template
   ```

2. **Rename the package** — update `name` in `Cargo.toml`.

3. **Enter the dev shell**:
   ```sh
   direnv allow   # if using direnv
   nix develop    # otherwise
   ```

4. **Install the pre-commit hook**:
   ```sh
   git config core.hooksPath .githooks
   ```

5. **Build and test**:
   ```sh
   just build
   just test
   ```

## What's included

| File | Purpose |
|------|---------|
| `flake.nix` | Dev shell with Rust toolchain, cargo-dylint, and pre-built lints via `rust-lints.lib.mkDevShell` |
| `.envrc` | Auto-activates the flake dev shell via direnv |
| `rustfmt.toml` | Edition 2024, grouped imports |
| `clippy.toml` | Allows `unwrap`/`expect` in tests |
| `Cargo.toml [lints]` | Comprehensive clippy configuration |
| `.githooks/pre-commit` | Auto-fix, format, lint, and banned crate detection |
| `justfile` | Build, test, check, fix, fmt recipes |

## Linting

```sh
just check      # clippy + dylint
just fix        # auto-fix + format
```

## Pre-commit hook

On every commit, the hook:

1. Auto-fixes all `MachineApplicable` clippy lints (fixed-point loop)
2. Formats with `cargo fmt`
3. Strips decorative comment dividers
4. Re-stages fixed files
5. Blocks on clippy, dylint, or test failures
6. Rejects banned crates (lazy_static, once_cell, dashmap, openssl, etc.)

## Staying up to date

Merge template updates periodically:

```sh
git fetch template
git merge template/main
```

[dylint]: https://github.com/trailofbits/dylint
