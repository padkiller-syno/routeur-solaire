#!/usr/bin/env python3
"""Carte v2 du routeur solaire (KiCad 9) : carte réduite, modules enfichés par leur barrette et portés par le boîtier.

La carte ne passe que sous les barrettes des modules (et sous l'ESP32) ; le reste de chaque module repose sur des
supports imprimés du boîtier (boitier-v2/). Gabarit < 100 × 100 mm : tarif JLCPCB le plus bas.
Cotes des modules : pcb/mesures-modules.md. Mêmes composants CMS que la v1 (assemblage JLCPCB Economic).
Repère : celui de l'intérieur du boîtier v1 (origine = coin de l'ancienne carte 154 × 124), mm, y vers le bas.
Lancer : python3 genere_pcb.py  puis  python3 route_pcb.py
"""
import csv
import os
from collections import defaultdict

import pcbnew

ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(ICI, "routeur-solaire-v2.kicad_pcb")
LIBS = "/usr/share/kicad/footprints"
mm = pcbnew.FromMM

# Décalage dans la feuille A4 pour l'impression 1:1 (la carte occupe x 18..117, y 22..112 du repère boîtier).
OX, OY = 81.0, 38.0


def V(x, y):
    return pcbnew.VECTOR2I(mm(x + OX), mm(y + OY))


def S(w, h):
    return pcbnew.VECTOR2I(mm(w), mm(h))


board = pcbnew.BOARD()
board.SetCopperLayerCount(2)
ds = board.GetDesignSettings()
ds.m_TrackMinWidth = mm(0.25)
ds.m_CopperEdgeClearance = mm(0.4)   # Freerouting garde 0,3 mm du bord ; JLCPCB demande ≥ 0,3

NETS = {}


def net(nom):
    if nom not in NETS:
        n = pcbnew.NETINFO_ITEM(board, nom)
        board.Add(n)
        NETS[nom] = n
    return NETS[nom]


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


def texte(parent, couche, x, y, txt, taille=1.0, epaisseur=0.15, angle=0):
    t = pcbnew.PCB_TEXT(parent)
    t.SetLayer(couche)
    t.SetText(txt)
    t.SetPosition(V(x, y))
    t.SetTextSize(S(taille, taille))
    t.SetTextThickness(mm(epaisseur))
    if angle:
        t.SetTextAngleDegrees(angle)
    parent.Add(t)


def module(ref, valeur, contour, broches, trous=(), notes=(), sur_carte=None, libelle=None, cote="gauche"):
    """Module enfichable. `contour` = emprise réelle du module (couche Fab seulement : il déborde de la carte) ;
    `sur_carte` = rectangle sérigraphié et courtyard (la partie du module au-dessus de la carte)."""
    x0, y0, x1, y1 = contour
    fp = pcbnew.FOOTPRINT(board)
    fp.SetReference(ref)
    fp.SetValue(valeur)
    fp.SetFPID(pcbnew.LIB_ID("routeur_solaire", f"Module_{ref}"))
    px = sum(b[2] for b in broches) / len(broches)
    py = sum(b[3] for b in broches) / len(broches)
    fp.SetPosition(V(px, py))
    lx, ly = libelle if libelle else (px, py - 3)
    fp.Reference().SetPosition(V(lx, ly))
    fp.Reference().SetTextSize(S(1.2, 1.2))
    fp.Value().SetPosition(V((x0 + x1) / 2, (y0 + y1) / 2))
    fp.Value().SetLayer(pcbnew.F_Fab)
    rect(fp, pcbnew.F_Fab, x0, y0, x1, y1, 0.1)
    if sur_carte:
        a, b, c, d = sur_carte
        rect(fp, pcbnew.F_SilkS, a, b, c, d, 0.15)
        rect(fp, pcbnew.F_CrtYd, a - 0.25, b - 0.25, c + 0.25, d + 0.25, 0.05)
    vertical = len({round(b[2], 2) for b in broches}) == 1
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
            if vertical:
                texte(fp, pcbnew.F_SilkS, x + (3.0 if cote == "droite" else -3.0), y, nom, 0.8, 0.12)
            else:
                texte(fp, pcbnew.F_SilkS, x, y + 1.9, nom, 0.8, 0.12)
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
# Rectangle 99 × 64 + languette montant sous la barrette du JSY : gabarit 99 × 92 mm.
X0, X1, Y0, Y1 = 18.0, 117.0, 50.0, 114.0
LANG = (92.5, 105.5, 22.0)          # languette du JSY : x0, x1, haut
CONTOUR = [(X0, Y0), (LANG[0], Y0), (LANG[0], LANG[2]), (LANG[1], LANG[2]), (LANG[1], Y0), (X1, Y0), (X1, Y1),
           (X0, Y1)]
