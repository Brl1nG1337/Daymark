# Design

## Referenzen

Die PNGs in `docs/mockups/` sind die visuelle Referenz. Für die Tagesansicht gilt
[Heute.png](mockups/Heute.png). Die anderen Mockups beschreiben künftige
Überarbeitungen; sie sind noch nicht vollständig umgesetzt.

## Heute

Das Desktop-Mockup hat 1586 × 992 Pixel. Seitenleiste: 228 Pixel, dunkelblau;
aktiver Eintrag: blau hinterlegt. Navigation: Heute, Klassen, Planung;
Einstellungen am unteren Rand. Bis zur Umsetzung des Einstellungs-Mockups
führt Einstellungen zur bestehenden Verwaltung schulfreier Tage.

Oben stehen Titel und Datumssteuerung in einer Reihe. Darunter teilen sich
Unterricht und Morgen den Inhaltsbereich ungefähr im Verhältnis 66:34.
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
Schmale Unterrichtszeilen zeigen den Status unter dem Fach. Header und
Panelüberschriften dürfen umbrechen. Lange Listen bleiben scrollbar.
Status wird mit Text und Symbolen vermittelt. Alle Stunden bleiben anklickbar,
auch abgeschlossene oder künftig geplante. Keine ausschließlich dekorativen
Schaltflächen ohne Funktion hinzufügen.

`lib/ui/today/today_preview.dart` enthält eine datenbankfreie Desktop-Vorschau.
Beispieldaten gehören ausschließlich in Vorschauen und Tests.
