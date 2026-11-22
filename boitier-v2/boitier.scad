// Boîtier imprimé 3D du routeur solaire, carte v2 (99 × 92 mm) : les modules sont enfichés dans la carte par leur
// barrette et portés par des supports imprimés (plots, appuis, crochets) là où ils débordent de la carte.
// Mêmes dimensions extérieures que le boîtier v1.
// Deux pièces : part = "fond" ou "couvercle" (ou "tout" pour l'aperçu).
//   openscad -D 'part="fond"' -o fond.stl boitier.scad
//   openscad -D 'part="couvercle"' -o couvercle.stl boitier.scad
// Matière : PETG ou ASA (230 V et triacs à l'intérieur : pas de PLA). Remplissage ≥ 25 %, 3 périmètres.
// Repère : x vers la droite, y vers l'arrière, z vers le haut. Carte vue de dessus comme dans KiCad
// (bord des dimmers/JSY = arrière, bord des sondes = avant, micro-USB = gauche, relais = droite).

part = "tout";

// ------------------------------------------------------------------ cotes de la carte et des modules
pcb_l = 154;          // largeur carte (x)
pcb_p = 124;          // profondeur carte (y)
pcb_e = 1.6;          // épaisseur carte
jeu = 2;              // jeu autour de la carte
plot_h = 5;           // hauteur des plots sous la carte
insert_d = 3.7;       // trou des inserts filetés M3 posés à chaud (inserts M3 × 3 mm, Ø ext. 4,0 / 3,7 mm)
insert_l = 4;         // profondeur du trou d'insert (insert + 1 mm pour le plastique refoulé)
module_h = 11;        // dessous des modules au-dessus de la carte (barrette femelle 8,5 + entretoise des broches)
dimmer_h = 42;        // hauteur du dimmer avec radiateur
ventilo = 40;         // ventilateur 40 × 40 × 10
ventilo_e = 10;
ventilo_entraxe = 32;

// ------------------------------------------------------------------ boîtier
paroi = 2.5;
fond_e = 2.5;
couv_e = 2.5;
int_l = pcb_l + 2 * jeu;
int_p = pcb_p + 2 * jeu;
int_h = plot_h + pcb_e + module_h + dimmer_h + ventilo_e + 4;   // ≈ 75 mm
ext_l = int_l + 2 * paroi;
ext_p = int_p + 2 * paroi;
rayon = 4;

z_pcb = fond_e + plot_h;              // dessous de la carte
z_dessus_pcb = z_pcb + pcb_e;         // dessus de la carte
z_modules = z_dessus_pcb + module_h;  // dessous des modules

// Position d'un point de la carte (repère KiCad : origine en haut à gauche, y vers le bas) dans le boîtier.
function P(bx, by) = [paroi + jeu + bx, paroi + jeu + (pcb_p - by)];

$fn = 48;

module boite_arrondie(l, p, h, r) {
    hull() for (x = [r, l - r], y = [r, p - r]) translate([x, y, 0]) cylinder(r = r, h = h);
}

// ------------------------------------------------------------------ éléments du fond
trous_pcb = [[20.5, 66.0], [21.5, 110.5], [104.0, 110.5], [113.5, 66.0]];   // trous M3 de la carte v2

module plots() {
    for (t = trous_pcb) translate(concat(P(t[0], t[1]), [fond_e - 0.01]))
        difference() {
            cylinder(d = 8, h = plot_h + 0.01);
            translate([0, 0, plot_h - insert_l]) cylinder(d = insert_d, h = insert_l + 1);   // insert M3
            cylinder(d = 3.2, h = plot_h + 1);    // dégagement de la vis M3 × 6 à travers la carte
        }
}

