# Design

## Referenzen

Die PNGs in `docs/mockups/` sind die visuelle Referenz. Für die Tagesansicht gilt
[Heute.png](mockups/Heute.png). Klassen, Schülerdetails, Stundenplan und
Einstellungen orientieren sich an den übrigen vier PNGs. Die Laufzeitansichten wurden bei 1586 × 992 Pixel gerendert
und mit den Mockups verglichen; Schrift und Icons können je nach Plattform
abweichen.

Das Daymark-Logo aus `assets/branding/daymark-logo-v1.png` erscheint im
Anmeldebildschirm. Die breite Seitenleiste begrüßt Birgit Röling passend zur
lokalen Tageszeit mit „Guten Morgen“, „Guten Tag“ oder „Guten Abend“. In der
schmalen Seitenleiste steht dafür ein kompaktes Grußsymbol mit vollständigem
Tooltip. Oberhalb einer feinen Trennlinie setzt der Grußbereich den persönlichen
Einstieg ruhig von der Navigation ab. Das App-Icon wird als Windows-Ressource und Linux-Fenstericon
verwendet.

## Unterricht

Das Desktop-Mockup hat 1586 × 992 Pixel. Die breite Seitenleiste ist in der
Umsetzung 260 Pixel breit, damit der persönliche Gruß vollständig Platz findet;
aktiver Eintrag: blau hinterlegt. Navigation: Unterricht, Klassen, Stundenplan;
Einstellungen am unteren Rand. Einstellungen öffnet den eigenen Screen;
schulfreie Tage liegen unter Einstellungen.

Oben steht die Datumssteuerung ohne zusätzliche Seitenüberschrift. Das
ausgewählte Datum bildet mit 26 Pixel und fettem Schnitt die visuelle
Überschrift; die separate Aktion „Heute“ bleibt erhalten. Darunter teilen sich
Unterricht und „Tagesnotizen“ den Inhaltsbereich ungefähr im Verhältnis
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

Verbindliche Farben liegen ausschließlich in
`lib/ui/theme/daymark_theme.dart`. `DaymarkBrandColors` enthält nur die wenigen
subtilen Markenakzente; `DaymarkSemanticColors` ordnet sie und notwendige
kontraststarke Abstufungen Rollen zu. Screens greifen nicht auf eigene HEX-Werte
zurück.

| Rolle | Hell | Dunkel |
| --- | --- | --- |
| Hintergrund | `#F8F9F7` | `#171C1D` |
| Sekundärer Hintergrund | `#F1F4F1` | `#293132` |
| Oberfläche | `#FFFFFF` | `#202728` |
| Erhöhte Oberfläche | `#F1F4F1` | `#293132` |
| Primäraktion | `#327378` | `#8EBDB9` |
| Primär dezent | `#E5F0EF` | `#293F40` |
| Sekundärakzent / Salbei | `#DCE8DF` | `#34443C` |
| Warmer Akzent / Sand | `#F3E9D6` | `#4A4133` |
| Primärtext | `#263035` | `#F1F3F0` |
| Sekundärtext | `#667475` | `#A7B3B0` |
| Kontur / Trenner | `#E3E8E5` | `#343E3D` |

Weitere semantische Rollen sind `hover`, `selected`, `disabled`, `focus`,
`sidebar`, `success`, `warning`, `error` und `info` mit passenden
Vordergrundfarben. Buttons, Icon-Buttons, Formfelder, Dropdowns, Dialoge,
Checkboxen, Radio-Buttons, Switches, Tabs, Tooltips, Snackbars,
Fortschrittsanzeigen und Scrollbars werden zentral aus diesen Rollen gestaltet.
Die dezente Fachcodierung des Stundenplans verwendet nur noch die drei
zentralen Markenakzente für schmale Marker und Chips; die Kartenflächen bleiben
neutral. Status bleibt zusätzlich durch Text oder Symbol erkennbar.

Die Kontrastpaare für normalen Text, Primär-, Sekundär-, Akzent- und
Statusflächen werden automatisiert auf mindestens 4,5:1 geprüft; der Fokusring
auf mindestens 3:1. Dezente, nicht allein zustandstragende Panelkonturen folgen
den vorgegebenen Border-Werten.

