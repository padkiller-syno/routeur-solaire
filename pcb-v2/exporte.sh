#!/bin/bash
# Fichiers de fabrication JLCPCB de la carte v2 (après genere_pcb.py et route_pcb.py).
set -euo pipefail
cd "$(dirname "$0")"
PCB=routeur-solaire-v2.kicad_pcb
rm -rf fabrication && mkdir fabrication
kicad-cli pcb export gerbers --layers F.Cu,B.Cu,F.Paste,F.SilkS,B.SilkS,F.Mask,B.Mask,Edge.Cuts \
  --subtract-soldermask --use-drill-file-origin -o fabrication/ "$PCB" >/dev/null
kicad-cli pcb export drill --excellon-separate-th \
  -o fabrication/ "$PCB" >/dev/null
rm -f routeur-solaire-v2-jlcpcb.zip
(cd fabrication && zip -q ../routeur-solaire-v2-jlcpcb.zip *)

# CPL : positions des seuls composants de la BOM (CMS assemblés par JLCPCB)
kicad-cli pcb export pos --format csv --units mm --side front -o /tmp/pos-v2.csv "$PCB" >/dev/null
python3 - <<'EOF'
import csv
refs = set()
for row in csv.DictReader(open("jlcpcb-bom.csv", encoding="utf-8")):
    refs.update(row["Designator"].split(","))
with open("jlcpcb-cpl.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["Designator", "Mid X", "Mid Y", "Layer", "Rotation"])
    for r in csv.DictReader(open("/tmp/pos-v2.csv", encoding="utf-8")):
        if r["Ref"] in refs:
            w.writerow([r["Ref"], r["PosX"] + "mm", r["PosY"] + "mm", "Top", r["Rot"]])
            refs.discard(r["Ref"])
if refs:
    raise SystemExit(f"absents du CPL : {sorted(refs)}")
EOF
rm -f /tmp/pos-v2.csv

kicad-cli pcb render --side top --quality high --width 1600 --height 1200 --zoom 1.0 \
  -o rendu-3d.png "$PCB" >/dev/null
kicad-cli pcb export pdf --layers Edge.Cuts,F.Fab,F.SilkS,F.Cu -o placement-1-1.pdf "$PCB" >/dev/null
echo "OK : routeur-solaire-v2-jlcpcb.zip, jlcpcb-bom.csv, jlcpcb-cpl.csv, rendu-3d.png, placement-1-1.pdf"
