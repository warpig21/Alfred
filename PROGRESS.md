# PROGRESS — Rebranding "AppFlowy → Alfred"

Branch di lavoro: `claude/eager-cori-q4mvfa`

## FASE 1 — Rebranding (nome visibile, identità visiva, identificatori app)

Regola guida: si toccano SOLO testi mostrati all'utente, asset e identificatori di
piattaforma. NON vengono rinominati crate Rust (`flowy-*`), package Dart interni
(`appflowy_backend`, `appflowy_editor`, `appflowy_board`, `flowy_infra`, ...),
tabelle, protobuf o chiavi evento FFI.

### 1.2 Identificatori di piattaforma — FATTO ✅

| Piattaforma | Chiave | Prima | Dopo |
|---|---|---|---|
| Android | `applicationId` (`android/app/build.gradle`) | `io.appflowy.appflowy` | `com.warpig21.alfred` |
| Android | `namespace` (`android/app/build.gradle`) | `io.appflowy.appflowy` | `com.warpig21.alfred` |
| Android | `package` (`MainActivity.kt`) | `io.appflowy.appflowy` | `com.warpig21.alfred` |
| Android | `android:label` (`AndroidManifest.xml`) | `AppFlowy` | `Alfred` |
| macOS | `PRODUCT_NAME` (`AppInfo.xcconfig`) | `AppFlowy` | `Alfred` |
| macOS | `PRODUCT_BUNDLE_IDENTIFIER` (`AppInfo.xcconfig`) | `io.appflowy.appflowy` | `com.warpig21.alfred` |
| macOS | `CFBundleDisplayName` (`Info.plist`) | (assente) | `Alfred` (aggiunto) |
| iOS | `PRODUCT_BUNDLE_IDENTIFIER` (`project.pbxproj`, 3 occorrenze) | `com.appflowy.appflowy.flutter` | `com.warpig21.alfred` |
| iOS | `CFBundleName` (`Info.plist`) | `AppFlowy` | `Alfred` |
| iOS | `CFBundleDisplayName` (`Info.plist`) | (assente) | `Alfred` (aggiunto) |

Note:
- `MainActivity.kt` `package` allineato al nuovo `namespace`: obbligatorio perché
  `AndroidManifest` usa `android:name=".MainActivity"` (= `<namespace>.MainActivity`).
  Senza questo allineamento la build Android si romperebbe.
- macOS `CFBundleName` resta `$(PRODUCT_NAME)` (variabile) → diventa `Alfred`
  automaticamente. Non toccato per non duplicare la fonte di verità.

### 1.1 Stringhe hardcoded visibili in `lib/` — FATTO ✅

| File | Prima | Dopo |
|---|---|---|
| `lib/startup/tasks/windows.dart` | titolo finestra `'AppFlowy'` | `'Alfred'` |
| `lib/mobile/presentation/home/mobile_home_page_header.dart` | header `'AppFlowy'` | `'Alfred'` |
| `lib/workspace/application/notification/notification_service.dart` | nome app notifiche `'AppFlowy'` | `'Alfred'` |

### 1.1 Stringhe traduzioni (`frontend/resources/translations/*.json`) — IN ATTESA DI CONFERMA ⏳
Base = `en-US.json` (NON `en.json`). Variabile centrale `appName` con riferimenti
`@:appName`. Vedi proposta dettagliata inviata in chat. In attesa di decisione su
sotto-brand (AppFlowy Cloud / AI / Local AI / Pro) e stringhe legali.

### 1.3 Identità visiva — IN ATTESA DI CONFERMA ⏳
- Palette colori brand: accent attuale `#00BCF0` (ciano/blu) in
  `packages/flowy_infra/lib/colorscheme/`. In attesa di scelta palette Alfred.
- Logo/icone: inventario path completato (vedi chat). Sorgenti binari a carico
  dell'utente. Config `flutter_launcher_icons` da predisporre dopo conferma.

## PROSSIMI PASSI
1. Confermare elenco sostituzioni traduzioni + sotto-brand → applicare a en-US e propagare.
2. Confermare palette colori → applicare a colorscheme + istanze hardcoded.
3. Predisporre `flutter_launcher_icons` e ricevere i file logo sorgente.
4. Build di controllo (codegen + desktop arm64).
