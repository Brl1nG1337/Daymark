# Architektur

Daymark ist eine lokale Flutter-Desktop-App. Produktionsziel ist Windows;
Linux dient zusätzlich der Entwicklung. Die Anwendung benötigt zur Laufzeit
keinen Netzwerkzugriff.

## Schichten und Abhängigkeiten

- `lib/domain/`: fachliche Modelle und Regeln, unabhängig von Flutter und SQL.
  `today_schedule.dart` enthält typisierte Tagesdaten und Zeitberechnung.
- `lib/data/`: Persistenz, native Integrationen und Adapter.
  `DaymarkStore` verwaltet Drift/SQLite; `TodayRepository` wandelt dessen
  Datenbankzeilen in `TodaySchedule` und `TodayLesson` um.
- `lib/ui/`: Darstellung und Benutzerinteraktion.
  `TodayPage` besitzt Ladezustand, ausgewähltes Datum und Uhr-Timer.
  `TodayView` und seine Zeilen erhalten ausschließlich Daten und Callbacks.
  `DaymarkSidebar` und `theme/daymark_theme.dart` definieren den gemeinsamen Rahmen.
- `lib/main.dart`: Einstieg, Passwortdialog und Lebenszyklus der Datenbank.

Abhängigkeitsrichtung: UI → Data → Domain; Domain importiert weder UI noch Data.
SQL und Datenbank-Maps gehören nicht in neue Darstellungswidgets. Bestehende
Stundendetails erhalten ihre Map über eine explizite Übergabe im App-Rahmen.

## Persistenz

`DaymarkStore` verwendet Drift mit explizitem SQL, Schema-Version 2 und
SQLite3MultipleCiphers. Das Passwort entsperrt die Datenbank im lokalen
App-Support-Verzeichnis. Es gibt keine Passwortwiederherstellung.
Schreibvorgänge mit mehreren zusammengehörigen Schritten sind transaktional.
SQL-Werte werden parametrisiert. Schemaänderungen müssen bestehende Dateien
weiter öffnen können; `CREATE TABLE IF NOT EXISTS` allein ist keine Migration.

Der Übergang von Drift-`user_version` 1 auf 2 besitzt eine explizite,
transaktionale Migration. Sie ergänzt fehlende Stundenfelder und erhält
bereits vorhandene Felder und Inhalte. Das gilt auch für ältere Dateien,
deren `app_meta.version` bereits 2 meldet, während `user_version` noch 1 ist.
Verschlüsselte Dateitests prüfen beide Ausgangszustände und erneutes Öffnen.
Die bisherige Sammelmeldung beim Öffnen unterscheidet technische Fehler
weiterhin nicht von einem falschen Passwort.

`dayEntries` vereinigt gültige Stundenplanplätze mit vorhandenen Stunden einer
Datumsauswahl, einschließlich historischer Stunden außerhalb der aktuellen
Slot-Gültigkeit. `weekEntries` verwendet dieselbe Tagesabfrage.

## Zustandsverwaltung

Lokaler Widget-State reicht für die bisherige Größe aus. Futures werden in
`TodayPage` bei Initialisierung und Datumswechsel erzeugt, nicht bei jedem
Build. Alte Tagesdaten werden beim Laden einer neuen Auswahl ausgeblendet.
Timer und Controller werden freigegeben. Nach asynchronen Operationen vor
UI-Zugriff `mounted` prüfen. Fehlerzustände müssen sichtbar und wiederholbar sein.

## Bestehende technische Schulden

`lib/ui/daymark_app.dart` bündelt weiterhin Klassen, Planung, freie Tage,
Stundendetails und Dialoge. `DaymarkStore` liefert für diese Bereiche noch
Maps. Diese Bereiche bei ihrer jeweiligen Überarbeitung schrittweise in
Features und typisierte Adapter zerlegen. Die Heute-Umsetzung ist der erste
Schritt; das Gesamtprojekt ist damit noch nicht vollständig umstrukturiert.
Neue Features dürfen die große UI-Datei nicht weiter vergrößern.