Typografie nutzt die installierte Flutter-Plattformschrift. Es liegt keine
Originalschrift im Projekt vor; deshalb ist plattformübergreifende
Pixelidentität zum PNG nicht garantiert. Titel: 34 Pixel, Paneltitel: 26 Pixel,
Stundentitel auf Desktop: 18 Pixel, Inhalte: 17 Pixel, Status: 16 Pixel.

## Anpassung und Bedienbarkeit

Unter 1000 Pixel Fensterbreite reduziert sich die Seitenleiste auf Symbole
mit Tooltips. Unter 850 Pixel Inhaltsbreite stehen die Panels untereinander.
Die Beschriftungen und Symbole der Seitenleiste erhalten beim Hover einen
ruhigen Primärtext-Kontrast; ausgewählte Navigation verwendet den dezenten
Petrol-Hintergrund.
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
eine über die gesamte Inhaltsbreite gespannte, bei Bedarf horizontal
scrollbare Reiterleiste für Anwesenheit, Stundeninhalt und Vorbereitung, eine
einspaltige, vertikal scrollbare Anwesenheitsliste sowie eine Bemerkungsseite für die
ausgewählte Person. Die Bemerkungsseite bindet das vorhandene lokale
Windows-Diktat ein. Das Notizsymbol in der Anwesenheitsliste öffnet die eine
Bemerkung des Schülers für diese Stunde; vorhandene Bemerkungen werden am Schüler
sichtbar markiert. Die vier Anwesenheitszustände werden als semantisch beschriftete
Icons mit Tooltip statt als Buchstaben dargestellt. Die Bemerkungskarte erscheint
erst nach der Aktion am Notizsymbol; ohne Auswahl bleibt die Anwesenheitsliste
vollständig frei. Der Editor zeigt nur Schülername und
Textfeld; die redundante Stundenbeschreibung entfällt. Änderungen werden nach
kurzer Eingabepause automatisch gespeichert und durch einen kompakten Status
bestätigt. Alle drei Reiter verwenden oberhalb ihrer Inhaltskarten denselben
Außenabstand von 22 Pixeln.
Geplante Stunden zeigen neben der Startaktion einen Editor für
„Vorbereitungsnotizen“. Nach dem Start bleibt derselbe Inhalt über den Reiter
„Vorbereitung“ erreichbar; Tagesnotizen auf dem Unterricht-Screen bleiben davon
unabhängig. Der Kopf zeigt „Begonnen“ erst nach dem ausdrücklichen Stundenstart;
bei einer nur geplanten Stunde bleibt dieser Status ausgeblendet.
Im Reiter Stundeninhalt stehen die Beschriftungen über den Eingabefeldern;
Platzhalter und Eingabetext beginnen auch in mehrzeiligen Feldern oben links.
Bei schmalen Fenstern bleibt die Anwesenheitsliste vertikal scrollbar;
unter 980 Pixel Inhaltsbreite stehen Liste und Bemerkung untereinander.

## Weitere Screens

