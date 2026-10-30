# Produkt

Daymark unterstützt Lehrkräfte bei Klassenverwaltung, Stundenplanung,
Anwesenheit und Schüleranmerkungen. Daten bleiben lokal und verschlüsselt.
Primäre Zielplattform ist Windows Desktop. UI-Sprache ist Deutsch.
Alle sichtbaren Kalenderdaten, Datumseingaben und Datumslisten verwenden
deutsche Formate und Bezeichnungen. Datumseingaben erfolgen als `TT.MM.JJJJ`.

## Bestehende Funktionen

Passwortschutz, Klassen und Schüler mit zeitabhängiger Klassenzugehörigkeit,
wiederkehrende Stundenplanplätze mit Gültigkeitszeitraum, Stunden starten und
abschließen, Anwesenheit bearbeiten, Stundeninhalt, Hausaufgaben, Anmerkungen,
NRW-Schulkalender, eigene freie Tage und Offline-Diktat.

## Unterricht-Screen

- Standardauswahl ist das aktuelle lokale Datum.
- Pfeile wechseln genau einen Kalendertag, auch über Wochen-, Monats- und
  Jahresgrenzen. Der Kalender wählt ein beliebiges Datum; „Heute“ setzt zurück.
- Unterricht zeigt Stunden der Auswahl nach Stundennummer und Startzeit.
- Neben dem Unterricht stehen die „Tagesnotizen“ für das ausgewählte
  Datum. Mehrere Einträge lassen sich unabhängig von Unterrichtsstunden anlegen,
  bearbeiten und löschen. Das funktioniert auch für vergangene und zukünftige
  Tage.
- Abgeschlossen ist ausschließlich eine ausdrücklich abgeschlossene Stunde.
  Vergangene Uhrzeit schließt eine Stunde nicht automatisch ab.
- Begonnen bezeichnet eine gestartete, noch nicht abgeschlossene Stunde.
  Der Start kann in den Stundendetails nach Bestätigung rückgängig gemacht
  werden; dabei werden die zugehörigen Stundendaten gelöscht.
- Die zeitlich laufende, nicht abgeschlossene Stunde wird blau hervorgehoben.
  Die Zeitmarkierung aktualisiert sich minütlich.
- Eine Stunde öffnen führt in ihre bestehenden Details. Das Starten bleibt
  eine eigene Aktion und erfolgt nicht bereits beim Öffnen der Übersicht.
- Ferien, Feiertage und eigene freie Tage erscheinen als Hinweis. Vorhandene
  Stunden bleiben sichtbar; ein Kalenderhinweis löscht keine Unterrichtsdaten.
- Leere Tagespläne bündeln Kalenderhinweis und Leerzustand in einer kompakten
  Darstellung; Ladefehler erlauben Wiederholen.
  Notizen bleiben auch bei einem Ladefehler des Unterrichtsplans zugänglich.

## Stunde Detail

- Das Öffnen einer Stunde aus „Unterricht“ führt in den
  Stundendetail-Arbeitsbereich.
  Geplante Stunden werden erst über „Stunde starten“ persistent angelegt.
- Geplante Stunden besitzen eigene Vorbereitungsnotizen. Sie werden unabhängig
  vom Stundenstart über Stundenplanplatz und Datum gespeichert, bleiben beim
  Start erhalten und sind danach im Reiter „Vorbereitung“ sichtbar.
- Begonnene Stunden zeigen Anwesenheit und Stundeninhalt in getrennten Reitern.
  Anwesenheiten und schülerbezogene Bemerkungen sind bis zum Abschließen
  bearbeitbar; abgeschlossene Stunden lassen sich ausdrücklich erneut öffnen.
- Pro Stunde und Schüler gibt es höchstens eine Bemerkung. Änderungen werden
  nach kurzer Eingabepause automatisch gespeichert und beim erneuten Öffnen
  weiterbearbeitet. Diktat verwendet weiterhin das lokale Windows-Modell.

## Annahmen und Grenzen

Das Schema speichert bisher nur Startzeiten. Die Unterrichtsansicht berechnet
das Ende mit 45 Minuten Unterrichtsdauer. Abweichende Dauern müssen künftig über
explizite Endzeiten oder zentrale Stundenzeiten modelliert werden. Fehlende
oder ungültige Startzeiten erscheinen als „–“ und werden nicht zeitlich markiert.
Mockup-Datum, Beispielklassen und Fächer sind keine produktiven Vorgabedaten.

Die Seitenleiste führt zu Unterricht, Klassen, Stundenplan und Einstellungen.
Klassen zeigen eine globale Schülersuche, eine kompakte Klasseninfo, eine
Schülerliste mit direkter Hinzufügen-Aktion, Schuljahres-Fehlzeiten und Schülerdetails mit
Bemerkungen. Stundenplan zeigt Einträge im Wochenraster. Schulfreie Tage werden unter
Einstellungen verwaltet. Einstellungen zeigen thematisch gruppierte Karten und speichern Unterrichtszeiten, aktuelles
Schuljahr, Planungs-Startdatum und Designwahl. Hell und Dunkel werden direkt
über einen Toggle in der App-Karte umgeschaltet. Unterrichtszeiten dienen als
Vorgabe für neue Plan-Einträge; bestehende Startzeiten bleiben erhalten. Alle
acht Startzeiten werden gemeinsam in einem Dialog bearbeitet, vor dem Speichern
auf gültige, überschneidungsfreie Uhrzeiten geprüft und atomar übernommen.
Verschlüsselte Backups können exportiert und nach Prüfung importiert werden;
Passwortwechsel und bestätigtes Löschen der lokalen App-Daten sind möglich.
Ein importiertes Diktatmodell liegt im lokalen App-Support-Verzeichnis.
Keine Cloud-Synchronisation, Telemetrie oder Online-Diktat ergänzen.
