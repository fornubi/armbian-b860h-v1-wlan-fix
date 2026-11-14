#!/bin/bash
set -e
KVER=$(uname -r)
KO=/home/bedman/Project/wifi_fix/src/8189fs.ko
echo "=== install 8189fs.ko ==="
install -D -m 0644 "$KO" /lib/modules/$KVER/kernel/drivers/net/wireless/8189fs.ko
depmod -a
# blacklist driver AIC yang nyasar (alias generic sdio class-07) agar tidak load
cat > /etc/modprobe.d/blacklist-aic8800.conf <<'BL'
blacklist aic8800_sdio_bsp
blacklist aic8800_sdio_wlan
BL
echo "=== load 8189fs ==="
modprobe 8189fs
sleep 3
echo "=== interface ==="
ip -br link
echo "=== modul ==="
lsmod | grep -E '8189fs|aic8800'
echo "=== dmesg tail ==="
dmesg | tail -15 | grep -iE '8189|wlan|firmware|error' 
