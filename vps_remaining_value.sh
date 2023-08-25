#!/usr/bin/env bash
#
# Author: Whiterabbit.Monster
# Date: 2023-08-21 23:00:34
# LastEditTime: 2023-08-22 16:00:35
# Description: 
# 
# Copyright (c) 2023 by Whiterabbit.Monster, All Rights Reserved. 
#

# 颜色定义
_green() {
    printf '\033[0;31;32m%b\033[0m' "$1"
}

_yellow() {
    printf '\033[0;31;33m%b\033[0m' "$1"
}

_red() {
    printf '\033[0;31;31m%b\033[0m' "$1"
}

# 外汇牌价
boc='https://www.boc.cn/sourcedb/whpj/index.html'

exchange_rate=$(curl -s $boc)

# 函数：无效输入错误
error_wrong_input()
{
    local error_code="$1"
    local error_message=""

    case $error_code in
    1) error_message="错误：无效的输入" ;;
    2) error_message="错误：剩余天数超出付款周期" ;;
    3) error_message="错误：日期格式无效，请使用202Y-MM-DD格式" ;;
    4) error_message="错误：已过到期时间" ;;
    5) error_message="错误：不存在的日期" ;;
    esac

    echo -e "$(_red $error_message)"
    exit 1
}

# 函数：判断有效价格
check_valid_price(){
    local price="$1"

    if [[ ! "$price" =~ ^[0-9]+$ && ! "$price" =~ ^[0-9]+\.[0-9]+$ ]]; then
        error_wrong_input 1
        exit 1
    fi
}


# 函数：提取美元、欧元、加元的中行折算价
extract_currency() {
    local currency="$1"
    local rates
    rates=$(echo "$exchange_rate" | grep -A 5 "<td>$currency</td>" | tail -n 1 | awk -F'[<>]' '{print $3}' | bc -l)
    
    calculated_rate=$(echo "scale=2; $rates / 100" | bc -l)
    echo "$calculated_rate"
}

# 函数：显示介绍
print_intro() {
    forex_update=$(echo "$exchange_rate" | grep "<td class=\"pjrq\">" | head -n 1 | awk -F'[<>]' '{print $3}')
    USD=$(extract_currency "美元")
    EUR=$(extract_currency "欧元")
    CAD=$(extract_currency "加拿大元")

    clear
    greenline=$(_green "--------------------------------------------------------------------")
    echo "$greenline"
    echo " Info                : $(_green "Calculate remaining value of vps")"
    echo " Version             : $(_green v2023-08-22)"
    echo " Author              : $(_green W.R.M)"
    echo "$greenline"
    echo " Forex               : $(_green "USD: $USD EUR: $EUR CAD: $CAD")"
    echo " Forex update        : $(_green "$forex_update")"
    echo " Forex source        : $(_green https://www.boc.cn/sourcedb/whpj/index.html)"
    echo "$greenline"
}

# 函数：获取币种、价格、汇率
get_purchase_price() {
    local choice
    echo -e "$(_yellow 请选择历史购买价格的币种：)"
    echo "1. 人民币"
    echo "2. 外币"
    read -r choice

    if [ "$choice" == "1" ]; then
        # 人民币
        echo -e "$(_yellow 请输入人民币价格：)"
        read -r cny_price
        check_valid_price $cny_price

    elif [ "$choice" == "2" ]; then
        # 外币
        echo -e "$(_yellow 请选择外币币种：)"
        echo "1. 美元"
        echo "2. 欧元"
        echo "3. 加拿大元"
        read -r choice

        case $choice in
            1) forex_rate=$USD ; forex_currency="USD " ;;
            2) forex_rate=$EUR ; forex_currency="EUR " ;;
            3) forex_rate=$CAD ; forex_currency="CAD " ;;
            *) error_wrong_input 1 ;;
        esac

        echo -e "$(_yellow 请输入外币价格：)"
        read -r forex_price
        check_valid_price $forex_price
                
    else
        error_wrong_input 1
    fi
}

# 函数：获取付款周期天数
get_period_days() {
    local choice
    echo -e "$(_yellow 请选择付款周期：)"
    echo "1. 月付（30天）"
    echo "2. 季付（90天）"
    echo "3. 年付（365天）"
    echo "4. 两年付（730天）"
    echo "5. 三年付（1095天）"
    echo "6. 五年付（1825天）"
    read -r choice
        case $choice in
            1) payment_period="月付" ; period_days=30 ;;
            2) payment_period="季付" ; period_days=90 ;;
            3) payment_period="年付" ; period_days=365 ;;
            4) payment_period="两年付" ; period_days=730 ;;
            5) payment_period="三年付" ; period_days=1095 ;;
            6) payment_period="五年付" ; period_days=1825 ;;
            *) error_wrong_input 1 ;;
        esac
}

# 函数：获取剩余时间
get_left_days() {
    local end_date input_timestamp current_timestamp diff_seconds
    echo -e "$(_yellow 请输入到期时间（202Y-MM-DD）：)"
    read -r end_date
    
    # 验证输入日期格式，只允许输入202[1-9]-[01-12]
    if [[ ! "$end_date" =~ ^202[0-9]-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$ ]]; then
        error_wrong_input 3
    fi

    # 验证日期是否无效，如2023-02-31
    input_timestamp=$(date -d "$end_date" +%s 2>/dev/null) # 输入日期的时间戳

    if [ $? -ne 0 ]; then
        error_wrong_input 5
    fi

    current_timestamp=$(date +%s) # 当前时间的时间戳

    # 到期时间必须大于当前时间
    if [ $input_timestamp -lt $current_timestamp ]; then
        error_wrong_input 4
    fi

    diff_seconds=$((input_timestamp - current_timestamp))
    left_days=$(echo "scale=2; $diff_seconds / 86400" | bc) # 一天有 86400 秒

    # 剩余天数整数位必须小于付款周期
    if [ ${left_days%.*} -ge $period_days ]; then
        error_wrong_input 2
    fi
}
    
# 函数：获取剩余价值
get_remaining_value() {
    if [ -n "$cny_price" ]; then
        remaining_value=$(echo "scale=8; $cny_price / $period_days * $left_days" | bc | xargs printf "%.*f\n" 2)
    else
        remaining_value=$(echo "scale=8; $forex_price / $period_days * $left_days * $forex_rate" | bc | xargs printf "%.*f\n" 2)
    fi
}

# 函数：输出剩余价值
print_remaining_value() {
    echo "$greenline"
    echo -e "$(_yellow 人民币剩余价值：)$(_green $remaining_value)"
    if [ -n "$cny_price" ]; then
        echo -e "$(_yellow 人民币购买价格：)$(_green $cny_price)"
    else
        echo -e "$(_yellow 外币购买价格：)$(_green "$forex_currency$forex_price")"
        echo -e "$(_yellow 外币汇率：)$(_green $forex_rate)"
    fi
    echo -e "$(_yellow 剩余天数：)$(_green $left_days)"
    echo -e "$(_yellow 付款周期：)$(_green "$payment_period$period_days天")"
}

# 主函数
print_intro
get_purchase_price
get_period_days
get_left_days
get_remaining_value
print_remaining_value

