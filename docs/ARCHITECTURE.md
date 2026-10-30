# Architektur

Daymark ist eine lokale Flutter-Desktop-App. Produktionsziel ist Windows;
Linux dient zusätzlich der Entwicklung. Die Anwendung benötigt zur Laufzeit
keinen Netzwerkzugriff.

Windows begrenzt das äußere Fenster über `WM_GETMINMAXINFO` auf mindestens
900 × 600 logische Pixel und höchstens die Größe des aktuellen Monitors.
Die Mindestgröße wird mit der Fenster-DPI in physische Pixel umgerechnet;
Maximieren folgt dem verfügbaren Arbeitsbereich von Windows. Linux setzt
GTK-Geometriegrenzen mit 900 × 600 logischen Pixeln als Minimum und dem
Arbeitsbereich des aktuellen Monitors als Maximum. Das Startfenster bleibt
1280 × 720.

## Schichten und Abhängigkeiten

- `lib/domain/`: fachliche Modelle und Regeln, unabhängig von Flutter und SQL.
  `today_schedule.dart` enthält typisierte Tagesdaten und Zeitberechnung.
- `lib/data/`: Persistenz, native Integrationen und Adapter.
  `DaymarkStore` verwaltet Drift/SQLite; `TodayRepository` wandelt dessen
  Datenbankzeilen in `TodaySchedule` und `TodayLesson` um.
  `DayNotesRepository` wandelt datumsgebundene Notizen in `DayNote` um.
- `lib/ui/`: Darstellung und Benutzerinteraktion.
  `TodayPage` besitzt Ladezustand, ausgewähltes Datum und Uhr-Timer.
  `TodayView` und seine Zeilen erhalten ausschließlich Daten und Callbacks.
  `desktop_date_picker_dialog.dart` kapselt die responsive, für Desktopfenster
  vergrößerte Datumsauswahl ohne Persistenzzugriff.
  `ui/day_notes/` besitzt den unabhängigen Lade- und Bearbeitungszustand der
  Tagesnotizen für das ausgewählte Datum. `ui/lesson_preparation/` kapselt
  Modellzustand und Editor für die Vorbereitungsnotizen einer konkreten Stunde;
  das typisierte Repository trennt die UI von den Datenbankzeilen.
  `DaymarkSidebar` und `theme/daymark_theme.dart` definieren den gemeinsamen Rahmen.
  Das Theme trennt die feste Schul-Markenpalette von den semantischen Light- und
  Dark-Tokens. Eine `ThemeExtension` stellt die Tokens zusätzlich über den
  Widget-Kontext bereit; zentrale Material-Komponententhemes leiten daraus
  Zustände, Formfelder, Dialoge, Navigation und Scrollbars ab.
  `ui/classes/`, `ui/planning/` und `ui/settings/` kapseln die weiteren
  Mockup-Screens. `ui/lesson_detail/lesson_detail_page.dart` kapselt den Stundendetail-Screen
  und wandelt die noch Map-basierten Store-Ergebnisse an seiner Grenze in
  private, typisierte Präsentationsdaten um. Schreibaktionen sperren
  parallele Eingaben; Bearbeitungen werden bei Wechseln auf ungespeicherte
  Änderungen geprüft.
- `lib/main.dart`: Einstieg, Passwortdialog und Lebenszyklus der Datenbank.

Abhängigkeitsrichtung: UI → Data → Domain; Domain importiert weder UI noch Data.
SQL und Datenbank-Maps gehören nicht in neue Darstellungswidgets. Der App-Rahmen übergibt typisierte Stunden an den Detail-Screen.

## Persistenz

`DaymarkStore` verwendet Drift mit explizitem SQL, Schema-Version 6 und
SQLite3MultipleCiphers. Das Passwort entsperrt die Datenbank im lokalen
App-Support-Verzeichnis. Es gibt keine Passwortwiederherstellung.
Schreibvorgänge mit mehreren zusammengehörigen Schritten sind transaktional.
Das Rückgängigmachen eines Stundenstarts entfernt Bemerkungen, Anwesenheiten
und die noch nicht abgeschlossene Stunde gemeinsam in einer Transaktion.
SQL-Werte werden parametrisiert. Schemaänderungen müssen bestehende Dateien
weiter öffnen können; `CREATE TABLE IF NOT EXISTS` allein ist keine Migration.
Kalendertage bleiben in der Persistenz und an bestehenden Store-Schnittstellen
kanonisch als `JJJJ-MM-TT` gespeichert. Die UI formatiert und validiert sie an
der Schichtengrenze zentral als deutsches `TT.MM.JJJJ`; so ändern sich weder
Sortierreihenfolge noch vorhandene Nutzerdaten.

Migrationen von Drift-`user_version` 1 bis 5 auf 6 laufen transaktional.
Fehlende Stundenfelder, die Einstellungstabelle, `day_notes` und
`lesson_preparations` werden ergänzt; vorhandene
Inhalte bleiben erhalten. Dies gilt auch für ältere Dateien, deren
`app_meta.version` bereits 2 meldet, während `user_version` noch 1 ist.
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

`lib/ui/daymark_app.dart` enthält vor allem Navigation und einen älteren
Texteingabedialog. `DaymarkStore` liefert für weitere Abfragen noch Maps; neue
Feature-Grenzen wandeln sie in typisierte Präsentationsdaten um. Eine gemeinsame
getypte Repository-Schicht für alle Features steht noch aus.

Schema-Version 6 begrenzt Bemerkungen auf einen Eintrag je Stunde und Schüler
und führt vorhandene Mehrfacheinträge ohne Inhaltsverlust zusammen. Version 5
ergänzte `lesson_preparations`, Version 4 `day_notes` und Version 3
`app_settings`.
Bearbeitungen bereits verwendeter
Stundenplanplätze legen eine neue gültige Version an, damit historische
Stundenzeiten erhalten bleiben. Backup-Export kopiert
nach einem SQLite-Checkpoint die verschlüsselte Datenbank. Ein Import prüft
Passwort und Integrität vor dem Ersetzen und behält die vorherige Datei als
verschlüsselte `.before-import`-Kopie bis zur Löschung der App-Daten.
Passwortwechsel nutzt SQLite3MultipleCiphers `rekey` und prüft den neuen
Schlüssel anschließend.
Nach erfolgreichen Einstellungsaktionen, einschließlich Backup-Export, wird
die Einstellungsansicht mit einem synchronen `setState`-Callback neu geladen;
das asynchrone Laden selbst läuft außerhalb des Callbacks.

Die Einstellungen zeigen responsive, thematisch gruppierte Karten; `ui/settings/free_days_dialog.dart`
verwaltet eigene schulfreie Tage über den bestehenden Store. Das Linux-Fenster
lädt sein Icon aus dem Flutter-Asset-Bundle; Windows verwendet die ICO-Ressource.
`ui/settings/lesson_times_dialog.dart` kapselt Formularzustand, Validierung und
Fehleranzeige der gemeinsamen Unterrichtszeiten-Bearbeitung; der Store schreibt
die acht überschneidungsfrei geprüften Startzeiten in einer Transaktion.
