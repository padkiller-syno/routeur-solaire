# Boîtier imprimé de la sonde du ballon

Source paramétrique : `boitier-sonde.scad` (OpenSCAD). Pièces : **`fond.stl`** et **`couvercle.stl`**.
Aperçus : `vue-montage.png`, `vue-fond.png`, `vue-usb.png`, `vue-couvercle.png`.

```bash
openscad -D 'part="fond"' -o fond.stl boitier-sonde.scad
openscad -D 'part="couvercle"' -o couvercle.stl boitier-sonde.scad
```

## Principe

Deux étages, sans aucune vis pour les cartes :

- **au fond** : le support 18650 contre la paroi avant (rail arrière + butées) et le **TP4056** dans un logement
  contre l'arrière, encliqueté par deux petits ergots, sa prise **USB-C dans la paroi gauche** (dégagement
  extérieur pour la coque de la fiche) ;
- **au-dessus** : une **plaque à pastilles 60 × 40 mm** portant le Pro Mini, le STX882 et l'adaptateur DS18B20.
  Elle repose sur deux rebords à 45° (avant, et arrière élargi : la boîte est plus profonde que la plaque, à cause de la
  18650 et du TP4056 côte à côte ; la longueur est fixée par le support 18650), bute contre la paroi gauche et deux taquets à droite,
  et les **4 tétons du couvercle** la plaquent sur ses rebords.

Paroi droite : trou Ø 12,5 pour un **presse-étoupe PG7** (câble de sonde 3-6,5 mm), au-dessus de la plaque, avec
12 mm libres pour l'écrou. Couvercle : trou Ø 2,5 pour sortir le **fil d'antenne de 17,3 cm** à la verticale
(position `antenne`, à mettre au-dessus du STX882 ; `antenne = []` si le ressort fourni reste dedans, le
plastique laisse passer le 433 MHz).

Dimensions extérieures ≈ **85 × 50 × 45 mm** (couvercle compris), plus les colonnes d'angle et deux pattes murales.

## Avant d'imprimer : mesurer le matériel reçu

Les cotes en tête du fichier sont des valeurs typiques : **`bat_l/bat_w/bat_h`** (support 18650 avec la cellule),
**`tp_l/tp_w`** et `tp_debord` (TP4056), **`perf_l/perf_w`** (plaque à pastilles ; une autre taille marche, le
boîtier suit) et **`comp_h`** (le composant le plus haut sur la plaque, souvent le bornier de l'adaptateur).

## Câblage sur la plaque

- Pro Mini posé à plat sur des **broches courtes** (ou fils soudés directement) ; STX882 et adaptateur DS18B20 à côté,
  le bornier de l'adaptateur côté presse-étoupe (droite), le STX882 sous le trou d'antenne.
- Plaque reliée au TP4056 par deux fils souples (OUT+ → VCC, OUT− → GND), assez longs pour sortir la plaque
  et recharger/déboguer couvercle ouvert.
- Schéma : [../cablage-sonde.svg](../cablage-sonde.svg).

## Impression

- **PETG** de préférence (buanderie humide, à côté du ballon) ; PLA possible, rien ne chauffe à l'intérieur.
- Couche 0,2 mm, 3 périmètres, 20 % de remplissage, **sans support** : fond posé sur le fond, couvercle face extérieure
  sur le plateau (les tétons et la lèvre vers le haut).

## Visserie

| Usage | Quantité |
|---|---|
| Inserts M3 à chaud (M3 × 3, Ø ext. 4,0 ; trou `insert_d` = 3,7 comme le boîtier du routeur) | 4 |
| Couvercle : vis M3 × 8 tête fraisée | 4 |
| Presse-étoupe PG7 (ou simple passe-fil + colle) | 1 |
| Fixation murale : vis Ø 4 tête fraisée + chevilles | 2 |
