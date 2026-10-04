#!/usr/bin/env python3
"""Validate the exported ZIP and write the update manifest; build hosts only."""
import hashlib
import json
import pathlib
import plistlib
import re
import stat
import struct
import sys
import zipfile


def validate(path: pathlib.Path, revision: str) -> dict:
    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError("Invalid revision")
    prefix = "No One Is Real.app/"
    with zipfile.ZipFile(path) as archive:
        for entry in archive.infolist():
            name = entry.filename
            if not name.startswith(prefix) or "\\" in name or any(ord(c) < 32 for c in name):
                raise ValueError(f"Unexpected member: {name!r}")
            if any(p in (".", "..", "") for p in name.rstrip("/").split("/")):
                raise ValueError(f"Unsafe member: {name!r}")
            mode = (entry.external_attr >> 16) & 0o170000
            if mode not in (0, stat.S_IFREG, stat.S_IFDIR):
                raise ValueError(f"Unsupported member type: {name!r}")
        info = plistlib.loads(archive.read(prefix + "Contents/Info.plist"))
        expected = {"CFBundleIdentifier": "com.santos.nooneisreal", "CFBundleExecutable": "No One Is Real", "NIRBuildRevision": revision}
        for key, value in expected.items():
            if info.get(key) != value:
                raise ValueError(f"Incorrect {key}: {info.get(key)!r}")
        binary = archive.read(prefix + "Contents/MacOS/No One Is Real")
        magic, count = struct.unpack_from(">II", binary)
        if magic != 0xCAFEBABE or not 1 <= count <= 8:
            raise ValueError("Expected a universal Mach-O binary")
        architectures = {struct.unpack_from(">I", binary, 8 + 20 * i)[0] for i in range(count)}
        if not {0x0100000C, 0x01000007} <= architectures:
            raise ValueError("Universal binary must contain arm64 and x86_64")
        if not any(n.endswith(".pck") for n in archive.namelist()):
            raise ValueError("Missing exported game pack")
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return {"schema": 1, "revision": revision, "sha256": digest.hexdigest(), "size": path.stat().st_size, "godot": "4.7-stable", "signing": "ad-hoc; not notarized"}


if __name__ == "__main__":
    directory, revision = pathlib.Path(sys.argv[1]), sys.argv[2]
    manifest = validate(directory / "NoOneIsReal-macos.zip", revision)
    (directory / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(manifest))