for (a, b), (c, d) in zip(CONTOUR, CONTOUR[1:] + CONTOUR[:1]):
    trait(board, pcbnew.Edge_Cuts, a, b, c, d, 0.1)
    # bande sans piste le long du bord (Freerouting ne garde que 0,3 mm)
    zone_interdite(min(a, c) - 0.7, min(b, d) - 0.7, max(a, c) + 0.7, max(b, d) + 0.7, "bord")

TROUS_CARTE = [(20.5, 66.0), (21.5, 110.5), (104.0, 110.5), (113.5, 66.0)]
for i, (x, y) in enumerate(TROUS_CARTE, 1):
    lib("MountingHole", "MountingHole_3.2mm_M3", f"H{i}", "M3", x, y)

# ----------------------------------------------------------------------------------------------- dimmers
# Comme la v1 : bornier 230 V vers le fond du boîtier, bord « commande » vers la carte, broches à 4 mm de ce bord,
# centrées, VCC GND Z-C PSM. Trous M3 du bord commande : sur la carte (entretoise) ou sur un plot du boîtier.
DIM_Y0, DIM_Y1 = 2.0, 62.0
DIMMERS = [("M1", 3.5, "Dimmer 1 (ballon) RobotDyn HL", "ZC", "PWM1"),
           ("M2", 48.0, "Dimmer 2 (option) RobotDyn HL", None, "PWM2")]


def sur_la_carte(x, y):
    dans_rect = X0 + 1.6 < x < X1 - 1.6 and Y0 + 1.6 < y < Y1 - 1.6
    dans_lang = LANG[0] + 1.6 < x < LANG[1] - 1.6 and LANG[2] + 1.6 < y < Y1
    return dans_rect or dans_lang


for ref, x0, nom, zc, pwm in DIMMERS:
    cx, yb = x0 + 21.0, DIM_Y1 - 4.0
    br = [(1, "VCC", cx - 3.81, yb, "+3V3"), (2, "GND", cx - 1.27, yb, "GND"),
          (3, "ZC", cx + 1.27, yb, zc), (4, "PSM", cx + 3.81, yb, pwm)]
    trous = [(x, DIM_Y1 - 4.3, 3.2) for x in (x0 + 3.2, x0 + 42.0 - 3.2) if sur_la_carte(x, DIM_Y1 - 4.3)]
    gauche = max(x0, X0 + 0.3)
    module(ref, nom, (x0, DIM_Y0, x0 + 42.0, DIM_Y1), br, trous,
           notes=[(cx, DIM_Y0 + 4, "L / N / LOAD 230 V"), (cx, DIM_Y0 + 26, "radiateur (h 42 mm)")],
           sur_carte=(gauche, Y0 + 0.3, x0 + 42.0, DIM_Y1), libelle=(cx, Y0 + 2.5))

# ----------------------------------------------------------------------------------------------- JSY-MK-194T
# Debout le long du dimmer 2, tourné de 180° par rapport à la v1 : J3 sur le bord gauche (au-dessus de la
# languette), tore en bas, broches L/N (J1) dans le coin bas-droit, loin de la carte.
JX0, JY0 = 96.0, 2.0
JX1, JY1 = JX0 + 36.6, JY0 + 60.5
jx = JX0 + 2.9
jy_vcc = JY1 - 26.5
module("M3", "JSY-MK-194T", (JX0, JY0, JX1, JY1),
       [(1, "VCC", jx, jy_vcc, "+5V"), (2, "RX", jx, jy_vcc - 2.54, "TX2"), (3, "TX", jx, jy_vcc - 5.08, "JSY_TX"),
        (4, "PF", jx, jy_vcc - 7.62, None), (5, "GND", jx, jy_vcc - 10.16, "GND")],
       notes=[(JX0 + 18, JY0 + 10, "JSY (h 27 mm), porté par le boîtier"), (JX1 - 8, JY1 - 6, "L/N 230 V")],
       sur_carte=(LANG[0] + 0.3, LANG[2] + 0.3, LANG[1] - 0.3, Y0 + 12.0), libelle=(jx + 4.0, LANG[2] + 3.5), cote="droite")
