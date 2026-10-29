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
- Morgen zeigt den unmittelbar folgenden Kalendertag, auch am Wochenende.
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

## Annahmen und Grenzen

Das Schema speichert bisher nur Startzeiten. Die Heute-Ansicht berechnet das
Ende mit 45 Minuten Unterrichtsdauer. Abweichende Dauern müssen künftig über
explizite Endzeiten oder zentrale Stundenzeiten modelliert werden. Fehlende
oder ungültige Startzeiten erscheinen als „–“ und werden nicht zeitlich markiert.
Mockup-Datum, Beispielklassen und Fächer sind keine produktiven Vorgabedaten.

Die neue Seitenleiste folgt dem Heute-Mockup. „Planung“ öffnet den vorhandenen
Stundenplan. „Einstellungen“ enthält vorläufig die bisherige Verwaltung freier
Tage. Die vollständigen übrigen Mockups sind nachfolgende Arbeitsschritte.
Keine Cloud-Synchronisation, Telemetrie oder Online-Diktat ergänzen.
