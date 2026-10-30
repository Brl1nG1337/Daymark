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
Unterricht und „Vor- & Nachbereitung“ den Inhaltsbereich ungefähr im Verhältnis
66:34.
Die Datumsschaltfläche öffnet auf Laptop- und Desktopfenstern einen großzügigen
Kalenderdialog mit separater deutscher Lang- und Kurzdatumsanzeige, großen
Tageszielen und einer direkten „Heute“-Aktion. Bei geringer Breite ordnen sich
Datumsanzeige und Kalender untereinander an.
Die rechte Spalte zeigt datumsgebundene Notizkarten, eine Aktion zum Hinzufügen
und einen verständlichen Leerzustand. Das ursprüngliche Mockup zeigt dort noch
„Morgen“; diese Produktänderung ersetzt den Bereich.
An schulfreien oder ungeplanten Tagen bündelt das Unterrichtspanel Anlass und
Leerzustand in einer zentrierten Darstellung. Die Inhaltskarten sind am Kopf
ausgerichtet; auf breiten Fenstern teilen sie die Fläche ungefähr im Verhältnis
68:32. Der „Heute“-Button ist deaktiviert, wenn bereits der aktuelle Tag gewählt
ist.
Panels haben feine Konturen, acht Pixel Eckradius und keinen starken Schatten.
Unterrichtszeilen sind kompakt und mindestens 88 Pixel hoch, damit übliche
Schultage auch in niedrigen Desktopfenstern möglichst vollständig sichtbar
bleiben. Eine vertikale Zeitlinie
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
Pixelidentität zum PNG nicht garantiert. Titel: 34 Pixel, Paneltitel: 26 Pixel,
Stundentitel auf Desktop: 18 Pixel, Inhalte: 17 Pixel, Status: 16 Pixel.

## Anpassung und Bedienbarkeit

Unter 1000 Pixel Fensterbreite reduziert sich die Seitenleiste auf Symbole
mit Tooltips. Unter 850 Pixel Inhaltsbreite stehen die Panels untereinander.
Auf Windows und Linux gilt 900 × 600 logische Pixel als Mindestgröße; die
Höchstgröße richtet sich nach dem aktuellen Monitor. Bei der Mindestgröße
gelten die kompakten Layouts.
Schmale Unterrichtszeilen zeigen den Status unter dem Fach. Header und
Panelüberschriften dürfen umbrechen. Lange Listen bleiben scrollbar.
Status wird mit Text und Symbolen vermittelt. Alle Stunden bleiben anklickbar,
auch abgeschlossene oder künftig geplante. Keine ausschließlich dekorativen
Schaltflächen ohne Funktion hinzufügen.

`lib/ui/today/today_preview.dart` enthält eine datenbankfreie Desktop-Vorschau.
Beispieldaten gehören ausschließlich in Vorschauen und Tests.

## Stunde Detail

`Stunde Detail Screen.png` ist umgesetzt: Kopfzeile mit Rücknavigation und
Abschlussaktion sowie kleiner Rückgängig-Aktion für eine begonnene Stunde,
Reiter für Anwesenheit/Stundeninhalt, zweispaltige
Anwesenheitsliste bei genügend Breite sowie eine Bemerkungsseite für die
ausgewählte Person. Die Bemerkungsseite bindet das vorhandene lokale
Windows-Diktat ein.
Im Reiter Stundeninhalt stehen die Beschriftungen über den Eingabefeldern;
Platzhalter und Eingabetext beginnen auch in mehrzeiligen Feldern oben links.
Bei schmalen Fenstern ist die Anwesenheitstabelle horizontal scrollbar;
unter 980 Pixel Inhaltsbreite stehen Liste und Bemerkung untereinander.

## Weitere Screens

Klassen: Kopf mit globaler Suche und Klassenwahl. Eine kompakte Klassenzeile zeigt
Name und Schuljahr mit der Nebenaktion „Klasse bearbeiten“. Die Schülerliste
nutzt die verfügbare Breite und trägt die Hauptaktion „Schüler hinzufügen“.
Tabellenkopf und Schülerzeilen verwenden dasselbe Spaltenraster einschließlich
einer festen Pfeilspalte; Namen sind linksbündig, Kennzahlen und letzter Eintrag
zentriert. Der letzte Eintrag erscheint im deutschen Datumsformat.
Schülerdetails
ersetzen den Klasseninhalt und zeigen Bemerkungen und Fehlzeiten nach Schuljahr.
Stundenplan: Schuljahreswahl, Wochenraster und Eintragsdetails. Die Hauptaktion
heißt „Stunde hinzufügen“. Fach und Klasse stehen im Raster in getrennten
Zeilen; eine stabile, dezente Farbcodierung je Fach verbindet wiederkehrende
Stunden visuell. Fachname und Farbakzent bilden die primäre Ebene, die Klasse
erscheint als sekundäres Label. Tageskopf und Stundenachse sind gegenüber den
Eintragskarten abgesetzt; Auswahlzustände bleiben mit Kontur und Farbe auch
ohne die Fachfarbe eindeutig. Leere Felder bleiben zum Anlegen anklickbar. Das
Raster scrollt bei vielen Stunden vertikal. Alle Einträge sind zusätzlich über
eine Liste erreichbar.
Einstellungen: Karten in zwei Spalten gruppieren Schuljahr & Kalender, App,
Unterricht sowie Daten & Sicherheit. Die Designauswahl liegt zusammen mit den
übrigen App-Einstellungen in der App-Karte. Bei schmalen Fenstern stehen die
Karten untereinander. Die Zeilen öffnen jeweils einen eigenen Dialog. Die Zeile
„Unterrichtszeiten“ führt direkt in ein gemeinsames Formular für alle acht
Startzeiten; es gibt keinen vorgeschalteten Ansichts- oder zweiten
Bearbeitungsdialog.
Schulfreie Tage lassen sich dort anlegen und entfernen; NRW-Ferien
und Feiertage sind integriert. Das ältere Projekt-Mockup zeigt noch Unterrichtszeiten als eigene Liste und die alte
zweispaltige Anordnung und den Reiter für schulfreie Tage im Stundenplan.
Die Beispieldaten der PNGs werden
nicht in produktive Datenbanken eingespielt. Das Dunkel-Theme nutzt dieselben
Layout- und Statusregeln mit angepasster Farbpalette. Die Theme-Daten für Hell
und Dunkel werden unabhängig vom aktuellen Modus erstellt; die Designauswahl
wird nach dem Speichern sofort sichtbar und bleibt für den nächsten Start erhalten.

## Sprache

Die gesamte App verwendet für Schüler das generische Maskulin. Sichtbare Texte
verwenden „Schüler“ statt Schrägstrichformen oder Doppelnennungen.
Sichtbare Datumswerte verwenden deutsche Monats- und Wochentagsnamen. Kurze
Datumswerte und Eingaben erscheinen als `TT.MM.JJJJ`; ISO-Daten sind kein
Bestandteil der Benutzeroberfläche.
