#!/bin/bash
# Rebuild + install driver 8189fs setelah update kernel.
# Jalankan: sudo bash ~/Project/wifi_fix/rebuild-and-install.sh
set -e

SRC=/home/bedman/Project/wifi_fix/src
KVER=$(uname -r)
KSRC=/lib/modules/$KVER/build

echo "=== Kernel target: $KVER ==="
if [ ! -d "$KSRC" ]; then
  echo "ERROR: kernel headers tidak ditemukan: $KSRC"
  echo "Install dulu, contoh: sudo apt install linux-headers-$KVER"
  exit 1
fi
if ! command -v make >/dev/null || ! command -v gcc >/dev/null; then
  echo "ERROR: make/gcc tidak tersedia"
  exit 1
fi

cd "$SRC"
echo "=== make clean ==="
make clean >/dev/null 2>&1 || true

echo "=== build (j=2) ==="
make ARCH=arm64 CROSS_COMPILE= KSRC="$KSRC" -j2

if [ ! -f 8189fs.ko ]; then
  echo "ERROR: build gagal, 8189fs.ko tidak terbentuk"
  exit 1
fi
echo "=== build OK: $(ls -lh 8189fs.ko | awk '{print $5}') ==="

echo "=== install ==="
install -D -m 0644 8189fs.ko /lib/modules/$KVER/kernel/drivers/net/wireless/8189fs.ko
depmod -a

# pastikan blacklist AIC tetap ada
cat > /etc/modprobe.d/blacklist-aic8800.conf <<'BL'
blacklist aic8800_sdio_bsp
blacklist aic8800_sdio_wlan
BL

echo "=== load modul ==="
modprobe -r 8189fs 2>/dev/null || true
modprobe 8189fs
sleep 2

echo "=== hasil ==="
ip -br link | grep -i wlan || true
lsmod | grep 8189fs || echo "WARNING: 8189fs tidak ter-load"
