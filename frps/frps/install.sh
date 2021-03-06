#!/bin/sh
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=$(nvram get productid)
module=frps
DIR=$(cd $(dirname $0); pwd)

# 获取固件类型
_get_type() {
	local FWTYPE=$(nvram get extendno|grep koolshare)
	if [ -d "/koolshare" ];then
		if [ -n $FWTYPE ];then
			echo "koolshare官改固件"
		else
			echo "koolshare梅林改版固件"
		fi
	else
		if [ "$(uname -o|grep Merlin)" ];then
			echo "梅林原版固件"
		else
			echo "华硕官方固件"
		fi
	fi
}

exit_install(){
	local state=$1
	case $state in
		1)
			echo_date "本插件适用于适用于【koolshare 梅林改/官改 hnd/axhnd/axhnd.675x】固件平台，你的固件平台不能安装！！！"
			echo_date "本插件支持机型/平台：https://github.com/koolshare/rogsoft#rogsoft"
			echo_date "退出安装！"
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 1
			;;
		0|*)
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 0
			;;
	esac
}

# 判断路由架构和平台
case $(uname -m) in
	aarch64)
		if [ "$(uname -o|grep Merlin)" -a -d "/koolshare" ];then
			echo_date 机型：$MODEL $(_get_type) 符合安装要求，开始安装插件！
		else
			exit_install 1
		fi
		;;
	armv7l)
		if [ "$MODEL" == "TUF-AX3000" -o "$MODEL" == "RT-AX82U" -o "$MODEL" == "RT-AX95Q" -o "$MODEL" == "RT-AX56_XD4" ] && [ -d "/koolshare" ];then
			echo_date 机型：$MODEL $(_get_type) 符合安装要求，开始安装插件！
		else
			exit_install 1
		fi
		;;
	*)
		exit_install 1
	;;
esac

if [ "$MODEL" == "GT-AC5300" ] || [ "$MODEL" == "GT-AX11000" ] || [ -n "$(nvram get extendno | grep koolshare)" -a "$MODEL" == "RT-AC86U" ];then
	# 官改固件，骚红皮肤
	ROG=1
fi

if [ "$MODEL" == "TUF-AX3000" ];then
	# 官改固件，橙色皮肤
	TUF=1
fi


# 安装插件
cd /
rm -f /koolshare/init.d/S97frps.sh
cp -f /tmp/${module}/bin/* /koolshare/bin/
cp -f /tmp/${module}/scripts/* /koolshare/scripts/
cp -f /tmp/${module}/res/* /koolshare/res/
cp -f /tmp/${module}/webs/* /koolshare/webs/
cp -f /tmp/${module}/init.d/* /koolshare/init.d/
rm -fr /tmp/frps* >/dev/null 2>&1
killall ${module}
if [ "$ROG" == "1" ];then
	continue
else
	if [ "$TUF" == "1" ];then
		sed -i 's/3e030d/3e2902/g;s/91071f/92650F/g;s/680516/D0982C/g;s/cf0a2c/c58813/g;s/700618/74500b/g;s/530412/92650F/g' /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
	else
		sed -i '/rogcss/d' /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
	fi
fi

chmod +x /koolshare/bin/${module}
chmod +x /koolshare/scripts/config-frps.sh
chmod +x /koolshare/scripts/frps_status.sh
chmod +x /koolshare/scripts/uninstall_frps.sh
chmod +x /koolshare/init.d/S97frps.sh
sleep 1

# 离线安装用
dbus set ${module}_version="${VERSION}"
#dbus set __event__onwanstart_frps=/koolshare/scripts/config-frps.sh
dbus set ${module}_client_version=`/koolshare/bin/${module} --version`
dbus set ${module}_common_cron_hour_min="hour"
dbus set ${module}_common_cron_time="12"
dbus set softcenter_module_${module}_install=1
dbus set softcenter_module_${module}_name=${module}
dbus set softcenter_module_${module}_title="Frps内网穿透"
dbus set softcenter_module_${module}_description="Frps路由器服务端，内网穿透利器。"
dbus set softcenter_module_${module}_version="${VERSION}"
en=`dbus get ${module}_enable`
if [ "$en" == "1" ]; then
    /koolshare/scripts/config-${module}.sh
fi
echo "${module} ${VERSION} install completed!"

