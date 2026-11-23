# Boîtier imprimé de la sonde du ballon

Source paramétrique : `boitier-sonde.scad` (OpenSCAD). Pièces : **`fond.stl`** et **`couvercle.stl`**.
Aperçus : `vue-montage.png`, `vue-fond.png`, `vue-dessous.png`, `vue-usb.png`, `vue-couvercle.png`.

```bash
openscad -D 'part="fond"' -o fond.stl boitier-sonde.scad
openscad -D 'part="couvercle"' -o couvercle.stl boitier-sonde.scad
```

## Principe

Deux étages, sans aucune vis pour les cartes :

- **au fond** : le support 18650 contre la paroi avant (rail arrière + butées) et le **TP4056** dans un logement
  contre l'arrière, encliqueté par deux petits ergots, sa prise **USB-C dans la paroi gauche** (dégagement
  extérieur pour la coque de la fiche) ;
- **au-dessus** : une **plaque à pastilles 60 × 40 mm** portant le Pro Mini, le STX882 et l'adaptateur DS18B20 **couché**
  (broches pliées vers le presse-étoupe, Kapton dessous, il dépasse de ~12 mm de la plaque : `adapt_debord`).
  Elle repose sur deux rebords à 45° (avant, et arrière élargi : la boîte est plus profonde que la plaque, à cause de la
  18650 et du TP4056 côte à côte ; la longueur est fixée par le support 18650), bute contre la paroi gauche et deux taquets à droite,
  et les **4 tétons du couvercle** la plaquent sur ses rebords.

Paroi droite : trou Ø 12,5 pour un **presse-étoupe PG7** (câble de sonde 3-6,5 mm), juste au-dessus de la plaque, à la
hauteur des entrées du bornier, avec 8 mm libres pour l'écrou. Couvercle : trou Ø 2,5 pour sortir le **fil d'antenne de 17,3 cm** à la verticale
(position `antenne` = pastille ANT du STX882, estimée d'après la photo à [4, 31] : à confirmer ; `antenne = []` si le ressort fourni reste dedans, le
plastique laisse passer le 433 MHz).

Dimensions extérieures ≈ **86 × 49 × 43 mm** (couvercle compris), plus les colonnes d'angle et deux pattes murales.

## Avant d'imprimer : mesurer le matériel reçu

Les cotes en tête du fichier sont des valeurs typiques : **`bat_l/bat_w/bat_h`** (support 18650 avec la cellule),
**`tp_l/tp_w`** et `tp_debord` (TP4056), **`perf_l/perf_w`** (plaque à pastilles ; une autre taille marche, le
boîtier suit) et **`comp_h`** (le plus haut au-dessus de la plaque : 14 mm pour l'adaptateur couché ; debout il fait 24 mm).

## Câblage sur la plaque

- Placement et fils : [../placement-plaque.svg](../placement-plaque.svg). Adaptateur côté presse-étoupe (droite), Pro Mini
  au milieu, STX882 à gauche, pastille ANT sous le trou du couvercle ; coins de la plaque libres (tétons).
- Plaque reliée au TP4056 par deux fils souples (OUT+ → VCC, OUT− → GND), assez longs pour sortir la plaque
  et recharger/déboguer couvercle ouvert.
- Schéma : [../cablage-sonde.svg](../cablage-sonde.svg).

## Économie de matière

Environ **35 cm³** en tout (fond 26,4 + couvercle 8,3), au lieu de 50,6 cm³ pour la première version pleine : **−31 %**.

- Parois, fond et couvercle de **1,6 mm** = exactement 4 passes d'une buse de 0,4 : pas de remplissage à l'intérieur des parois.
- **Fond en nid d'abeille** (`fond_ajoure`), plein seulement sous le logement du TP4056 et sous les rails du support 18650.
  Le fond est **contre le mur** (pattes au ras du fond) : les alvéoles ne se voient pas et laissent sortir la condensation.
  Mettre `fond_ajoure = false` si le boîtier est posé sur une étagère.
- **Colonnes de vis réduites à un bossage** de 9 mm en tête, porté par un gousset à 45° qui descend dans l'angle des parois.

Dans le trancheur : 4 périmètres (les parois sortent pleines), remplissage gyroïde 10-15 % (ne concerne plus que
les bossages et les pattes), 4 couches dessus et dessous.

## Impression

- **PETG** de préférence (buanderie humide, à côté du ballon) ; PLA possible, rien ne chauffe à l'intérieur.
- Couche 0,2 mm, 4 périmètres, **sans support** : fond posé sur le fond, couvercle face extérieure
  sur le plateau (les tétons et la lèvre vers le haut).

## Visserie

| Usage | Quantité |
|---|---|
| Inserts M3 à chaud (M3 × 3, Ø ext. 4,0 ; trou `insert_d` = 3,7 comme le boîtier du routeur) | 4 |
| Couvercle : vis M3 × 8 tête fraisée | 4 |
| Presse-étoupe PG7 (ou simple passe-fil + colle) | 1 |
| Fixation murale : vis Ø 4 tête fraisée + chevilles | 2 |
