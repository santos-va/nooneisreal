#!/usr/bin/env python3
"""Measure UAL source stance speeds, in metres/second, without starting Godot.

Requires NumPy and SciPy. Reads source glTF transforms (not Godot-retargeted heroes).
The 3 cm contact envelope is provisional calibration and is not a collision solver.
"""
import json
from pathlib import Path
import struct

import numpy as np
from scipy.spatial.transform import Rotation

ROOT = Path(__file__).resolve().parents[2]


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
        if not name.startswith(("Walk_", "Jog_")) or not name.endswith("_Loop"):
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
        speeds = []
        for side in ["l", "r"]:
            foot, toe = points["foot_" + side], points["ball_" + side]
            velocity = np.diff(toe, axis=0) / np.diff(times)[:, None]
            height = np.minimum(foot[:, 1], toe[:, 1])
            contact = height[:-1] < height.min() + 0.03
            speeds.extend(np.linalg.norm(velocity[contact][:, [0, 2]], axis=1).tolist())
        print(f"{name}: {np.median(speeds):.3f} m/s ({len(speeds)} contact samples)")


if __name__ == "__main__":
    for library in ["UAL1", "UAL2"]:
        measure(ROOT / "game/assets/animations/ual" / f"{library}.glb")
