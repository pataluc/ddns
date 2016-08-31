#!/bin/bash
# Teste si l'ip publique a été modifiée et met à jour l'enregistrement DNS
# Utilise la clé TSIG
# François Grange 2012
# Inits
ADMIN="xxxx@onsenfout.com"
ZONE="onsenfout.com"
RR="monip.$ZONE."
TTL=30
LAST_IP="0.0.0.0"
LAST_IP_FILE="/var/local/lastip"
FLAG_ERR=0
ERR_FILE="/var/local/dyndns.err"
KEY_FILE="/etc/bind/keys/Kmonip.onsenfout.com.+157+13642.private"
TMP_FILE="/tmp/dyndns.tmp"
CUR_IP=`wget -q -O - whatismyip.org`
sortie() {
	# mail si erreur ou modification
	if [ $1 -eq 1 ]; then
		if [ ! -f $ERR_FILE ]; then
			touch $ERR_FILE
			cat $TMP_FILE | mail -s "Erreur de mise à jour de $RR" $ADMIN
		fi
	else
		cat $TMP_FILE | mail -s "Changement d'IP pour $RR" $ADMIN
		if [ -f $ERR_FILE ]; then
			rm -f $ERR_FILE
		fi
	fi
	exit
}
if [ "$CUR_IP" = "" ] || [ "$CUR_IP" = "unknown" ]; then
	echo "Impossible de récupérer l'IP actuelle - Abandon" > $TMP_FILE
	sortie 1
fi
if [ -f $LAST_IP_FILE ]; then
	LAST_IP=`cat $LAST_IP_FILE`
fi
if [ ! "$LAST_IP" = "$CUR_IP" ]; then
	# L'adresse a changé
	echo "IP actuelle : $CUR_IP" > $TMP_FILE
	echo "IP précédente : $LAST_IP" >> $TMP_FILE
	(
	echo "zone $ZONE"
	echo "update delete $RR A"
	echo "update add $RR $TTL A $CUR_IP"
	echo "send"
	) | nsupdate -k $KEY_FILE -v
	if [ $? -ne 0 ]; then
		echo "Echec de la mise à jour de $RR" >> $TMP_FILE
		FLAG_ERR=1
	else
		echo $CUR_IP > $LAST_IP_FILE
	fi
	sortie $FLAG_ERR
fi
