# Sähkönseuranta

Suomen sähkön pörssihinnat yhdellä silmäyksellä — suomeksi.

Sähkönseuranta näyttää sähkön spot-hinnan nyt ja tulevaisuudessa.
Nykyinen hinta ja taso näkyvät värikoodattuna pallona: vihreä on
halpa, keltainen keskitaso ja punainen kallis. Hintaennuste kertoo,
milloin taso vaihtuu ja mihin.

## Ominaisuudet

- Nykyinen pörssihinta ja taso väripallona (halpa / keskitaso / kallis)
- Ennuste: milloin hintataso vaihtuu ja mihin hintaan
- Vieritettävä hintakuvaaja nyt-hetkestä eteenpäin, myös huomisen
  hinnat; palkit värjäytyvät hintatason mukaan
- Keskiarvo, alin ja ylin hinta — sekä ajankohta, jolloin ne
  toteutuvat
- Asetuksista säädettävät hintarajat (oletuksena 5 ja 10 snt/kWh) ja
  hinnoittelutarkkuus (15 min tai 1 h)
- Kansi näyttää nykyisen hinnan ilman sovelluksen avaamista
- Automaattinen päivitys hintojen vaihtuessa; hakuväli pysähtyy
  taustalla

Hinnat haetaan porssisahko.net:n avoimesta rajapinnasta. Sovellus ei
vaadi kirjautumista eikä avaimia. Käyttöliittymä on suomeksi.

Lisenssi AGPL-3.0-or-later. Lähdekoodi:
https://github.com/Zesseth/Sahkonseuranta
