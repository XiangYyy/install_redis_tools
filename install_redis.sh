#!/bin/bash
## Author：yanxiang
## Time:20220909

set -eu

# 运行用户
RUN_USER="rcsr"
# 无需配置，脚本使用全局变量
PKG_NAME=""
OS_NAME=""
OS_VERSION=""
OS_CPU_TOTAL=""
OS_RAM_TOTAL=""
SERVICE_PATH="/etc/systemd/system"

# 打印Error
function EchoError() {
	red_color='\E[1;31m'
	res='\E[0m'
	echo -e "${red_color}ERROR: ${1}${res}" >&2
}

# 打印INFO
function EchoInfo() {
	local green_color='\E[1;32m'
	local res='\E[0m'
	echo -e "${green_color}INFO: ${1}${res}"
}

# 校验运行脚本的用户
function CheckRunUser() {
	EchoInfo "check run user"
	if [ $UID -ne 0 ]; then
		EchoError "Please use root or sudo run this script!!"
		exit 1
	fi
}

# 获取操作系统基本信息
function InitGetOSMsg() {
	if [ -f "/etc/redhat-release" ] && [ "$(awk '{print $1}' /etc/redhat-release)" = "CentOS" ]; then
		OS_NAME="CentOS"
		OS_VERSION="$(awk -F 'release ' '{print $2}' /etc/redhat-release | awk '{print $1}' | awk -F '.' -v OFS='.' '{print $1,$2}')"
	elif [ -f "/etc/redhat-release" ] && [ "$(awk -v OFS='' '{print $1,$2}' /etc/redhat-release)" = "RedHat" ]; then
		OS_NAME="RedHat"
		OS_VERSION="$(awk -F 'release ' '{print $2}' /etc/redhat-release | awk '{print $1}')"
	elif [ -f "/etc/issue" ] && [ "$(awk '{print $1}' /etc/issue)" = "Ubuntu" ]; then
		OS_NAME="Ubuntu"
		OS_VERSION="$(awk '{print $2}' /etc/issue | head -n 1)"
	else
		EchoError "OS Not Support"
		exit 1
	fi

	OS_CPU_TOTAL=$(grep -c 'processor' /proc/cpuinfo)
	OS_RAM_TOTAL=$(free -g | grep Mem | awk '{print $2}')

	echo "OS_NAME=$OS_NAME"
	echo "OS_VERSION=$OS_VERSION"
	echo "OS_CPU_TOTAL=$OS_CPU_TOTAL"
	echo "OS_RAM_TOTAL=$OS_RAM_TOTAL"
}

function Init() {
	if [ ! -f "./install_redis.conf" ]; then
		EchoError 'config file "./install_redis.conf" not found'
		exit 1
	fi

	EchoInfo "load install config"
	# load config
	# shellcheck source=/dev/null
	source "./install_redis.conf"

	PKG_NAME="redis-${PKG_VERSION}.tar.gz"

	InitGetOSMsg

}

function CheckSystemExists() {
	local server_name="redis_${PORT}"
	local redis_systemctl_path="${SERVICE_PATH}/${server_name}.service"

	if [ "$(systemctl status "${server_name}" | wc -l)" -ne 0 ]; then
		EchoError "systemctl server $server_name is exists"
		exit 1
	fi
	if [ -e "${redis_systemctl_path}" ]; then
		EchoError "systemctl server conf ${redis_systemctl_path} is exists"
		exit 1
	fi

	if [ -e "/etc/default/${server_name}" ]; then
		EchoError "systemctl server env /etc/default/${server_name} is exists"
		exit 1
	fi
}

function CheckDeployingSets() {
	EchoInfo "check deploying path"
	# check deploying path
	if [ -e "$INSTALL_PATH" ] &&
		[ "$(find "$INSTALL_PATH" -maxdepth 1 ! -name "$(basename "$INSTALL_PATH")" |
			wc -l)" -ne 0 ]; then
		EchoError "$INSTALL_PATH is not empty directories"
		exit 1
	fi
	EchoInfo "check deploying pass"

	#check port
	local min_sys_tmp_port
	min_sys_tmp_port=$(awk '{print $1}' "/proc/sys/net/ipv4/ip_local_port_range")
	EchoInfo "check port: $PORT"

	if ! [[ $PORT =~ ^[0-9]+$ ]] || [ "$PORT" -ge "$min_sys_tmp_port" ] ||
		[ "$PORT" -le "1024" ]; then
		EchoError "redis port $PORT not allowed"
		exit 1
	fi
	if [ "$(ss -anlp | grep -wc "\:${PORT}")" -ne "0" ]; then
		EchoError "redis port $PORT is listen"
		exit 1
	fi
	EchoInfo "redis port check $PORT pass"
}

# 安装系统依赖的基础包
function InstallSysPkgs() {
	if [ "$SKIP_SYS_PKG_INSTALL" -ne "0" ]; then
		EchoInfo "skip install sys pkgs"
		return 0
	fi

	if [ "$OS_NAME" = "CentOS" ] || [ "$OS_NAME" = "RedHat" ]; then
		EchoInfo "Install sys pkgs"
		if ! yum install gcc -y; then
			EchoError "Install sys pkgs faild"
			exit 1
		fi
	fi

	if [ "$OS_NAME" = "Ubuntu" ]; then
		EchoInfo "Install sys pkgs"
		if ! apt -y update || ! apt -y install gcc; then
			EchoError "Install sys pkgs faild"
			exit 1
		fi
	fi
}

