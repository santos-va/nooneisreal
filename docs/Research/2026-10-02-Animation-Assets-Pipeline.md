# Ресерч — анімації, 2D→3D, Higgsfield, SFX (2026-10-02)

**Роль:** T3 Архімед (суб-агент). Перевірено напряму: MCP-каталог Higgsfield (`models_explore`,
`animation_actions`, workflow `character-sheet`), GitHub-репо та ліцензії; сайти Adobe/Quaternius/Rokoko/
Cascadeur/Sonniss/Meshy закриті проксі — факти звідти вторинні («verify»).

## 1. Безкоштовні бібліотеки анімацій

| джерело | ліцензія | формат | завантаження | бій |
|---|---|---|---|---|
| Mixamo | royalty-free, без перепродажу; ToS забороняє датасети | FBX/Collada | браузер + Adobe ID; API немає; сайт ламався (06.2025+) | ~2 500 кліпів, базові удари, Sword & Shield, Melee Axe |
| Quaternius UAL | **CC0** | FBX/GLB/.blend | пряме | Standard 45 кліпів (бій — verify), Pro 120+ |
| KayKit Adventurers | **CC0** | FBX + GLB | `git clone` | 75 кліпів: 1H/2H attacks, Block, Dodge, Hit, Death |
| Kenney Animated Characters | **CC0** | FBX/glTF | пряме | без бою |
| Rokoko Motion Library | безкоштовно комерційно | FBX/BVH | акаунт | 150 + 10 + 13 бойових мокапів; Rokoko Vision — відеомокап 15 с |
| Cascadeur | free без FBX; Indie $19/міс або $96/рік (< $100k) | FBX/DAE | застосунок | авторські спецудари |
| Unity Asset Store / Fab | «Non-Restricted» / Fab Standard — не прив'язані до движка; **Epic UE-Only (Game Animation Sample, Megascans) — лише Unreal** | FBX | браузер | перевіряти кожен лістинг |

Авториги: Mixamo (коли працює), **AccuRig 2.0** (безкоштовно, FBX/USD), **UniRig** (MIT, локально, розуміє VRM).
Godot 4.3+: FBX через ufbx, бон-мапа `SkeletonProfileHumanoid`, ретаргет вбудований; хелпери RaidTheory/
Godot-Mixamo-Animation-Retargeter, MixaBridge, MixamoToGodot.

## 2. 2D → 3D (2026)

| сервіс | ціна | риг/анімація | нотатки |
|---|---|---|---|
| Meshy v6/7 | free 100 кр/міс; Pro $20 | авториг 0 кр, 600+ кліпів, FBX із Mixamo-скелетом; `pose_mode` t/a | найкращі пропорції; обличчя спрощені |
| Tripo 3.0/H3.1 | free 200 кр **некомерційно, публічно**; Pro $20 | біпед+ін., Mixamo-нейминг | найкращі обличчя (P1) |
| Rodin/Hyper3D | $30/міс | без авторига | хард-сьорфейс |
| Hunyuan3D 2.1 (open) | self-host 10–29 GB VRAM | статика | ліцензія виключає EU/UK/KR |
| TRELLIS.2 (MIT) | ≥ 24 GB VRAM | статика | + UniRig = повністю відкритий локальний шлях |
| **Higgsfield `generate_3d`** | кредити плану; ~38 кр/ригований персонаж + ~8/кліп (внутрішній док, verify `get_cost`) | Meshy image_to_3d / multi_image_to_3d (1–4 види), `enable_rigging`, `enable_animation` + `animation_action_id` (678 кліпів), `3d_rigging`, Tripo H3.1, Hunyuan3D v3, SAM 3 3D | одна фігура на зображення, білий фон, T-pose, `enable_pbr:false` |

Реальність cel-shading: усі image-to-3D запікають світло в альбедо і не кладуть лупи на суглобах →
`texture_prompt` «flat cel colors, no shadows», сплющити в Blender, toon у Godot.
**VRoid Studio** — найшвидший шлях до риг-готових аніме-персонажів (VRM 1.0, MToon, godot-vrm);
ціна — впізнаване базове тіло, лікується текстурами з карток.

## 3. Higgsfield для геймдеву (з живого MCP)

- Зображення: Soul 2.0 (+Soul ID/Cast/Location), Nano Banana / Pro / 2, Seedream 4.5/5.0, FLUX.2/FLUX 3 (до 10 референсів), Flux Kontext,
  GPT Image 2/2.5 (прозорий фон), Ideogram 4.5, **Recraft V4.1** (вектор/іконки для UI), Z Image.
- Утиліти: Background Remover, Outpaint, Topaz upscale, **Image Decompose** (шари для паралаксу), Reframe.
- **AutoSprite** — спрайт-шити (idle/walk/run/attack/jump/custom, ізометрія, 2–64 кадри, ≤ 512 px).
- Тайли: «Texture Tile Factory» (GPT Image 2 seamless + `pipeline.py`: FFT-шов, basecolor/normal/roughness/height).
- Відео: Kling 2.6–3.0, Veo 3.x, Seedance 2.x, Wan, Genjutsu (motion transfer) — для аніматиків, не мокапу.
- Аудіо: Seed Audio 1.0, Mirelo (SFX), Sonilo (музика), TTS. **Кредити зараз: 2.55 (Ultra).**
- Промпт-рецепт листа персонажа (workflow `character-sheet`): композиція → «identical original character on all views» →
  білий фон → ідентичність → обличчя → очі → волосся → тіло → гардероб з голови до ніг → render-модуль
  anime-2d («clean anime illustration, crisp lineart, cel-shaded flat color…») → негативний хвіст. 16:9 для листів.
- API `api.higgsfield.ai` (`Authorization: Key id:secret`), MCP `mcp.higgsfield.ai/mcp`, CLI `higgsfield-ai/cli` (MIT), skills `higgsfield-ai/skills`.

## 4. SFX і музика

Sonniss GDC 2026 (7.47 GB, 347 WAV, royalty-free, без AI-навчання) · Kenney Impact/Interface/Music Jingles (CC0) ·
Freesound (фільтр CC0, акаунт) · OGA CC0 Sounds Library, Swishes · Zapsplat free — атрибуція · Incompetech CC BY 4.0 ·
ElevenLabs SFX (Starter ≈ $5/міс для комерційного) · Higgsfield Seed Audio/Mirelo.

## Рекомендований пайплайн

Швидко: лист T-pose з картки (Nano Banana Pro) → VRoid → VRM → godot-vrm → UAL + KayKit + Rokoko → фони outpaint/decompose →
Sonniss + Kenney. Якісно: multi_image_to_3d (Meshy 7, t-pose, quad, no PBR) → Blender flatten → Meshy/AccuRig/UniRig риг →
Cascadeur для спецударів. Гігієна: уникати Epic UE-Only, Tripo free, ElevenLabs free, CC-BY-NC/SA. → [[Pipeline-2D-to-3D]]

## Related
- [[Pipeline-2D-to-3D]] · [[07-Audio]] · [[Style-Guide]] · [[Textures-Registry]]
