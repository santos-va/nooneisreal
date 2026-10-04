#!/usr/bin/env bash
# Fetch the Higgsfield-generated source art into the Godot project.
# Runs on a dev machine or in the cloud container (CDN allowed for T6 since 2026-10-03):
#   bash tools/fetch_assets.sh          # downloads into game/assets/...
# Every file here is registered in docs/Art/Textures-Registry.md — keep the two in sync (gate: texture_registry_check.py).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BG="$ROOT/game/assets/backgrounds"
CARDS="$ROOT/game/assets/characters/cards"
MODELS="$ROOT/game/assets/characters/models"
TEX="$ROOT/game/assets/textures"
PROPS="$ROOT/game/assets/props"
MENU="$ROOT/game/assets/menu"
SPRITES="$ROOT/game/assets/sprites"
VFX="$ROOT/game/assets/vfx"
mkdir -p "$BG" "$CARDS" "$MODELS" "$TEX" "$PROPS" "$MENU" "$SPRITES" "$VFX"
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


# 3D heroes with Meshy rig (C2, Santos 2026-10-03 «M-0, M-1 — так»). Different Higgsfield user folder than $CDN above.
CDN3D="https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO"
fetch "$CDN3D/hf_20261003_034701_2488e146-f049-4469-9aad-4a512a810022.glb" "$MODELS/choko_m0.glb"
fetch "$CDN3D/hf_20261003_034702_f7f95324-7686-48af-8d0c-3f4d5010502c.glb" "$MODELS/skea_m1.glb"

# Sprint lane C (T6, 2026-10-03): Sketch-Cel art already generated and picked by Santos in wave 2, never downloaded.
# 0 credits — docs/Art/Prompts/Arenas-360-Prompts.md, docs/Art/Prompts/Menu-Skyline-Prompts.md rows 24, 25, 38 and 1b.
fetch "$CDN3D/hf_20261003_005206_a2913501-694d-4bbc-9908-66892760bf7e.png" "$BG/stage_river_plate_v1.png"
fetch "$CDN3D/hf_20261003_013154_b0a9189d-0b0a-435f-b5a5-459b105374ce.png" "$TEX/tex_water_foam.png"
# v2 (T6, Santos «go» 2026-10-03): v1 has a smeared city-reflection band at 55–87 % height; v2 has no reference image. 2 credits.
fetch "$CDN3D/hf_20261003_174931_3e04a378-87e8-4796-b918-f8ba2fbe784d.png" "$TEX/tex_water_foam_v2.png"
fetch "$CDN3D/hf_20261003_013154_bb5e3e44-27c1-478c-9b2d-2252bf2e9339.png" "$TEX/tex_water_ripple.png"
fetch "$CDN3D/hf_20261003_013416_c5900952-f4f0-4728-8ada-5b30d641be3a.png" "$PROPS/props_anchors_v1.png"

# Wave 2 canon picked by Santos, never downloaded (plan Picks-to-Game B1). 0 credits.
# docs/Art/Prompts/Menu-Skyline-Prompts.md rows 1c, 27, 31, 33, 39, 43, 30 and N-7..N-9.
# Decompose layers bc9d78b2 / 9fe905f1: Higgsfield tools return no layer URLs — not fetchable.
fetch "$CDN3D/hf_20261003_005204_73ee9806-ca24-4dcc-965f-848941e01fe7.png" "$MENU/menu_skyline_plate_v1.png"
fetch "$CDN3D/hf_20261003_013309_f500c1cf-46e3-4931-a83e-8cda14c5fdd2.png" "$MENU/menu_roof_edge_v1.png"
fetch "$CDN3D/hf_20261003_013449_08c09625-7766-4984-81c8-f03d9bae618f.png" "$MENU/menu_depth_cards_v1.png"
fetch "$CDN3D/hf_20261003_013335_4603954f-5b46-4067-826c-43788b9d8b79.png" "$SPRITES/sprite_steamcars_v1.png"
fetch "$CDN3D/hf_20261003_013319_cc4637e4-da18-48d9-90b0-45ca3e8c3941.png" "$SPRITES/sprite_pedestrian_worker_walk.png"
fetch "$CDN3D/hf_20261003_022151_b4cc96ad-0d95-42e6-a2e7-23d7c4d6ba8c.png" "$SPRITES/sprite_pedestrian_lady_walk.png"
fetch "$CDN3D/hf_20261003_022149_76fac42d-05a0-43a2-b900-3cb9ac705be0.png" "$SPRITES/sprite_pedestrian_courier_walk.png"
fetch "$CDN3D/hf_20261003_022150_ccc3ca6e-5e08-4673-baf2-e34dbd197351.png" "$SPRITES/sprite_pedestrian_elder_walk.png"
fetch "$CDN3D/hf_20261003_013334_bd9797c1-11f4-4ef3-9e32-a26aef2dc1ca.png" "$VFX/vfx_steam_puff_v1.png"
fetch "$CDN3D/hf_20261003_013436_e9fd9e33-beaa-43b7-8e1c-573c12691253.png" "$PROPS/drone_heavy_v1.png"

