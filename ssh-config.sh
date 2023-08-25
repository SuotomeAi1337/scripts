#!/usr/bin/env bash
#
# Author: Whiterabbit.Monster
# Date: 2023-01-28 13:13:03
# LastEditTime: 2023-08-25 10:51:44
# Description: ssh服务初始化设置
# 
# Copyright (c) 2023 by Whiterabbit.Monster, All Rights Reserved. 
#

# 函数：输出颜色定义
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

# 函数：打印分隔符
greenline() {
    color_print green "----------------------------------------------"
}

# 函数：打印说明
print_intro() {
    clear
    greenline
    color_print yellow "本脚本的功能："
    echo -e "添加登录公钥\n更改登录端口\n启用公钥认证\n指定授权密钥文件的位置\n更改登录端口\n允许Root用户登录\n禁用密码登陆\n设置客户端保活时间为60秒\n设置客户端最大保活次数为30次\n启用 RSA 密钥身份验证"
    color_print yellow "Tips:"
    echo -e "如果不希望更改原有的公钥或端口，输入原信息即可"
    greenline
    color_print yellow "按任意键继续..."
    read -s -n1 -p ""
    clear
}
print_intro

# 函数：初始化
init() {
    cd /root
    ssh_config="/root/test"
    #ssh_config="/etc/ssh/sshd_config"
}

# 函数：如果非root登录则退出
check_root() {
    if [ "$UID" -ne 0 ]; then
        color_print red "必须以root用户执行此脚本"
    exit
    fi
}

# 函数：备份sshd配置文件
bak_sshd() {
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config_bak
    greenline
    color_print blue "sshd_config已备份为：/etc/ssh/sshd_config_bak"
}

# 函数：检测并添加公钥
input_public_key() {
    greenline
    # 有authorized_keys文件但没有公钥，添加公钥
    # 没有authorized_keys文件，创建文件并添加公钥
    if [ -e .ssh/authorized_keys ]; then
        color_print yellow "检测到公钥文件，包含的公钥为："
        cat .ssh/authorized_keys
        color_print yellow "请输入您的公钥 >"
        read public_key
        result=$(cat .ssh/authorized_keys | grep "${public_key:8:20}")
        if [ "$result" != "" ]; then
            color_print red "已有此公钥"
        else
            echo $public_key >> .ssh/authorized_keys
        fi
    else
        touch .ssh/authorized_keys
        echo $public_key >> .ssh/authorized_keys
    fi
}

# 函数：修改ssh配置文件
set_ssh_conf() {
    old_port=$(grep -w "Port" $ssh_config | awk '{print $2}')
    color_print yellow "ssh登录端口为：$old_port"
    color_print yellow "请输入新的端口 >"
    read new_port
    color_print blue "新的端口为：$new_port"
    # 启用公钥认证
    # 指定授权密钥文件的位置
    # 更改登录端口
    # 允许Root用户登录
    # 禁用密码登陆
    # 设置客户端保活时间为60秒
    # 设置客户端最大保活次数为30次
    # 启用 RSA 密钥身份验证

    declare -A conf
    conf=(
        ["PubkeyAuthentication"]="PubkeyAuthentication yes"
        ["AuthorizedKeysFile"]="AuthorizedKeysFile .ssh\/authorized_keys"
        ["Port"]="Port ${new_port}"
        ["PermitRootLogin"]="PermitRootLogin yes"
        ["PasswordAuthentication"]="PasswordAuthentication no"
        ["ClientAliveInterval"]="ClientAliveInterval 60"
        ["ClientAliveCountMax"]="ClientAliveCountMax 30"
        ["RSAAuthentication"]="RSAAuthentication yes"
    )
    for key in ${!conf[@]}; do
        value=${conf[$key]}
        # 使用grep -w精确匹配key值，如果存在则整行替换，不存在则添加
        if grep -qw $key $ssh_config ; then
            sed -i "/$key/c$value" $ssh_config
        else
            echo $value >> $ssh_config
        fi
    done
}

# 函数：重启ssh服务
restart_sshd() {
    service sshd restart
    greenline
    color_print blue "重启sshd服务"
}

# 主模块
clear
check_root
init
print_intro
bak_sshd
input_public_key
set_ssh_conf
restart_sshd
