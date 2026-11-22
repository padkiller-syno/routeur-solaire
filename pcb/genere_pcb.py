#!/usr/bin/env python3
"""Génère la carte mère du routeur solaire (KiCad 9) : placement, empreintes des modules, liaisons, zones 230 V.

Cotes des modules : mesures-modules.md (relevés au pied à coulisse du 21-22/11/2026).
Repère : millimètres, origine en haut à gauche de la carte, y vers le bas (convention KiCad).
Lancer : python3 genere_pcb.py  → routeur-solaire.kicad_pcb (le routage des pistes est fait à part).
"""
import os
import pcbnew

ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(ICI, "routeur-solaire.kicad_pcb")
LIBS = "/usr/share/kicad/footprints"

mm = pcbnew.FromMM


# Décalage de la carte dans la feuille A4 (297 × 210) : carte centrée, pour l'impression 1:1 sans marges coupées.
OX, OY = 71.0, 43.0


def V(x, y):
    """Position sur la carte (décalée dans la feuille)."""
    return pcbnew.VECTOR2I(mm(x + OX), mm(y + OY))


def S(w, h):
    """Taille (non décalée)."""
    return pcbnew.VECTOR2I(mm(w), mm(h))


board = pcbnew.BOARD()
board.SetCopperLayerCount(2)
ds = board.GetDesignSettings()
ds.m_TrackMinWidth = mm(0.25)
ds.m_CopperEdgeClearance = mm(0.5)

# ----------------------------------------------------------------------------------------------- liaisons
NETS = {}


def net(nom):
    if nom not in NETS:
        n = pcbnew.NETINFO_ITEM(board, nom)
        board.Add(n)
        NETS[nom] = n
    return NETS[nom]


# ----------------------------------------------------------------------------------------------- outils
def trait(parent, couche, x0, y0, x1, y1, largeur=0.12):
    s = pcbnew.PCB_SHAPE(parent, pcbnew.SHAPE_T_SEGMENT)
    s.SetLayer(couche)
    s.SetStart(V(x0, y0))
    s.SetEnd(V(x1, y1))
    s.SetWidth(mm(largeur))
    parent.Add(s)


def rect(parent, couche, x0, y0, x1, y1, largeur=0.12):
    for a, b, c, d in ((x0, y0, x1, y0), (x1, y0, x1, y1), (x1, y1, x0, y1), (x0, y1, x0, y0)):
        trait(parent, couche, a, b, c, d, largeur)


def texte(parent, couche, x, y, txt, taille=1.0, epaisseur=0.15):
    t = pcbnew.PCB_TEXT(parent)
    t.SetLayer(couche)
    t.SetText(txt)
    t.SetPosition(V(x, y))
    t.SetTextSize(S(taille, taille))
    t.SetTextThickness(mm(epaisseur))
    parent.Add(t)


