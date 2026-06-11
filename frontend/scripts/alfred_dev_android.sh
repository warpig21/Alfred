#!/usr/bin/env bash
#
# Alfred — build & run the app on Android.
#
# Run from the `frontend/` directory:
#     sh scripts/alfred_dev_android.sh [device-id] [--no-core] [--no-icons]
#
# Arguments:
#   device-id    Optional target device/emulator id (see `flutter devices`).
# Options:
#   --no-core    Skip the (slow) Rust core rebuild — use for quick dart-only reruns.
#   --no-icons   Skip regenerating the platform launcher icons.
#
# Prerequisites (one-time): Rust 1.85, Flutter >=3.27.4, Android SDK + NDK,
#   the Android Rust targets
#   (`rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android`),
#   `cargo install --force cargo-make`, `cargo install duckscript_cli`,
#   and `cargo make appflowy-flutter-deps-tools`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$FRONTEND_DIR"

PROFILE="development-android"
RUN_CORE=1
RUN_ICONS=1
DEVICE=""
for arg in "$@"; do
  case "$arg" in
    --no-core) RUN_CORE=0 ;;
    --no-icons) RUN_ICONS=0 ;;
    --*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) DEVICE="$arg" ;;
  esac
done

echo "==> Profile: $PROFILE"

if [ "$RUN_CORE" = "1" ]; then
  echo "==> Building Rust core for Android ABIs (needs Android NDK)…"
  cargo make --profile "$PROFILE" appflowy-core-dev-android
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

echo "==> Launching Alfred on Android…"
if [ -n "$DEVICE" ]; then
  flutter run -d "$DEVICE"
else
  flutter run
fi
