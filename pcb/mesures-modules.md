# Relevés des modules pour le PCB support (photos au pied à coulisse du 21-22/11/2026)

Précision estimée ±0,5 mm (photos) ; placement validé par une impression 1:1 le 22/11 avant la commande JLCPCB.
Repère de chaque module : à plat, composants dessus.

## ESP32 DevKit V1 (clone 30 broches, sérigraphie « NodeMCU-ESP32 / ESP32 DEVKITV1 »)

- Circuit 51,8 × 28,2 mm (photos : 51,8 et 52,1 ; 28,2).
- 2 × 15 broches au pas de 2,54 ; **écart entre rangées 25,4 mm** (variante large).
- 4 trous dans les coins (non utilisés : tenu par barrettes femelles).
- **Ordre des broches confirmé** (photo du dessus, 22/11), antenne en haut :
  gauche EN VP VN D34 D35 D32 D33 D25 D26 D27 D14 D12 D13 GND VIN ; droite D23 D22 TX0 RX0 D21 D19 D18 D5 TX2 RX2 D4 D2 D15 GND 3V3.
  Boutons EN et BOOT et micro-USB en bas (bord à dégager dans le boîtier).

## Dimmer RobotDyn « AC Dimmer Module HL » 16/24 A

- Circuit 60 × 42 mm (largeur mesurée 42-42,5 ; longueur avec bornier ≈ 60).
- Connecteur de commande : 4 broches pas 2,54, ordre **VCC, GND, Z-C, PSM** (PSM = commande du triac),
  rangée parallèle au bord « commande », **centrée sur la largeur 42 mm** (broches à 17,2 / 19,7 / 22,3 / 24,8 mm
  d'un côté), à **4,0 mm du bord commande** (mesuré au pied à coulisse le 22/11).
- 2 trous de fixation sur le bord commande : ≈ 3,2 mm des côtés, ≈ 4,3 mm du bord, Ø ≈ 3,2 (M3).
- Partie 230 V (MOC3021, triac, bornier L / N / LOAD) à partir de ≈ 14-15 mm du bord commande → zone sans cuivre
  dès 12 mm.
- **Hauteur totale avec radiateur : 42 mm** (mesuré 22/11). Radiateur **dans l'emprise du circuit** : son bord est à
  3,5 mm du bord du PCB, ses pattes soudées à 5 mm (mesuré 22/11) ; pas de débord (les photos coupaient le module).
- Broches de commande à souder vers le bas (décision user) pour se piquer dans une barrette femelle.

## JSY-MK-194T (V1.0, 2021.09.01)

- Circuit 60,5 × 36,6 mm (manuel : 60,48 × 36,81). **Hauteur avec le tore : 27 mm** (mesuré 22/11).
- Vue de dessus, origine coin bas-gauche (bord bas = côté connecteur J2, bord haut = côté tore) :
  - **J3** (broches mâles soudées) : centre des broches à **3,0 mm du bord** (mesuré 22/11 ; le plastique de la
    barrette commence à 1,5 mm du bord, soit un centre à ≈ 2,8 mm : retenu 2,9 ± 0,2, à valider à l'impression 1:1) ;
    y : GND 23,8 / PF 26,3 / TX 28,9 / RX 31,4 / **VCC 34,0** (VCC ≈ 26,5 mm du bord tore, mesuré photo 16).
  - **J1 (230 V)** : L et N, x ≈ 2,0 ; L à ≈ 2 mm du bord haut, N ≈ 7,6 mm plus bas.
  - J4 (5 pastilles, non équipé) et J2 (4 pastilles en bas, non équipé) : non utilisés.
- Pas de trou de fixation (module prévu pour être soudé). Tore couché : le fil du ballon le traverse
  parallèlement au circuit.
- Retenu : pas de cuivre sous J1 (encoche dans le PCB), fils secteur soudés sur J1 par-dessus ; le bord opposé à J3
  repose sur la colonnette du boîtier, qui traverse le trou Ø 5 de la carte.
- Le JSY rafraîchit ses mesures toutes les 330 ms (manuel).

## Modules relais 10 A

- Modules 5 V 1 canal à **déclenchement bas**, relais **Songle SRD-05VDC-SL-C** (achetés le 22/11), ≈ 43 × 17 mm.
- Connecteur IN / GND / VCC côté LED, broches à ≈ 4 mm du bord ; bornier NO / COM / NC à l'autre bout ; pas de trou
  de fixation. Enfichés dans K1 / K2 (barrettes femelles 1 × 3), bornier vers l'extérieur de la carte.
- Commande par transistor (pas d'optocoupleur visible malgré l'annonce) : voir le piège du 3,3 V dans le README.

## Sondes DS18B20

- Sans adaptateur : résistance de tirage 4,7 kΩ (DAT → 3,3 V) sur le PCB, une par bus (ballon GPIO4 → R3, triacs
  GPIO27 → R4), un **bornier à vis 3 points** par sonde (J2, J3 : VCC 3,3 V, DAT, GND).
- Condensateur 100 nF entre VCC et GND près de chaque bornier (C1, C2) pour les câbles de sonde longs.

## Ventilateur 5 V des dimmers

- 40 × 40 mm, 2 fils (rouge / noir) terminés en Dupont femelles → J1, 2 broches mâles au pas de 2,54 (5 V, GND),
  piloté par le MOSFET Q1 sur GPIO13 (tout ou rien).