Klassen: Kopf mit globaler Suche und Klassenwahl. Eine kompakte Klassenzeile zeigt
Name und Schuljahr mit der Nebenaktion „Klasse bearbeiten“. Die Schülerliste
nutzt die verfügbare Breite und trägt die Hauptaktion „Schüler hinzufügen“.
Vor- und Nachname werden beim Hinzufügen und Bearbeiten eines Schülers gemeinsam
in einem Dialog erfasst und zusammen gespeichert.
Tabellenkopf und Schülerzeilen verwenden dasselbe Spaltenraster einschließlich
einer festen Pfeilspalte; Namen sind linksbündig, Kennzahlen und letzter Eintrag
zentriert. Der letzte Eintrag erscheint im deutschen Datumsformat.
Schülerdetails
ersetzen den Klasseninhalt und zeigen Bemerkungen und Fehlzeiten nach Schuljahr.
Die Aktion „Schüler bearbeiten“ steht im Detailkopf direkt rechts neben dem
Schülernamen und bricht nur bei fehlender Breite in die nächste Zeile um.
Stundenplan: Die neue visuelle Referenz ist das vom Nutzer bereitgestellte Mockup mit hellem Wochenraster und rechter Detailspalte. Der Kopf zeigt Titel, Schuljahr und die Hauptaktion; acht Stunden sind durch 80-Pixel-Zeilen kompakt. Der Leerzustand der Detailspalte ist zentriert. Die vorhandene Liste aller Einträge bleibt über die Listenaktion erreichbar. Der Dialog „Eintrag anlegen“ hält zwischen den Formularfeldern Abstand, damit schwebende Beschriftungen die Nachbarfelder nicht berühren. Leere Rasterfelder zeigen beim Hover „Stunde hinzufügen“. Die Mockup-Symbole für Ansichten sind derzeit nur teilweise umgesetzt: Die Kalenderaktion schaltet zwischen Raster und einfacher Tagesliste um; es gibt keine weitere Kalenderansicht. Die Schrift und Illustration werden mit Flutter-Standards angenähert.
Stundenplan: Schuljahreswahl, Wochenraster und Eintragsdetails. Die Hauptaktion
heißt „Stunde hinzufügen“. Fach und Klasse stehen im Raster in getrennten
Zeilen; eine stabile, dezente Farbcodierung je Fach verbindet wiederkehrende
Stunden visuell. Das Fach ist als größere primäre Zeile sichtbar, während die
Klasse als deutlich beschriftete, kontrastreiche sekundäre Kennung darunter
steht. Fachname und Farbakzent bilden die primäre Ebene. Tageskopf und
Stundenachse sind gegenüber den
Eintragskarten abgesetzt; Auswahlzustände bleiben mit Kontur und Farbe auch
ohne die Fachfarbe eindeutig. Leere Felder bleiben zum Anlegen anklickbar. Das
Raster scrollt bei vielen Stunden vertikal. Alle Einträge sind zusätzlich über
eine Liste erreichbar.
Einstellungen: Karten in zwei Spalten gruppieren Schuljahr & Kalender, App,
Unterricht sowie Daten & Sicherheit. Die Designauswahl liegt zusammen mit den
übrigen App-Einstellungen in der App-Karte und schaltet Hell/Dunkel direkt mit
einem Toggle um, ohne einen Dialog zu öffnen. Bei schmalen Fenstern stehen die
Karten untereinander. Die übrigen Zeilen öffnen jeweils einen eigenen Dialog. Die Zeile
„Unterrichtszeiten“ führt direkt in ein gemeinsames Formular für alle acht
Startzeiten; es gibt keinen vorgeschalteten Ansichts- oder zweiten
Bearbeitungsdialog.
Schulfreie Tage lassen sich dort anlegen und entfernen; NRW-Ferien
und Feiertage sind integriert. Das ältere Projekt-Mockup zeigt noch Unterrichtszeiten als eigene Liste und die alte
zweispaltige Anordnung und den Reiter für schulfreie Tage im Stundenplan.
Die Beispieldaten der PNGs werden
nicht in produktive Datenbanken eingespielt. Das Dunkel-Theme nutzt dieselben
Layout- und Statusregeln mit eigenständig abgestuften, neutralen Flächen und
Petrol als gemeinsamem Primärakzent. Die Theme-Daten für Hell und Dunkel werden unabhängig vom aktuellen
Modus erstellt; die Designauswahl wird nach dem Speichern sofort sichtbar und
bleibt für den nächsten Start erhalten. Die bestehende Auswahl umfasst Hell und
Dunkel; ein Systemmodus war bislang nicht Bestandteil der App und wurde durch
die reine Farbumstellung nicht ergänzt.

## Sprache

Die gesamte App verwendet für Schüler das generische Maskulin. Sichtbare Texte
verwenden „Schüler“ statt Schrägstrichformen oder Doppelnennungen.
Sichtbare Datumswerte verwenden deutsche Monats- und Wochentagsnamen. Kurze
Datumswerte und Eingaben erscheinen als `TT.MM.JJJJ`; ISO-Daten sind kein
Bestandteil der Benutzeroberfläche.
