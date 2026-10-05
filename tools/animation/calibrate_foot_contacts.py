#!/usr/bin/env python3
"""Measure UAL source stance speeds, in metres/second, without starting Godot.

Requires NumPy and SciPy. Reads source glTF transforms (not Godot-retargeted heroes).
Reproduces the source-only contact windows frozen before the ground-contact solver.
Requires NumPy and SciPy; never reads the corrected hero or solver flags.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct

import numpy as np
from scipy.spatial.transform import Rotation

ROOT = Path(__file__).resolve().parents[2]
result=[]


def measure(path):
    raw = path.read_bytes()
    json_length = struct.unpack_from("<I", raw, 12)[0]
    document = json.loads(raw[20:20 + json_length])
    binary = raw[28 + json_length:]
    nodes = document["nodes"]
    parents = {child: i for i, node in enumerate(nodes)
               for child in node.get("children", [])}

    def accessor(index):
        item = document["accessors"][index]
        view = document["bufferViews"][item["bufferView"]]
        dtype = {5126: "<f4", 5123: "<u2", 5125: "<u4"}[item["componentType"]]
        width = {"SCALAR": 1, "VEC3": 3, "VEC4": 4, "MAT4": 16}[item["type"]]
        assert "byteStride" not in view, "Interleaved accessors require a stride-aware reader"
        return np.frombuffer(binary, dtype=dtype, count=item["count"] * width,
                             offset=view.get("byteOffset", 0) + item.get("byteOffset", 0)
                             ).reshape(item["count"], width)

    for animation in document["animations"]:
        name = animation["name"]
        if not name.startswith(("Walk_", "Jog_", "Sprint_")) or not name.endswith("_Loop"):
            continue
        if any(excluded in name for excluded in ["Lean", "Carry", "Formal"]):
            continue
        channels = {}
        times = None
        for channel in animation["channels"]:
            sampler = animation["samplers"][channel["sampler"]]
            channel_times = accessor(sampler["input"])[:, 0]
            if times is not None:
                assert np.array_equal(times, channel_times), "Resample uneven source keys first"
            times = channel_times
            target = channel["target"]
            channels[target["node"], target["path"]] = accessor(sampler["output"])
        points = {}
        for bone in ["foot_l", "foot_r", "ball_l", "ball_r"]:
            index = next(i for i, node in enumerate(nodes) if node.get("name") == bone)
            trajectory = []
            for frame in range(len(times)):
                def world(i):
                    node = nodes[i]
                    values = {}
                    for key, default in [("translation", [0, 0, 0]),
                                         ("rotation", [0, 0, 0, 1]), ("scale", [1, 1, 1])]:
                        values[key] = (channels[i, key][frame] if (i, key) in channels
                                       else node.get(key, default))
                    transform = np.eye(4)
                    transform[:3, :3] = (Rotation.from_quat(values["rotation"]).as_matrix()
                                            @ np.diag(values["scale"]))
                    transform[:3, 3] = values["translation"]
                    return world(parents[i]) @ transform if i in parents else transform
                trajectory.append(world(index)[:3, 3])
            points[bone] = np.array(trajectory)
        result.append({"clip":name,"times":times.tolist(),"points":{k:v.tolist() for k,v in points.items()}})

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--raw-output", type=Path)
    args = parser.parse_args()
    sources = {}
    for library in ["UAL1", "UAL2"]:
        path = ROOT / "game/assets/animations/ual" / f"{library}.glb"
        sources[str(path.relative_to(ROOT))] = hashlib.sha256(path.read_bytes()).hexdigest()
        measure(path)
    raw_bytes = json.dumps(result).encode()
    if args.raw_output:
        args.raw_output.write_bytes(raw_bytes)
    metadata = {
        "baseline": "3df43a520e494c809905854efff44ffe7de4341f",
        "source_raw_sha256": hashlib.sha256(raw_bytes).hexdigest(),
        "classification": {
            "point": "UAL ball_l/ball_r; hero ToeBase, not ankle",
            "height_envelope_m": .015,
            "max_vertical_speed_mps": .15,
            "minimum_source_window_seconds": .05,
            "candidate_dependent": False,
            "note": "Both endpoints low and slow vertically. Horizontal speed is deliberately not a filter: source slip cannot exclude a failing support interval. Toe roll is allowed around this ball point. Wrap intervals must join across loop boundary."
        }, "clips": {}
    }
    for item in result:
        if item["clip"] == "Sprint_Shield_Loop":
            continue
        times = np.array(item["times"])
        sides = {}
        for side, suffix in [("Left", "l"), ("Right", "r")]:
            points = np.array(item["points"]["ball_" + suffix])
            velocity = np.diff(points, axis=0) / np.diff(times)[:, None]
            mask = ((points[:-1, 1] <= points[:, 1].min() + .015)
                    & (points[1:, 1] <= points[:, 1].min() + .015)
                    & (abs(velocity[:, 1]) <= .15))
            changes = np.diff(np.r_[False, mask, False].astype(int))
            starts, ends = np.where(changes == 1)[0], np.where(changes == -1)[0]
            intervals = [[float(times[a] / times[-1]), float(times[b] / times[-1])]
                         for a, b in zip(starts, ends) if times[b] - times[a] >= .05]
            sides[side] = {"intervals": intervals, "min_ball_height_m": float(points[:, 1].min())}
        metadata["clips"][item["clip"]] = {"length": float(times[-1]), "sides": sides}
    args.output.write_text(json.dumps(metadata, indent=2))
    print(json.dumps({"source_sha256": sources, "metadata_sha256": hashlib.sha256(args.output.read_bytes()).hexdigest(), "clips": len(metadata["clips"])}, indent=2))


if __name__ == "__main__":
    main()