# T6·C (Santos 2026-10-03 «даю добро на все»): Choko's printer device and helper drone, canon H13–H14. 11 credits.
# docs/Art/Prompts/Prompt-Library.md § 16–17.
fetch "$CDN3D/hf_20261003_160102_e74e5c35-1c47-4581-ad11-22c471a1a8a5.png" "$CARDS/choko_printer_v1.png"
fetch "$CDN3D/hf_20261003_160106_d829cadc-41cf-480c-836c-0681c85024ac.png" "$CARDS/choko_drone_helper_v1.png"

# Arena cut-out strips v2 (Arena-Depth-Life F3.1, T6 2026-10-04): 12 directions, 77 credits spent earlier on lane C.
mkdir -p "$BG/river"; fetch "$CDN3D/hf_20261003_103524_9d96757d-da5c-4491-9134-311113be796a.png" "$BG/river/stage_river_n_strips.png"
mkdir -p "$BG/bazaar"; fetch "$CDN3D/hf_20261003_103525_bc50c97d-27f6-41d5-be65-3799cb4a45d1.png" "$BG/bazaar/stage_bazaar_n_strips.png"
mkdir -p "$BG/river"; fetch "$CDN3D/hf_20261003_105011_6a0d67d3-9ee7-43df-b1c7-f62b8f3e0b6c.png" "$BG/river/stage_river_e_strips.png"
mkdir -p "$BG/river"; fetch "$CDN3D/hf_20261003_105012_8dfc14ec-fe34-42b8-911f-2755bd8cb4ef.png" "$BG/river/stage_river_s_strips.png"
mkdir -p "$BG/river"; fetch "$CDN3D/hf_20261003_105011_58ae71af-8b94-4c48-b9e4-bbc408737744.png" "$BG/river/stage_river_w_strips.png"
mkdir -p "$BG/bazaar"; fetch "$CDN3D/hf_20261003_105011_9a1f06b2-6661-4fef-8ba5-773eb89cc3a9.png" "$BG/bazaar/stage_bazaar_e_strips.png"
mkdir -p "$BG/bazaar"; fetch "$CDN3D/hf_20261003_105012_19181cec-e4bc-4a4e-b299-590d33622f90.png" "$BG/bazaar/stage_bazaar_s_strips.png"
mkdir -p "$BG/bazaar"; fetch "$CDN3D/hf_20261003_105013_039a422b-0076-48ed-b186-73ee3b0faffd.png" "$BG/bazaar/stage_bazaar_w_strips.png"
mkdir -p "$BG/fountain"; fetch "$CDN3D/hf_20261003_105057_c190a897-5057-417e-ac06-bebf3f3fba18.png" "$BG/fountain/stage_fountain_n_strips.png"
mkdir -p "$BG/fountain"; fetch "$CDN3D/hf_20261003_105056_3b78eacc-4038-4c13-b876-f5e6d6b1fec0.png" "$BG/fountain/stage_fountain_e_strips.png"
mkdir -p "$BG/fountain"; fetch "$CDN3D/hf_20261003_105055_39b433fa-becf-4c77-a05d-48b97b12bed2.png" "$BG/fountain/stage_fountain_s_strips.png"
mkdir -p "$BG/fountain"; fetch "$CDN3D/hf_20261003_105056_df3b68bb-5041-41ad-a7e8-fcc1ca8e2931.png" "$BG/fountain/stage_fountain_w_strips.png"

echo "done. Now run: make check   (re-imports the new textures headlessly)"
