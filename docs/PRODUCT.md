# Produkt

Daymark unterstützt Lehrkräfte bei Klassenverwaltung, Stundenplanung,
Anwesenheit und Schüleranmerkungen. Daten bleiben lokal und verschlüsselt.
Primäre Zielplattform ist Windows Desktop. UI-Sprache ist Deutsch.

## Bestehende Funktionen

Passwortschutz, Klassen und Schüler mit zeitabhängiger Klassenzugehörigkeit,
wiederkehrende Stundenplanplätze mit Gültigkeitszeitraum, Stunden starten und
abschließen, Anwesenheit bearbeiten, Stundeninhalt, Hausaufgaben, Anmerkungen,
Schülerhistorie, NRW-Schulkalender, eigene freie Tage und Offline-Diktat.

## Heute-Screen

- Standardauswahl ist das aktuelle lokale Datum.
- Pfeile wechseln genau einen Kalendertag, auch über Wochen-, Monats- und
  Jahresgrenzen. Der Kalender wählt ein beliebiges Datum; „Heute“ setzt zurück.
- Unterricht zeigt Stunden der Auswahl nach Stundennummer und Startzeit.
- Neben dem Unterricht stehen Tagesnotizen für das ausgewählte Datum. Mehrere
  Notizen lassen sich unabhängig von Unterrichtsstunden anlegen, bearbeiten und
  löschen. Das funktioniert auch für vergangene und zukünftige Tage.
- Abgeschlossen ist ausschließlich eine ausdrücklich abgeschlossene Stunde.
  Vergangene Uhrzeit schließt eine Stunde nicht automatisch ab.
- Begonnen bezeichnet eine gestartete, noch nicht abgeschlossene Stunde.
- Die zeitlich laufende, nicht abgeschlossene Stunde wird blau hervorgehoben.
  Die Zeitmarkierung aktualisiert sich minütlich.
- Eine Stunde öffnen führt in ihre bestehenden Details. Das Starten bleibt
  eine eigene Aktion und erfolgt nicht bereits beim Öffnen der Übersicht.
- Ferien, Feiertage und eigene freie Tage erscheinen als Hinweis. Vorhandene
  Stunden bleiben sichtbar; ein Kalenderhinweis löscht keine Unterrichtsdaten.
- Leere Tagespläne zeigen „Keine Stunde geplant.“; Ladefehler erlauben Wiederholen.
  Notizen bleiben auch bei einem Ladefehler des Unterrichtsplans zugänglich.

## Stunde Detail

- Das Öffnen einer Stunde aus „Heute“ führt in den Stundendetail-Arbeitsbereich.
  Geplante Stunden werden erst über „Stunde starten“ persistent angelegt.
- Begonnene Stunden zeigen Anwesenheit und Stundeninhalt in getrennten Reitern.
  Anwesenheiten und schülerbezogene Bemerkungen sind bis zum Abschließen
  bearbeitbar; abgeschlossene Stunden lassen sich ausdrücklich erneut öffnen.
- Vorhandene Bemerkungen bleiben einzeln auswählbar. Die Schülerhistorie ist
  aus der Anwesenheitsliste erreichbar. Diktat verwendet weiterhin das lokale
  Windows-Modell.

## Annahmen und Grenzen

Das Schema speichert bisher nur Startzeiten. Die Heute-Ansicht berechnet das
Ende mit 45 Minuten Unterrichtsdauer. Abweichende Dauern müssen künftig über
explizite Endzeiten oder zentrale Stundenzeiten modelliert werden. Fehlende
oder ungültige Startzeiten erscheinen als „–“ und werden nicht zeitlich markiert.
Mockup-Datum, Beispielklassen und Fächer sind keine produktiven Vorgabedaten.

Die Seitenleiste führt zu Heute, Klassen, Stundenplan und Einstellungen. Klassen
zeigen eine globale Schülersuche, Schuljahres-Fehlzeiten und Schülerdetails mit
Bemerkungen. Stundenplan zeigt Einträge im Wochenraster. Schulfreie Tage werden unter
Einstellungen verwaltet. Einstellungen zeigen eine Liste mit einzelnen Dialogen und speichern Unterrichtszeiten, aktuelles
Schuljahr, Planungs-Startdatum und Designwahl. Unterrichtszeiten dienen als
Vorgabe für neue Plan-Einträge; bestehende Startzeiten bleiben erhalten.
Verschlüsselte Backups können exportiert und nach Prüfung importiert werden;
Passwortwechsel und bestätigtes Löschen der lokalen App-Daten sind möglich.
Ein importiertes Diktatmodell liegt im lokalen App-Support-Verzeichnis.
Keine Cloud-Synchronisation, Telemetrie oder Online-Diktat ergänzen.
