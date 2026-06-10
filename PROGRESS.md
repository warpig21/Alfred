# PROGRESS — Rebranding "AppFlowy → Alfred"

Branch di lavoro: `claude/eager-cori-q4mvfa`

## FASE 1 — Rebranding (nome visibile, identità visiva, identificatori app)

Regola guida: si toccano SOLO testi mostrati all'utente, asset e identificatori di
piattaforma. NON vengono rinominati crate Rust (`flowy-*`), package Dart interni
(`appflowy_backend`, `appflowy_editor`, `appflowy_board`, `flowy_infra`, ...),
tabelle, protobuf o chiavi evento FFI.

### ⚠️ Scoperta utile: toolkit ufficiale di white-labeling
Esiste già `frontend/scripts/white_label/` con: `white_label.sh` (orchestratore),
`i18n_white_label.sh`, `code_white_label.sh`, `icon_white_label.sh`,
`font_white_label.sh`, `windows_white_label.sh` + `*_white_label.sh` per piattaforma.
NON è stato usato alla cieca perché `i18n_white_label.sh` fa un `gsub` globale di
"AppFlowy" (sostituirebbe anche "AppFlowy Cloud" e il testo legale "AppFlowy's",
contro le decisioni prese). Utile però per le fasi successive (icone, font).

---

### 1.2 Identificatori di piattaforma — FATTO ✅ (commit `9f99456`)

| Piattaforma | Chiave | Prima | Dopo |
|---|---|---|---|
| Android | `applicationId` (`android/app/build.gradle`) | `io.appflowy.appflowy` | `com.warpig21.alfred` |
| Android | `namespace` (`android/app/build.gradle`) | `io.appflowy.appflowy` | `com.warpig21.alfred` |
| Android | `package` (`MainActivity.kt`) | `io.appflowy.appflowy` | `com.warpig21.alfred` |
| Android | `android:label` (`AndroidManifest.xml`) | `AppFlowy` | `Alfred` |
| macOS | `PRODUCT_NAME` (`AppInfo.xcconfig`) | `AppFlowy` | `Alfred` |
| macOS | `PRODUCT_BUNDLE_IDENTIFIER` (`AppInfo.xcconfig`) | `io.appflowy.appflowy` | `com.warpig21.alfred` |
| macOS | `CFBundleDisplayName` (`Info.plist`) | (assente) | `Alfred` (aggiunto) |
| iOS | `PRODUCT_BUNDLE_IDENTIFIER` (`project.pbxproj`, 3×) | `com.appflowy.appflowy.flutter` | `com.warpig21.alfred` |
| iOS | `CFBundleName` (`Info.plist`) | `AppFlowy` | `Alfred` |
| iOS | `CFBundleDisplayName` (`Info.plist`) | (assente) | `Alfred` (aggiunto) |

Note:
- `MainActivity.kt` `package` allineato al nuovo `namespace`: obbligatorio perché
  `AndroidManifest` usa `android:name=".MainActivity"` (= `<namespace>.MainActivity`).
  Senza questo allineamento la build Android si romperebbe.
- macOS `CFBundleName` resta `$(PRODUCT_NAME)` (variabile) → diventa `Alfred`
  automaticamente. Non toccato per non duplicare la fonte di verità.
- NON toccati (da valutare in seguito, fuori scope Fase 1):
  - deep-link scheme Android `appflowy-flutter` (`AndroidManifest.xml`) — cambiarlo
    può rompere link esistenti.
  - `PRODUCT_COPYRIGHT = Copyright © 2025 AppFlowy.IO...` (macOS `AppInfo.xcconfig`)
    — decisione legale/aziendale.

### 1.1 Stringhe hardcoded visibili in `lib/` — FATTO ✅ (commit `9f99456`)

| File | Prima | Dopo |
|---|---|---|
| `lib/startup/tasks/windows.dart` | titolo finestra desktop `'AppFlowy'` | `'Alfred'` |
| `lib/mobile/presentation/home/mobile_home_page_header.dart` | header `'AppFlowy'` | `'Alfred'` |
| `lib/workspace/application/notification/notification_service.dart` | `_localNotifierAppName` `'AppFlowy'` | `'Alfred'` |

### 1.1 Stringhe traduzioni — FATTO ✅ (commit `b717ef4`)
Fonte di verità: `frontend/resources/translations/*.json` (base `en-US.json`).
Le `appflowy_flutter/assets/translations/` sono generate via
`scripts/code_generation/language_files/generate_language_files.sh` (copia da
`resources/`); aggiornato anche l'unico file lì tracciato (`mr-IN.json`).

