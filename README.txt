README zu  AGI_Reverse_Lookup_DACH

Das Perl-Skript dient der Namensauflösung von Telefonnummern (Rückwärtssuche) im Asterisk-Dialplan
Unterstützt derzeit Deutschland (D), Österreich (A), Schweiz (CH) und Italien (IT)

Versionsgeschichte:
2016.07.07   Fix Suche Italien (fehlende vorangestellte Null bei Argumente Seitenaufruf)
2016.06.07   Parserskripte neu angepasst, Rückwärtssuche Italien eingebaut (Dank an AAG) / Bash-Parserfehler-Überwachungsskript check.bash (z.B. als Cronjob)
2014.05.19   Kleiner Bug bei Ausgabe online nicht gefunden ohne Cachenutzung behoben
2014.10.29   Grabbing bei oert und klick aktualisiert (Dank an Schnappatmer)
2014.05.19   Kleiner Bug bei Ausgabe online nicht gefunden ohne Cachenutzung 
2014.04.11   Konfiguration mehrerer (kommaseparierter) statischer Datenbanken möglich
2014.04.03   Rufnummernnormalisierung, neue Aufrufparameter
2014.04.02.1 Verbesserte Fehlererkennung ("Navigationshilfen" bei DNS-Fehler), Prüfung Response-Content-Länge
2014.04.02 LWPx::ParanoidAgent mit "echtem" Timeout; Verbesserte Fehlererkennung (Seitenfehler Onlineabfrage)
2014.03.28.1 Initial

Das Skript holt sich den Namen zur gegebenen Nummer, indem es diesen aus den Webseiten der Rückwärtssuche verschiedener Telefonnummernsuchanbieter extrahiert. Das ist jedoch noch nicht alles - das Skript kommt mit weiteren Features, die alle voll konfigurierbar sind:

- Rückwärtssuche für Nummern aus Deutschland, Schweiz, Österreich
- intelligentes Caching via Asterisk-eingebauter AstDB mit konfig. Verfallszeiträumen (expire)
- zusätzliche Suche in einer eigenen AstDB-"Kundendatenbank"
- Statistiken zu Cache- und Onlineabfragen

Um den Skriptaufruf zu beschleunigen, kann pperl oder perperl genutzt werden. Dafür einfach die erste Zeile des Skriptes entsprechend anpassen.


----------------------------------------------------------------------------
Überwachung der Grabbing-Funktionalität
----------------------------------------------------------------------------
Änderungen an der Webseite eines Rückwärtssuchen-Anbieters führen zu einem
Versagen des entsprechenden Rufnummern-Grabbers, der diese Webseite durchsucht.
Das Skript check.bash ermöglicht eine regelmäßige Prüfung der Skript-Funktionalität
und schickt im Fehlerfall eine E-Mail an eine konfigurierbare Adresse


----------------------------------------------------------------------------
Implementierung des Reverse Lookup in den Asterisk-Dialplan
----------------------------------------------------------------------------
Das Skript kann auf einfache Weise in eine Extension der extensions.conf des Asterisk eingebaut werden:

  exten => _X.,1,Verbose(1,${STRFTIME()} Reverse Lookup ${CALLERID(num)})
   same => n,AGI(reverse_search.agi, ${CALLERID(num)})
   same => n,Verbose(1,${STRFTIME()}- Ergebnis: ${RESULTREV})
   same => n,Set(CALLERID(name)=${RESULTREV})
   same => n,Dial(SIP/123)
 
Den Pfad zu den AGI-Skripten findet sich in der asterisk.conf

----------------------------------------------------------------------------
Aufrufparameter
----------------------------------------------------------------------------
<scriptname> number static cache luonline fromshell
#   - number: die zu suchende Telefonnummer
#   - static: Name der zu nutzenden Datenbank oder 0, um diese Suche zu unterbinden (überschreibt config)
#   - cache:  Nutzung des Caches ein- (1) oder ausschalten (0) (überschreibt config)
#   - luonline: Onlinesuche ein- (1) oder ausschalten (0) (überschreibt config)
#   - fromshell: bei Start von der Shell sollte dieser Paraneter auf (1) gesetzt werden

In der Regel erfolgt der Aufruf über Asterisk-AGI nur in der Form:
<scriptname> number

----------------------------------------------------------------------------
Aufruf des Skriptes über die Shell
----------------------------------------------------------------------------
Zu Debuggingzwecken ist es nützlich, wenn man das Skript von der Shell aus aufrufen kann. Folgendes Kommando startet das AGI-Skript so, dass es durchläuft:

while true;do echo " \n";sleep 0.1;done | sudo perl /usr/share/asterisk/agi-bin/reverse_search.agi +49123456789 1 1 1 1

oder, um ausschließlich die Onlinesuchen zu prüfen (ohne Caches und Datenbanken)

while true;do echo " \n";sleep 0.1;done | sudo perl /usr/share/asterisk/agi-bin/reverse_search.agi +49123456789 0 0 1 1

(AGI-Aufrufe erwarten vor einem Abschluss eine Eingabe - daher das while-do-Konstrukt)



