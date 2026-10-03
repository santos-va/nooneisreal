class_name ArenaLayout
extends RefCounted
## Sprint A3: grapple anchors and cover per arena in free movement — T5 Арес, docs/GDD/04-Grapple-System.md § Якорі й
## укриття на `bazaar` і `fountain`. All PLACEHOLDER / ДИЗАЙН. Metres from the arena centre; `h` = the Marker3D height
## above the floor. A stage picks its layout with GameState.STAGES[...]["layout"]; without one the 0.2 anchors + ring stay.

## Cover is static: on layer 1 (fighters, mask 1, cannot walk through) and on COVER_LAYER, which the grapple's line-of-
## sight ray reads alone (so the floor never cuts a rope). The camera arm ignores cover bodies (ADR-018 п. 5).
const COVER_LAYER := 8


## [x, z, h, lamp] — lamp = a lantern that lights up at night (A3).
static func anchors(layout: String) -> Array:
	var out: Array = []
	match layout:
		"fountain":
			out.append([0.0, 0.0, 6.0, false])                      # statue on the fountain
			for k in 8:                                             # square lanterns, r 12 every 45° from 0°
				var a := deg_to_rad(45.0 * k)
				out.append([cos(a) * 12.0, sin(a) * 12.0, 5.5, true])
			for k in 8:                                             # balconies, r 19 every 45° from 22.5°
				var b := deg_to_rad(22.5 + 45.0 * k)
				out.append([cos(b) * 19.0, sin(b) * 19.0, 7.0, false])
		"bazaar":
			for x in [-14.0, -7.0, 0.0, 7.0, 14.0]:                 # garland lantern posts over the stalls
				for z in [-6.0, 6.0]:
					out.append([x, z, 5.0, true])
			for x in [-8.0, 8.0]:                                   # balconies / washing lines
				for z in [-15.0, 15.0]:
					out.append([x, z, 7.0, false])
			for x in [-18.0, 18.0]:                                 # tram catenary at the street ends
				out.append([x, 0.0, 6.5, false])
	return out


## [kind, centre, size]: "box" (size = extents x, y, z — full sizes) or "cylinder" (size = Vector3(radius, height, 0)).
static func cover(layout: String) -> Array:
	var out: Array = []
	match layout:
		"fountain":
			out.append(["cylinder", Vector3(0.0, 0.45, 0.0), Vector3(3.0, 0.9, 0.0)])   # the fountain bowl
		"bazaar":
			# two rows of stalls, z ±4 (3.2…4.8), x −16…16, with 3 m passages at x −10.5, 0, 10.5; stall height 1.1
			for z in [-4.0, 4.0]:
				for seg in [[-16.0, -12.0], [-9.0, -1.5], [1.5, 9.0], [12.0, 16.0]]:
					var x0: float = seg[0]
					var x1: float = seg[1]
					out.append(["box", Vector3((x0 + x1) * 0.5, 0.55, z), Vector3(x1 - x0, 1.1, 1.6)])
			# 6 crates 1 × 1 × 1 on the street side, staggered so the street between the rows stays ≥ 5 m wide
			for c in [[-14.0, 2.7], [-6.0, 2.7], [6.5, 2.7], [-3.0, -2.7], [4.0, -2.7], [14.0, -2.7]]:
				out.append(["box", Vector3(c[0], 0.5, c[1]), Vector3(1.0, 1.0, 1.0)])
	return out