// ------------------------------------------------------------------ supports des modules (hors carte)
h_appui = z_modules - fond_e;          // dessus d'un appui = dessous des modules
module appui(bx, by, d = 8) {          // appui plat
    translate(concat(P(bx, by), [fond_e - 0.01])) cylinder(d = d, h = h_appui + 0.01);
}
module plot_vis(bx, by) {              // appui avec insert M3 en tête (trou de fixation du module)
    translate(concat(P(bx, by), [fond_e - 0.01])) difference() {
        cylinder(d = 8, h = h_appui + 0.01);
        translate([0, 0, h_appui - insert_l]) cylinder(d = insert_d, h = insert_l + 1);   // insert M3
        cylinder(d = 3.2, h = h_appui + 1);
    }
}
// crochet souple : lame verticale contre le bord du module, bec de 1,2 mm au-dessus du circuit (1,6 mm)
// sens = direction vers l'extérieur du module (vecteur unité dans le plan, repère boîtier)
module crochet(bx, by, angle) {
    translate(concat(P(bx, by), [fond_e - 0.01])) rotate([0, 0, angle]) {
        translate([0, -4, 0]) cube([1.8, 8, h_appui + 1.6 + 0.3 + 1.5]);
        translate([-1.2, -4, h_appui + 1.6 + 0.3]) hull() {
            cube([3.0, 8, 0.01]);
            translate([1.2, 0, 1.5]) cube([1.8, 8, 0.01]);
        }
        translate([0, -4, 0]) cube([4, 8, h_appui]);   // pied
    }
}
module supports_modules() {
    // dimmer 1 (x 3,5..45,5, y 2..62) : vis dans son trou gauche (hors carte), appuis sous le bord bornier
    plot_vis(6.7, 57.7);
    appui(8, 6); appui(41, 6);
    // dimmer 2 (x 48..90) : ses deux trous sont sur la carte (entretoises) ; appuis sous le bord bornier
    appui(52.5, 6); appui(85.5, 6);
    // JSY (x 96..132,6, y 2..62,5) : appuis aux coins hors carte + crochets sur les bords haut et droit
    appui(100, 6, 7); appui(128.6, 6, 7); appui(128.6, 40, 7);
    crochet(115, 2, 90);          // bord haut (vers le fond du boîtier)
    crochet(132.6, 25, 0);        // bord droit
    // relais (x 108..151) : appui sous l'extrémité bornier + crochet sur le bout
    for (y0 = [70, 91]) { appui(146, y0 + 8.5, 7); crochet(151, y0 + 8.5, 0); }
}

// colonnes des vis du couvercle, accolées à l'extérieur des coins : l'intérieur reste libre pour la carte
coins = [[-1.5, -1.5], [ext_l + 1.5, -1.5], [-1.5, ext_p + 1.5], [ext_l + 1.5, ext_p + 1.5]];
colonne_d = 10;
module contour(h) {   // boîtier + colonnes d'angle accolées (union : les parois gardent leur épaisseur)
    boite_arrondie(ext_l, ext_p, h, rayon);
    for (c = coins) translate([c[0], c[1], 0]) cylinder(d = colonne_d, h = h);
}
module trous_vis_couvercle() {
    for (c = coins) translate([c[0], c[1], fond_e + int_h]) {
        translate([0, 0, -insert_l]) cylinder(d = insert_d, h = insert_l + 1);   // insert M3 en tête de colonne
        translate([0, 0, -12]) cylinder(d = 3.2, h = 12);                       // dégagement de la vis M3 × 10
    }
}

// pattes de fixation murale (vis Ø 4-5 mm)
module pattes() {
    for (x = [-9, ext_l + 9], y = [18, ext_p - 18]) translate([x, y, 0]) difference() {
        hull() {
            translate([x < 0 ? 10 : -10, -8, 0]) cube([0.1, 16, fond_e + 1]);   // pénètre de 1 mm dans la paroi
            cylinder(d = 16, h = fond_e + 1);
        }
        translate([0, 0, -1]) cylinder(d = 5, h = 10);
        translate([0, 0, fond_e + 1 - 2.2]) cylinder(d1 = 5, d2 = 9.5, h = 2.3);   // fraisure
    }
}

// passe-câbles (presse-étoupes) : M20 → Ø 20,3 ; M16 → Ø 16,2
module presse_etoupe(d) { rotate([90, 0, 0]) cylinder(d = d, h = paroi * 4, center = true); }

