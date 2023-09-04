#!/usr/bin/env bash
#
# Author: Whiterabbit.Monster
# Date: 2023-08-25 21:28:41
# LastEditTime: 2023-09-04 21:58:39
# Description: 安装xray-core
# 
# Copyright (c) 2023 by Whiterabbit.Monster, All Rights Reserved. 
#

# 函数：导入公共参数和函数
import_common_func() {
	local common_script_link="https://raw.githubusercontent.com/whiterabbit-monster/scripts/main/common/common_function.sh"
	source <(wget -qO- $common_script_link)
	if [ $? -eq 0 ]; then
		color_print green "成功导入公共函数"
	else
		echo "无法导入公共函数，请检查网络"
	fi
}

# 定义相关变量
# 必备软件
dependency=("wget" "unzip" "curl")
# github请求头
request_head="Accept: application/vnd.github.v3+json"
# 最新稳定版
release_latest_link="https://api.github.com/repos/XTLS/Xray-core/releases/latest"
# 所有版本
release_list_link="https://api.github.com/repos/XTLS/Xray-core/releases"

# 函数：检测架构，包装软件安装卸载命令
check_os_arch() {
  if [[ "$(uname)" == 'Linux' ]]; then
    case "$(uname -m)" in
      'i386' | 'i686')
        MACHINE='32'
        ;;
      'amd64' | 'x86_64')
        MACHINE='64'
        ;;
      'armv5tel')
        MACHINE='arm32-v5'
        ;;
      'armv6l')
        MACHINE='arm32-v6'
        grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm32-v5'
        ;;
      'armv7' | 'armv7l')
        MACHINE='arm32-v7a'
        grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm32-v5'
        ;;
      'armv8' | 'aarch64')
        MACHINE='arm64-v8a'
        ;;
      'mips')
        MACHINE='mips32'
        ;;
      'mipsle')
        MACHINE='mips32le'
        ;;
      'mips64')
        MACHINE='mips64'
        lscpu | grep -q "Little Endian" && MACHINE='mips64le'
        ;;
      'mips64le')
        MACHINE='mips64le'
        ;;
      'ppc64')
        MACHINE='ppc64'
        ;;
      'ppc64le')
        MACHINE='ppc64le'
        ;;
      'riscv64')
        MACHINE='riscv64'
        ;;
      's390x')
        MACHINE='s390x'
        ;;
      *)
        echo "error: The architecture is not supported."
        exit 1
        ;;
    esac
    if [[ ! -f '/etc/os-release' ]]; then
      echo "error: Don't use outdated Linux distributions."
      exit 1
    fi
    # Do not combine this judgment condition with the following judgment condition.
    ## Be aware of Linux distribution like Gentoo, which kernel supports switch between Systemd and OpenRC.
    if [[ -f /.dockerenv ]] || grep -q 'docker\|lxc' /proc/1/cgroup && [[ "$(type -P systemctl)" ]]; then
      true
    elif [[ -d /run/systemd/system ]] || grep -q systemd <(ls -l /sbin/init); then
      true
    else
      echo "error: Only Linux distributions using systemd are supported."
      exit 1
    fi
    
  else
    echo "error: This operating system is not supported."
    exit 1
  fi
}

# 函数：检测现有xray版本和服务
check_xray() {
	local release_current_version
	if [ -e "/usr/local/bin/xray" ]; then
		release_current_version=$(/usr/local/bin/xray version | awk 'NR==1 {print $2}')
		color_print blue "检测到当前Xray版本为v$release_current_version"
	else
		color_print red "没有检测到Xray安装"
	fi
}

