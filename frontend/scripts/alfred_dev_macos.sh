#!/usr/bin/env bash
#
# Alfred — build & run the desktop app on macOS.
#
# Run from the `frontend/` directory:
#     sh scripts/alfred_dev_macos.sh [--no-core] [--no-icons]
#
# Options:
#   --no-core    Skip the (slow) Rust core rebuild — use for quick dart-only reruns.
#   --no-icons   Skip regenerating the platform launcher icons.
#
# Prerequisites (one-time): Rust 1.85, Flutter >=3.27.4,
#   `cargo install --force cargo-make`, `cargo install duckscript_cli`,
#   and `cargo make appflowy-flutter-deps-tools`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$FRONTEND_DIR"

# Choose the Rust profile based on CPU architecture.
if [ "$(uname -m)" = "arm64" ]; then
  PROFILE="development-mac-arm64"
else
  PROFILE="development-mac-x86_64"
fi

RUN_CORE=1
RUN_ICONS=1
for arg in "$@"; do
  case "$arg" in
    --no-core) RUN_CORE=0 ;;
    --no-icons) RUN_ICONS=0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

echo "==> Profile: $PROFILE"

if [ "$RUN_CORE" = "1" ]; then
  echo "==> Building Rust core (dart_ffi)…"
  cargo make --profile "$PROFILE" appflowy-core-dev
fi

echo "==> Code generation (protobuf, freezed, translations, flowy_icons)…"
cargo make --profile "$PROFILE" code_generation

cd appflowy_flutter

echo "==> flutter pub get…"
flutter pub get

if [ "$RUN_ICONS" = "1" ]; then
  echo "==> Generating app launcher icons…"
  dart run flutter_launcher_icons
fi

echo "==> Launching Alfred on macOS…"
flutter run -d macos
