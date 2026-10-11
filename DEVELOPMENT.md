# Development Environment Setup — Sähkönseuranta

This guide explains how to set up a SailfishOS development environment on
Windows, Linux, or macOS and get the project building and tested.

## Overview

Sähkönseuranta is a SailfishOS application. Building the full application
requires:

- **Qt 5.15** (SailfishOS 4.6 ships Qt 5.15)
- **SailfishOS SDK** — provides the SailfishApp module and Silica components
- **Target:** Jolla Phone 2026 (`armv7hl`)

The SailfishOS SDK only runs on Linux. On Windows or macOS, use a Linux
environment such as WSL2 or a virtual machine.

## Setup

### 1. Linux environment

**Debian** is recommended; any recent Debian or Ubuntu LTS release works.

On Windows, enable WSL2 and install Debian:

```powershell
wsl --install
wsl --set-default-version 2
wsl --install -d Debian
```

On macOS, run Debian in a VM (UTM, VirtualBox, etc.).

### 2. Dependencies

Inside the Linux environment:

```bash
sudo apt-get update
sudo apt-get install -y wget curl git build-essential \
    cmake pkg-config qt5-qmake qtbase5-dev \
    qtdeclarative5-dev
```

### 3. SailfishOS SDK

Download and run the SailfishOS SDK installer (see the current link on
[docs.sailfishos.org/Tools/Sailfish_SDK](https://docs.sailfishos.org/Tools/Sailfish_SDK/);
SDK 3.13.5 at the time of writing):

```bash
wget https://releases.sailfishos.org/sdk/installers/3.13.5/SailfishSDK-3.13.5-linux64-online.run
chmod +x SailfishSDK-3.13.5-linux64-online.run
./SailfishSDK-3.13.5-linux64-online.run
```

The SDK build engine requires Docker (or VirtualBox); on WSL2 use Docker.
For unattended/headless installation:

```bash
QT_QPA_PLATFORM=minimal ./SailfishSDK-3.13.5-linux64-online.run \
    non-interactive=1 accept-licenses=1 build-engine-type=docker
```

Add `sfdk` to PATH and install the build target:

```bash
echo 'export PATH="$HOME/SailfishOS/lib/sfdk/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
sfdk tools install SailfishOS-4.6.0.13-armv7hl
```

### 4. Clone and build

```bash
git clone https://github.com/Zesseth/Sahkonseuranta.git
cd Sahkonseuranta
sfdk config target=SailfishOS-4.6.0.13-armv7hl && sfdk build
```

A successful build produces
`RPMS/armv7hl/harbour-sahkonseuranta-0.1.0-1.*.rpm`.

## Unit testing without the SDK

The `PriceFetcher` backend class does not depend on Silica, so it can be
compiled and tested with any plain Qt5 installation — no SailfishOS SDK
needed:

```bash
cd tests
qmake tests.pro
make
./pricefetcher_test
```

The test fetches live data from the porssisahko.net API, so it requires
network access. See [TESTING.md](TESTING.md) for expected output and
acceptance criteria.

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `SailfishApp not found` | Building on the host instead of the SDK | Build with `sfdk build` |
| `sfdk: command not found` | PATH not set | Add `~/SailfishOS/lib/sfdk/bin` to PATH |
| Target missing | Target not installed | `sfdk tools target install SailfishOS-4.6.0.13-armv7hl` |
| Qt version mismatch | Wrong Qt version | The SDK provides its own Qt; do not mix host Qt into SDK builds |
| CMake flags from the wrong target | In-source CMake cache left over from building another target | `rm -rf CMakeCache.txt CMakeFiles` (and `Makefile`, generated binaries) before `sfdk build` |

## Links

- SailfishOS SDK documentation: https://docs.sailfishos.org/SDK_Guide/
- Qt 5.15 documentation: https://doc.qt.io/qt-5/
- porssisahko.net API: https://porssisahko.net/api
