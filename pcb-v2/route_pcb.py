#!/usr/bin/env python3
"""Route la carte générée par genere_pcb.py (v2) avec Freerouting.

Étapes : règles de pistes, plan de masse (face dessous), export Specctra DSN, routage automatique par Freerouting
(sans interface), réimport de la session SES, remplissage des plans, enregistrement.
Lancer après genere_pcb.py (v2) : python3 route_pcb.py
"""
import os
import subprocess
import pcbnew

ICI = os.path.dirname(os.path.abspath(__file__))
PCB = os.path.join(ICI, "routeur-solaire-v2.kicad_pcb")
DSN = os.path.join(ICI, "routeur-solaire-v2.dsn")
SES = os.path.join(ICI, "routeur-solaire-v2.ses")
JAR = os.path.expanduser("~/.local/share/freerouting/freerouting-2.5.0.jar")
mm = pcbnew.FromMM

board = pcbnew.LoadBoard(PCB)

# Règles : pistes 0,5 mm (≈ 1,3 A en cuivre 35 µm, largement assez), isolement 0,3 mm, vias 0,9 / 0,45 mm.
ds = board.GetDesignSettings()
nc = ds.m_NetSettings.GetDefaultNetclass()
nc.SetTrackWidth(mm(0.5))
nc.SetClearance(mm(0.3))
nc.SetViaDiameter(mm(0.9))
nc.SetViaDrill(mm(0.45))
ds.m_MinClearance = mm(0.2)
ds.m_TrackMinWidth = mm(0.25)
ds.m_ViasMinSize = mm(0.6)
ds.m_MinThroughDrill = mm(0.3)

# Plan de masse sur la face dessous, sur tout le contour (les zones 230 V restent sans cuivre).
gnd = board.FindNet("GND")
bb = board.GetBoardEdgesBoundingBox()
z = pcbnew.ZONE(board)
z.SetLayer(pcbnew.B_Cu)
z.SetNet(gnd)
z.SetZoneName("Plan de masse")
z.SetLocalClearance(mm(0.4))
z.SetMinThickness(mm(0.3))
z.SetPadConnection(pcbnew.ZONE_CONNECTION_FULL)
z.SetThermalReliefGap(mm(0.4))
z.SetThermalReliefSpokeWidth(mm(0.5))
z.SetIslandRemovalMode(pcbnew.ISLAND_REMOVAL_MODE_ALWAYS)   # pas d'îlot de cuivre isolé
o = z.Outline()
o.NewOutline()
for x, y in ((bb.GetLeft(), bb.GetTop()), (bb.GetRight(), bb.GetTop()),
             (bb.GetRight(), bb.GetBottom()), (bb.GetLeft(), bb.GetBottom())):
    o.Append(x, y)
board.Add(z)
pcbnew.ZONE_FILLER(board).Fill(board.Zones())

# Export DSN, routage, réimport.
if not pcbnew.ExportSpecctraDSN(board, DSN):
    raise SystemExit("export DSN impossible")
if os.path.exists(SES):
    os.remove(SES)
cmd = ["java", "-Djava.awt.headless=true", "-jar", JAR, "-de", DSN, "-do", SES, "-mp", "40", "-mt", "4",
       "--gui.enabled=false"]
print("routage :", " ".join(cmd[3:]))
r = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
lignes = [l for l in (r.stdout + r.stderr).splitlines() if any(k in l.lower() for k in ("pass", "unrouted", "complete", "error", "fini", "routed"))]
print("\n".join(lignes[-12:]))
if not os.path.exists(SES):
    raise SystemExit("Freerouting n'a pas produit de session SES")
if not pcbnew.ImportSpecctraSES(board, SES):
    raise SystemExit("réimport SES impossible")

# Après routage : second plan de masse sur la face du dessus, dans l'espace laissé libre par les pistes.
# Les broches traversantes touchent les deux plans : aucune masse isolée par une piste.
z2 = pcbnew.ZONE(board)
z2.SetLayer(pcbnew.F_Cu)
z2.SetNet(gnd)
z2.SetZoneName("Plan de masse dessus")
z2.SetLocalClearance(mm(0.4))
z2.SetMinThickness(mm(0.3))
z2.SetPadConnection(pcbnew.ZONE_CONNECTION_FULL)
z2.SetThermalReliefGap(mm(0.4))
z2.SetThermalReliefSpokeWidth(mm(0.5))
z2.SetIslandRemovalMode(pcbnew.ISLAND_REMOVAL_MODE_ALWAYS)   # pas d'îlot de cuivre isolé
o2 = z2.Outline()
o2.NewOutline()
for x, y in ((bb.GetLeft(), bb.GetTop()), (bb.GetRight(), bb.GetTop()),
             (bb.GetRight(), bb.GetBottom()), (bb.GetLeft(), bb.GetBottom())):
    o2.Append(x, y)
board.Add(z2)
pcbnew.ZONE_FILLER(board).Fill(board.Zones())
board.Save(PCB)
print("routé et enregistré :", PCB, "–", len(board.GetTracks()), "segments/vias")
