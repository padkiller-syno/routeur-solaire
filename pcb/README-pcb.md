# Carte mère du routeur solaire (PCB)

Carte 2 couches de **154 × 124 mm**, basse tension seulement (3,3 V / 5 V) : les modules (ESP32, 2 dimmers, JSY, 2 relais)
s'enfichent dessus ; le 230 V arrive directement sur leurs borniers et ne passe jamais par le PCB (zones sans cuivre sous
leurs parties secteur, encoche sous les broches L/N du JSY). **Montage mixte** : les 13 petits composants sont en CMS,
posés et soudés par JLCPCB ; les connecteurs (barrettes femelles, borniers) restent traversants et se soudent à la main.

Fichiers :
- `genere_pcb.py` : génère `routeur-solaire.kicad_pcb` (empreintes des modules d'après `mesures-modules.md`, placement,
  liaisons, zones 230 V). Relancer après toute correction de cote.
- `route_pcb.py` : plan de masse (dessous), routage automatique par Freerouting 2.5.0
  (`~/.local/share/freerouting/freerouting-2.5.0.jar`, Java 25), réimport. À lancer après `genere_pcb.py`.
- `placement-1-1.pdf` : placement à l'échelle 1:1 avec règles de contrôle de 100 mm (essai sur papier validé le 22/11).
- `rendu-3d.png` : rendu de la carte nue.
- **`routeur-solaire-jlcpcb.zip`** : Gerber (avec la couche de pâte) + perçages PTH et NPTH séparés.
- **`jlcpcb-bom.csv`** : liste des composants CMS à assembler, avec les références LCSC.
- **`jlcpcb-cpl.csv`** : positions et orientations des composants CMS.

État au 22/11/2026 : contrôle KiCad **0 erreur, 0 liaison manquante** (seules restent des remarques de sérigraphie).
Plans de masse sur les deux faces, broches raccordées en plein. **Commandée le 22/11** : 5 cartes vert HASL, assemblage
Economic face dessus.

## Commande JLCPCB (PCB + assemblage des CMS)

1. Sur jlcpcb.com, téléverser `routeur-solaire-jlcpcb.zip`. Réglages : **2 couches**, 1,6 mm, quantité 5.
2. Activer **PCB Assembly** : type **Economic**, côté **Top**, quantité assemblée 2 (minimum) ou 5.
3. Téléverser `jlcpcb-bom.csv` (BOM) puis `jlcpcb-cpl.csv` (CPL).
4. Vérifier que chaque ligne trouve sa pièce LCSC (C17513, C17604, C17673, C49678, C81598, C2480, C20917,
   C2846895, C2992615) et qu'elle est en stock ; C2846895 (fusible) et C2992615 (470 µF) sont des pièces
   « étendues » (petit supplément), les autres sont des pièces de base.
5. **Contrôler l'aperçu de placement** : JLCPCB affiche chaque composant sur la carte. Vérifier surtout l'orientation
   de **Q1** (SOT-23), **D1**, **D2** (repère de cathode du côté du +5 V) et de **C3** (+ vers le +5 V) ; corriger la
   rotation dans l'aperçu si l'un est tourné (décalages fréquents entre KiCad et JLCPCB).
6. Les connecteurs ne sont pas dans la BOM : JLCPCB ne les pose pas.

La carte dépasse 100 × 100 mm : le prix n'est plus celui des cartes à 2 $ ; l'assemblage Economic ajoute des frais
de mise en route, les pièces et un petit coût par pièce étendue. Le devis s'affiche avant paiement.

## Liste des composants

**Soudés par JLCPCB (CMS)**

| Réf. | Composant | LCSC | Rôle |
|---|---|---|---|
| Q1 | AO3400A (MOSFET N, SOT-23) | C20917 | commande du ventilateur (GPIO13) |
| R5 | 1 kΩ 0805 | C17513 | grille de Q1 |
| R6 | 4,7 kΩ 0805 | C17673 | grille de Q1 → masse (ventilateur arrêté au démarrage) |
| D1 | 1N4148W (SOD-123) | C81598 | roue libre du ventilateur |
| R1 | 1 kΩ 0805 | C17513 | pont diviseur TX du JSY (à remplacer par un pont de soudure si TX en 3,3 V) |
| R2 | 2 kΩ 0805 | C17604 | pont diviseur (à dessouder si TX en 3,3 V) |
| R3, R4 | 4,7 kΩ 0805 | C17673 | tirage des sondes ballon (GPIO4) et triacs (GPIO27) |
| C1, C2 | 100 nF 0805 | C49678 | près des borniers des sondes |
| C3 | 470 µF 16 V CMS 8 × 10,5 | C2992615 | réserve du 5 V (bobines de relais) |
| F1 | PTC 1,1 A 6 V (1206) | C2846895 | protection de J4 |
| D2 | SS14 (Schottky, SMA) | C2480 | en inverse sur le 5 V : avec F1, protège contre une inversion de J4 |

**À souder soi-même (traversants)**

| Réf. | Composant | Remarque |
|---|---|---|
| U1 | 2 barrettes femelles 1 × 15, pas 2,54 | ESP32 DevKit V1 (rangées à 25,4 mm) |
| M1, M2 | 2 barrettes femelles 1 × 4 + 4 entretoises M3 | dimmers, broches soudées vers le bas |
| M3 | 1 barrette femelle 1 × 5 | JSY (J3) ; L/N soudés en fils au-dessus de l'encoche ; colonnette du boîtier dans le trou Ø 5 |
| K1, K2 | 2 barrettes femelles 1 × 3 | modules relais 5 V 10 A (SRD-05VDC), broches droites vers le bas |
| J1 | barrette mâle 1 × 2 | ventilateur 40 mm 5 V (fils Dupont femelles) |
| J2, J3 | 2 borniers à vis 3 points, pas 3,5 mm | sondes : VCC 3,3 V, DAT, GND |
| J4 | bornier débrochable 2 points, pas 3,5 mm | alimentation 5 V (+ / GND) depuis l'IRM-05-5 du boîtier |
| H1–H4 | — | trous M3 de fixation dans le boîtier |

**Connecteurs achetés à part** (pour les 5 cartes) : kit de barrettes femelles 2,54 mm RUNCCI (1 × 4, 6, 8, 10, 12,
16, 20, 40), barrette mâle 2,54 mm, borniers à vis **pas de 3,5 mm** 3 points (ZB350 / KF350) et borniers débrochables
2 points au même pas pour J4, entretoises M3 ≈ 11 mm.

Coupe des barrettes femelles : une coupe sacrifie une position. 1 × 15 = une 1 × 16 ou une 1 × 20 coupée (la 1 × 20
laisse une 1 × 4) ; 1 × 4 telles quelles ; 1 × 5 et 1 × 3 dans les 1 × 6 (ou dans les restes de 1 × 4 pour les 1 × 3).
Poncer la coupe au papier de verre.
