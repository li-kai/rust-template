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

# Run tests (pass additional args, e.g., just test --no-capture)
# Doc tests run in parallel when no args are passed
[no-exit-message]
test *args:
    #!/usr/bin/env bash
    # -e intentionally omitted to capture individual exit codes
    set -uo pipefail
    if [[ $# -eq 0 ]]; then
        # Run doctests in background, capture output
        doctest_out=$(mktemp)
        trap 'rm -f "$doctest_out"' EXIT
        just doctest > "$doctest_out" 2>&1 &
        doctest_pid=$!

        # Run nextest in foreground
        nextest_ok=true
        cargo nextest run || nextest_ok=false

        # Wait for doctests and capture exit code
        doctest_ok=true
        wait $doctest_pid || doctest_ok=false

        # Show doctest results based on nextest outcome
        if $nextest_ok; then
            echo ""
            cat "$doctest_out"
        else
            # Just show summary
            if grep -q "^test result:" "$doctest_out"; then
                echo ""
                echo "Doc tests: $(grep "^test result:" "$doctest_out")"
            fi
        fi

        # Exit with failure if either failed
        $nextest_ok && $doctest_ok
    else
        cargo nextest run {{ args }}
    fi

# Run doc tests only (nextest doesn't support doc tests)
doctest *args:
    #!/usr/bin/env bash
    set -uo pipefail
    output=$(cargo test --doc -- --quiet {{ args }} 2>&1)
    rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "$output"
        exit $rc
    fi
    echo "$output" | awk '
        /all doctests ran in/ { time = $5; gsub(/;/, "", time) }
        /^test result:/ { passed += $4; failed += $6; ignored += $8 }
        END {
            total = passed + failed
            t = time ? time : "?.??s"
            s = sprintf("   Doc tests [%9s] %d tests run: %d passed", t, total, passed)
            if (failed > 0) s = s sprintf(", %d failed", failed)
            if (ignored > 0) s = s sprintf(", %d skipped", ignored)
            print s
        }
    '

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

ci:
    cargo fmt --all -- --check
    just check-all
