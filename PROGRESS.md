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

### 1.3 Identità visiva — COLORI: FATTO ✅ / TIPOGRAFIA: in attesa font ⏳

Fonte di verità = design system **Fitbill** (`fitbill/src/styles.css`, token OKLCH).
Conversione OKLCH→sRGB con **gamut-fitting CSS Color 4** (riduzione di chroma fino
al bordo gamut, non troncamento). Brand verificato = **`#FF5B34`** (atteso ~#FF5B34).
Grigi neutri combaciano con la scala Tailwind v4 (validazione pipeline).

Decisioni utente applicate: tinte selezione → arancio tenue; appflowy_ui → brand +
semantici Fitbill completi.

**Token applicati (brand + semantici, light/dark):**
- brand/accent: `#FF5B34` (hover scuro `#E7451B`; in dark hover `#FF8C71`)
- destructive: `#E40016` (light) / `#FF6568` (dark)
- warning: `#F9AD26`; success: `#009A46` (light) / `#03A14A` (dark)
- info: `#006FD8` (light) / `#53A0FF` (dark)
- tinte selezione/hover legacy → arancio tenue `#FFE9E3`/`#FFF4F1`

**File toccati (colori):**
- `packages/flowy_infra/lib/colorscheme/default_colorscheme.dart` — accent
  (`main1`/`main2`/`primary`/`darkMain1`/`darkMain2`) cyan→brand; `red`/`yellow`/
  `green`→destructive/warning/success; retint `hover`/`selector`/`tint9`. (commit accent + semantici)
- 14 file in `lib/` — 23 istanze hardcoded `Color(0xFF00BCF0)` + `_primaryColor`
  mobile + 2 commenti → `#FF5B34` (sidebar, date_picker, selection menu, mobile
  toolbar, editor plugins, ai_chat banner). ✅ il PROMEMORIA sulle hardcoded è RISOLTO.
- `packages/appflowy_ui/lib/src/theme/data/appflowy_default/semantic.dart` — token
  `theme*`/`action`/`skyline`/`textHighlight`/`textSelect` cyan→brand; semantici
  info/success/warning/error→valori Fitbill (light+dark). `featured`(purple) e
  neutri NON toccati. Tinte chiare `info` (blue100/200) mantenute (info resta blu).

**⚠️ Caveat appflowy_ui / JSON:** `semantic.dart` è autogenerato da
`script/*.tokens.json` via `generate_theme.dart`. È stato editato il **dart
generato** (ciò che compila e gira), NON i JSON sorgente, perché: (a) il generatore
emette *riferimenti a token* non literal, (b) non è eseguibile/verificabile in
questo ambiente (manca dart). Se in futuro si rilancia `generate_theme.dart`, il
brand tornerebbe ciano. Follow-up per renderlo persistente: aggiungere una rampa
`Brand` orange a `Primitive.Mode 1.tokens.json`, ripuntare i token `theme-*`/
`Skyline` e i semantici nei JSON, poi rigenerare.

**Temi alternativi** (`dandelion`/`lemonade`/`lavender`) NON toccati: sono temi
opzionali selezionabili, non il brand di default.

**Tipografia — FATTO ✅**
- Font: **heading = Tex Gyre Heros** (file `.otf` forniti dall'utente, GUST Font
  License), **body/UI = Geist Sans** (scelta utente al posto di Inter; OFL, scaricato
  ufficiale da vercel/geist-font). Mono invariato (RobotoMono).
- File font in `assets/fonts/Geist/` (8 pesi TTF + OFL) e
  `assets/fonts/TexGyreHeros/` (regular + condensed regular OTF) + `README.md` licenze.
- `pubspec.yaml`: dichiarate famiglie `Geist`, `Tex Gyre Heros`, `Tex Gyre Heros Cn`.
- Wiring:
  - `base_appearance.dart`: costanti `builtInBodyFontFamily='Geist'`,
    `builtInHeadingFontFamily='Tex Gyre Heros'`; `getTextTheme` splitta
    heading (display*/title* → Heros) vs body (body* → Geist) quando si usa il
    default. Font utente selezionato → applicato a tutto (comportamento invariato).
  - `google_fonts_extension.dart`: Geist/Heros/Heros Cn registrati come built-in
    (NON scaricati da Google Fonts).
  - `desktop_appearance.dart` + `mobile_appearance.dart`: `ThemeData.fontFamily`
    default → Geist; tooltip/callout/caption → Geist.
  - `app_widget.dart`: anche il tema `appflowy_ui` usa Geist di default.
- Note: gli heading mantengono i pesi AppFlowy esistenti (w600); Tex Gyre Heros è
  fornito solo in regular (Fitbill usa w400 per gli heading) → Flutter sintetizza il
  grassetto. Se preferisci la resa Fitbill esatta (heading w400) è una modifica
  banale. I componenti `appflowy_ui` usano Geist anche per gli heading (no split).

**Fix colore aggiuntivi (durante la tipografia):** sostituiti residui brand-cyan
`#00C8FF`/`#00B5FF` (indicatori tab, hover drag, sidebar resizer, hover azioni
tabella, pulsanti swipe mobile, `primaryColorLight` mobile) → `#FF5B34`. NON toccati
`builtInSpaceColors` e `SelectOptionColorPB.Blue` (opzioni colore utente).

**Logo / icone — App icon: PRONTO (da generare in locale) ⏳ / Logo in-app: in attesa wordmark ⏳**

Decisione utente: **app icon = riquadro arancione tinta unita `#FF5B34`, minimalista**
(nessun simbolo). Master generati e committati:
- `assets/brand/alfred_icon_1024.png` (solid #FF5B34, full-bleed)
- `assets/brand/alfred_icon_foreground_1024.png` (trasparente, foreground adattiva)

Config `flutter_launcher_icons` predisposta in `pubspec.yaml` (android adattiva con
background `#FF5B34`, ios con remove_alpha, macos, web con theme_color `#FF5B34`,
windows). **Da eseguire in locale** (qui non c'è Flutter/dart):
```bash
cd frontend/appflowy_flutter && flutter pub get && dart run flutter_launcher_icons
```
Questo rigenera: android `mipmap-*/ic_launcher*`, iOS/macOS asset catalog, web
`web/icons/*`, windows `app_icon.ico`. (Linux `linux/packaging/assets/logo.png` e lo
splash `assets/images/appflowy_launch_splash.jpg` vanno sostituiti a mano se serve.)

**Logo in-app mark — FATTO ✅:** `resources/flowy_icons/16x/app_logo.svg` e
`40x/app_logo.svg` sostituiti con un quadrato arancione `#FF5B34` arrotondato
(minimalista, coerente con l'icona). Usati da `FlowySvgs.app_logo_s/_xl`.
NB: `assets/flowy_icons/` è generato da `resources/flowy_icons/` (rebuild/codegen
per propagare).

**Logo in-app "con testo" (wordmark) — FATTO ✅:**
`resources/flowy_icons/40x/app_logo_with_text_{light,dark}.svg` rigenerati =
mark arancione `#FF5B34` + "Alfred" in **Tex Gyre Heros**, testo convertito in
**tracciati SVG** (via fontTools, così rende in `flutter_svg`). Testo `#0A0A0A`
(light) / `#FAFAFA` (dark).

**ai_chat_logo, logo legacy e splash — FATTO ✅:**
- `resources/flowy_icons/16x/ai_chat_logo.svg` → mark arancione `#FF5B34`.
- `assets/images/flowy_logo.svg` → mark arancione; `flowy_logo_with_text.svg` /
  `flowy_logo_dark_mode.svg` → wordmark Alfred (Tex Gyre Heros, tracciati).
- `assets/images/appflowy_launch_splash.jpg` → splash sfondo bianco + wordmark
  Alfred centrato (1696×928, `BoxFit.cover`).

Unico passo rimasto per le icone: lanciare in locale
`flutter pub get && dart run flutter_launcher_icons` per le icone di sistema.

---

## VERIFICA FINALE FASE 1
- ✅ Nessun crate Rust / package interno rinominato. Verificato presenza intatta:
  `appflowy_backend` (818 file), `appflowy_editor` (406), `appflowy_board` (13),
  `flowy_infra` (707), `flowy-core` (8), `flowy-user` (210).
- ✅ Nessun crate Rust / `Cargo.toml` / `*.toml` / protobuf modificato. (Il
  `pubspec.yaml` del client è stato modificato SOLO per dichiarare i font del brand —
  nessuna rinomina di package.)
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
1. Logo/icone: scegliere approccio (`icon_white_label.sh` vs `flutter_launcher_icons`),
   fornire SVG/PNG sorgente, poi generare e sostituire gli asset.
2. (Opz.) Rendere persistente il rebrand appflowy_ui aggiornando i JSON token +
   rigenerando con `generate_theme.dart` (vedi caveat 1.3).
3. (Opz. tipografia) Se si vuole la resa Fitbill esatta: heading a peso w400; font
   Heros bold/italic e Heros Cn se servono pesi aggiuntivi; eventuale Geist Mono al
   posto di RobotoMono per il codice.
4. Build di verifica locale macOS con i comandi sopra; confronto visivo: brand
   arancione-corallo su pulsanti primari, link, selezioni, accenti (light + dark) +
   heading in Tex Gyre Heros, testo in Geist.