module ouvertures() {
    // arrière : 230 V des dimmers et du JSY (borniers vers le fond)
    for (bx = [24.5, 69]) translate([P(bx, 0)[0], ext_p - paroi / 2, z_modules + 22]) presse_etoupe(20.3);
    translate([P(118, 0)[0], ext_p - paroi / 2, z_modules + 22]) presse_etoupe(16.2);
    // droite : relais
    for (by = [78.5, 99.5]) translate([ext_l - paroi / 2, P(0, by)[1], z_dessus_pcb + 22])
        rotate([0, 0, 90]) presse_etoupe(16.2);
    // avant : basse tension (sondes, 5 V, pince du JSY) face aux borniers
    translate([P(56, 0)[0], paroi / 2, z_dessus_pcb + 20]) presse_etoupe(16.2);
    // gauche : micro-USB de l'ESP32 (centre y 80,1 ; prise au niveau du DevKit enfiché)
    translate([paroi / 2, P(0, 80.1)[1], z_dessus_pcb + 8.5 + pcb_e + 1.6])
        rotate([0, 90, 0]) hull() for (dy = [-4.5, 4.5]) translate([0, dy, 0]) cylinder(d = 8, h = paroi * 4, center = true);
    // ouïes d'évacuation hautes (fentes de 2 mm : pas de doigt possible)
    for (i = [0 : 10]) translate([paroi / 2, P(0, 12 + i * 5)[1], fond_e + int_h - 20])
        cube([paroi * 4, 2, 14], center = true);
    for (i = [0 : 16]) translate([P(8 + i * 5, 0)[0], ext_p - paroi / 2, fond_e + int_h - 9])
        cube([2, paroi * 4, 10], center = true);
}

// ------------------------------------------------------------------ alimentation 230 V → 5 V interne
// Mean Well IRM-05-5 (33,7 × 22,2 × 15) posé sur une console accrochée à la paroi avant, au-dessus du relais avant.
// Pattes vers le bas dans deux fentes : fils soudés et gainés sous la console, sortie 5 V soudée dans J4.
// Porte-fusible de façade 5 × 20 (trou Ø 12,3) dans la paroi avant, à droite de la console (fusible T1A sur L).
// Coordonnées en repère boîtier (communes aux boîtiers v1 et v2, mêmes dimensions intérieures).
alim = [33.7, 22.2, 15];
alim_jeu = 0.2;          // serré : une goutte de silicone neutre suffit à le bloquer
alim_x0 = 98;            // bord gauche du logement (presse-étoupe avant v1 jusqu'à x 92,6)
alim_z = 55;             // dessus de la console (dessous des goussets > haut des relais, z ≈ 39)
console_e = 2.5;
logement_h = 8;          // hauteur des rebords du logement
fusible_x = 145;         // axe du porte-fusible
fusible_z = 60;
fusible_d = 12.3;

module console_alim() {
    lx = alim[0] + 2 * alim_jeu;
    ly = alim[1] + 2 * alim_jeu;
    r = 1.6;             // épaisseur des rebords
    p = ly + r;          // profondeur de la console depuis la paroi avant
    difference() {
        union() {
            translate([alim_x0 - r, paroi - 0.01, alim_z - console_e]) cube([lx + 2 * r, p, console_e + logement_h]);
            // goussets à 45° (imprimables sans support), un de chaque côté
            for (x = [alim_x0 - r - 2.9, alim_x0 + lx + r - 0.1]) translate([x, paroi - 0.01, alim_z - console_e + 0.01])
                rotate([90, 0, 90]) linear_extrude(3) polygon([[0, 0], [p, 0], [0, -p]]);
        }
        translate([alim_x0, paroi - 0.02, alim_z]) cube([lx, ly + 0.02, logement_h + 1]);          // logement
        for (x = [alim_x0 + 0.6, alim_x0 + lx - 0.6 - 6])                                         // fentes des pattes
            translate([x, paroi + 1.5, alim_z - console_e - 1]) cube([6, ly - 3, console_e + 2]);
    }
}
module trou_fusible() {
    translate([fusible_x, paroi / 2, fusible_z]) rotate([90, 0, 0]) cylinder(d = fusible_d, h = paroi * 4, center = true);
}