# pas de cuivre sous le JSY en dehors de la bande de J3 (partie basse de la carte sous le module)
zone_interdite(jx + 3.2, Y0, X1, JY1, "230V JSY")

# ----------------------------------------------------------------------------------------------- relais
# Couchés, connecteur VCC GND IN côté carte (4 mm du bord), bornier NO/COM/NC vers la paroi droite.
for ref, y0, nom, in_net in (("K1", 70.0, "Relais MF (NC → contacteur)", "REL_MF"),
                             ("K2", 91.0, "Relais surplus", "REL_SURPLUS")):
    x0, x1, cy = 108.0, 151.0, y0 + 8.5
    module(ref, nom, (x0, y0, x1, y0 + 17.0),
           [(1, "VCC", x0 + 4.0, cy - 2.54, "+5V"), (2, "GND", x0 + 4.0, cy, "GND"),
            (3, "IN", x0 + 4.0, cy + 2.54, in_net)],
           notes=[(x0 + 27, cy + 5, "NO / COM / NC 230 V →")],
           sur_carte=(x0, y0, X1 - 0.3, y0 + 17.0), libelle=(x0 + 4.5, y0 - 1.5))
    zone_interdite(x0 + 7.5, y0, X1, y0 + 17.0, f"230V {ref}")

# ----------------------------------------------------------------------------------------------- ESP32 DevKit V1
# Couché, micro-USB vers la gauche (passage libre jusqu'à la paroi gauche), antenne vers la droite.
HAUT = ["EN", "VP", "VN", "D34", "D35", "D32", "D33", "D25", "D26", "D27", "D14", "D12", "D13", "GND", "VIN"]
BAS = ["D23", "D22", "TX0", "RX0", "D21", "D19", "D18", "D5", "TX2", "RX2", "D4", "D2", "D15", "GND", "3V3"]
NET_ESP = {"D35": "ZC", "D32": "PWM1", "D33": "PWM2", "D25": "REL_MF", "D26": "REL_SURPLUS", "D27": "DS_TRIACS",
           "D13": "VENTILO_CMD", "GND": "GND", "VIN": "+5V", "TX2": "TX2", "RX2": "RX2", "D4": "DS_BALLON",
           "3V3": "+3V3"}
EX0, EY0 = 40.0, 66.0
EX1, EY1 = EX0 + 51.8, EY0 + 28.2
broches = [(i + 1, n, EX0 + 45.36 - 2.54 * i, EY0 + 1.4, NET_ESP.get(n)) for i, n in enumerate(HAUT)]
broches += [(i + 16, n, EX0 + 45.36 - 2.54 * i, EY0 + 26.8, NET_ESP.get(n)) for i, n in enumerate(BAS)]
fp = module("U1", "ESP32 DevKit V1 (30 broches)", (EX0, EY0, EX1, EY1), broches,
            notes=[((EX0 + EX1) / 2, (EY0 + EY1) / 2, "micro-USB ← | ESP32 | antenne →")],
            sur_carte=(EX0, EY0, EX1, EY1), libelle=(EX0 + 3, EY0 + 4))

# ----------------------------------------------------------------------------------------------- CMS (JLCPCB)
LCSC = {}


def cms(biblio, nom, ref, valeur, x, y, rot, nets, lcsc):
    lib(biblio, nom, ref, valeur, x, y, rot, nets)
    LCSC[ref] = (valeur, nom, lcsc)


R0805 = ("Resistor_SMD", "R_0805_2012Metric")
C0805 = ("Capacitor_SMD", "C_0805_2012Metric")
# Colonne à gauche de l'ESP32 (x 20..38)
cms(*R0805, "R1", "1k", 26.5, 68.0, 0, {"1": "JSY_TX", "2": "RX2"}, "C17513")
cms(*R0805, "R2", "2k", 26.5, 72.0, 0, {"1": "RX2", "2": "GND"}, "C17604")
cms(*R0805, "R3", "4k7", 26.5, 76.0, 0, {"1": "DS_BALLON", "2": "+3V3"}, "C17673")
cms(*R0805, "R4", "4k7", 26.5, 80.0, 0, {"1": "DS_TRIACS", "2": "+3V3"}, "C17673")
cms(*C0805, "C1", "100n", 26.5, 84.0, 0, {"1": "+3V3", "2": "GND"}, "C49678")
cms(*C0805, "C2", "100n", 26.5, 88.0, 0, {"1": "+3V3", "2": "GND"}, "C49678")
cms(*R0805, "R5", "1k", 34.5, 68.0, 0, {"1": "VENTILO_CMD", "2": "VENTILO_G"}, "C17513")
cms(*R0805, "R6", "4k7", 34.5, 72.0, 0, {"1": "VENTILO_G", "2": "GND"}, "C17673")
cms("Package_TO_SOT_SMD", "SOT-23", "Q1", "AO3400A", 34.5, 77.0, 0,
    {"1": "VENTILO_G", "2": "GND", "3": "VENTILO_NEG"}, "C20917")