def module(ref, valeur, x0, y0, x1, y1, broches, trous=(), notes=()):
    """Empreinte d'un module enfichable : contour (Fab, sérigraphie, courtyard), pastilles de la barrette
    femelle, trous de fixation non métallisés. Coordonnées en repère carte."""
    fp = pcbnew.FOOTPRINT(board)
    fp.SetReference(ref)
    fp.SetValue(valeur)
    # nom de bibliothèque obligatoire pour l'aller-retour Specctra (Freerouting)
    fp.SetFPID(pcbnew.LIB_ID("routeur_solaire", f"Module_{ref}"))
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    fp.SetPosition(V(cx, cy))
    fp.Reference().SetPosition(V(x0 + 2, y0 + 2.5))
    fp.Reference().SetTextSize(S(1.2, 1.2))
    fp.Value().SetPosition(V(cx, cy))
    fp.Value().SetLayer(pcbnew.F_Fab)
    rect(fp, pcbnew.F_Fab, x0, y0, x1, y1, 0.1)
    rect(fp, pcbnew.F_SilkS, x0, y0, x1, y1, 0.15)
    rect(fp, pcbnew.F_CrtYd, x0 - 0.25, y0 - 0.25, x1 + 0.25, y1 + 0.25, 0.05)
    for i, (num, nom, x, y, nom_net) in enumerate(broches):
        p = pcbnew.PAD(fp)
        p.SetNumber(str(num))
        p.SetAttribute(pcbnew.PAD_ATTRIB_PTH)
        p.SetLayerSet(pcbnew.PAD.PTHMask())
        p.SetShape(pcbnew.PAD_SHAPE_RECTANGLE if i == 0 else pcbnew.PAD_SHAPE_CIRCLE)
        p.SetSize(S(1.7, 1.7))
        p.SetDrillSize(S(1.0, 1.0))
        p.SetPosition(V(x, y))
        if nom_net:
            p.SetNet(net(nom_net))
        fp.Add(p)
        if nom:
            vertical = len({round(b[2], 2) for b in broches}) == 1   # rangée verticale : libellé à gauche
            if vertical:
                texte(fp, pcbnew.F_SilkS, x - 3.0, y, nom, 0.8, 0.12)
            else:
                texte(fp, pcbnew.F_SilkS, x, y - 1.9, nom, 0.8, 0.12)
    for x, y, d in trous:
        p = pcbnew.PAD(fp)
        p.SetAttribute(pcbnew.PAD_ATTRIB_NPTH)
        p.SetLayerSet(pcbnew.PAD.UnplatedHoleMask())
        p.SetShape(pcbnew.PAD_SHAPE_CIRCLE)
        p.SetSize(S(d, d))
        p.SetDrillSize(S(d, d))
        p.SetPosition(V(x, y))
        fp.Add(p)
    for x, y, txt in notes:
        texte(fp, pcbnew.F_Fab, x, y, txt, 1.0, 0.12)
    board.Add(fp)
    return fp


def lib(biblio, nom, ref, valeur, x, y, rot=0, nets=None):
    fp = pcbnew.FootprintLoad(os.path.join(LIBS, biblio + ".pretty"), nom)
    if fp is None:
        raise SystemExit(f"empreinte introuvable : {biblio}:{nom}")
    fp.SetParent(board)
    fp.SetReference(ref)
    fp.SetValue(valeur)
    fp.SetPosition(V(x, y))
    fp.SetOrientationDegrees(rot)
    for pad in fp.Pads():
        if nets and pad.GetNumber() in nets and nets[pad.GetNumber()]:
            pad.SetNet(net(nets[pad.GetNumber()]))
    board.Add(fp)
    return fp


def zone_interdite(x0, y0, x1, y1, nom):
    """Zone sans cuivre (pistes, vias, plans) sous les parties 230 V des modules, sur les deux faces."""
    z = pcbnew.ZONE(board)
    z.SetIsRuleArea(True)
    z.SetDoNotAllowTracks(True)
    z.SetDoNotAllowVias(True)
    z.SetDoNotAllowCopperPour(True)
    z.SetDoNotAllowPads(False)
    z.SetDoNotAllowFootprints(False)
    ls = pcbnew.LSET()
    ls.AddLayer(pcbnew.F_Cu)
    ls.AddLayer(pcbnew.B_Cu)
    z.SetLayerSet(ls)
    z.SetZoneName(nom)
    o = z.Outline()
    o.NewOutline()
    for x, y in ((x0, y0), (x1, y0), (x1, y1), (x0, y1)):
        o.Append(mm(x + OX), mm(y + OY))
    board.Add(z)


# ----------------------------------------------------------------------------------------------- contour
L, H = 154.0, 124.0
ENCOCHE = (108.0, 117.0, 20.0)  # encoche pour les broches L/N (230 V) du JSY : x0, x1, profondeur
pts = [(0, 0), (ENCOCHE[0], 0), (ENCOCHE[0], ENCOCHE[2]), (ENCOCHE[1], ENCOCHE[2]), (ENCOCHE[1], 0),
       (L, 0), (L, H), (0, H)]
for (a, b), (c, d) in zip(pts, pts[1:] + pts[:1]):
    trait(board, pcbnew.Edge_Cuts, a, b, c, d, 0.1)

