# WiFi Fix — B860H v1 (Armbian, kernel 6.18.59-ophub)

![License](https://img.shields.io/badge/License-GPL%20v2-blue.svg)
![Kernel](https://img.shields.io/badge/Kernel-6.18.59--ophub-9cf.svg)
![Platform](https://img.shields.io/badge/Platform-Amlogic%20S905X-green.svg)
![WiFi Chip](https://img.shields.io/badge/Chip-Realtek%20RTL8189FTV-lightgrey.svg)

## Problem

The B860H v1 uses a **Realtek RTL8189FTV** WiFi chip (`SDIO 024C:F179`).
The Armbian/ophub image ships an **AIC8800** driver (`aic8800_sdio_bsp`, generic alias
`sdio:c07v*d*`) that "hijacks" the device — no driver actually claims `024C:F179`,
so `wlan0` never appears.

## Solution

Build the out-of-tree **8189fs** driver from `jwrdegoede/rtl8189ES_linux` (branch `rtl8189fs`),
patched to compile on kernel 6.18 (cfg80211 ops: `net_device` → `wireless_dev`,
`remain_on_channel` cookie by value + `rx_addr`, `mgmt_tx` cookie by value).

The firmware is **embedded** in the `.ko` — no external firmware file needed.

## Files

- `src/` — driver source (clone of `jwrdegoede/rtl8189ES_linux`, branch `rtl8189fs`)
- `build.log` — last build log
- `INSTALL.sh` — install a pre-built `.ko` (no rebuild)
- `rebuild-and-install.sh` — rebuild + install (for after a kernel update)

## Usage

### After a normal reboot (same kernel)

Nothing to do — the module auto-loads from `/lib/modules/...` + AIC blacklist.

### First install / reinstall without rebuild

```bash
sudo bash ~/Project/wifi_fix/INSTALL.sh
```

### After a kernel update (rebuild REQUIRED)

```bash
sudo bash ~/Project/wifi_fix/rebuild-and-install.sh
```

This script will:
1. check that kernel headers are available
2. run `make clean && make`
3. install the `.ko` to `/lib/modules/$(uname -r)/...`
4. run `depmod -a`
5. make sure the AIC blacklist is in place
6. load the `8189fs` module

### Remove the swap file (optional, saves eMMC)

```bash
sudo swapoff /swapfile && sudo rm /swapfile
```

## Local patches

Changes applied on top of upstream:

- `src/os_dep/linux/ioctl_cfg80211.c` — kernel 6.18 compatibility: cfg80211 ops `net_device` → `wireless_dev`,
  pass-by-value cookie in `remain_on_channel`/`mgmt_tx` + new `rx_addr` parameter, `strncpy` → `strscpy_pad`.
- `src/Makefile` — `CONFIG_PLATFORM_I386_PC = y` for native builds (arm64, no cross-compile).

Build artifacts (`*.o`, `*.ko`, etc.) are excluded via `.gitignore`; rebuild with `rebuild-and-install.sh`.

## Source & License

- The driver code in `src/` comes from [jwrdegoede/rtl8189ES_linux](https://github.com/jwrdegoede/rtl8189ES_linux),
  branch `rtl8189fs`, commit `13bbdbc` (merge PR #148). Licensed under **GPL-2.0** (see `LICENSE`),
  copyright Realtek Corporation.

## Notes

- Out-of-tree driver: every kernel upgrade requires a rebuild.
- Keep the `src/` folder — do not delete it.
- The second interface (`wlan1`, no-carrier) is normal (virtual/P2P interface from the driver).

## Scripts

- `build.sh` — build only (no install). Output: `src/8189fs.ko`.
- `INSTALL.sh` — install the existing `.ko` (no rebuild). Requires root.
- `rebuild-and-install.sh` — rebuild + install in one go (for after a kernel update). Requires root.
