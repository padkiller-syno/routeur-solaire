# Sonde déportée du ballon (433 MHz, sur batterie)

Le routeur est près du tableau, à ~10 m du ballon. Une DS18B20 au bout d'un câble de 10 m qui longe l'alimentation
du ballon (découpée par le triac) et traverse les autres circuits donne des lectures fausses. La sonde est donc lue
**sur place** par un Arduino Pro Mini, qui envoie la température en 433 MHz. Le routeur la reçoit directement (récepteur
SRX882 sur le bornier J2), **sans passer par Home Assistant ni le wifi**.

## Matériel

| Côté ballon | Côté routeur |
|---|---|
| Arduino Pro Mini (ATmega328P) | récepteur **SRX882** sur J2 : VCC → 3,3 V, DATA → DAT (GPIO4), GND → GND, **CS → 3,3 V** |
| DS18B20 étanche + son adaptateur (4,7 kΩ intégrée) | antenne : ressort fourni ou fil rigide de **17,3 cm** sur ANT, à sortir du tableau s'il est métallique |
| émetteur **STX882** + antenne (ressort ou fil de 17,3 cm) | |
| module 18650 (charge micro-USB) | |

## Câblage du Pro Mini

Schéma complet (sonde, routeur, antennes) : [cablage-sonde.svg](cablage-sonde.svg).
Boîtier imprimé : [boitier/](boitier/README.md) (18650 et TP4056 au fond, plaque à pastilles au-dessus).
Placement sur la plaque 60 × 40 et fils : [placement-plaque.svg](placement-plaque.svg).

| Pro Mini | Vers |
|---|---|
| VCC | **+ de la cellule 18650** (borne B+ du module), pas les broches 3,3 V du module |
| GND | − de la cellule, GND du STX882, GND de la sonde |
| D2 | DATA du STX882 (VCC du STX882 → + de la cellule) |
| D3 | DAT de la sonde |
| D4 | VCC de la sonde (alimentée seulement pendant la mesure, ~0,4 s par minute) |

**À faire sur le Pro Mini** : retirer la LED d'alimentation (ou sa résistance), sinon elle consomme à elle seule
2 à 3 mA en permanence, soit plus que tout le reste. Le régulateur de la carte n'est pas utilisé (on entre sur VCC, pas
sur RAW) ; le retirer est facultatif.

**Le module 18650** : ses broches 3,3 V viennent en général d'un convertisseur 5 V suivi d'un régulateur, toujours
actifs (plusieurs mA à vide) : avec eux, la batterie tiendrait quelques semaines. On garde le module pour le support de
la cellule, la charge par micro-USB et la protection contre la décharge profonde, mais on prend la tension **directement
sur la cellule** (3,0 à 4,2 V, que le Pro Mini, la DS18B20 et le STX882 acceptent).

## Firmware

`platformio.ini` + `src/main.cpp`. Deux versions selon le quartz du Pro Mini (lire le boîtier argenté ou la référence
du régulateur : 8 MHz = version 3,3 V, 16 MHz = version 5 V) :

Le Pro Mini de la sonde est un **8 MHz** (vérifié le 23/11 par un test de clignotement : le fusible bas `0xFF` est le même
sur les deux versions). Il est programmé en **ISP par un USBasp**, cellule débranchée :

| USBasp (10 broches) | Pro Mini |
|---|---|
| 1 MOSI | D11 |
| 9 MISO | D12 |
| 7 SCK | D13 |
| 5 RESET | RST |
| 2 VCC | VCC |
| 4 GND | GND |

Cavalier du USBasp sur **5 V** (rangée 5V/3.3V), **JP2 retiré** (JP2 = auto-programmation du USBasp lui-même). Puis :

```
pio run -t upload
```

Accès au USBasp sans root : règle udev `/etc/udev/rules.d/99-usbasp.rules` (16c0:05dc, groupe `dialout`, `uaccess`).
Le flash ISP a effacé le bootloader d'origine (ATmegaBOOT 57 600 bauds) : ça ne gêne pas, la carte démarre directement
sur le firmware.

**Par le bootloader** (Pro Mini qui l'a encore, 2e carte flashée ainsi le 26/11) : adaptateur série PL2303 (TX → RXI,
RX → TXO, VCC, GND), 57 600 bauds pour un 8 MHz. Le PL2303 n'a **pas de DTR** : appuyer sur **reset** du Pro Mini dès que
la commande démarre (le bootloader n'écoute qu'environ 1 s ; une carte vierge, elle, y reste en permanence) :

```bash
pio run -e pro_mini_8mhz
~/.platformio/packages/tool-avrdude/avrdude -C ~/.platformio/packages/tool-avrdude/avrdude.conf \
  -p m328p -c arduino -P /dev/ttyUSB0 -b 57600 -D -U flash:w:.pio/build/pro_mini_8mhz/firmware.hex:i
```

Le PL2303 (copie, 067b:2303) a renvoyé des erreurs `-32` le 23/11 mais a fonctionné le 26/11 : s'il échoue, débrancher et
rebrancher, sinon passer par le USBasp.
Les versions `*_debug` écrivent sur le port série (57 600 bauds) : il faut alors un adaptateur USB-série qui marche (CH340,
CP2102) relié à TXO/GND.

Fonctionnement : mesure (résolution 11 bits), tension de la batterie (référence interne), émission de la trame 5 fois
(~0,3 s), puis veille profonde 7 × 8 s. Sous 3,1 V : un envoi toutes les ~10 min seulement.

Trame de 32 bits (protocole 1 de rc-switch, impulsion 350 µs) : identifiant `0xA` sur 4 bits, température
((°C + 20) × 10) sur 11 bits (2047 = sonde en défaut), batterie ((mV − 2000) / 20) sur 7 bits, compteur sur 2 bits,
CRC-8 (polynôme 0x07) sur 8 bits. Décodée dans `../esphome/routeur-solaire.yaml` (`remote_receiver`).

## Consommation estimée

Veille ~5 µA (sans la LED) ; par minute : ~0,5 s éveillé à 8 MHz, conversion de la sonde, ~0,3 s d'émission
(~20 mA). En moyenne ≈ 0,15 mA : **plus d'un an** avec une 18650 de 2 500 mAh. À vérifier au multimètre en série sur
le + de la cellule : en veille, quelques µA ; sinon chercher la LED, le régulateur ou le module 18650.

## Côté routeur et Home Assistant

- `Température ballon` garde le même nom, donc la même entité HA (`sensor.sdb_routeur_solaire_temperature_ballon`) :
  automatisations et carte inchangées.
- Nouvelles entités : `Batterie sonde ballon` (V, diagnostic) et `Sonde ballon` (connectivité : trame reçue depuis
  moins de 5 min).
- Sans trame pendant 5 min, la température passe à « inconnue ». Le routage continue (le thermostat du ballon reste la
  limite) ; la marche forcée de secours sur température ne peut plus se déclencher.
- Recharge : quand `Batterie sonde ballon` passe sous ~3,3 V (prévoir une notification HA).

Réglage de la mesure de batterie : comparer la tension affichée avec celle du multimètre et corriger `VREF_CAL` dans
`src/main.cpp` (`1125300 × tension mesurée / tension affichée`).
