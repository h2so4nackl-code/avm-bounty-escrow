#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
sdk="${1:-$root/.runtime/avm-sdk-linux-x86_64}"
sdk="$(cd "$sdk" && pwd)"
export PATH="$sdk/bin:$PATH"
cd "$root"
mkdir -p evidence
rustc --version
python3 scripts/runtime_info.py --sdk "$sdk"
cargo fmt -p avm-bounty-escrow -p avm-bounty-receiver -p avm-bounty-tests -- --check
cargo clippy --workspace --all-targets --locked --offline -- -D warnings 2>&1 | tee evidence/clippy-native.txt
cargo test --workspace --locked --offline 2>&1 | tee evidence/native-tests.txt
avm-contract-build build --manifest-path contracts/escrow/Cargo.toml | tee evidence/build-escrow.txt
avm-contract-build build --manifest-path contracts/receiver/Cargo.toml | tee evidence/build-receiver.txt
python3 scripts/sync_ids.py --check
cargo clippy -p avm-bounty-escrow --target wasm32-unknown-unknown --locked --offline -- -D warnings 2>&1 | tee evidence/clippy-wasm-escrow.txt
cargo clippy -p avm-bounty-receiver --no-default-features --target wasm32-unknown-unknown --locked --offline -- -D warnings 2>&1 | tee evidence/clippy-wasm-receiver.txt
python3 scripts/e2e.py --sdk "$sdk"
python3 scripts/verify_artifacts.py
python3 scripts/summarize.py
echo "All local checks passed."
