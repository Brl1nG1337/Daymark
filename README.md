# Daymark

Eigenständige, vollständig lokale Flutter-Desktop-App für Klassen, Stundenplan, Anwesenheit und Schüleranmerkungen.

## Stand

Implementiert: Passwortdialog, verschlüsselte Drift/SQLite-Datenbank, Klassen und Schüler, wiederkehrende Stundenplan-Einträge mit Gültigkeitszeitraum, Tages-Dashboard, NRW-Ferien/Feiertage und eigene schulfreie Tage, Anwesenheitsstatus, Stundenabschluss, Anmerkungen und Schülerhistorie.

Offline-Diktat ist über eine native Windows-Mikrofonaufnahme und ein lokal mitgeliefertes `whisper.cpp`-Modell angebunden. Noch offen: echter Windows-Release-Test und redaktioneller UX-Schliff. Die App enthält absichtlich keinen Netzwerkcode. Die Datenbank liegt im App-Support-Verzeichnis des Windows-Benutzers; das Passwort ist nicht wiederherstellbar.

## Entwicklung

```sh
flutter pub get
flutter analyze
flutter test
powershell -File scripts/package_windows.ps1
```

Das Paket-Skript baut die Windows-App und `whisper.cpp`, lädt einmalig das mehrsprachige Basismodell und erzeugt `build/Daymark-Windows.zip`. Die SQLite3MultipleCiphers-Native-Assets werden beim ersten Build durch den `sqlite3`-Build-Hook bezogen. Dafür braucht der Entwicklungsrechner einmalig Netzwerkzugang. Die fertige App braucht ihn nicht. Für Windows muss der gesamte `Release`-Ordner mit EXE, DLLs und `data` ausgeliefert werden.

NRW-Ferien: https://bass.schule.nrw/191.htm. Die enthaltenen Daten decken die veröffentlichten Termine bis 2029/30 ab; bewegliche Ferientage werden lokal ergänzt.

## Vorgaben für Coding Agents

Produktverhalten: [PRODUCT.md](docs/PRODUCT.md), Architektur:
[ARCHITECTURE.md](docs/ARCHITECTURE.md), visuelle Vorgaben:
[DESIGN.md](docs/DESIGN.md), Entwicklungs- und Clean-Code-Regeln:
[DEVELOPMENT.md](docs/DEVELOPMENT.md). Mockups liegen in `docs/mockups/`.
