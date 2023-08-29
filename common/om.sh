#!/usr/bin/env bash
#
# Author: Whiterabbit.Monster
# Date: 2023-08-29 14:28:23
# LastEditTime: 2023-08-29 14:35:32
# Description: 运维相关，打包常用命令
# 
# Copyright (c) 2023 by Whiterabbit.Monster, All Rights Reserved. 
#

# 函数：systemctl相关
st() {
    operation="$1"
    service_name="$2"
    
    case "$operation" in
        s)
            systemctl start "$service_name"
            ;;
        p)
            systemctl stop "$service_name"
            ;;
        r)
            systemctl restart "$service_name"
            ;;
        u)
            systemctl status "$service_name"
            ;;
        e)
            systemctl enable "$service_name"
            ;;
        d)
            systemctl disable "$service_name"
            ;;
        *)
            echo "Invalid action. Usage: s [operation: s|p|r|u|e|d] <service_name>"
            ;;
    esac
}