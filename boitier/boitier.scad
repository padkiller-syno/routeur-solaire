// Boîtier imprimé 3D de la carte mère du routeur solaire (PCB 154 × 124 mm, modules enfichés).
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
trous_pcb = [[3.5, 3.5], [150.5, 3.5], [3.5, 120.5], [150.5, 120.5]];   // trous M3 de la carte

module plots() {
    for (t = trous_pcb) translate(concat(P(t[0], t[1]), [fond_e - 0.01]))
        difference() {
            cylinder(d = 7, h = plot_h + 0.01);
            cylinder(d = 2.6, h = plot_h + 1);    // vis M3 autotaraudeuse (ou insert : d = 4.0)
        }
}

// colonnette sous le JSY : traverse le trou Ø5 de la carte et soutient le module
module colonnette_jsy() {
    translate(concat(P(125, 58), [fond_e - 0.01])) {
        cylinder(d = 7, h = plot_h + 0.01);
        cylinder(d = 4.4, h = z_modules - fond_e - 0.4);
    }
}

// colonnes des vis du couvercle, accolées à l'extérieur des coins : l'intérieur reste libre pour la carte
coins = [[-1.5, -1.5], [ext_l + 1.5, -1.5], [-1.5, ext_p + 1.5], [ext_l + 1.5, ext_p + 1.5]];
colonne_d = 10;
module contour(h) {   // boîtier + colonnes d'angle accolées (union : les parois gardent leur épaisseur)
    boite_arrondie(ext_l, ext_p, h, rayon);
    for (c = coins) translate([c[0], c[1], 0]) cylinder(d = colonne_d, h = h);
}
module trous_vis_couvercle() {
    for (c = coins) translate([c[0], c[1], fond_e + int_h - 14]) cylinder(d = 2.6, h = 15);
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
    // arrière : 230 V des dimmers et du JSY
    for (bx = [28, 78]) translate([P(bx, 0)[0], ext_p - paroi / 2, z_modules + 22]) presse_etoupe(20.3);
    translate([P(128, 0)[0], ext_p - paroi / 2, z_modules + 22]) presse_etoupe(16.2);
    // droite : relais
    for (by = [83.5, 106.5]) translate([ext_l - paroi / 2, P(0, by)[1], z_dessus_pcb + 22])
        rotate([0, 0, 90]) presse_etoupe(16.2);
    // avant : basse tension (sondes, 5 V, pince du JSY)
    translate([P(80, 0)[0], paroi / 2, z_dessus_pcb + 20]) presse_etoupe(16.2);
    // gauche : micro-USB de l'ESP32 (prise au niveau du DevKit enfiché)
    translate([paroi / 2, P(0, 88.7)[1], z_dessus_pcb + 8.5 + pcb_e + 1.6])
        rotate([0, 90, 0]) hull() for (dy = [-4.5, 4.5]) translate([0, dy, 0]) cylinder(d = 8, h = paroi * 4, center = true);
    // ouïes d'évacuation hautes (fentes de 2 mm : pas de doigt possible)
    for (i = [0 : 10]) translate([paroi / 2, P(0, 12 + i * 5)[1], fond_e + int_h - 20])
        cube([paroi * 4, 2, 14], center = true);
    for (i = [0 : 16]) translate([P(8 + i * 5, 0)[0], ext_p - paroi / 2, fond_e + int_h - 9])
        cube([2, paroi * 4, 10], center = true);
}

module fond() {
    difference() {
        union() {
            difference() {
                contour(fond_e + int_h);
                translate([paroi, paroi, fond_e]) cube([int_l, int_p, int_h + 1]);
            }
            plots();
            colonnette_jsy();
            pattes();
        }
        ouvertures();
        trous_vis_couvercle();
        // repères gravés au fond
        translate([ext_l / 2, 12, fond_e - 0.6]) linear_extrude(1)
            text("230 V : ne pas ouvrir sous tension", size = 5, halign = "center");
    }
}

// ------------------------------------------------------------------ couvercle
ventilo_c = P(53, 30);   // au-dessus de l'espace entre les deux radiateurs

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
    color("darkgreen", 0.9) translate(concat(P(0, 124), [z_pcb])) cube([pcb_l, pcb_p, pcb_e]);
    color("dimgray", 0.6) for (x0 = [7, 57]) translate(concat(P(x0, 67), [z_modules])) cube([42, 60, dimmer_h]);
    color("teal", 0.6) translate(concat(P(110, 67.5), [z_modules])) cube([36.6, 60.5, 27]);
    color("navy", 0.6) for (y0 = [92, 115]) translate(concat(P(108, y0), [z_modules])) cube([43, 17, 19]);
    color("royalblue", 0.6) translate(concat(P(3, 102.8), [z_dessus_pcb + 8.5])) cube([51.8, 28.2, 6]);
    color("black", 0.8) translate(concat(ventilo_c, [fond_e + int_h - ventilo_e])) translate([-20, -20, 0]) cube([40, 40, 10]);
}

if (part == "fond") fond();
else if (part == "couvercle") couvercle();
else {
    fond();
    apercu_carte();
    translate([0, 0, fond_e + int_h + 25]) couvercle();
}
