#!/bin/bash

function parallel_ping()
{
	ping $1 -c 1 > /dev/null
	if [[ $? -eq 0 ]] ; then
		echo $1: OK
	fi
}

if [ -z $1 ]
then
	echo "Usage:"
	echo "$0 <subnet>"
	echo "Ej:"
	echo "$0 192.168.1"
	exit
fi

for (( i=1; i<255; i++)); do
    parallel_ping $1.$i &
done

wait
