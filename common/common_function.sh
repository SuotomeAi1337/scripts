#!/usr/bin/env bash
#
# Author: Whiterabbit.Monster
# Date: 2023-08-25 23:47:42
# LastEditTime: 2023-08-28 14:00:45
# Description: define common var and function
# 
# Copyright (c) 2023 by Whiterabbit.Monster, All Rights Reserved. 
#

# 后续功能添加
# wget等常用命令加入检测，如果命令不存在则安装相应软件包

# 函数：颜色输出
color_print() {
    local color_code=""
    case $1 in
        red)    color_code="31;31";;
        green)  color_code="31;32";;
        yellow) color_code="31;33";;
        blue)   color_code="31;36";;
        *)      color_code="0";;
    esac
    printf '\033[0;%sm%b\033[0m\n' "$color_code" "$2"
}

# 函数：检测root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        color_print red "This script must be run as root!"
        exit 1
    fi
}

# 函数：检测命令是否存在
exists() {
    local cmd="$1"
    if eval type type > /dev/null 2>&1; then
        eval type "$cmd" > /dev/null 2>&1
    elif command > /dev/null 2>&1; then
        command -v "$cmd" > /dev/null 2>&1
    else
        which "$cmd" > /dev/null 2>&1
    fi
    local rt=$?
    return ${rt}
}

# 函数：获取软件包安装命令
get_install_command() {
    # debian/ubuntu
    if [[ "$(type -P apt)" ]]; then
        package_install='apt -y --no-install-recommends install'
        package_remove='apt purge'
    # centos/redhat
    elif [[ "$(type -P yum)" ]]; then
        package_install='yum -y install'
        package_remove='yum remove'
    # archlinux
    elif [[ "$(type -P pacman)" ]]; then
        package_install='pacman -Syu --noconfirm'
        package_remove='pacman -Rsn'
    else
        echo "error: The script does not support the package manager in this operating system."
        exit 1
    fi
}

# 函数：安装软件
install_dependency() {
    local dependency=("$@")
    if [ $# -eq 0 ]; then
        return
    fi

    for cmd in "${dependency[@]}"; do
        if ! exists "$cmd"; then
            color_print blue "正在安装$cmd\n"
            $package_install "$cmd"
        fi
    done
}

# func: timer
start_timer() {
    start_time=$(date +%s)
}

stop_timer() {
    end_time=$(date +%s)
    execution_time=$((end_time - start_time))
    if [ $execution_time -gt 60 ]; then
        minutes=$((total_seconds / 60))
        seconds=$((total_seconds % 60))
        echo "Script execution time: $minutes minutes $seconds seconds"
    else
        echo "Script execution time: $seconds seconds"
    fi
}



