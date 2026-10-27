#!/usr/bin/env bash
# Regenerates the schematic PDF and the board renders of one prototype
# (hardware/<proto>/docs/) from its KiCad project. Needs kicad-cli (KiCad 10).
#
# Usage: scripts/export-docs.sh proto1
set -euo pipefail

proto="${1:?usage: $0 <proto1|proto2>}"
root="$(cd "$(dirname "$0")/.." && pwd)/hardware/$proto"
name="Adafruit Metro RP2350"
out="$root/docs"

# render size follows the board outline: proto1 is 41.6 x 78 mm, proto2 40 x 40 mm
case "$proto" in
    proto1) width=1000 height=1900 ;;
    *)      width=1000 height=1000 ;;
esac

mkdir -p "$out"
kicad-cli sch export pdf -o "$out/schematic.pdf" "$root/kicad/$name.kicad_sch"
for side in top bottom; do
    kicad-cli pcb render --side "$side" --quality high --width "$width" --height "$height" \
        -o "$out/pcb-$side.png" "$root/kicad/$name.kicad_pcb"
done
