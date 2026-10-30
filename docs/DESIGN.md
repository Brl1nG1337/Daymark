# Design

## Referenzen

Die PNGs in `docs/mockups/` sind die visuelle Referenz. Für die Tagesansicht gilt
[Heute.png](mockups/Heute.png). Klassen, Schülerdetails, Stundenplan und
Einstellungen orientieren sich an den übrigen vier PNGs. Die Laufzeitansichten wurden bei 1586 × 992 Pixel gerendert
und mit den Mockups verglichen; Schrift und Icons können je nach Plattform
abweichen.

Das Daymark-Logo aus `assets/branding/daymark-logo-v1.png` erscheint im
Anmeldebildschirm und in der breiten Seitenleiste auf heller Fläche, damit die
dunkelblaue Wortmarke lesbar bleibt. Die schmale Seitenleiste zeigt weiterhin
ein kompaktes Kalendersymbol. Das neue App-Icon wird als Windows-Ressource und Linux-Fenstericon verwendet.

## Heute

Das Desktop-Mockup hat 1586 × 992 Pixel. Seitenleiste: 228 Pixel, dunkelblau;
aktiver Eintrag: blau hinterlegt. Navigation: Heute, Klassen, Stundenplan;
Einstellungen am unteren Rand. Einstellungen öffnet den eigenen Screen;
schulfreie Tage liegen unter Einstellungen.

Oben stehen Titel und Datumssteuerung in einer Reihe. Darunter teilen sich
Unterricht und Tagesnotizen den Inhaltsbereich ungefähr im Verhältnis 66:34.
Die rechte Spalte zeigt datumsgebundene Notizkarten, eine Aktion zum Hinzufügen
und einen verständlichen Leerzustand. Das ursprüngliche Mockup zeigt dort noch
„Morgen“; diese Produktänderung ersetzt den Bereich.
Panels haben feine Konturen, acht Pixel Eckradius und keinen starken Schatten.
Unterrichtszeilen sind mindestens 115 Pixel hoch. Eine vertikale Zeitlinie
verbindet die Stunden; die aktuelle Stunde erhält eine hellblaue Fläche,
einen blauen Ring und die Aktion „Öffnen“. Abgeschlossene Stunden tragen einen
grünen Haken und „Abgeschlossen“. Geplante Stunden zeigen „Geplant“.

## Tokens

Verbindliche Farben liegen in `lib/ui/theme/daymark_theme.dart`:

| Rolle | Wert |
| --- | --- |
| Hintergrund | `#F7F9FB` |
| Panel | `#FCFDFF` |
| Seitenleiste | `#152C42` |
| Navigation aktiv | `#164B6C` |
| Primärtext | `#0D2043` |
| Sekundärtext | `#4C648A` |
| Kontur | `#DFE6EF` |
| Primäraktion | `#006FA6` |
| Aktuelle Stunde | `#0785FF` / Fläche `#E5F4FF` |
| Abgeschlossen | `#128348` |

Typografie nutzt die installierte Flutter-Plattformschrift. Es liegt keine
Originalschrift im Projekt vor; deshalb ist plattformübergreifende
Pixelidentität zum PNG nicht garantiert. Titel: 34 Pixel, Paneltitel: 28 Pixel,
Stundentitel und Inhalte auf Desktop: 21 Pixel, Status: 18 Pixel.

## Anpassung und Bedienbarkeit

Unter 1000 Pixel Fensterbreite reduziert sich die Seitenleiste auf Symbole
mit Tooltips. Unter 850 Pixel Inhaltsbreite stehen die Panels untereinander.
Auf Windows liegt die äußere Fenstergröße zwischen 900 × 600 und 1600 × 1000
logischen Pixeln; bei der Mindestgröße gelten die kompakten Layouts.
Schmale Unterrichtszeilen zeigen den Status unter dem Fach. Header und
Panelüberschriften dürfen umbrechen. Lange Listen bleiben scrollbar.
Status wird mit Text und Symbolen vermittelt. Alle Stunden bleiben anklickbar,
auch abgeschlossene oder künftig geplante. Keine ausschließlich dekorativen
Schaltflächen ohne Funktion hinzufügen.

`lib/ui/today/today_preview.dart` enthält eine datenbankfreie Desktop-Vorschau.
Beispieldaten gehören ausschließlich in Vorschauen und Tests.

## Stunde Detail

`Stunde Detail Screen.png` ist umgesetzt: Kopfzeile mit Rücknavigation und
Abschlussaktion, Reiter für Anwesenheit/Stundeninhalt, zweispaltige
Anwesenheitsliste bei genügend Breite sowie eine Bemerkungsseite für die
ausgewählte Person. Die Bemerkungsseite bindet das vorhandene lokale
Windows-Diktat ein.
Im Reiter Stundeninhalt stehen die Beschriftungen über den Eingabefeldern;
Platzhalter und Eingabetext beginnen auch in mehrzeiligen Feldern oben links.
Bei schmalen Fenstern ist die Anwesenheitstabelle horizontal scrollbar;
unter 980 Pixel Inhaltsbreite stehen Liste und Bemerkung untereinander.

## Weitere Screens

Klassen: Kopf mit globaler Suche, Klassenwahl und zwei Panels. Schülerdetails
ersetzen den Klasseninhalt und zeigen Bemerkungen und Fehlzeiten nach Schuljahr.
Stundenplan: Schuljahreswahl, Wochenraster und Eintragsdetails. Die Hauptaktion
heißt „Stunde hinzufügen“. Fach und Klasse stehen im Raster in getrennten
Zeilen; leere Felder bleiben zum Anlegen anklickbar. Das Raster scrollt bei
vielen Stunden vertikal. Alle Einträge sind zusätzlich über eine Liste erreichbar.
Einstellungen: eine durchgehende Liste öffnet für jeden Eintrag einen eigenen
Dialog. Schulfreie Tage lassen sich dort anlegen und entfernen; NRW-Ferien
und Feiertage sind integriert. Das bestehende Mockup zeigt noch die alte
zweispaltige Anordnung und den Reiter für schulfreie Tage im Stundenplan.
Die Beispieldaten der PNGs werden
nicht in produktive Datenbanken eingespielt. Das Dunkel-Theme nutzt dieselben
Layout- und Statusregeln mit angepasster Farbpalette. Die Theme-Daten für Hell
und Dunkel werden unabhängig vom aktuellen Modus erstellt; die Designauswahl
wird nach dem Speichern sofort sichtbar und bleibt für den nächsten Start erhalten.