for i, (x, y) in enumerate(((3.5, 3.5), (L - 3.5, 3.5), (3.5, H - 3.5), (L - 3.5, H - 3.5)), 1):
    lib("MountingHole", "MountingHole_3.2mm_M3", f"H{i}", "M3", x, y)

# ----------------------------------------------------------------------------------------------- ESP32 DevKit V1
# Couché, micro-USB contre le bord gauche, antenne à droite. Rangées à 25,4 mm. Broche i : x = 48,36 - 2,54 i.
HAUT = ["EN", "VP", "VN", "D34", "D35", "D32", "D33", "D25", "D26", "D27", "D14", "D12", "D13", "GND", "VIN"]
BAS = ["D23", "D22", "TX0", "RX0", "D21", "D19", "D18", "D5", "TX2", "RX2", "D4", "D2", "D15", "GND", "3V3"]
NET_ESP = {"D35": "ZC", "D32": "PWM1", "D33": "PWM2", "D25": "REL_MF", "D26": "REL_SURPLUS", "D27": "DS_TRIACS",
           "D13": "VENTILO_CMD", "GND": "GND", "VIN": "+5V", "TX2": "TX2", "RX2": "RX2", "D4": "DS_BALLON",
           "3V3": "+3V3"}
Y_HAUT, Y_BAS = 76.0, 101.4
broches = []
for i, nom in enumerate(HAUT):
    broches.append((i + 1, nom, 48.36 - 2.54 * i, Y_HAUT, NET_ESP.get(nom)))
for i, nom in enumerate(BAS):
    broches.append((i + 16, nom, 48.36 - 2.54 * i, Y_BAS, NET_ESP.get(nom)))
module("U1", "ESP32 DevKit V1 (30 broches)", 3.0, 74.6, 54.8, 102.8, broches,
       notes=[(28, 88.7, "micro-USB ← | ESP32 DevKit V1 | antenne →")])

# ----------------------------------------------------------------------------------------------- dimmers
# Bornier 230 V vers le haut de la carte, bord « commande » en bas. Broches à 4,0 mm du bord commande,
# centrées sur la largeur 42 mm, dans l'ordre VCC GND Z-C PSM (gauche → droite vue de dessus).
def dimmer(ref, x0, nom, zc_net, pwm_net):
    y0, y1 = 7.0, 67.0
    cx = x0 + 21.0
    yb = y1 - 4.0
    br = [(1, "VCC", cx - 3.81, yb, "+3V3"), (2, "GND", cx - 1.27, yb, "GND"),
          (3, "ZC", cx + 1.27, yb, zc_net), (4, "PSM", cx + 3.81, yb, pwm_net)]
    module(ref, nom, x0, y0, x0 + 42.0, y1, br,
           trous=[(x0 + 3.2, y1 - 4.3, 3.2), (x0 + 42.0 - 3.2, y1 - 4.3, 3.2)],
           notes=[(cx, y0 + 4, "L / N / LOAD 230 V"), (cx, y0 + 26, "radiateur (h 42 mm)")])
    zone_interdite(x0, y0, x0 + 42.0, y1 - 12.0, f"230V {ref}")


dimmer("M1", 7.0, "Dimmer 1 (ballon) RobotDyn HL", "ZC", "PWM1")
dimmer("M2", 57.0, "Dimmer 2 (option) RobotDyn HL", None, "PWM2")

# ----------------------------------------------------------------------------------------------- JSY-MK-194T
# Tore vers le haut (L/N dans l'encoche), J3 le long du bord droit à 2,9 mm, VCC à 26,5 mm du bord tore.
JX0, JY0, JX1, JY1 = 110.0, 7.0, 146.6, 67.5
jx = JX1 - 2.9
module("M3", "JSY-MK-194T", JX0, JY0, JX1, JY1,
       [(1, "VCC", jx, JY0 + 26.5, "+5V"), (2, "RX", jx, JY0 + 29.04, "TX2"), (3, "TX", jx, JY0 + 31.58, "JSY_TX"),
        (4, "PF", jx, JY0 + 34.12, None), (5, "GND", jx, JY0 + 36.66, "GND")],
       trous=[(125.0, 58.0, 5.0)],
       notes=[(121, 12, "L/N 230 V : fils soudés au-dessus"), (125, 30, "tore (h 27 mm)"),
              (125, 62.5, "colonnette de soutien")])
