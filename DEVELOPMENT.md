# Development Environment Setup — Sahkonseuranta

This document describes how to set up a SailfishOS development environment on Windows, Linux, or macOS and test the Sahkonseuranta application.

---

## Overview

Sahkonseuranta is a SailfishOS application that requires:
- Qt 5.15.15 (SailfishOS 4.6 uses Qt 5.15)
- SailfishOS SDK (Mer SDK) — provides SailfishApp module and Silica components
- Target platform: Jolla Phone 2026 (armv7hl)

---

## Recommended: Debian Linux

### Windows (WSL2)
```powershell
wsl --install
wsl --set-default-version 2
wsl --install -d Debian
```

### Debian (WSL2/VM/Native)
```bash
sudo apt-get update
sudo apt-get install -y wget curl git build-essential \
    cmake pkg-config qt5-qmake qtbase5-dev \
    qtdeclarative5-dev libqt5network5 libqt5core5a \
    openjdk-17-jdk-headless
```

### Install Qt 5.15.15
```bash
wget https://download.qt.io/online/qtsdk/online-installer-linux-x64-4.6.1.run
chmod +x online-installer-linux-x64-4.6.1.run
./online-installer-linux-x64-4.6.1.run
```

### Install SailfishOS SDK
```bash
wget https://releases.sailfishos.org/sdk/installers/latest/Jolla/latest/SailfishOS-IDE-linux-offline-64-bit.run
chmod +x SailfishOS-IDE-linux-offline-64-bit.run
./SailfishOS-IDE-linux-offline-64-bit.run
```

Configure:
```bash
echo 'export PATH="$HOME/SailfishOS/lib/sfdk/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
sfdk config --add-target SailfishOS-4.6.0.15-armv7hl
```

### Build
```bash
git clone https://github.com/Zesseth/Sahkonseuranta.git
cd Sahkonseuranta
sfdk build -d SailfishOS-4.6.0.15-armv7hl
```

---

## Unit Testing (No SDK Required)

```bash
cd Sahkonseuranta/tests
qmake tests.pro
make
./pricefetcher_test
```

Expected: 9 checks, 0 failures

---

## Need Help?

Ask me for platform-specific guidance.

---

*Document created: 2026-10-11*
