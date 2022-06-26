#!/bin/bash

status=0

check_ip() {
    IP_REGEX='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
    printf '%s' "$1" | tr -d '\n' | grep -Eq "$IP_REGEX"
}

exec_check() {
    if ! check_ip $1; then
        printf '%s %s %s\n' "ERROR: Invalid IP (" "$1" ")"
    fi

}

exec_check "192.168.1.16"
exec_check "192.168.1.300"

exit $status
