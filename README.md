# Sähkönseuranta

Sähkön pörssihinnan seuranta SailfishOS:lle. Sovellus näyttää Suomen
sähkön spot-hinnat **palkkigraafina** 15 minuutin tai tunnin
tarkkuudella. Kohde: Jolla Phone (2026), julkaisu Jolla Storeen.

## Ominaisuudet (v0.1)

- Pörssisähkön hinta nyt isolla (snt/kWh, sis. ALV), HattiWatti-tyylinen
  liikennevalo: vihreä = halvaalla (≤ keskihinta tai negatiivinen),
  keltainen = normaali (≤ 2 × keskihinta), punainen = kallis
- 15 min tai 1 h tarkkuuden vaihto
- Päivän hintojen palkkigraafi liikennevaloväreillä (vihreä/keltainen/
  punainen), nykyhetken palkki korostettuna, negatiiviset hinnat
  nollaviivan alapuolella
- Tänään / huomenna -näkymä
- Tilastorivi HattiWatin tyyliin: Keskiarvo / Alin / Ylin
- Kansinäyttö nykyisellä hinnalla
- Automaattinen päivitys 30 min välein; hinnat haetaan
  [porssisahko.net](https://porssisahko.net/api) v2-rajapinnasta
  (avoin, ei vaadi avainta, 192 varttihintaa per haku)

## Rakenne

```
qml/harbour-sahkonseuranta.qml — sovellusikkuna
qml/pages/MainPage.qml         — pääsivu (graafi, hintatiedot)
qml/components/PriceGraph.qml — palkkigraafikomponentti (liikennevalovärit)
qml/components/TrafficLight.qml — liikennevalo (halpa/normaali/kallis)
qml/cover/CoverPage.qml        — kansinäyttö
src/main.cpp                   — käynnistys, priceFetcher context-propertynä
src/pricefetcher.{h,cpp}       — API-haku, JSON-jäsennys, aggregointi
icons/                         — launcher-ikonit (86, 108, 128, 256)
rpm/harbour-sahkonseuranta.yaml — RPM-paketointi
```

## Kääntäminen (SailfishOS SDK)

```
sfdk build -d SailfishOS-4.6.0.15-armv7hl   # Jolla Phone (2026)
```

Sovellus käyttää vain Sailfish App / Silica / Qt5-perusmoduuleja —
ei openrepo-riippuvuuksia, joten se täyttää Jolla Storen
harbour-vaatimukset.

## Lisensointi

BSD-3-Clause — ks. [LICENSE](LICENSE).
