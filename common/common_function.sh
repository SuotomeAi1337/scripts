#!/usr/bin/env bash
#
# Author: Whiterabbit.Monster
# Date: 2023-08-25 23:47:42
# LastEditTime: 2023-08-25 23:53:37
# Description: define common var and function
# 
# Copyright (c) 2023 by Whiterabbit.Monster, All Rights Reserved. 
#

# func: color output
color_print() {
    local color_code=""
    case $1 in
        red)    color_code="31;31";;
        green)  color_code="31;32";;
        yellow) color_code="31;33";;
        blue)   color_code="31;36";;
        *)      color_code="0";;
    esac
    printf '\033[0;%sm%b\033[0m' "$color_code" "$2"
        
}

# func: check root user
check_root() {
    if [[ $EUID -ne 0 ]]; then
        color_print red "This script must be run as root!"
        exit 1
    fi
}

# func: timer
start_timer() {
    start_time=$(date +%s)
}

stop_timer() {
    end_time=$(date +%s)
    execution_time=$((end_time - start_time))
    if [ execution_time -gt 60 ]; then
        minutes=$((total_seconds / 60))
        seconds=$((total_seconds % 60))
        echo "Script execution time: $minutes minutes $seconds seconds"
    else
        echo "Script execution time: $seconds seconds"
}

