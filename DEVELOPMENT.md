# Kehitysympäristön asennus ja testaus — Sähkönseuranta

Tämä dokumentti kuvaa, miten voit asentaa SailfishOS kehitysympäristön **Windows-koneelle** ja testata Sähkönseuranta-sovellusta.

---

## Yleiskuva

Sovellus on SailfishOS-sovellus, joka vaatii:
- **Qt 5.15.15** (SailfishOS 4.6 käyttää Qt 5.15:ta)
- **SailfishOS SDK** (Mer SDK) — sisältää SailfishApp-moduulin ja Silica-komponentit
- **Jolla Phone 2026** kohde-alustana (armv7hl)

---

## Suositeltu ratkaisu: WSL2 + Ubuntu 22.04

### Vaihe 1: Asenna WSL2 (10 min)

```powershell
# PowerShell (Admin)
wsl --install
wsl --set-default-version 2
wsl --install -d Ubuntu-22.04
```

**Varmista WSL2:**
```powershell
wsl --list --verbose
```

### Vaihe 2: Asenna riippuvuudet Ubuntuun (10 min)

Avaa Ubuntu WSL2:
```powershell
wsl -d Ubuntu-22.04
```

Asenna paketit:
```bash
sudo apt-get update
sudo apt-get install -y wget curl git build-essential \
    cmake pkg-config qt5-qmake qtbase5-dev \
    qtdeclarative5-dev libqt5network5 libqt5core5a \
    openjdk-17-jdk headless
```

### Vaihe 3: Asenna Qt 5.15.15 (20 min)

Lataa Qt Online Installer:
```bash
cd ~
wget https://download.qt.io/online/qtsdk/online-installer-linux-x64-4.6.1.run
chmod +x online-installer-linux-x64-4.6.1.run
./online-installer-linux-x64-4.6.1.run
```

**Asennusvalinnat graafisessa installerissa:**
- [x] Qt 5.15.15 for Linux
- [ ] Qt 6.x (ei tarpeen)
- [ ] MSVC (ei tarpeen Linuxilla)

**TAKEOVER:** SailfishOS SDK vaatii **Qt 5.15.15**, ei uudempaa!

### Vaihe 4: Asenna SailfishOS SDK (30 min)

Lataa SDK:
```bash
wget https://releases.sailfishos.org/sdk/installers/latest/Jolla/latest/SailfishOS-IDE-linux-offline-64-bit.run
chmod +x SailfishOS-IDE-linux-offline-64-bit.run
./SailfishOS-IDE-linux-offline-64-bit.run
```

Konfiguroi:
```bash
# Lisää sfdk PATHiin
echo 'export PATH="$HOME/SailfishOS/lib/sfdk/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Tarkista
sfdk --version

# Lisää target
sfdk config --add-target SailfishOS-4.6.0.15-armv7hl
```

### Vaihe 5: Kloonaa ja käännä sovellus (5 min)

```bash
cd ~/projects
git clone https://github.com/Zesseth/Sahkonseuranta.git
cd Sahkonseuranta
git checkout vibe/sahkonseuranta-mvp

# Käännä
sfdk build -d SailfishOS-4.6.0.15-armv7hl
```

**Onnistuminen:**
- Käännös menee läpi ilman virheitä
- `RPMS/armv7hl/harbour-sahkonseuranta-0.1.0-1.*.rpm` luodaan

---

## Yksikkötestaus (PriceFetcher)

**Ei vaadi SailfishOS SDK:ta!**

### WSL2/Ubuntu

```bash
cd ~/projects/Sahkonseuranta
sudo apt-get install -y qtbase5-dev qtdeclarative5-dev
cd tests
qmake tests.pro
make
./pricefetcher_test
```

### Odotettu tulostus

```
prices fetched, bars=96
  00:00  1.583 snt/kWh
  00:15  1.505 snt/kWh
  ...
current=4.533 avg=3.331 min=1.365 max=6.275 res=15
after res switch: bars=24  first 00:00 1.677

ok  : 96 bars at 15 min resolution
ok  : bars in ascending time order
ok  : bars span a single local day
ok  : current price set
ok  : min <= avg
ok  : avg <= max
ok  : 24 bars at 60 min resolution
ok  : first hourly bar starts at 00:00

7 checks, 0 failures
```

### Hyväksymiskriteerit