Sostituzione chirurgica sui **valori** (mai sulle chiavi JSON) su tutti i 36 locale:
- `appName` → `Alfred` (propaga automaticamente a tutti i `@:appName`).
- `AppFlowy AI` / `AppFlowy Local AI` / `AppFlowy Pro` → `Alfred ...`.
- Nome app puro ("Download AppFlowy", "About @:appName", ecc.) → `Alfred`.
- **Preservato `AppFlowy Cloud`** (nome reale del servizio backend) — incl.
  conversione dei `@:appName Cloud` templati in `AppFlowy Cloud` letterale.
- **Preservato il legale `AppFlowy's`** (Terms/Privacy).
356 righe-valore aggiornate, 35 file. JSON validi, formattazione preservata,
nessuna chiave alterata.

Decisioni utente applicate: sotto-brand → solo AI/Pro rinominati, Cloud invariato;
testo legale invariato.

### 1.3 Identità visiva — RIMANDATO ⏳ (in attesa utente)

**Colori / palette** — NON ancora modificati (scelta "Non ora").
- Accent brand attuale = `#00BCF0` (ciano).
- Punti centrali: `packages/flowy_infra/lib/colorscheme/default_colorscheme.dart`
  (`lightMain1` r.15, `darkMain1` r.22, `darkMain2` r.23, `main2` light r.59,
  `main2` dark ~r.118; tinte chiare `lightHover`/`lightSelector`/`lightTint9`) +
  `lib/workspace/application/settings/appearance/mobile_appearance.dart` r.10.
- ⚠️ PROMEMORIA (richiesto dall'utente): aggiornare anche le **~22 istanze
  hardcoded** `Color(0xFF00BCF0)` sparse in `lib/` (sidebar space icon/shared_widget,
  date_picker, mobile selection menu, mobile toolbar `_toolbar_theme.dart`).
- Palette proposte (in attesa di scelta): A — Indigo `#5B5BD6`/`#4F46E5`;
  B — Teal `#0D9488`/`#0F766E`. (oppure hex forniti dall'utente)

**Logo / icone** — inventario completato, sorgenti binari a carico dell'utente.
Path da sostituire:
- In-app: `assets/images/flowy_logo.svg`, `flowy_logo_dark_mode.svg`,
  `flowy_logo_with_text.svg`, splash `assets/images/appflowy_launch_splash.jpg`.
- macOS: `macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png` (16→1024).
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png`.
- Android: `android/app/src/main/res/mipmap-*/ic_launcher*.png` (+ `mipmap-anydpi-v26/*.xml`,
  `values/ic_launcher_background.xml`) e `ic_launcher-playstore.png`.
- Windows: `windows/runner/resources/app_icon.ico`. Linux: `linux/packaging/assets/logo.png`.
- Web: `web/icons/Icon-*.png`, `web/favicon.png`.
- Nessuna config `flutter_launcher_icons`/`flutter_native_splash` presente.
- Due opzioni di generazione (da scegliere): (a) toolkit interno
  `scripts/white_label/icon_white_label.sh --icon-path <svg>`; (b) aggiungere
  `flutter_launcher_icons` al `pubspec.yaml`. Config da predisporre dopo conferma
  approccio e ricezione del logo sorgente.

---

## VERIFICA FINALE FASE 1
- ✅ Nessun crate Rust / package interno rinominato. Verificato presenza intatta:
  `appflowy_backend` (818 file), `appflowy_editor` (406), `appflowy_board` (13),
  `flowy_infra` (707), `flowy-core` (8), `flowy-user` (210).
- ✅ Nessun file `.rs`, `Cargo.toml`, `pubspec.yaml` o `*.toml` modificato.
- ⚠️ Build di controllo NON eseguibile in questo ambiente: `flutter`/`dart` non
  installati (presenti solo `cargo`/`rustc`). Comandi da lanciare in locale (macOS):
  ```bash
  cd frontend
  # 1. genera i file lingua (copia resources→assets + locale_keys.g.dart)
  sh scripts/code_generation/language_files/generate_language_files.sh
  # 2. codegen completo (protobuf, freezed, ecc.) + build core Rust
  cargo make --profile development-mac-arm64 appflowy-core-dev
  cargo make --profile development-mac-arm64 code_generation
  # 3. build/run desktop arm64
  cd appflowy_flutter
  flutter run -d macos            # oppure: flutter build macos --debug
  ```
  Nota: le modifiche traduzioni cambiano solo VALORI (nessuna chiave nuova),
  quindi `locale_keys.g.dart` non cambia e la build resta verde senza nuovi simboli.

## PROSSIMI PASSI
1. Identità visiva — colori: scegliere palette (A Indigo / B Teal / hex propri),
   poi applicare a colorscheme + mobile_appearance **e** alle ~22 istanze hardcoded
   `Color(0xFF00BCF0)` (PROMEMORIA esplicito).
2. Identità visiva — logo/icone: scegliere approccio (icon_white_label.sh vs
   flutter_launcher_icons), fornire SVG/PNG sorgente, poi generare e sostituire gli asset.
3. Build di verifica locale macOS con i comandi sopra.
