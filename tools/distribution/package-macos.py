#!/usr/bin/env python3
"""Validate the exported ZIP and write the update manifest; build hosts only."""
import gzip
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


CHUNK_BYTES = 4 * 1024 * 1024


def write_chunks(path: pathlib.Path, directory: pathlib.Path) -> dict:
    """Exact signed bundle bytes, split at fixed offsets including Mach-O signatures."""
    chunk_dir = directory / "chunks"
    chunk_dir.mkdir(exist_ok=True)
    rows = [f"NIR_CHUNKS_1\t{CHUNK_BYTES}"]
    prefix = "No One Is Real.app/"
    with zipfile.ZipFile(path) as archive:
        for entry in sorted(archive.infolist(), key=lambda item: item.filename):
            if entry.is_dir():
                continue
            relative = entry.filename.removeprefix(prefix)
            if not re.fullmatch(r"Contents/[A-Za-z0-9 ._+/\-]+", relative):
                raise ValueError(f"Unsupported incremental path {relative!r}")
            mode = (entry.external_attr >> 16) & 0o777
            if mode not in (0o644, 0o755):
                raise ValueError(f"Unsupported incremental permissions {mode:o}")
            data = archive.read(entry)
            count = (len(data) + CHUNK_BYTES - 1) // CHUNK_BYTES
            rows.append(f"F\t{relative}\t{mode:o}\t{len(data)}\t{hashlib.sha256(data).hexdigest()}\t{count}")
            for offset in range(0, len(data), CHUNK_BYTES):
                raw = data[offset:offset + CHUNK_BYTES]
                digest = hashlib.sha256(raw).hexdigest()
                compressed = gzip.compress(raw, compresslevel=6, mtime=0)
                name = f"chunk-{digest}.gz"
                (chunk_dir / name).write_bytes(compressed)
                rows.append(f"C\t{len(raw)}\t{digest}\t{len(compressed)}\t{hashlib.sha256(compressed).hexdigest()}")
    index = ("\n".join(rows) + "\n").encode()
    (directory / "chunk-index.tsv").write_bytes(index)
    return {"incremental_schema": 1, "index_sha256": hashlib.sha256(index).hexdigest(), "index_size": len(index)}


if __name__ == "__main__":
    directory, revision = pathlib.Path(sys.argv[1]), sys.argv[2]
    manifest = validate(directory / "NoOneIsReal-macos.zip", revision)
    manifest.update(write_chunks(directory / "NoOneIsReal-macos.zip", directory))
    (directory / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(manifest))
