#!/usr/bin/env bash
#
# Author: Whiterabbit.Monster
# Date: 2023-06-20 14:57:55
# LastEditTime: 2023-08-29 10:30:48
# Description: Monitoring DDNS IP changes.
#
# Copyright (c) 2023 by Whiterabbit.Monster, All Rights Reserved.
#

# Telegram bot
TOKEN="your token"
CHAT_ID="your chat id"
API_URL="https://api.telegram.org/bot$TOKEN/sendMessage"

# get ipv4/ipv6 using ip.sb
script_dir=$(cd "$(dirname "$0")" && pwd)
log="$script_dir/ip.log"
ipv4=$(curl -4 -s ip.sb)
ipv6=$(curl -6 -s ip.sb)

# if ip.sb return wrong ipv4/ipv6 format then exit
# ipv6 only match first two segment due to abbreviated form
if ! [[ $ipv4 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || ! [[ $ipv6 =~ ^([0-9A-Fa-f]{1,4}:){2} ]]; then
        exit 1
fi

# get last record of ip from logfile
if [[ -f "$log" ]]; then
        last_ip=$(tail -n 1 "$log")
fi

last_ipv4=$(echo "$last_ip" | awk -F ' ' '{print $3}')
last_ipv6=$(echo "$last_ip" | awk -F ' ' '{print $4}')

# combine message of tg bot
MESSAGE="🚀Detected ip change: $last_ipv4 -> $ipv4"

if [[ "$ipv4" != "$last_ipv4" ]] || [[ "$ipv6" != "$last_ipv6" ]]; then
        # log as "2023-06-20 06:56:03 1.170.217.203 2001:b030:a42d:5dc0:98::"
        echo "$(TZ=Asia/Shanghai date +'%Y-%m-%d %H:%M:%S') $ipv4 $ipv6" >> "$log"
        # send message use tg bot
        curl -s -X POST $API_URL -d chat_id=$CHAT_ID -d text="$MESSAGE" >/dev/null 2>&1
fi

