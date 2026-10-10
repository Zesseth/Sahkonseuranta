# Testausohjeet — Sähkönseuranta

Tämä dokumentti kuvaa, miten sovellus testataan ennen Jolla Storeen
julkaisua: automaattinen testiohjelma, SDK-käännös, emulaattoritesti ja
laitetestaus Jolla Phonella.

## 1. Yksikkötesti: PriceFetcher (ei vaadi SDK:ta)

`src/pricefetcher.{h,cpp}` on riippumaton Silica-käyttöliittymästä, joten
sen voi kääntää ja testata missä tahansa Qt5-ympäristössä.

### Mitä testiohjelma tekee

`tests/pricefetcher_test.cpp`:

1. Hakee oikean rajapinnan
   (`https://api.porssisahko.net/v2/latest-prices.json`) verkosta
2. Varmistaa että 15 min resoluutiossa palkit ovat
   - peräkkäisessä aikajärjestyksessä (00:00 → 23:45)
   - yhden paikallisen vuorokauden sisällä
3. Vaihtaa resoluution 60 minuuttiin ja varmistaa
   - palkkeja on täsmälleen 24
   - ensimmäinen palkki alkaa klo 00:00
   - tunnin hinta on sen 4 vartin keskiarvo
4. Tulostaa hinta nyt / keskihinta / min / max tarkistettavaksi

### Ajo (esim. Linux + qtbase5-dev, qtdeclarative5-dev)

```bash
qmake tests/tests.pro   # tai ks. manuaalinen kääntö alla
make
./pricefetcher_test
```

Manuaalinen kääntö ilman qmakea (esim. CI-ympäristössä):

```bash
moc src/pricefetcher.h -o moc_pricefetcher.cpp
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt5Core Qt5Network) \
    -Isrc -c src/pricefetcher.cpp -o pricefetcher.o
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt5Core Qt5Network) \
    -Isrc -c moc_pricefetcher.cpp -o moc_pf.o
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt5Core Qt5Network) \
    -Isrc -c tests/pricefetcher_test.cpp -o test_main.o
g++ pricefetcher.o moc_pf.o test_main.o -o pricefetcher_test \
    $(pkg-config --libs Qt5Core Qt5Network)
./pricefetcher_test
```

### Hyväksymiskriteerit

- `bars=96` (15 min) ja `bars=24` (60 min) paikallispäivänä
- Ajat nousevassa järjestyksessä, ensimmäinen 00:00, viimeinen 23:45/23:00
- `current` on järkevä arvo (esim. 0–10 snt/kWh), `min <= avg <= max`
- Palautus 0 (ei kaatumista, ei assertiovirhettä)

Testi vaatii verkkoyhteyden. Jos rajapinta on alas, testi tulostaa
`TIMEOUT` — ajettava uudelleen myöhemmin.

### Mitä on jo ajettu (2026-10-10, Qt 5.15.15, Debian)

```
prices fetched, bars=96
  00:00  1.583 snt/kWh
  00:15  1.505 snt/kWh
  ...
current=4.533 avg=3.331 min=1.365 max=6.275 res=15
after res switch: bars=24  first 00:00 1.677
```

Löydetyt ja korjatut viat: ks. "Testihistoria" loppuun.

## 2. SDK-käännös (Jolla Phone 2026, armv7hl)

Koko sovellus (ml. QML) pitää kääntää SailfishOS SDK:lla:

```bash
sfdk config --sailfish-sdk-map <SDK-polku>
sfdk build -d SailfishOS-4.6.0.15-armv7hl
```

Onnistumisen kriteerit:

- `moc` ja kääntö menevät läpi ilman varoituksia
- `RPMS/noarch/` (tai `RPMS/armv7hl/`) syntyy
  `harbour-sahkonseuranta-0.1.0-1.*.rpm`
- `rpmlint harbour-sahkonseuranta-*.rpm` ei erroita

Vianetsintä:

- `SailfishApp not found` → Varmista `find_package(SailfishApp)`
  ja että buildi ajetaan sfdk-virtuaalikoneessa, ei isäntäkoneella
- ` Sailfish.Silica` puuttuu → CMake asentaa vain `qml/`-kansion;
  Silica tulee SDK:n imagesta eikä sitä paketoida

## 3. Emulaattoritesti (SailfishOS SDK)

```bash
sfdk emulator --armv7hl   # tai x86-virtuaalikone
```

1. Asenna RPM: `sfdk engine exec sb2 -m ... pkcon install-local <rpm>`
2. Käynnistä sovellus launcherista ("Sähkönseuranta")
3. Tarkista:
   - [ ] Hinta nyt näkyy muutamassa sekunnissa
   - [ ] Palkkigraafi piirtyy: 96 palkkia, nouseva aikajärjestys
   - [ ] "1 h" -napista graafi tiivistyy 24 palkkiin
   - [ ] "15 min" palauttaa 96 palkkiin
   - [ ] PullDownMenu → "Päivitä" päivittää datan
   - [ ] PullDownMenu → "Näytä huominen": klo 14:15 jälkeen palkit
         näkyvät, ennen sitä tyhjä näkymä on OK
   - [ ] Kansi (cover) näyttää nykyhinnan sovelluksen ollessa
         taustalla; kansion klikkaus tuo sovelluksen eteen
   - [ ] Lentotila: "Päivitä" näyttää virheilmoituksen kaatumatta

## 4. Laitetestaus (Jolla Phone 2026)

```bash
sfdk device           # tai scp + pkcon install-local
```

Laitetasolla lisäksi:

- [ ] Launcher-ikoni näkyy oikein (86x86)
- [ ] Graafi on luettava ulko-aurinkoisessa valossa (Ambience-värit)
- [ ] Verkkoyhteys mobiilidata: haku ei kaadu hitaaseen verkkoon
- [ ] Muistikäyttö pysyy vakaana 30 min automaattipäivityssyklin
      kanssa (tarkista `systemctl` / valvonta-asetukset)
- [ ] Sailjail: sovellus pyytää vain `Internet`-luvan
- [ ] Ei jättänyt taustaprosessia, kun suljetaan Home-näppäimellä

## 5. Ennen Jolla Store -julkaisua

Storen tarkistuslista (harbour-säännöt):

- [ ] Nimi alkaa `harbour-` (kyllä)
- [ ] Ei openrepo- tai kolmannen osapuolen riippuvuuksia (kyllä)
- [ ] Kuvakaappaukset vähintään 2 kpl (piirrä emulaattorista)
- [ ] Kuvaus + versionumero synkronoitu `rpm/*.yaml` kanssa
- [ ] `sfdk check` / storen validointi menee läpi

## Testihistoria

- **2026-10-10** Ensimmäinen ajettu testi paljasti kaksi aitovaa:
  1. `setLoading`/`setErrorString` puuttuivat headerista
     (käännösvirhe)
  2. 60 min aggregointi kaatui `QList::replace`-assertioon
     (map-kopio ei ollut listassa). Korjattu indeksipohjaisella
     ryhmittelyllä.
  3. Palkit olivat käänteisessä aikajärjestyksessä (API palauttaa
     uusimmat ensin). Korjattu `std::sort`-lajittelulla.
  Kaikki korjattu ja testi ajettu onnistuneesti läpi.
