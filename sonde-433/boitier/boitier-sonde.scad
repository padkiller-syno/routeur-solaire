// Boîtier imprimé 3D de la sonde déportée du ballon (433 MHz).
// Au fond : support 18650 (avant) et module TP4056 (arrière, USB-C dans la paroi gauche).
// Au-dessus : plaque à pastilles 60 × 40 (Pro Mini + STX882 + adaptateur DS18B20 couché) posée sur deux rebords,
// maintenue par 4 tétons du couvercle. Presse-étoupe PG7 de la sonde dans la paroi droite.
//   openscad -D 'part="fond"' -o fond.stl boitier-sonde.scad
//   openscad -D 'part="couvercle"' -o couvercle.stl boitier-sonde.scad
// Repère : x vers la droite, y vers l'arrière, z vers le haut. Cotes en mm.

part = "tout";   // "fond", "couvercle" ou "tout" (aperçu)

// ------------------------------------------------------------------ cotes du matériel (à vérifier à réception)
bat_l = 77;       // support 18650 simple (longueur)
bat_w = 21;       // largeur
bat_h = 21;       // hauteur, cellule en place
tp_l = 28;        // TP4056 USB-C protégé
tp_w = 17.5;
tp_e = 1.6;
tp_debord = 0.8;  // la prise USB-C dépasse du bord de la carte
usb_l = 9.4;      // prise USB-C (largeur × hauteur)
usb_h = 3.4;
perf_l = 60;      // plaque à pastilles 60 × 40
perf_w = 40;
perf_e = 1.6;
comp_h = 14;      // composants au-dessus de la plaque (adaptateur DS18B20 couché + bornier ≈ 12-13 mm)
adapt_debord = 14; // l'adaptateur couché dépasse de la plaque vers le presse-étoupe
pg_d = 12.5;      // presse-étoupe PG7 (câble 3-6,5 mm) ; 5 pour un simple trou + colle
insert_d = 3.7;   // inserts M3 à chaud (comme le boîtier du routeur)
insert_l = 5;
antenne = [4, 31];   // pastille ANT du STX882 (repère intérieur ≈ repère de la plaque) ; [] = pas de trou

// ------------------------------------------------------------------ boîtier
jeu = 0.3;
// Économie de matière : parois de 1,6 = 4 passes de buse 0,4 ; fond ajouré (côté mur) ; colonnes réduites à un bossage.
paroi = 1.6;
fond_e = 1.6;
couv_e = 1.6;
fond_ajoure = true;   // nid d'abeille dans le fond (caché contre le mur) ; false si le boîtier est posé autrement
alveole = 9;          // alvéoles hexagonales (diamètre sur les pointes)
nervure = 1.6;        // nervures entre alvéoles
bossage_h = 9;        // hauteur du bossage d'insert en tête de colonne
cale = 2;                         // rails sous le TP4056 (place des soudures)
int_l = max(perf_l + 2 * jeu + adapt_debord + 8, bat_l + 4);   // adaptateur qui dépasse + écrou du presse-étoupe
int_p = max(perf_w + 2 * jeu, bat_w + tp_w + 7);  // 18650 et TP4056 côte à côte
corbeau_av = 2.5;                                  // rebord avant sous la plaque
corbeau_ar = 2.5 + int_p - 2 * jeu - perf_w;      // rebord arrière, élargi si la boîte est plus profonde que la plaque
z_perf = bat_h + 3;               // dessous de la plaque (au-dessus du fond intérieur)
int_h = z_perf + perf_e + comp_h;
ext_l = int_l + 2 * paroi;
ext_p = int_p + 2 * paroi;
ext_h = fond_e + int_h;
y_tp = int_p - 1.5 - 2 * jeu - tp_w;    // TP4056 contre l'arrière
colonnes = [[-1, -1], [ext_l + 1, -1], [-1, ext_p + 1], [ext_l + 1, ext_p + 1]];


$fn = 40;

module I() { translate([paroi, paroi, fond_e]) children(); }   // repère intérieur

module contour(h) {
    cube([ext_l, ext_p, h]);
    for (c = colonnes) translate([c[0], c[1], 0]) cylinder(d = 8, h = h);
}

