# Entwicklung und Regeln für Coding Agents

Vor Änderungen `PRODUCT.md`, `ARCHITECTURE.md` und `DESIGN.md` lesen; bei
UI-Arbeiten zusätzlich das passende PNG unter `docs/mockups/` öffnen.
Diese Dateien müssen den tatsächlichen Implementierungsstand beschreiben.

## Clean Code

- Kleine, zusammenhängende Features und Widgets mit einer klaren Aufgabe.
- Aussagekräftige Namen, unveränderliche Modelle und explizite Typen an Grenzen.
- Geschäftsregeln in Domain, SQL und native APIs in Data, Darstellung in UI.
- Bestehendes Verhalten und gespeicherte Nutzerdaten erhalten.
- Duplikate an fachlich gemeinsamer Stelle entfernen; keine vorsorglichen
  Frameworks, globalen Service-Locators oder ungenutzten Abstraktionen einführen.
- Keine Datenbankzeilen oder `dynamic` in neuen Präsentationsschnittstellen.
- Kein stilles Verschlucken von Fehlern. Lade-, Fehler- und Leerzustände gestalten.
- Ressourcen freigeben, veraltete asynchrone Ergebnisse vermeiden und
  `mounted` vor späteren UI-Zugriffen prüfen.
- Kommentare erklären Annahmen und Gründe; selbsterklärenden Code nicht nacherzählen.
- Keine pauschalen Lint-Unterdrückungen oder abgeschwächten Tests für grüne Checks.
- Refactorings schrittweise durchführen und bestehende Schulden ehrlich benennen.

Die Analyse aktiviert `strict-casts`, `strict-inference`, `strict-raw-types`,
Flutter-Lints sowie die Prüfung unbehandelter Futures.

## Lokale Prüfung

```sh
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Verhaltensänderungen benötigen aussagekräftige Regressionstests. UI-Tests
prüfen Interaktion, echte Zustände, kleine Fenster und vorhandene Navigation.
Zeitabhängige Tests verwenden feste Daten statt den aktuellen Wochentag.
Für den visuellen Vergleich die Desktop-Vorschau unter
`lib/ui/today/today_preview.dart` verwenden:

```sh
flutter widget-preview start
```

Vorschauen dürfen keine transitiven Abhängigkeiten auf native Datenbanken,
`dart:io` oder FFI erhalten. Echte Datenbankintegration separat testen.

## Auslieferung

Windows-Paket mit `powershell -File scripts/package_windows.ps1` erstellen.
Das Skript baut auch die native Offline-Diktat-Integration. SDK, native
SQLite-Artefakte und das Whisper-Modell können beim Build Netzwerk benötigen;
die ausgelieferte Anwendung läuft offline. Den gesamten Release-Ordner
mit DLLs und `data` ausliefern. Ein echter Windows-Release-Test steht noch aus.

## Fertig-Kriterium

Code formatiert, Analyse ohne Befunde, relevante Tests bestanden,
Mockup visuell verglichen und Dokumentation aktualisiert. Im Abschlussbericht
Änderungen, Prüfungen und verbleibende Einschränkungen nennen. Ein bestandener
Analyzer allein belegt weder korrektes Verhalten noch visuelle Übereinstimmung.

Der schmale Mockup-Test für 700 × 700 Pixel prüft die kompakte
Datumssteuerung; der frühere 64-Pixel-RenderFlex-Overflow ist behoben. Die
Theme- und Sidebar-Tests sowie die übrigen Tests laufen durch; die
Farbumstellung verändert keine Layoutgrenzen.
