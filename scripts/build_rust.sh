#!/usr/bin/env zsh
set -euo pipefail

export PATH="$HOME/.cargo/bin:$PATH"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Building Rust core (libtc_core.dylib)..."
cd "$ROOT_DIR/rust"
cargo build --release

echo "Rust core built at $ROOT_DIR/rust/target/release/libtc_core.dylib"