// ------------------------------------------------------------------ fond
// prolonge une pièce posée sur le fond de 0,3 mm vers le bas, pour qu'elle fasse corps avec lui
module ancre() {
    children();
    translate([0, 0, -0.3]) linear_extrude(0.31) projection(cut = true) translate([0, 0, -0.05]) children();
}

module berceau_18650() {
    x0 = 0.5; y0 = jeu;
    // rail arrière (l'avant est la paroi)
    translate([x0 + 8, y0 + bat_w + jeu, 0]) cube([bat_l - 16, 1.5, 7]);
    // butées d'extrémité, aux coins (les fils sortent au milieu des bouts)
    for (y = [y0, y0 + bat_w - 3]) translate([x0 + bat_l + jeu, y, 0]) cube([1.5, 3, 6]);
}

module logement_tp4056() {
    x0 = tp_debord; y0 = y_tp; l = tp_l + jeu; w = tp_w + 2 * jeu;
    h_mur = cale + tp_e + 0.8;
    for (y = [y0, y0 + w - 1.5]) translate([x0, y, 0]) cube([l, 1.5, cale]);   // rails
    for (y = [y0 - 1.2, y0 + w]) translate([x0, y, 0]) cube([l, 1.2, h_mur]);  // bords
    translate([x0 + l, y0 - 1.2, 0]) cube([1.2, w + 2.4, cale + 1]);           // butée arrière (pastilles B+/B-)
    // ergots d'encliquetage au milieu des grands côtés
    for (s = [[y0, 1], [y0 + w, -1]]) translate([x0 + l / 2 - 4, s[0], cale + tp_e + jeu])
        hull() {
            translate([0, s[1] > 0 ? -0.2 : 0, 0]) cube([8, 0.2, 0.8]);
            translate([0, s[1] > 0 ? 0 : -0.5, 0.4]) cube([8, 0.5, 0.4]);
        }
}

module rebords_plaque() {
    // corbeaux à 45° le long des parois avant et arrière, butée de fin de plaque
    for (m = [0, 1]) let(d = m ? corbeau_ar : corbeau_av) translate([0, m ? int_p : 0, 0]) mirror([0, m, 0]) {
        translate([-0.3, 0, z_perf]) rotate([0, 90, 0]) linear_extrude(perf_l + 2 * jeu + 0.3)
            polygon([[0, -0.3], [0, d], [d + 0.3, -0.3]]);   // ancré de 0,3 dans la paroi
        translate([perf_l + 2 * jeu, -0.3, z_perf - d]) cube([1.5, d + 1.8, d + perf_e]);   // à ras de la plaque (adaptateur couché au-dessus)
    }
}

module colonnes_vis() {
    // bossage en tête seulement, porté par un gousset à 45° qui descend dans l'angle des parois
    for (c = colonnes) {
        coin = [c[0] < 0 ? 0 : ext_l - paroi, c[1] < 0 ? 0 : ext_p - paroi];
        hull() {
            translate([c[0], c[1], ext_h - bossage_h]) cylinder(d = 8, h = bossage_h);
            translate([coin[0], coin[1], ext_h - bossage_h - 9]) cube([paroi, paroi, 0.01]);
        }
    }
}

// alvéoles du fond, hors des zones qui portent un rail, une butée ou le logement du TP4056
module nid_abeille() {
    pas = alveole * cos(30) + nervure;
    marge = 2.5;
    difference() {
        intersection() {
            translate([marge, marge]) square([int_l - 2 * marge, int_p - 2 * marge]);
            for (j = [0 : ceil(int_p / (pas * sin(60)))], i = [-1 : ceil(int_l / pas)])
                translate([i * pas + (j % 2) * pas / 2, j * pas * sin(60)]) rotate(30) circle(d = alveole, $fn = 6);
        }
        // logement du TP4056
        translate([tp_debord - 2.5, y_tp - 2.5]) square([tp_l + jeu + 5, tp_w + 2 * jeu + 5]);
        // rail arrière et butées du support 18650
        translate([0.5 + 8 - 1, jeu + bat_w + jeu - 1]) square([bat_l - 14, 3.5]);
        translate([0.5 + bat_l + jeu - 1, 0]) square([3.5, bat_w + 2]);
    }
}

