# Justfile
# Install: cargo install just
# Usage: just build

set positional-arguments := true
set dotenv-load := true
set quiet := true
set shell := ["bash", "-euo", "pipefail", "-c"]

# Default: show all recipes
default:
    just --list

# Build the project
build *args:
    cargo build {{ args }}

# Run tests
[no-exit-message]
test *args:
    cargo nextest run {{ args }}

# Check code with clippy and dylint (no modifications)
check *args:
    cargo clippy --lib --tests --benches --bins {{ args }} -- -D warnings
    cargo dylint --all -- --lib --tests --benches --bins

# Auto-fix clippy and dylint issues, then format
fix *args:
    cargo clippy --lib --tests --benches --bins --fix --allow-dirty {{ args }} -- -D warnings
    cargo dylint --fix --all -- --allow-dirty --lib --tests --benches --bins
    just fmt

# Format code (use --check to verify without changing)
fmt *args:
    cargo fmt --all {{ args }}

# Watch and rebuild on changes
watch *args='build':
    cargo watch -x {{ args }}

# Clean build artifacts
[confirm("This will delete all build artifacts. Continue?")]
clean:
    cargo clean

# Run all checks
check-all:
    just check
    just test
