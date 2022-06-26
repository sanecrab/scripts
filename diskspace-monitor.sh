#!/bin/bash

MOUNT_POINTS=("/" "/var/run/media/DATA")
ALERT_PERCENTS=(10 60)
warns=0

from="luiscarlosgonzalezbarcenas@gmail.com"
recipients="luiscarlosgonzalezbarcenas@gmail.com,user@mail.com"
mail_from="From: LuisCarlos<$from>"
mail_to="To: LuisCarlos<luiscarlosgonzalezbarcenas@gmail.com>"
mail_subject="Subject:Alerta HDD - Servidor($(hostname))"
mail_body="\nServidor:\n$(hostname)\n\nFecha/Hora:$(date)\n\n"

function send_alert_mail(){
	#printf "$mail_from\n$mail_to\n$mail_subject\n$mail_body"
	printf "$mail_from\n$mail_to\n$mail_subject\n$mail_body" | msmtp $recipients
}

mail_body=$mail_body".PUNTO DE MONTAJE.......................%%USADO.......\n"
#mail_body=$mail_body".....................................................\n"
for ((i=0;i<${#MOUNT_POINTS[*]};i++))
do
	SIZE=$(df -k --output=size ${MOUNT_POINTS[$i]} | tail -n1)
	USED=$(df -k --output=used ${MOUNT_POINTS[$i]} | tail -n1)
	#FREE=$(df -k --output=avail ${MOUNT_POINTS[$i]} | tail -n1)
	PERCENT=$(($USED * 100 / $SIZE))
	if [ $PERCENT -gt ${ALERT_PERCENTS[$i]} ]
	then
		(( warns++ ))
		mail_body=$mail_body"\"${MOUNT_POINTS[$i]}\""
		#echo $((40 - ${#MOUNT_POINTS[$i]}))
		for ((c=0; c<$((50 - ${#MOUNT_POINTS[$i]}));c++))
		do
			mail_body=$mail_body"."
		done
		mail_body=$mail_body"$PERCENT%%\n"
	fi
done

#si hay alguna alerta, enviar mail
if [ $warns -gt 0 ]
then
	send_alert_mail
fi
