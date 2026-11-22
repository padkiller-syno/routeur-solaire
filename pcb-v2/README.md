# Carte v2 du routeur solaire (compacte, < 100 × 100 mm)

Variante de la carte v1 (`../pcb/`) pour réduire le prix chez JLCPCB : la carte ne passe que sous **l'ESP32 et les
barrettes des modules**. Chaque module reste enfiché directement (aucun câble basse tension) ; la partie qui déborde
de la carte repose sur des **supports imprimés** du boîtier (`../boitier-v2/` : appuis, plot à vis, crochets souples).

- Carte **99,1 × 92,1 mm**, 2 couches, mêmes 13 composants CMS que la v1 (assemblage JLCPCB Economic, mêmes
  références LCSC) et mêmes connecteurs à souder (barrettes femelles, borniers au pas de 3,5 mm, barrette ventilateur).
- Contrôle KiCad : **0 erreur, 0 liaison manquante** (remarques de sérigraphie seulement).
- Plus aucun 230 V au-dessus de la carte, sauf la bande basse tension des modules : seul le bord « commande » des
  dimmers (12 mm), la bande de J3 du JSY et l'extrémité VCC/GND/IN des relais surplombent la carte.

Disposition (repère de l'intérieur du boîtier, comme la v1) :
- dimmers côte à côte au fond (borniers vers la paroi arrière), barrettes sur le bord haut de la carte ;
- JSY debout à droite des dimmers, **tourné de 180° par rapport à la v1** (J3 à gauche sur la languette de la carte,
  tore en bas, L/N dans le coin bas-droit) ;
- relais couchés à droite, borniers NO/COM/NC vers la paroi droite ;
- ESP32 au centre, micro-USB vers la paroi gauche ; borniers des sondes et du 5 V sur le bord avant.

Fichiers : `genere_pcb.py` (placement), `route_pcb.py` (Freerouting + plans de masse), `exporte.sh` (Gerber, CPL,
rendu, PDF 1:1), `routeur-solaire-v2-jlcpcb.zip`, `jlcpcb-bom.csv`, `jlcpcb-cpl.csv`, `rendu-3d.png`,
`placement-1-1.pdf`.

**Non testée** : à valider par une impression 1:1 avec les modules posés dessus avant commande, comme la v1.
Commande : même procédure que `../pcb/README-pcb.md` (finition HASL, Economic, C3 = C2992615).