module fond() {
    difference() {
        union() {
            difference() {
                contour(fond_e + int_h);
                translate([paroi, paroi, fond_e]) cube([int_l, int_p, int_h + 1]);
            }
            plots();
            supports_modules();
            pattes();
            console_alim();
        }
        ouvertures();
        trou_fusible();
        trous_vis_couvercle();
        // repères gravés au fond
        translate([ext_l / 2, 12, fond_e - 0.6]) linear_extrude(1)
            text("230 V : ne pas ouvrir sous tension", size = 5, halign = "center");
    }
}

// ------------------------------------------------------------------ couvercle
ventilo_c = P(46.75, 30);   // au-dessus de l'espace entre les deux radiateurs

module couvercle() {
    difference() {
        union() {
            contour(couv_e);
            // lèvre de centrage qui entre dans le fond
            translate([paroi + 0.4, paroi + 0.4, -3]) difference() {
                cube([int_l - 0.8, int_p - 0.8, 3]);
                translate([2, 2, -1]) cube([int_l - 4.8, int_p - 4.8, 5]);
            }
        }
        // vis du couvercle
        for (c = coins) translate([c[0], c[1], -1]) {
            cylinder(d = 3.4, h = couv_e + 2);
            translate([0, 0, couv_e + 1 - 1.9]) cylinder(d1 = 3.4, d2 = 6.6, h = 1.95);
        }
        // grille du ventilateur (anneaux) et ses 4 vis
        translate(concat(ventilo_c, [-1])) {
            difference() {
                cylinder(d = ventilo - 2, h = couv_e + 2);
                for (r = [8, 15]) difference() { cylinder(d = 2 * r + 2.4, h = 10); cylinder(d = 2 * r, h = 10); }
                for (a = [0, 60, 120]) rotate([0, 0, a]) translate([-1.2, -ventilo / 2, 0]) cube([2.4, ventilo, 10]);
                cylinder(d = 10, h = 10);
            }
            for (x = [-1, 1], y = [-1, 1]) translate([x * ventilo_entraxe / 2, y * ventilo_entraxe / 2, 0])
                cylinder(d = 3.4, h = couv_e + 2);
        }
        translate([ext_l / 2 + 30, ext_p / 2, couv_e - 0.6]) linear_extrude(1)
            text("Routeur solaire", size = 7, halign = "center");
    }
}

// ------------------------------------------------------------------ aperçu de la carte et des modules
module apercu_carte() {
    contour_v2 = [[18, 50], [92.5, 50], [92.5, 22], [105.5, 22], [105.5, 50], [117, 50], [117, 114], [18, 114]];
    color("darkgreen", 0.9) translate([0, 0, z_pcb]) linear_extrude(pcb_e) polygon([for (q = contour_v2) P(q[0], q[1])]);
    color("dimgray", 0.6) for (x0 = [3.5, 48]) translate(concat(P(x0, 62), [z_modules])) cube([42, 60, dimmer_h]);
    color("teal", 0.6) translate(concat(P(96, 62.5), [z_modules])) cube([36.6, 60.5, 27]);
    color("navy", 0.6) for (y0 = [87, 108]) translate(concat(P(108, y0), [z_modules])) cube([43, 17, 19]);
    color("royalblue", 0.6) translate(concat(P(40, 94.2), [z_dessus_pcb + 8.5])) cube([51.8, 28.2, 6]);
    color("white", 0.9) translate([alim_x0 + alim_jeu, paroi + alim_jeu, alim_z]) cube(alim);
    color("black", 0.8) translate(concat(ventilo_c, [fond_e + int_h - ventilo_e])) translate([-20, -20, 0]) cube([40, 40, 10]);
}

if (part == "fond") fond();
else if (part == "couvercle") couvercle();
else if (part == "apercu") { fond(); apercu_carte(); }   // sans couvercle
else {
    fond();
    apercu_carte();
    translate([0, 0, fond_e + int_h + 25]) couvercle();
}
