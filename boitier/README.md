# Boîtier imprimé 3D du routeur solaire

Source paramétrique : `boitier.scad` (OpenSCAD). Pièces à imprimer : **`fond.stl`** et **`couvercle.stl`**.
Aperçus : `vue-montage.png`, `vue-fond.png`, `vue-dessus.png`.

Régénérer après une modification :
```bash
openscad -D 'part="fond"' -o fond.stl boitier.scad
openscad -D 'part="couvercle"' -o couvercle.stl boitier.scad
```

## Dimensions

- Intérieur ≈ 158 × 128 × 75 mm (carte 154 × 124 + 2 mm de jeu ; hauteur : plots 5 + carte 1,6 + modules 11 +
  dimmer 42 + ventilateur 10 + marge).
- Extérieur ≈ 163 × 133 × 78 mm, plus les colonnes d'angle et les pattes murales.
- Tient sur un plateau de 220 × 220 mm.

## Impression

- **PETG ou ASA** (230 V et triacs à 60-75 °C à l'intérieur) : **pas de PLA**, qui se ramollit vers 55 °C.
- Couche 0,2 mm, 3 périmètres, remplissage 25 % ou plus.
- Fond : posé à plat sur le fond, sans support (les trous des parois sont ronds et petits : ils passent en pont).
- Couvercle : posé face extérieure sur le plateau, lèvre de centrage vers le haut.

## Ce qui est prévu

- **4 plots** sous les trous M3 de la carte (Ø 2,6 → vis M3 autotaraudeuses ; pour des inserts filetés M3 à chaud,
  passer le trou à 4,0 mm dans `plots()`).
- **Colonnette du JSY** : traverse le trou Ø 5 de la carte et soutient le JSY par-dessous (hauteur réglable
  via `module_h`).
- **Passe-câbles** (presse-étoupes) : arrière 2 × M20 (dimmers) + 1 × M16 (JSY), droite 2 × M16 (relais),
  avant 1 × M16 (sondes, 5 V, pince du JSY) ; ou passe-fils caoutchouc de même diamètre.
- **Accès micro-USB** de l'ESP32 sur la gauche, à la hauteur du DevKit enfiché.
- **Ventilateur 40 mm** vissé sous le couvercle (entraxe 32 mm), soufflant vers le bas entre les deux radiateurs ;
  grille d'aspiration dans le couvercle, **ouïes d'évacuation** de 2 mm (pas de doigt possible) en haut des parois
  arrière et gauche.
- **Couvercle** vissé dans 4 colonnes d'angle (vis M3 × 16 à tête fraisée, autotaraudeuses dans Ø 2,6).
- **4 pattes de fixation murale** (vis Ø 4-5 mm, tête fraisée).
- Mention gravée au fond : « 230 V : ne pas ouvrir sous tension ».

## Visserie

| Usage | Quantité |
|---|---|
| Carte → plots : vis M3 × 8 autotaraudeuses (ou inserts M3 + vis M3 × 6) | 4 |
| Dimmers → carte : entretoises M3 (≈ 11 mm, à ajuster à la hauteur des barrettes) + vis M3 | 4 + 8 |
| Couvercle : vis M3 × 16 tête fraisée | 4 |
| Ventilateur → couvercle : vis M3 × 14 + écrous (ou vis de ventilateur) | 4 |
| Presse-étoupes M20 / M16 | 2 / 4 |
| Fixation murale : vis Ø 4-5 + chevilles | 4 |

## À vérifier au premier montage

- La hauteur réelle des modules au-dessus de la carte (`module_h` = 11 mm) : barrette femelle + entretoise des broches.
  Si la colonnette du JSY est trop haute ou trop basse, ajuster `module_h` et réimprimer le fond.
- La position de la prise micro-USB face à son ouverture.
