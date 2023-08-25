#!/usr/bin/env bash
# 2023-3-1
# 显示256色ANSI转义颜色
# 默认输出背景色，带参数fg为前景色

# 宽度对齐
# 一行8个，每个颜色9字符，共72字符长
# 一行12个，每个颜色6字符，共72字符长

# 前景色：\e[38;5;#m
# 背景色：\e[48;5;#m

case $1 in
    -fg)
        fgbg=38
        ;;
    -h)
        echo "-----------------"
        echo "fg - 前景色显示"
        echo "-----------------"
        echo -e "前景色：\e[38;5;#m"
        echo -e "背景色：\e[48;5;#m"
        exit 0
        ;;
    *)
        fgbg=48
        ;;
esac

    # 标准色
    printf "\e[48;5;235m%*s%2s%*s\e[0m\n" 28 " " "Standard  colors" 28 " "
    for color in {0..7} ; do
        # 显示颜色，手工对齐颜色代码
        # %*s%2s%*s 3 " " $color 4 " "
        # 3空格+2字符宽度颜色代码+4空格
        printf "\e[${fgbg};5;%sm%*s%2s%*s\e[0m" $color 3 " " $color 4 " "
    done
    echo # New line

    # 高对比色
    printf "\e[48;5;235m%*s%2s%*s\e[0m\n" 25 " " "High-intensity  colors" 25 " "
    for color in {8..15} ; do
        printf "\e[${fgbg};5;%sm%*s%2s%*s\e[0m" $color 3 " " $color 4 " "
    done
    echo

    # 216色
    printf "\e[48;5;235m%*s%2s%*s\e[0m\n" 31 " " "216 colors" 31 " "
    for color in {16..231} ; do # Colors
        printf "\e[${fgbg};5;%sm  %3s \e[0m" $color $color
        # 每行12个
        # 每行10个，第一行6个的写法
        # $((($color + 1) % 10)) == 6
        # 0  1  2  3  4  5
        # 6  7  8  9  10 11 12 13 14 15
        if [ $((($color + 1) % 12)) == 4 ] ; then
            echo
        fi
    done 

    # 灰度色
    printf "\e[48;5;235m%*s%2s%*s\e[0m\n" 28 " " "Grayscale colors" 28 " "
    for color in {232..255} ; do # Colors
        # Display the color
        printf "\e[${fgbg};5;%sm  %3s \e[0m" $color $color
        # 每行12个
        if [ $((($color + 1) % 12)) == 4 ] ; then
            echo
        fi
    done
    echo

 
exit 0
