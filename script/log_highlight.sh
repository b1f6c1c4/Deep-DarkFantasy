#!/bin/sh

awk '
    /^# / { printf "\033[36m%s\033[0m\n", $0; }
    /^ERROR:/ { printf "\033[31m%s\033[0m\n", $0; }
    /^CRITICAL WARNING:/ { printf "\033[35m%s\033[0m\n", $0; }
    /^WARNING:/ {
      if (match($0, /\[Synth 8-689\]/)) {
        printf "\033[31m%s\033[0m\n", $0;
      } else if (match($0, /\[Synth 8-7023\]/)) {
        printf "\033[31m%s\033[0m\n", $0;
      } else {
        printf "\033[33m%s\033[0m\n", $0;
      }
    }
'
