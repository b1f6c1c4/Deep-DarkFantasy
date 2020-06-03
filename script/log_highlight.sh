#!/bin/sh

awk '
    /^# / { printf "\033[36m%s\033[0m\n", $0; }
    /^ERROR:/ { printf "\033[31m%s\033[0m\n", $0; }
    /^CRITICAL WARNING:/ { printf "\033[35m%s\033[0m\n", $0; }
    /^WARNING:/ { printf "\033[33m%s\033[0m\n", $0; }
    /^Resolution:/ { print $0; }
'
