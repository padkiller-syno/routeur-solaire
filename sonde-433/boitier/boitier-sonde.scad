// Boîtier imprimé 3D de la sonde déportée du ballon (433 MHz).
// Au fond : support 18650 (avant) et module TP4056 (arrière, USB-C dans la paroi gauche).
// Au-dessus : plaque à pastilles 60 × 40 (Pro Mini + STX882 + adaptateur DS18B20) posée sur deux rebords,
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
comp_h = 15;      // composants au-dessus de la plaque (bornier de l'adaptateur, ressort d'antenne couché)
pg_d = 12.5;      // presse-étoupe PG7 (câble 3-6,5 mm) ; 5 pour un simple trou + colle
insert_d = 3.7;   // inserts M3 à chaud (comme le boîtier du routeur)
insert_l = 5;
antenne = [perf_l - 12, perf_w - 4];   // trou du fil d'antenne de 17,3 cm (repère intérieur), [] = pas de trou

// ------------------------------------------------------------------ boîtier
jeu = 0.3;
paroi = 2;
fond_e = 2;
couv_e = 2;
cale = 2;                         // rails sous le TP4056 (place des soudures)
int_l = max(perf_l + 2 * jeu + 12, bat_l + 4);   // ≥ 12 mm à droite de la plaque pour l'écrou du presse-étoupe
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
        translate([0, 0, z_perf]) rotate([0, 90, 0]) linear_extrude(perf_l + 2 * jeu)
            polygon([[0, 0], [0, d], [d, 0]]);
        translate([perf_l + 2 * jeu, 0, z_perf - d]) cube([1.5, d + 1.5, d + perf_e + 1]);
    }
}

module colonnes_vis() {
    for (c = colonnes) translate([c[0], c[1], 0]) difference() {
        cylinder(d = 8, h = ext_h);
        translate([0, 0, ext_h - insert_l]) cylinder(d = insert_d, h = insert_l + 1);
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
            contour(ext_h);
            colonnes_vis();
            pattes();
        }
        translate([paroi, paroi, fond_e]) cube([int_l, int_p, int_h + 1]);
        for (c = colonnes) translate([c[0], c[1], ext_h - insert_l]) cylinder(d = insert_d, h = insert_l + 1);
        ouvertures();
    }
    I() { berceau_18650(); logement_tp4056(); rebords_plaque(); }
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
