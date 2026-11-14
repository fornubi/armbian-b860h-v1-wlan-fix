#!/bin/bash
# Hanya build driver (tanpa install). Hasil: src/8189fs.ko
# Jalankan: bash ~/Project/wifi_fix/build.sh
set -e
SRC=/home/bedman/Project/wifi_fix/src
KVER=$(uname -r)
KSRC=/lib/modules/$KVER/build
cd "$SRC"
make clean >/dev/null 2>&1 || true
make ARCH=arm64 CROSS_COMPILE= KSRC="$KSRC" -j2
ls -lh 8189fs.ko
