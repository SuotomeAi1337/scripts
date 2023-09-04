#!/usr/bin/env bash
#
# Author: Whiterabbit.Monster
# Date: 2023-08-29 14:28:23
# LastEditTime: 2023-08-30 08:20:03
# Description: 运维相关，打包常用命令
# 
# Copyright (c) 2023 by Whiterabbit.Monster, All Rights Reserved. 
#

# 函数：systemctl相关
# 函数名为System Control的缩写，易混淆的操作为头尾字母，其他为单字母
sc() {
    operation="$1"
    service_name="$2"
    
    case "$operation" in
        st)
            systemctl start "$service_name"
            ;;
        sp)
            systemctl stop "$service_name"
            ;;
        r)
            systemctl restart "$service_name"
            ;;
        ss)
            systemctl status "$service_name"
            ;;
        e)
            systemctl enable "$service_name"
            ;;
        d)
            systemctl disable "$service_name"
            ;;
        *)
            echo "Invalid action. "
            echo "Usage: sc [operation] <service_name>"
            echo "  st: start"
            echo "  sp: stop"
            echo "  ss: status"
            echo "  r:  restart"
            echo "  e:  enable"
            echo "d  :  disable"
            ;;
    esac
}