zone_interdite(JX0, JY0, jx - 3.2, JY1, "230V JSY")
zone_interdite(jx - 3.2, JY0, JX1, JY0 + 24.0, "230V JSY tore")

# ----------------------------------------------------------------------------------------------- relais 10 A
# Bornier NO/COM/NC contre le bord droit, connecteur VCC GND IN à 4 mm du bord gauche du module.
def relais(ref, y0, nom, in_net):
    x0, x1 = 108.0, 151.0
    cy = y0 + 8.5
    module(ref, nom, x0, y0, x1, y0 + 17.0,
           [(1, "VCC", x0 + 4.0, cy - 2.54, "+5V"), (2, "GND", x0 + 4.0, cy, "GND"),
            (3, "IN", x0 + 4.0, cy + 2.54, in_net)],
           notes=[(x0 + 27, cy + 5, "NO / COM / NC 230 V →")])
    zone_interdite(x0 + 10.0, y0, x1, y0 + 17.0, f"230V {ref}")


relais("K1", 75.0, "Relais MF (NC → contacteur)", "REL_MF")
relais("K2", 98.0, "Relais surplus", "REL_SURPLUS")

# ----------------------------------------------------------------------------------------------- ventilateur
lib("Connector_PinHeader_2.54mm", "PinHeader_1x02_P2.54mm_Vertical", "J1", "Ventilateur 5 V", 53.0, 60.0,
    nets={"1": "+5V", "2": "VENTILO_NEG"})
# Petits composants en CMS, assemblés par JLCPCB (option « Economic ») ; références LCSC dans LCSC ci-dessous.
# Les connecteurs (barrettes, borniers) restent traversants et sont soudés à la main.
LCSC = {}


def cms(biblio, nom, ref, valeur, x, y, rot, nets, lcsc):
    lib(biblio, nom, ref, valeur, x, y, rot, nets)
    LCSC[ref] = (valeur, nom, lcsc)


R0805 = ("Resistor_SMD", "R_0805_2012Metric")
C0805 = ("Capacitor_SMD", "C_0805_2012Metric")
# MOSFET AO3400A (SOT-23 : 1 = G, 2 = S, 3 = D), commande du ventilateur, composant de base JLCPCB.
cms("Package_TO_SOT_SMD", "SOT-23", "Q1", "AO3400A", 64.0, 76.5, 0,
    {"1": "VENTILO_G", "2": "GND", "3": "VENTILO_NEG"}, "C20917")
cms("Diode_SMD", "D_SOD-123", "D1", "1N4148W", 62.0, 72.0, 0, {"1": "+5V", "2": "VENTILO_NEG"}, "C81598")
cms(*R0805, "R5", "1k", 77.0, 80.0, 0, {"1": "VENTILO_CMD", "2": "VENTILO_G"}, "C17513")
cms(*R0805, "R6", "4k7", 77.0, 84.0, 0, {"1": "VENTILO_G", "2": "GND"}, "C17673")

# ----------------------------------------------------------------------------------------------- JSY : pont diviseur
cms(*R0805, "R1", "1k", 77.0, 88.0, 0, {"1": "JSY_TX", "2": "RX2"}, "C17513")
cms(*R0805, "R2", "2k", 77.0, 92.0, 0, {"1": "RX2", "2": "GND"}, "C17604")

