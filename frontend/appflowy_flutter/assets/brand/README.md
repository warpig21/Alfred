# Alfred brand source assets

Drop the Alfred brand source files here, then generate the platform icons.

## 1. App launcher icon (all platforms)

Provide:

- `alfred_icon_1024.png` — 1024×1024, full-bleed app icon (no transparency for iOS).
- `alfred_icon_foreground_1024.png` — 1024×1024 with **transparent** background,
  the logo centered with ~25% safe-zone padding (used for the Android adaptive
  icon foreground).

Then generate every platform icon (android mipmaps, iOS/macOS asset catalogs,
web icons, windows .ico) with:

```bash
cd frontend/appflowy_flutter
flutter pub get
dart run flutter_launcher_icons
```

Config lives in `pubspec.yaml` under `flutter_launcher_icons:`.
(Generation requires the Flutter/Dart toolchain — it is not run in CI here.)

## 2. In-app logo (SVG, vector)

These are shown inside the app (sidebar, onboarding, about). Replace the
existing AppFlowy SVGs with the Alfred versions — same file names, same viewBox:

| Provide (Alfred SVG) | Replaces |
|---|---|
| `app_logo.svg` (square mark/symbol) | `frontend/resources/flowy_icons/16x/app_logo.svg` and `40x/app_logo.svg` |
| `app_logo_with_text_light.svg` | `frontend/resources/flowy_icons/40x/app_logo_with_text_light.svg` |
| `app_logo_with_text_dark.svg` | `frontend/resources/flowy_icons/40x/app_logo_with_text_dark.svg` |
| `ai_chat_logo.svg` (optional) | `frontend/resources/flowy_icons/16x/ai_chat_logo.svg` |

Legacy/extra (optional, used in a few older screens):
`frontend/appflowy_flutter/assets/images/flowy_logo.svg`,
`flowy_logo_dark_mode.svg`, `flowy_logo_with_text.svg`, and the splash
`appflowy_launch_splash.jpg`.

Note: `resources/flowy_icons/` is the source of truth; it is copied to
`assets/flowy_icons/` by the codegen step, so regenerate or rebuild after replacing.
