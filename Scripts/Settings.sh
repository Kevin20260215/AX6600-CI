#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")


# =========================================================
# 写入 AX6600 专属开机初始化脚本 (三频独立命名与优化)
# =========================================================
mkdir -p ./package/base-files/files/etc/uci-defaults/

cat <<EOF > ./package/base-files/files/etc/uci-defaults/set-wifi
#!/bin/sh

# 等待系统默认的 Wi-Fi 配置文件生成完毕
sleep 3

board_name=\$(cat /tmp/sysinfo/board_name)

# 仅当设备为 AX6600 时执行
if [ "\$board_name" = "jdcloud,ax6600" ] || [ "\$board_name" = "jdcloud,re-cs-02" ]; then
    uci -q batch <<-UciEoF
		# === 5GHz-1 配置 ===
		set wireless.radio0.channel="149"
		set wireless.radio0.htmode="HE80"
		set wireless.radio0.mu_beamformer="1"
		set wireless.radio0.country="CN"
		set wireless.radio0.txpower="22"
		set wireless.radio0.cell_density="0"
		set wireless.radio0.disabled="0"
		set wireless.default_radio0.ssid="${WRT_SSID}_5G1"
		set wireless.default_radio0.encryption="psk2+ccmp"
		set wireless.default_radio0.key="${WRT_WORD}"
		set wireless.default_radio0.ieee80211k="1"
		set wireless.default_radio0.time_advertisement="2"
		set wireless.default_radio0.time_zone="CST-8"
		set wireless.default_radio0.bss_transition="1"
		set wireless.default_radio0.wnm_sleep_mode="1"
		set wireless.default_radio0.wnm_sleep_mode_no_keys="1"

		# === 2.4GHz 配置 ===
		set wireless.radio1.channel="1"
		set wireless.radio1.htmode="HE20"
		set wireless.radio1.mu_beamformer="1"
		set wireless.radio1.country="CN"
		set wireless.radio1.txpower="22"
		set wireless.radio1.cell_density="0"
		set wireless.radio1.disabled="0"
		set wireless.default_radio1.ssid="${WRT_SSID}"
		set wireless.default_radio1.encryption="psk2+ccmp"
		set wireless.default_radio1.key="${WRT_WORD}"
		set wireless.default_radio1.ieee80211k="1"
		set wireless.default_radio1.time_advertisement="2"
		set wireless.default_radio1.time_zone="CST-8"
		set wireless.default_radio1.bss_transition="1"
		set wireless.default_radio1.wnm_sleep_mode="1"
		set wireless.default_radio1.wnm_sleep_mode_no_keys="1"

		# === 5GHz-2 配置 ===
		set wireless.radio2.channel="44"
		set wireless.radio2.htmode="HE160"
		set wireless.radio2.mu_beamformer="1"
		set wireless.radio2.country="CN"
		set wireless.radio2.txpower="23"
		set wireless.radio2.cell_density="0"
		set wireless.radio2.disabled="0"
		set wireless.default_radio2.ssid="${WRT_SSID}_5G2"
		set wireless.default_radio2.encryption="psk2+ccmp"
		set wireless.default_radio2.key="${WRT_WORD}"
		set wireless.default_radio2.ieee80211k="1"
		set wireless.default_radio2.time_advertisement="2"
		set wireless.default_radio2.time_zone="CST-8"
		set wireless.default_radio2.bss_transition="1"
		set wireless.default_radio2.wnm_sleep_mode="1"
		set wireless.default_radio2.wnm_sleep_mode_no_keys="1"
	UciEoF

    uci commit wireless
    /etc/init.d/network restart
fi

exit 0
EOF

chmod +x ./package/base-files/files/etc/uci-defaults/set-wifi


CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config


#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi


#高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#取消nss相关feed
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	#设置NSS版本
	echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
	#其他调整
	echo "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y" >> ./.config
fi