# ----------------------------------------------------------------------------------------------- sondes DS18B20
cms(*R0805, "R3", "4k7", 77.0, 96.0, 0, {"1": "DS_BALLON", "2": "+3V3"}, "C17673")
cms(*R0805, "R4", "4k7", 77.0, 100.0, 0, {"1": "DS_TRIACS", "2": "+3V3"}, "C17673")
TB3 = ("TerminalBlock_Phoenix", "TerminalBlock_Phoenix_PT-1,5-3-3.5-H_1x03_P3.50mm_Horizontal")
TB2 = ("TerminalBlock_Phoenix", "TerminalBlock_Phoenix_PT-1,5-2-3.5-H_1x02_P3.50mm_Horizontal")
lib(*TB3, "J2", "Sonde ballon (VCC DAT GND)", 62.0, 116.0, 0, nets={"1": "+3V3", "2": "DS_BALLON", "3": "GND"})
lib(*TB3, "J3", "Sonde triacs (VCC DAT GND)", 78.0, 116.0, 0, nets={"1": "+3V3", "2": "DS_TRIACS", "3": "GND"})
cms(*C0805, "C1", "100n", 64.5, 108.0, 0, {"1": "+3V3", "2": "GND"}, "C49678")
cms(*C0805, "C2", "100n", 80.5, 108.0, 0, {"1": "+3V3", "2": "GND"}, "C49678")

# ----------------------------------------------------------------------------------------------- alimentation
cms("Capacitor_SMD", "CP_Elec_8x10.5", "C3", "470uF 16V", 95.0, 88.0, 0, {"1": "+5V", "2": "GND"}, "C2992615")
lib(*TB2, "J4", "Alim 5 V (+ / GND)", 94.0, 116.0, 0, nets={"1": "+5V_EXT", "2": "GND"})
# Protection contre l'inversion de J4 sans chute de tension : fusible réarmable 1,1 A en série + Schottky en inverse.
cms("Fuse", "Fuse_1206_3216Metric", "F1", "PTC 1,1 A 6 V", 101.0, 108.0, 0, {"1": "+5V_EXT", "2": "+5V"}, "C2846895")
cms("Diode_SMD", "D_SMA", "D2", "SS14", 91.0, 102.0, 0, {"1": "+5V", "2": "GND"}, "C2480")

texte(board, pcbnew.F_SilkS, 28.0, 120.0, "Routeur solaire v1 — basse tension seulement", 1.2, 0.18)

# Règles de contrôle d'impression (hors carte, couche Fab : ignorées par le fabricant). Doivent mesurer 100 mm.
def regle(x0, y0, horizontale):
    for i in range(0, 101, 10):
        long = 3.0 if i % 50 == 0 else 1.5
        if horizontale:
            trait(board, pcbnew.F_Fab, x0 + i, y0, x0 + i, y0 - long, 0.15)
        else:
            trait(board, pcbnew.F_Fab, x0, y0 + i, x0 - long, y0 + i, 0.15)
    if horizontale:
        trait(board, pcbnew.F_Fab, x0, y0, x0 + 100, y0, 0.2)
        texte(board, pcbnew.F_Fab, x0 + 50, y0 + 3, "CONTRÔLE : cette règle doit mesurer 100 mm", 2.0, 0.25)
    else:
        trait(board, pcbnew.F_Fab, x0, y0, x0, y0 + 100, 0.2)


regle(27.0, 134.0, True)
regle(-8.0, 12.0, False)
texte(board, pcbnew.F_Fab, 77.0, 142.0, "Carte : 154 × 124 mm. Imprimer à 100 % (taille réelle), jamais « ajuster à la page ».", 2.0, 0.25)

board.Save(SORTIE)
import csv
from collections import defaultdict
groupes = defaultdict(list)
for ref, (val, emp, lcsc) in LCSC.items():
    groupes[(val, emp, lcsc)].append(ref)
with open(os.path.join(ICI, "jlcpcb-bom.csv"), "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["Comment", "Designator", "Footprint", "LCSC Part #"])
    for (val, emp, lcsc), refs in sorted(groupes.items(), key=lambda g: g[1][0]):
        w.writerow([val, ",".join(sorted(refs)), emp, lcsc])
print("écrit", SORTIE, "–", len(board.GetFootprints()), "empreintes,", len(NETS), "liaisons")