# 编译安装 Reids
function BuildRedis() {
	if [ ! -e "$INSTALL_PATH" ]; then
		mkdir -p "$INSTALL_PATH"
	fi

	EchoInfo "unzip redis pkgs"
	tar -zxvf "$PKG_NAME"

	EchoInfo "Make install Redis"
	cd "redis-${PKG_VERSION}"
	make PREFIX="${INSTALL_PATH}" install
}

# 更改 redis cluster 配置
function ChangeClusterConf() {
	local conf_path="${INSTALL_PATH}/etc/${PORT}.conf"
	sed -i "/# cluster-enabled yes/a\cluster-enabled yes" "$conf_path"
	sed -i "/# cluster-config-file nodes-6379.conf/a\cluster-config-file nodes-6379.conf" "$conf_path"
	sed -i "/# cluster-node-timeout 15000/a\cluster-node-timeout 15000" "$conf_path"
	sed -i '/# save ""/a\save ""' "$conf_path"
	sed -i "s#appendonly no#appendonly yes#g" "$conf_path"

	if [ "$REDIS_PASSWORD" != "" ]; then
		sed -i "/# masterauth/a\masterauth ${REDIS_PASSWORD}" "$conf_path"
	fi
}

# 更改配置文件
function ChangeConf() {

	EchoInfo "add etc/data/log path"

	mkdir -p "${INSTALL_PATH}/etc"
	mkdir -p "${INSTALL_PATH}/data/${PORT}"
	mkdir -p "${INSTALL_PATH}/log"
	local conf_path="${INSTALL_PATH}/etc/${PORT}.conf"

	cp -rp redis.conf "$conf_path"

	EchoInfo "change $conf_path conf"

	sed -i "s#/var/run/redis_${PORT}.pid#${INSTALL_PATH}/log/redis_${PORT}.pid#g" "$conf_path"
	sed -i "s#daemonize no#daemonize yes#g" "$conf_path"
	sed -i "s#logfile \"\"#logfile ${INSTALL_PATH}/log/redis_${PORT}.log#g" "$conf_path"
	sed -i "s#dir ./#dir ${INSTALL_PATH}/data/${PORT}#g" "$conf_path"
	sed -i "s#port 6379#port ${PORT}#g" "$conf_path"

	if [ "$REDIS_PASSWORD" != "" ]; then
		sed -i "s/# requirepass foobared/requirepass ${REDIS_PASSWORD}/g" "$conf_path"
	fi

	if [ "$ENABLE_CLUSTER" -eq "1" ]; then
		ChangeClusterConf
	fi

}

# 配置 systemctl
function AddRedisSystemd() {
	local server_name="redis_${PORT}"
	local redis_systemctl_path="${SERVICE_PATH}/${server_name}.service"

	cd ..
	cp -rp redis_template.env "/etc/default/${server_name}"
	sed -i "s#{{ BIND_IP }}#$BIND_IP#g" "/etc/default/${server_name}"

	cp -rp redis_template.service "${redis_systemctl_path}"

	sed -i "s#{{ PORT }}#$PORT#g" "/etc/default/${server_name}"
	sed -i "s#{{ INSTALL_PATH }}#$INSTALL_PATH#g" "/etc/default/${server_name}"
	sed -i "s#{{ INSTALL_PATH }}#$INSTALL_PATH#g" "${redis_systemctl_path}"
	sed -i "s#{{ PORT }}#$PORT#g" "${redis_systemctl_path}"
	sed -i "s#{{ RUN_USER }}#$RUN_USER#g" "${redis_systemctl_path}"

	# 更改 redis 配置
	sed -i "s#bind 127.0.0.1#bind $BIND_IP#g" "${INSTALL_PATH}/etc/${PORT}.conf"

	if [ "$REDIS_PASSWORD" != "" ]; then
		sed -i "s/shutdown/shutdown -a ${REDIS_PASSWORD}/g" "${redis_systemctl_path}"
	fi

	systemctl daemon-reload
	systemctl enable "$server_name"

}

# 需手动配置内容
function StartRedis() {
	EchoInfo "Redis_$PORT Install Success"
	EchoInfo "redis path: $INSTALL_PATH"
	EchoInfo "bind ip: $BIND_IP"
	EchoInfo "port: $PORT"

	EchoInfo "Enable Redis_${PORT}"
	systemctl enable "redis_${PORT}"
	EchoInfo "Start redis_${PORT}"
	systemctl start "redis_${PORT}"
}

# 设置用户权限
function SetRedisRole() {
	if ! id "$RUN_USER"; then
		EchoInfo "add $RUN_USER"
		useradd -s /sbin/nologin -M -r $RUN_USER
	fi
	EchoInfo "chown to $RUN_USER"
	chown -R $RUN_USER.$RUN_USER "$INSTALL_PATH"
	chmod -R 750 "$INSTALL_PATH"
}

function PreCheck() {
	CheckRunUser
	CheckSystemExists
	CheckDeployingSets
}

function main() {
	Init
	PreCheck
	InstallSysPkgs
	BuildRedis
	ChangeConf
	AddRedisSystemd
	SetRedisRole
	StartRedis
}

main "$@"