----------------------------------------------------------------------------
Konfigurationsparameter im Skript
----------------------------------------------------------------------------
Informationen zu den Parametern finden sich auch im Skript selbst.
Hier noch einmal die Übersicht:

    $vl = 1;
		Verboselevel an der Asterisk-CLI unter dem die Ausgaben erfolgen

	$countryprefix = "\\+";
		Länderprefix der übergebenen Telefonnummern (meist "\\+" oder "00"

    $use_klicktel = 0;
		klicktel.de nutzen, wenn "Das Oertliche" nichts gefunden hat. Klicktel kann Einträge finden, die das Oertliche nicht findet, liefert aber ab und an auch Unsinn (besonders wenn es keine Nummer findet und dann eine "Ähnlichkeitssuche" macht

	$cache = 1;
		Caching nutzen
    
	$staticfamilies = "";
		werden hier ein oder mehrere (kommaseparierte) Name angegeben, so wird in dieser AstDB-Datenbank (eigentlich: AstDB-Zweig oder -"family") über die Nummer als Key ein zugehöriger Name gesucht. In dieser Datenbank kann man z.B. Telefondaten der eigenen Kundendatenbank vorhalten. In dieser Datenbank wird stets zuerst gesucht.
    
	$cachefamily = "cidcache";
		Name der Datenbank, die die zwischengespeicherten Nummern-Namen-Paare als Ergebnis älterer Suchen vorhält
    
	$cachetsfamily = "cidcachets";
		Name der Datenbank, die Zeitstamps zu den in der Vergangenheit gesuchten Nummern enthält
    
	$statsfamily = "cidstats";
		Name der Datenbank, in der Statistikdaten über den Cache und die Onlinesuchen gespeichert werden
    
	$f_expire = 365;
		Zeitraum in Tagen, nach dem Ergebnisse erfolgreicher Rückwärtssuchen im Cache verfallen (einst gefundene Nummern werden dann nochmals gesucht). Ist der Wert 0, dann verfallen gefundene Nummern nie, es erfolgt also keine weitere Suche.
    
	$nf_expire = 60;
		Zeitraum in Tagen, nach dem Ergebnisse erfolgloser Rückwärtssuchen im Cache verfallen (vormals online nicht gefundene Nummern werden dann nochmals gesucht). Ist der Wert 0, dann wird trotz erfolgloser Suche in der Vergangenheit stets noch einmal eine Onlinesuche versucht.
    
	$dont_delete_existing = 1;
		Vorhandene Namenseinträge werden bei einer Aktualisierung (nach Verfallszeitraum) nicht gelöscht, wenn dann kein name mehr gefunden werden kann (z.B. weil die Nummer nicht mehr in der Rückwärtssuche gefunden wurde)
    
	$refresh_names_without_ts = 1;
		Legt den Umgang mit Namenseinträgen fest, für die kein Zeitstempel exisiert.0=Zeitstempel wird auf die aktuelle Zeit gesetzt, bis zum Verfallsdatum wird keine neue Suche vorgenommen - 1=solche Namen werden exired gesetzt und online neu gesucht/aktualisiert
    
	$ua->timeout(3);
		Timeout für die Online-Requests in Sekunden. Sollte nicht zu hoch eingestellt werden, damit der Dialplan nicht zu lange blockiert ist.
    
	$ua->agent('Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.0)');
		Bei den Onlineabfragen genutzer Useragent-String

Hinweise: Wenn beide expire-Zeiten (f_expire & nf_expire) oben ungesetzt sind (=0), dann werden keinerlei Zeitstempel in der AstDB gespeichert! Doch keine Angst: Die AstDB ist recht leistungsfähig. In meiner Kundendatenbank auf dem Raspi befinden sich bspw. 15000 Einträge und es sind keinerlei Auswirkung auf die Zugriffen zu bemerken.

----------------------------------------------------------------------------
Statistiken
----------------------------------------------------------------------------
Werden per gesetztem "statsfamily" Statistikdaten zu den Abfragen gespeichert, so können diese folgendermaßen an der Asterisk-CLI abgerufen werden:

database show cidstats

Die daraufhin gelisteten Einträge gliedern sich in Bereiche mit folgenden Prefixen:

    _static - fixe (staticfamily) Datenbank, in der gesucht wurde (z.B. Kundendatenbank)
    _cache - Lokalsuche im Cache
    DE-oert - Onlinesuchen auf das-oertliche.de
    DE-klick - Onlinesuchen auf klicktel.de
    AT-abc - Onlinesuchen auf telefonabc.at
    CH-telsearch - Onlinesuchen auf tel.search.ch
	IT-pag - Onlinesuche über paginebianche.it

Diese Bereiche haben gegebenenfalls Untereinträge mit folgenden Bezeichnungen:

    hitfound - valider Fund, zugehöriger Name wurde gefunden
    hitempty - Cache: Anzahl für gefundene Einträge, deren (zwischengespeicherte) Onlinesuche erfolglos war (d.h. im Web wurde damals kein Name gefunden) | Bei den Onlinesuchen steht hier die Anzahl der suchen ohne Erfolg (kein Eintrag gefunden)
    miss - Cache: Kein Eintrag - Nicht gefunden | Online: Parsingfehler
    expi - nur Cache: Verfallenen Eintrag gefunden
    erro - nur Onlinesuche : Requesterror (Seitenaufruf fehlgeschlagen oder Timeout)
