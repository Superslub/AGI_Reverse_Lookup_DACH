#!/bin/bash
#
# Version 2016.06.07
#
# Prüft die angegebene Nummern (zu denen es Rückwärtssucheergebnisse geben muss!)
# gegen das Asterisk Rückwärtssuche-Skript und sendet bei einem ausbleibenden
# positiven Suchergebnis eine E-Mail mit entsprechender Warnmeldung.
# 
# Einzige Einschränkung ist die doppelte Suche deutscher Telefonnummern,
# hier kann die sekundäre Suche über Klicktel nicht effektiv geprüft werden.
#
# Beispielhafter Eintrag in die Crontab
# 20 12   * * *   root   bash /home/pi/_reverselookup/check.bash > /dev/null 2>&1 || true
#

# Zu prüfende Nummern - diese müssen bei Rückwärtssuche ein Ergebnis liefern
numbers='
 003930984673
 0039885432087
 0041265051361
 0041627513235
 0049762113311
 00492315340048
 004372362372
 0043735320036
'

for num in $numbers; do
    out=`while true; do echo " \n"; sleep 0.1; done | perl /usr/share/asterisk/agi-bin/reverse_search.agi $num  0 0 1 1 | grep 'Nummer nicht gefunden'`
    if [ -n "$out" ]
    then
        echo "$num Konnte nicht gefunden werden - sende Mail"
        betreff="Asterisk Reversesearch pruefen"
        msg="Reversesearch der Nummer $num war nicht mehr moeglich. Evtl. muss der Parser angepasst werden!"
        sendemail -f Absende@Mail-Adres.se -t Ziel@Mail-Adres.se -u "$betreff" -m "$msg" -s mail.gmx.net:587 -o tls=yes -xu MySmtpLogin -xp MySmptPassword
        exit 0;
    else
        echo "$num OK"
    fi
done