cms("Diode_SMD", "D_SOD-123", "D1", "1N4148W", 34.5, 82.0, 0, {"1": "+5V", "2": "VENTILO_NEG"}, "C81598")
# Alimentation, entre l'ESP32 et les relais
cms("Fuse", "Fuse_1206_3216Metric", "F1", "PTC 1,1 A 6 V", 99.0, 86.0, 90, {"1": "+5V_EXT", "2": "+5V"}, "C2846895")
cms("Diode_SMD", "D_SMA", "D2", "SS14", 99.0, 78.0, 90, {"1": "+5V", "2": "GND"}, "C2480")
cms("Capacitor_SMD", "CP_Elec_8x10.5", "C3", "470uF 16V", 100.0, 100.0, 0, {"1": "+5V", "2": "GND"}, "C2992615")

# ----------------------------------------------------------------------------------------------- connecteurs
TB3 = ("TerminalBlock_Phoenix", "TerminalBlock_Phoenix_PT-1,5-3-3.5-H_1x03_P3.50mm_Horizontal")
TB2 = ("TerminalBlock_Phoenix", "TerminalBlock_Phoenix_PT-1,5-2-3.5-H_1x02_P3.50mm_Horizontal")
YB = Y1 - 5.5     # entrée des fils vers le bord avant (presse-étoupe avant)
lib(*TB3, "J2", "Sonde ballon (VCC DAT GND)", 42.0, YB, 0, nets={"1": "+3V3", "2": "DS_BALLON", "3": "GND"})
lib(*TB3, "J3", "Sonde triacs (VCC DAT GND)", 56.0, YB, 0, nets={"1": "+3V3", "2": "DS_TRIACS", "3": "GND"})
lib(*TB2, "J4", "Alim 5 V (+ / GND)", 70.0, YB, 0, nets={"1": "+5V_EXT", "2": "GND"})
lib("Connector_PinHeader_2.54mm", "PinHeader_1x02_P2.54mm_Vertical", "J1", "Ventilateur 5 V", 30.0, 96.0,
    nets={"1": "+5V", "2": "VENTILO_NEG"})

texte(board, pcbnew.F_SilkS, 84.0, 110.0, "Routeur solaire v2", 1.2, 0.18)
texte(board, pcbnew.F_SilkS, 84.0, 112.2, "basse tension seulement", 0.9, 0.14)


# Règles de contrôle d'impression 1:1 (couche Fab, ignorées par le fabricant).
def regle(x0, y0):
    for i in range(0, 101, 10):
        trait(board, pcbnew.F_Fab, x0 + i, y0, x0 + i, y0 - (3.0 if i % 50 == 0 else 1.5), 0.15)
    trait(board, pcbnew.F_Fab, x0, y0, x0 + 100, y0, 0.2)
    texte(board, pcbnew.F_Fab, x0 + 50, y0 + 3, "CONTRÔLE : cette règle doit mesurer 100 mm", 2.0, 0.25)


regle(18.0, 126.0)

board.Save(SORTIE)

groupes = defaultdict(list)
for ref, (val, emp, lcsc) in LCSC.items():
    groupes[(val, emp, lcsc)].append(ref)
with open(os.path.join(ICI, "jlcpcb-bom.csv"), "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["Comment", "Designator", "Footprint", "LCSC Part #"])
    for (val, emp, lcsc), refs in sorted(groupes.items(), key=lambda g: g[1][0]):
        w.writerow([val, ",".join(sorted(refs)), emp, lcsc])
print("écrit", SORTIE, "–", len(board.GetFootprints()), "empreintes,", len(NETS), "liaisons")