# 函数：选择版本，组装下载链接，下载，解压缩
# 解压缩目录有：xray、geoip.dat、geosite.dat、LICENSE、README.md
download_release() {
	local download_link tmp_dir zip_file
	color_print blue "发行版本列表："
	echo -e "$release_color_tag"
	color_print yellow "请输入你想安装的版本--> "
	read install_version
	while true; do
		if grep -xq "$install_version" <<< "$release_list"; then
			color_print green "你选择的版本是$install_version"
			break
		else
			color_print red "列表中无此版本"
			color_print yellow "请输入你想安装的版本--> "
			read install_version
		fi
	done

	download_link="https://github.com/XTLS/Xray-core/releases/download/${install_version}/Xray-linux-${MACHINE}.zip"

	tmp_dir="$(mktemp -d)"
	zip_file="${tmp_dir}/Xray-linux-$MACHINE.zip"

	color_print blue "临时文件夹为$tmp_dir"
	color_print blue "指定文件名为$zip_file"

	color_print blue "正在下载指定版本Xray压缩包: $download_link"
	if ! wget -q "$download_link" -O "$zip_file" ; then
		color_print red '下载指定版本Xray压缩包失败，请检查网络'
	fi

	color_print blue "正在下载指定版本Xray验证文件: $download_link.dgst"
	if ! wget -q "$download_link.dgst" -O "$zip_file.dgst" ; then
		color_print red '下载指定版本Xray验证文件失败，请检查网络'
	fi

	if [[ "$(cat "$zip_file".dgst)" == 'Not Found' ]]; then
		color_print red '本版本不支持验证，请更换版本'
	fi

	checksum=$(cat "$zip_file".dgst | awk -F '= ' '/256=/ {print $2}')
	localsum=$(sha256sum "$zip_file" | awk '{printf $1}')
	if [[ "$checksum" == "$localsum" ]]; then
		color_print blue "SHA256验证成功"
	else
		color_print red 'SHA256验证失败，请检测网络重新下载'
		exit 1
	fi

	if ! unzip -q "$zip_file" -d "$tmp_dir"; then
		color_print red '指定版本Xray解压缩错误'
		rm -r "$zip_file"
		color_print green "已清除文件: $zip_file"
		exit 1
	fi

	# 复制xray程序到目录
	mv -f "$tmp_dir/xray" "/usr/local/bin/xray"
	chmod 755 /usr/local/bin/xray
	color_print blue "成功安装Xray程序"

	# 复制geo文件到目录
	if [ ! -d "/usr/local/share/xray/" ]; then
		mkdir -p /usr/local/share/xray/
	fi

	mv -f "$tmp_dir"/geo* "/usr/local/share/xray/"
	chmod 644 /usr/local/share/xray/geo*
	color_print blue "成功安装Xray的geo文件"
}

# 函数：使用最新版升级geo文件
update_geodata() {
	local download_link tmp_dir zip_file
	color_print blue "使用最新版Xray更新geo文件"
	download_link="https://github.com/XTLS/Xray-core/releases/download/${release_newest_version}/Xray-linux-${MACHINE}.zip"

	tmp_dir="$(mktemp -d)"
	zip_file="${tmp_dir}/Xray-linux-$MACHINE.zip"
	color_print blue "临时文件夹为$tmp_dir"
	color_print blue "指定文件名为$zip_file"

	color_print blue "正在下载最新版本Xray压缩包: $download_link"
	if ! wget -q "$download_link" -O "$zip_file" ; then
		color_print red '下载指定版本Xray压缩包失败，请检查网络'
	fi

	color_print blue "正在下载最新版本Xray验证文件: $download_link.dgst"
	if ! wget -q "$download_link.dgst" -O "$zip_file.dgst" ; then
		color_print red '下载最新版本Xray验证文件失败，请检查网络'
	fi

	if [[ "$(cat "$zip_file".dgst)" == 'Not Found' ]]; then
		color_print red '本版本不支持验证，请更换版本'
	fi

	checksum=$(cat "$zip_file".dgst | awk -F '= ' '/256=/ {print $2}')
	localsum=$(sha256sum "$zip_file" | awk '{printf $1}')
	if [[ "$checksum" == "$localsum" ]]; then
		color_print blue "SHA256验证成功"
	else
		color_print red 'SHA256验证失败，请检测网络重新下载'
		exit 1
	fi
	if ! unzip -q "$zip_file" -d "$tmp_dir"; then
		color_print red '最新版Xray解压缩错误'
		rm -r "$zip_file"
		color_print green "已清除文件: $zip_file"
		exit 1
  	fi

	# 复制geo文件到目录
	if [ ! -d "/usr/local/share/xray/" ]; then
		mkdir -p /usr/local/share/xray/
	fi

	mv -f "$tmp_dir"/geo* "/usr/local/share/xray/"
	chmod 644 /usr/local/share/xray/geo*
	color_print blue "成功升级Xray的geo文件"
}

# 比较指定版本和最新版的版本号，测试为真则$2大于$1
version_gt() {
  test "$(echo -e "$1\\n$2" | sort -V | head -n 1)" != "$1"
}

# 函数：安装systemd服务
install_systemd_service() {
cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
	color_print blue "成功安装Xray服务"
}

# 函数：运行服务
start_systemd() {
	if [ -e "/usr/local/etc/xray/config.json" ]; then
		systemctl start xray
		sleep 1s
		if systemctl -q is-active xray; then
			color_print blue "Xray服务成功启动"
		else
			color_print red "Xray服务未成功启动"
		fi
	else
		color_print red "没有检测到xray配置文件，请创建/usr/local/etc/xray/config.json"
	fi
}
# 导入公共函数和参数
import_common_func
# 检测root
check_root
# 安装必备软件
install_dependency ${dependency[@]}
# 检测系统和架构
check_os_arch
# 检测现有xray版本
check_xray
greenline
# 获取xray版本
get_release
# 下载解压缩xray
download_release
greenline
# 升级xray的geo文件
if  [ "$install_version" != "$release_newest_version" ] ; then
	update_geodata
fi
greenline
# 安装并启动服务
install_systemd_service
start_systemd
# 清理tmp
rm -r /tmp/tmp*