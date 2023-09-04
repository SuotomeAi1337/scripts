#!/usr/bin/env bash
#
# Author: Whiterabbit.Monster
# Date: 2023-08-25 23:47:42
# LastEditTime: 2023-09-04 21:54:45
# Description: scrips public lib
# 
# Copyright (c) 2023 by Whiterabbit.Monster, All Rights Reserved. 
#

# 后续功能添加
# wget等常用命令加入检测，如果命令不存在则安装相应软件包

# Spec
# Function name: verb_name

# Set simple bash theme
set_bash_theme() {
    echo "export PS1='[\[\e[31;1m\]\u@\[\e[33;1m\]\h \[\e[34;1m\]\W\[\e[0m\]]\$ '" > /etc/profile && source /etc/profile
}

# Print colorful string
print_color_string() {
    if [ $# -ne 2 ]; then
        echo "Usage: print_color_string [red|green|yellow|blue] <string>"
    return 1

    fi

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

# Print a greenline
print_greenline() {
    print_color_string green "--------------------------------------------------------------------"
}

# Print colorful separator
print_color_separator() {
    if [ $# -ne 3 ]; then
        print_color_string green "Usage: print_color_separator <color> <separator> <count>"
        return 1
    fi
    
    local color="$1"
    local separator="$2"
    local count="$3"
    
    if [ "$count" -le 0 ]; then
        return 0
    fi
    
    local separator_string=""
    for ((i = 0; i < count; i++)); do
        separator_string="${separator_string}${separator}"
    done
    
    print_color_string "$color" "$separator_string"
}

# check ip format
check_ip_format() {
    if ! [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || ! [[ $1 =~ ^([0-9A-Fa-f]{1,4}:){2} ]]; then 
        return 0
    else
        return 1
    fi
}

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_color_string red "This script must be run as root!"
        exit 1
    fi
}

# Check command exist
check_command_exist() {
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

# Get command for install package
get_package_install_command() {
    # debian/ubuntu
    if check_command_exist "apt"; then
        package_install='apt -y --no-install-recommends install'
        package_remove='apt purge'
    # centos/redhat
    elif check_command_exist "yum"; then
        package_install='yum -y install'
        package_remove='yum remove'
    # archlinux
    elif check_command_exist "pacman"; then
        package_install='pacman -Syu --noconfirm'
        package_remove='pacman -Rsn'
    else
        print_color_string red "error: The script does not support the package manager in this operating system."
        exit 1
    fi
}

# Install package
# Usage: install_package "${package_name[@]}"
install_package() {
    local package_name=("$@")
    if [ $# -eq 0 ]; then
        return
    fi

    for cmd in "${package_name[@]}"; do
        if ! check_command_exist "$cmd"; then
            print_color_string blue "正在安装$cmd"
            #$package_install "$cmd"
        fi
    done
}

# Get start time
get_start_time() {
    start_time=$(date +%s)
}

# Get end time and print exection time
print_exection_time() {
    end_time=$(date +%s)
    local execution_time minutes seconds
    
    if [ -n "$start_time" ]; then
        execution_time=$((end_time - start_time))
    else
        return
    fi

    if [ "$execution_time" -gt 60 ]; then
        minutes=$((execution_time / 60))
        seconds=$((execution_time % 60))
        print_color_string green "Execution time: $minutes minutes $seconds seconds"
    else
        print_color_string green "Execution time: $execution_time seconds"
    fi
}

# test tgbot
# Error output: {"ok":false,"error_code":401,"description":"Unauthorized"}
test_tgbot() {
    local curl_response curl_status
    if [ -z "$chat_id" ] || [ -z "$bot_token" ]; then
        print_color_string red "Please export chat_id and bot_token"
        return 1
    fi

    curl_response=$(curl -sSX POST \
                -H 'Content-Type: application/json' \
                -d '{"chat_id": '${chat_id}', "text": "🤖This is a test from curl😁", "disable_notification": true}' \
                "https://api.telegram.org/bot$bot_token/sendMessage")

    if echo $curl_response | grep -qw "false" ; then
        print_color_string red "Send message to tgbot error."
    else
        print_color_string green "Send message to tgbot success."
    fi
}

# Get latest release version or colorful list of release from Github
# eg: get_github_release 'XTLS/Xray-core'
# variable: version_release_latest; release_color_tag
get_github_release() {
    local request_head="Accept: application/vnd.github.v3+json"
    local link_release_latest="https://api.github.com/repos/$1/releases/latest"
    local link_release_list="https://api.github.com/repos/$1/releases"

    local response_release_latest=$(curl -sS -H "$request_head" "$link_release_latest")
    local response_release_list=$(curl -sS -H "$request_head" "$link_release_list")

    if [ -n "$response_release_latest" ]; then
        version_release_latest=$(echo $response_release_latest | sed 'y/,/\n/' | grep 'tag_name' | awk -F '"' '{print $4}')
        version_release_new=$(echo $response_release_list | sed 'y/,/\n/' | grep -m1 'tag_name' | awk -F '"' '{print $4}')
        release_list=$(echo $response_release_list | sed 'y/,/\n/' | grep 'tag_name' | awk -F '"' '{print $4}' | head -n 10)
        release_color_tag=$(echo "$release_list" | sed "s/${version_release_latest}/\\\\e[33m${version_release_latest} (latest)\\\\e[0m/g")
    else
        echo "Please check network..."
        exit 1
    fi

}

