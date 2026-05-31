#!/usr/bin/env bash
set -euo pipefail
# Fixed-point `cargo clippy --fix` loop over the workspace, restricted to the
# auto-fixable lints declared in Cargo.toml.
#
# Those lints are set to `allow` under the "Auto-fixable lints" marker in
# Cargo.toml (silent during dev) and re-enabled here as `-W` so clippy applies
# the machine-applicable fix at commit time — Cargo.toml is the single source of
# truth for the set, so the two can't drift.
#
# --fix skips fixes with overlapping spans, so a single pass can leave code
# unfixed; iterate until clippy reports no more "Fixed" lines (bounded at 5).

# Build the -W flags from the auto-fixable section of Cargo.toml.
mapfile -t flags < <(awk '
  /# Auto-fixable lints:/ { on = 1; next }
  on && /^[a-z_0-9]+ = "allow"/ { print "-W"; print "clippy::" $1 }
' Cargo.toml)

for (( i=0; i<5; i++ )); do
  output=$(cargo clippy --fix --allow-dirty --allow-staged -- "${flags[@]}" 2>&1 || true)
  grep -Eq 'Fixed' <<<"$output" || break
done

# Surface any residual diagnostics after the loop settles.
if grep -Eq '^error|^warning\[' <<<"$output"; then
  echo "$output"
fi