module pattes() {
    for (p = [[-9, paroi + 4], [ext_l - 1, ext_p - paroi - 18]]) translate([p[0], p[1], 0]) difference() {
        cube([10, 14, 3]);
        translate([p[0] < 0 ? 4 : 6, 7, -1]) cylinder(d = 4.5, h = 5);
        translate([p[0] < 0 ? 4 : 6, 7, 1.5]) cylinder(d1 = 4.5, d2 = 8.5, h = 2.01);
    }
}

module ouvertures() {
    // USB-C du TP4056, paroi gauche, et dégagement extérieur pour la coque de la fiche
    yc = paroi + y_tp + jeu + tp_w / 2;
    zc = fond_e + cale + tp_e + usb_h / 2;
    translate([-1, yc, zc]) rotate([0, 90, 0]) linear_extrude(paroi + 2)
        offset(r = 1.2) square([usb_h + 0.6 - 2.4, usb_l + 0.6 - 2.4], center = true);
    translate([-1, yc, zc]) rotate([0, 90, 0]) linear_extrude(1 + paroi - 1)
        offset(r = 2) square([7.5 - 4, 12.5 - 4], center = true);
    // presse-étoupe de la sonde, paroi droite, au niveau de la plaque
    translate([ext_l - paroi - 1, ext_p / 2, fond_e + z_perf + perf_e + pg_d / 2 + 0.5])
        rotate([0, 90, 0]) cylinder(d = pg_d, h = paroi + 2);
}

module fond() {
    difference() {
        union() {
            cube([ext_l, ext_p, ext_h]);
            colonnes_vis();
            pattes();
        }
        translate([paroi, paroi, fond_e]) cube([int_l, int_p, int_h + 1]);
        for (c = colonnes) translate([c[0], c[1], ext_h - insert_l]) cylinder(d = insert_d, h = insert_l + 1);
        ouvertures();
        if (fond_ajoure) translate([paroi, paroi, -1]) linear_extrude(fond_e + 2) nid_abeille();
    }
    I() { ancre() berceau_18650(); ancre() logement_tp4056(); rebords_plaque(); }
}

// ------------------------------------------------------------------ couvercle (imprimé face extérieure sur le plateau)
module couvercle() {
    difference() {
        union() {
            contour(couv_e);
            // lèvre de centrage sur 3 côtés (pas à droite : écrou du presse-étoupe)
            translate([paroi + jeu, paroi + jeu, couv_e]) difference() {
                cube([int_l - 2 * jeu, int_p - 2 * jeu, 3]);
                translate([1.2, 1.2, -1]) cube([int_l, int_p - 2 * jeu - 2.4, 5]);
            }
            // tétons qui plaquent la plaque à pastilles sur ses rebords
            for (x = [3, perf_l - 3], y = [3, perf_w - 3])
                translate([paroi + jeu + x, paroi + jeu + y, couv_e]) cylinder(d = 4, h = comp_h - 0.3);
        }
        for (c = colonnes) translate([c[0], c[1], -1]) {
            cylinder(d = 3.4, h = couv_e + 2);
            cylinder(d1 = 6.8, d2 = 3.4, h = 1 + 1.7);   // tête fraisée M3
        }
        if (len(antenne) == 2) translate([paroi + jeu + antenne[0], paroi + jeu + antenne[1], -1]) cylinder(d = 2.5, h = 10);
    }
}

// ------------------------------------------------------------------ aperçu
if (part == "fond") fond();
else if (part == "couvercle") couvercle();
else { fond(); I() {
        color("steelblue", 0.6) translate([0.5, jeu, 0]) cube([bat_l, bat_w, bat_h]);
        color("dimgray") translate([tp_debord, y_tp + jeu, cale]) cube([tp_l, tp_w, tp_e]);
        color("green", 0.7) translate([jeu, jeu, z_perf]) cube([perf_l, perf_w, perf_e]);
    }
    translate([0, 0, ext_h + 25]) translate([0, 0, couv_e]) mirror([0, 0, 1]) couvercle(); }
