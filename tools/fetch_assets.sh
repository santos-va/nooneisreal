#!/usr/bin/env bash
# Fetch the Higgsfield-generated source art into the Godot project.
# The cloud agent container cannot reach the CDN (egress policy), so this runs on a dev machine:
#   bash tools/fetch_assets.sh          # downloads into game/assets/...
# Every file here is registered in docs/Art/Textures-Registry.md — keep the two in sync (gate: texture_registry_check.py).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BG="$ROOT/game/assets/backgrounds"
CARDS="$ROOT/game/assets/characters/cards"
mkdir -p "$BG" "$CARDS"
CDN="https://d8j0ntlcm91z4.cloudfront.net/user_3JiwWmSIzQvXHlHhmCxwWysInqU"

fetch() { # url, dest
  if [ -s "$2" ]; then echo "skip (exists): $(basename "$2")"; return; fi
  echo "fetch: $(basename "$2")"
  curl -fsSL --retry 3 -o "$2" "$1"
}

# Backgrounds (Kronshift stages). "_min.webp" = CDN-downsized preview; the ".png" raw is 2688x1520.
fetch "$CDN/hf_20261002_131105_0b5c85b7-3c3f-4539-a967-f66a3aba5077_min.webp" "$BG/bg_kronshift_market_street.webp"
fetch "$CDN/hf_20261002_131105_a479d377-6809-4f9a-a433-53a55b2889f9_min.webp" "$BG/bg_kronshift_back_alley.webp"
fetch "$CDN/hf_20261002_131104_8510a1fc-3e5c-496e-b054-c0dddfc81669_min.webp" "$BG/bg_kronshift_main_street.webp"
fetch "$CDN/hf_20261002_102352_6c5c895d-67b1-4cca-8c3c-b48cda5e14c9_min.webp" "$BG/bg_kronshift_city_reference.webp"
# Full-resolution PNGs (optional, larger; uncomment when needed for upscales / outpaint):
# fetch "$CDN/hf_20261002_131105_0b5c85b7-3c3f-4539-a967-f66a3aba5077.png" "$BG/bg_kronshift_market_street_2k.png"

# Character cards
fetch "$CDN/hf_20261002_111512_bcddbbc6-9079-4060-9846-b5032092d0b8.png" "$CARDS/card_choko_v3.png"
fetch "$CDN/hf_20261002_111511_9652a5b1-3346-46b0-b342-c68a75184de1.png" "$CARDS/weapon_choko_main_sword.png"
fetch "$CDN/hf_20261002_102352_f00d0272-1c4f-4d56-8607-c30fce7cb325.png" "$CARDS/weapons_choko_ultimate.png"
fetch "$CDN/hf_20261002_110646_b776f4f8-c0a8-46b1-8987-242907591958.png" "$CARDS/hands_choko.png"
# Skeasse: the message listed the SAME URL as Choko's card. Replace when the real card link is known:
# fetch "<SKEASSE_CARD_URL>" "$CARDS/card_skeasse_v1.png"

echo "done. Now run: make check   (re-imports the new textures headlessly)"