- [ ] `bars=96` (15 min resoluutio)
- [ ] `bars=24` (60 min resoluutio)
- [ ] Ajat nousevassa järjestyksessä (00:00 -> 23:45)
- [ ] `current` on järkevä arvo (0-20 snt/kWh)
- [ ] `min <= avg <= max`
- [ ] Palautusarvo 0 (ei kaatumista)

---

## Emulaattoritestaus

### Käynnistä emulaattori

```bash
sfdk emulator --armv7hl
```

Odota 1-2 minuuttia emulaattorin käynnistyessä.

### Asenna RPM emulaattoriin

```bash
sfdk engine exec sb2 -t SailfishOS-4.6.0.15-armv7hl \
    -m sdk-build -R \
    pkcon install-local RPMS/armv7hl/harbour-sahkonseuranta-0.1.0-1.*.rpm
```

### Testauschecklist

#### Perustoiminnot
- [ ] Sovellus käynnistyy launcherista
- [ ] Hinta nyt näkyy muutamassa sekunnissa
- [ ] Palkkigraafi piirtyy (96 palkkia 15 min / 24 palkkia 60 min)
- [ ] Palkit ovat nousevassa aikajärjestyksessä

#### Resoluution vaihto
- [ ] "1 h" -nappi tiivistää graafin 24 palkkiin
- [ ] "15 min" -nappi palauttaa 96 palkkiin

#### Päivämäärän vaihto
- [ ] PullDownMenu -> "Paivita" päivittää datan
- [ ] PullDownMenu -> "Nayta huominen" näyttää huomisen hinnat (klo 14:15 jälkeen)

#### Kansi
- [ ] Kansinäyttö näyttää nykyhinnan
- [ ] Kansion klikkaus tuo sovelluksen eteen

#### Virhekäsittely
- [ ] Lentotila: "Paivita" näyttää virheilmoituksen kaatumatta

---

## Laitetestaus (Jolla Phone 2026)

### Siirrä RPM laitteelle

```bash
scp RPMS/armv7hl/harbour-sahkonseuranta-0.1.0-1.*.rpm defaultuser@<laitteen-ip>:
```

### Asenna laitteelle

```bash
pkcon install-local harbour-sahkonseuranta-0.1.0-1.*.rpm
```

### Laitespesifiset testit

- [ ] Launcher-ikoni näkyy oikein (86x86)
- [ ] Graafi on luettava ulko-aurinkoisessa valossa
- [ ] Verkkoyhteys mobiilidata: haku ei kaadu hitaaseen verkkoon
- [ ] Muistikäyttö pysyy vakaana 30 min automaattipäivityksellä
- [ ] Sailjail: vain `Internet`-lupa
- [ ] Ei taustaprosessia Home-näppäimellä suljettaessa

---

## Vianetsintä

| Virhe | Syy | Ratkaisu |
|-------|-----|----------|
| `SailfishApp not found` | Käännös isäntäkoneella | Käännä sfdk-virtuaalikoneessa |
| `sfdk: command not found` | PATH puuttuu | `export PATH="$HOME/SailfishOS/lib/sfdk/bin:$PATH"` |
| Target puuttuu | Ei konfiguroitu | `sfdk config --add-target SailfishOS-4.6.0.15-armv7hl` |
| Build kaatuu Qt:hen | Väärä Qt versio | Asenna Qt 5.15.15 |
| TIMEOUT testissä | API alas | Yritä uudelleen myöhemmin |

---

## Aikataulu

| Vaihe | Aika | Tila |
|-------|------|------|
| WSL2 asennus | 10 min | |
| Riippuvuudet | 10 min | |
| Qt 5.15.15 | 20 min | |
| SailfishOS SDK | 30 min | |
| Kloonaus & build | 5 min | |
| Yksikkötesti | 2 min | |
| Emulaattoritesti | 10 min | |
| **Yhteensä** | **~1.5 tuntia** | |

---

## Hyödyllisiä komentoja

```bash
# Listaa targetit
sfdk config --list-targets

# Päivitä targetit
sfdk config --refresh-targets

# Tarkista asennus
sfdk --version
sfdk doctor

# Puhdista build
sfdk build --clean
```

---

## Linkit

- SailfishOS SDK: https://docs.sailfishos.org/SDK_Guide/
- Qt 5.15: https://doc.qt.io/qt-5/
- Jolla Store: https://harbour.jolla.com/
- API: https://porssisahko.net/api

---

*Dokumentti luotu: 2026-10-11*
