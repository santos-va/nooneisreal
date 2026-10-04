#!/usr/bin/env python3
"""Adversarial updater tests on Linux/macOS; OS services mocked, filesystem real.
These tests do not claim Gatekeeper, codesign or LaunchAgent acceptance on a Mac.
"""
import gzip
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import unittest
import zipfile

SCRIPT = Path(__file__).with_name('update-macos.sh').resolve()
APP_NAME = 'No One Is Real.app'
OLD = '1' * 40
NEW = '2' * 40

HELPER = '''import json, os, plistlib, sys
mode, path, key = sys.argv[1:]
if mode == "json": print(json.load(open(path))[key])
elif mode == "plist": print(plistlib.load(open(path + "/Contents/Info.plist", "rb"))[key])
elif mode == "stat": print(os.stat(path).st_size if key == "%z" else int(os.stat(path).st_mtime))
'''
MOCKS = r'''
source "$TEST_SCRIPT"
APP="$TEST_ROOT/Applications/$APP_NAME"
STATE_DIR="$TEST_ROOT/User Data/Updater"
uname() { echo Darwin; }
running() { [ -f "$TEST_ROOT/game-running" ]; }
field() { "$TEST_PY" "$TEST_ROOT/helper.py" json "$1" "$2"; }
bundle_field() { "$TEST_PY" "$TEST_ROOT/helper.py" plist "$1" "$2"; }
stat() { "$TEST_PY" "$TEST_ROOT/helper.py" stat "$3" "$2"; }
codesign() { [ "${TEST_BAD_SIGNATURE:-}" != yes ]; }
lipo() { echo 'x86_64 arm64'; }
ditto() {
    touch "$TEST_ROOT/extractor-ran"
    unzip -q "$3" -d "$4"
    if [ "${TEST_START_GAME:-}" = yes ]; then touch "$TEST_ROOT/game-running"; fi
}
mv() {
    if [ "${TEST_FAIL_SWAP:-}" = yes ] && [[ "$2" = */extracted/* ]]; then return 1; fi
    if [ "${TEST_FAIL_RESTORE:-}" = yes ] && [[ "$2" = *.previous.app ]]; then return 1; fi
    command mv "$@"
    if [ "${TEST_INTERRUPT:-}" = yes ] && [ "$2" = "$APP" ]; then kill -TERM $$; fi
}
fetch() {
    local name="${1##*/}" source="$TEST_ROOT/feed/${1##*/}"
    if [[ "$name" = chunk-*.gz ]]; then source="$TEST_ROOT/feed/chunks/$name"; fi
    printf '%s\n' "$name" >> "$TEST_ROOT/downloads"
    cp "$source" "$2"
}
if [ "${TEST_NETWORK:-}" = yes ]; then update; else update "$TEST_ROOT/feed"; fi
'''


def metadata(revision=NEW, bundle='com.santos.nooneisreal'):
    return {'CFBundleIdentifier': bundle, 'CFBundleExecutable': 'No One Is Real', 'NIRBuildRevision': revision}


class DistributionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='nir updater test ')
        self.root = Path(self.temp.name)
        self.feed = self.root / 'feed'
        self.feed.mkdir()
        self.apps = self.root / 'Applications'
        self.apps.mkdir()
        self.app = self.apps / APP_NAME
        self.backup = self.apps / '.No One Is Real.previous.app'
        (self.root / 'helper.py').write_text(HELPER)
        self.make_app(self.app, OLD)
        (self.root / 'saves').write_text('player settings and NPC memory')
        self.make_zip()

    def tearDown(self):
        self.temp.cleanup()

    def make_app(self, path, revision):
        (path / 'Contents/MacOS').mkdir(parents=True)
        (path / 'Contents/Info.plist').write_bytes(plistlib.dumps(metadata(revision)))
        executable = path / 'Contents/MacOS/No One Is Real'
        executable.write_text('fixture executable')
        executable.chmod(0o755)

    def make_zip(self, extras=(), revision=NEW, bundle='com.santos.nooneisreal', many=False):
        archive = self.feed / 'NoOneIsReal-macos.zip'
        with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
            for name, mode, data in extras:
                entry = zipfile.ZipInfo(name)
                entry.create_system = 3
                entry.external_attr = mode << 16
                z.writestr(entry, data)
            z.writestr(APP_NAME + '/Contents/Info.plist', plistlib.dumps(metadata(revision, bundle)))
            entry = zipfile.ZipInfo(APP_NAME + '/Contents/MacOS/No One Is Real')
            entry.create_system = 3
            entry.external_attr = (stat.S_IFREG | 0o755) << 16
            z.writestr(entry, b'fixture executable')
            if many:
                for i in range(20000):
                    z.writestr(f'{APP_NAME}/Contents/Resources/{i}', b'x')
        self.manifest = {'schema': 1, 'revision': NEW, 'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(), 'size': archive.stat().st_size}
        self.write_manifest()

    def write_manifest(self):
        (self.feed / 'manifest.json').write_text(json.dumps(self.manifest))

    def run_update(self, **flags):
        env = dict(os.environ, TEST_SCRIPT=str(SCRIPT), TEST_ROOT=str(self.root), TEST_PY=sys.executable, **flags)
        result = subprocess.run(['/bin/bash', '-c', MOCKS], env=env, capture_output=True, text=True)
        self.assertEqual((self.root / 'saves').read_text(), 'player settings and NPC memory')
        return result

    def current(self, app=None):
        return plistlib.loads(((app or self.app) / 'Contents/Info.plist').read_bytes())['NIRBuildRevision']

    def test_success_and_backup(self):
        result = self.run_update()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.current(), NEW)
        self.assertEqual(self.current(self.backup), OLD)
        self.assertFalse(list(self.apps.glob('.nooneisreal-update.*')))

    def test_current_revision_skips_extraction(self):
        (self.app / 'Contents/Info.plist').write_bytes(plistlib.dumps(metadata(NEW)))
        self.assertEqual(self.run_update().returncode, 0)
        self.assertFalse((self.root / 'extractor-ran').exists())

    def test_checksum_failure_preserves_app(self):
        self.manifest['sha256'] = 'f' * 64
        self.write_manifest()
        self.assertNotEqual(self.run_update().returncode, 0)
        self.assertEqual(self.current(), OLD)
        self.assertFalse((self.root / 'extractor-ran').exists())

    def test_manifest_rejects_url_like_revision(self):
        self.manifest['revision'] = '../bad'
        self.write_manifest()
        self.assertNotEqual(self.run_update().returncode, 0)
        self.assertEqual(self.current(), OLD)

    def test_archive_size_mismatch(self):
        self.manifest['size'] += 1
        self.write_manifest()
        self.assertNotEqual(self.run_update().returncode, 0)
        self.assertFalse((self.root / 'extractor-ran').exists())

    def test_archive_paths_and_symlinks(self):
        for name, mode, data in [
            ('../escape', stat.S_IFREG | 0o644, b'x'),
            ('/tmp/escape', stat.S_IFREG | 0o644, b'x'),
            (APP_NAME + '/../escape', stat.S_IFREG | 0o644, b'x'),
            (APP_NAME + '/Contents/link', stat.S_IFLNK | 0o777, b'../../../../tmp/escape'),
            (APP_NAME + '/Contents/pipe', stat.S_IFIFO | 0o600, b''),
            (APP_NAME + '/Contents/a\nb', stat.S_IFREG | 0o644, b'x'),
            (APP_NAME + '/Contents/a\\b', stat.S_IFREG | 0o644, b'x'),
        ]:
            with self.subTest(name=name):
                self.make_zip([(name, mode, data)])
                self.assertNotEqual(self.run_update().returncode, 0)
                self.assertEqual(self.current(), OLD)
                self.assertFalse((self.root / 'extractor-ran').exists())

    def test_large_symlink_archive_cannot_hide_behind_sigpipe(self):
        self.make_zip([(APP_NAME + '/Contents/link', stat.S_IFLNK | 0o777, b'../../../../tmp/escape')], many=True)
        result = self.run_update()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse((self.root / 'extractor-ran').exists())

    def test_invalid_bundle_signature_and_revision(self):
        for kwargs, flags in [({'bundle': 'other.app'}, {}), ({'revision': OLD}, {}), ({}, {'TEST_BAD_SIGNATURE': 'yes'})]:
            with self.subTest(kwargs=kwargs, flags=flags):
                self.make_zip(**kwargs)
                self.assertNotEqual(self.run_update(**flags).returncode, 0)
                self.assertEqual(self.current(), OLD)

    def test_running_game_defers_before_and_after_download(self):
        (self.root / 'game-running').touch()
        self.assertEqual(self.run_update().returncode, 0)
        self.assertFalse((self.root / 'extractor-ran').exists())
        (self.root / 'game-running').unlink()
        self.assertEqual(self.run_update(TEST_START_GAME='yes').returncode, 0)
        self.assertEqual(self.current(), OLD)

    def test_swap_failure_rolls_back(self):
        self.assertNotEqual(self.run_update(TEST_FAIL_SWAP='yes').returncode, 0)
        self.assertEqual(self.current(), OLD)

    def test_signal_between_renames_restores_prior_app(self):
        self.assertNotEqual(self.run_update(TEST_INTERRUPT='yes').returncode, 0)
        self.assertEqual(self.current(), OLD)

    def test_failed_rollback_retains_both_backup_and_stage(self):
        self.assertNotEqual(self.run_update(TEST_FAIL_SWAP='yes', TEST_FAIL_RESTORE='yes').returncode, 0)
        self.assertEqual(self.current(self.backup), OLD)
        self.assertTrue(list(self.apps.glob('.nooneisreal-update.*/extracted/' + APP_NAME)))

    def test_next_run_recovers_kill9_gap(self):
        self.app.rename(self.backup)
        self.assertEqual(self.run_update().returncode, 0)
        self.assertEqual(self.current(), NEW)
        self.assertEqual(self.current(self.backup), OLD)

    def test_old_empty_lock_recovers_and_new_lock_defers(self):
        lock = self.root / 'User Data/Updater/lock'
        lock.mkdir(parents=True)
        self.assertEqual(self.run_update().returncode, 0)
        self.assertEqual(self.current(), OLD)
        os.utime(lock, (time.time() - 600, time.time() - 600))
        self.assertEqual(self.run_update().returncode, 0)
        self.assertEqual(self.current(), NEW)


    def incremental_feed(self):
        spec = importlib.util.spec_from_file_location('mac_package', SCRIPT.with_name('package-macos.py'))
        package = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(package)
        self.old_binary = b'A' * package.CHUNK_BYTES + b'B' * package.CHUNK_BYTES + b'old signature'
        self.new_binary = self.old_binary[:-13] + b'new signature'
        self.old_pck = b'C' * package.CHUNK_BYTES + b'old scene'
        self.new_pck = self.old_pck[:-9] + b'new scene'
        (self.app / 'Contents/MacOS/No One Is Real').write_bytes(self.old_binary)
        resources = self.app / 'Contents/Resources'
        resources.mkdir()
        (resources / 'No One Is Real.pck').write_bytes(self.old_pck)
        (resources / 'removed.txt').write_text('removed in target')
        entries = {
            'Contents/Info.plist': (plistlib.dumps(metadata(NEW)), 0o644),
            'Contents/MacOS/No One Is Real': (self.new_binary, 0o755),
            'Contents/Resources/No One Is Real.pck': (self.new_pck, 0o644),
        }
        archive = self.feed / 'NoOneIsReal-macos.zip'
        with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
            for path, (data, mode) in entries.items():
                item = zipfile.ZipInfo(APP_NAME + '/' + path)
                item.create_system = 3
                item.external_attr = (stat.S_IFREG | mode) << 16
                item.compress_type = zipfile.ZIP_DEFLATED
                z.writestr(item, data)
        self.manifest['sha256'] = hashlib.sha256(archive.read_bytes()).hexdigest()
        self.manifest['size'] = archive.stat().st_size
        self.manifest.update(package.write_chunks(archive, self.feed))
        self.write_manifest()

    def rewrite_index(self, text):
        index = text.encode()
        (self.feed / 'chunk-index.tsv').write_bytes(index)
        self.manifest['index_sha256'] = hashlib.sha256(index).hexdigest()
        self.manifest['index_size'] = len(index)
        self.write_manifest()

    def test_incremental_reuses_engine_and_content_blocks_exactly(self):
        self.incremental_feed()
        result = self.run_update(TEST_NETWORK='yes')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.app / 'Contents/MacOS/No One Is Real').read_bytes(), self.new_binary)
        self.assertEqual((self.app / 'Contents/Resources/No One Is Real.pck').read_bytes(), self.new_pck)
        self.assertFalse((self.app / 'Contents/Resources/removed.txt').exists())
        fetched = (self.root / 'downloads').read_text().splitlines()
        self.assertNotIn('NoOneIsReal-macos.zip', fetched)
        chunks = [name for name in fetched if name.startswith('chunk-') and name.endswith('.gz')]
        self.assertEqual(len(chunks), 3)  # Metadata and two small changed tails.
        fetched_bytes = sum((self.feed / 'chunks' / name).stat().st_size for name in chunks)
        self.assertLess(fetched_bytes, self.manifest['size'] // 2)
        self.assertIn(f'downloaded {fetched_bytes} bytes', result.stdout)
        self.assertIn('reused 3 chunks', result.stdout)
        # Already-current check does not fetch even the index again.
        (self.root / 'downloads').unlink()
        self.assertEqual(self.run_update(TEST_NETWORK='yes').returncode, 0)
        self.assertEqual((self.root / 'downloads').read_text().splitlines(), ['manifest.json'])

    def test_incremental_offline_uses_complete_archive_without_network(self):
        self.incremental_feed()
        result = self.run_update()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse((self.root / 'downloads').exists())
        self.assertEqual(self.current(), NEW)

    def test_incremental_index_rejects_unsafe_and_casefold_paths(self):
        self.incremental_feed()
        original = (self.feed / 'chunk-index.tsv').read_text()
        rows = original.splitlines()
        f_index = next(i for i, row in enumerate(rows) if row.startswith('F\tContents/Info.plist\t'))
        metadata_rows = rows[f_index:f_index + 2]
        bad_indexes = [
            original.replace('Contents/Info.plist', 'Contents/../Info.plist'),
            original.replace('\t644\t', '\t4755\t', 1),
            original.replace('\t644\t', '\t0644\t', 1),
            original.replace('\t755\t', '\t755\t0', 1),
            original + '\n'.join(metadata_rows) + '\n',
            original + '\n'.join(row.replace('Contents/Info.plist', 'Contents/info.plist') for row in metadata_rows) + '\n',
            original + '\n'.join(row.replace('Contents/Info.plist', 'Contents/INFO.PLIST/child') for row in metadata_rows) + '\n',
            original + 'EXTRA\n',
            '\n'.join(rows[:-1]) + '\n',
        ]
        for bad in bad_indexes:
            with self.subTest(index=bad[:90]):
                self.rewrite_index(bad)
                result = self.run_update(TEST_NETWORK='yes')
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.current(), OLD)
                downloads = (self.root / 'downloads').read_text().splitlines()
                self.assertFalse(any(name.endswith('.gz') for name in downloads))

    def test_incremental_corrupt_missing_and_short_chunks_preserve_app(self):
        self.incremental_feed()
        index = (self.feed / 'chunk-index.tsv').read_text()
        # Info.plist is the first changed payload and cannot be reused from OLD.
        row = next(line.split('\t') for line in index.splitlines() if line.startswith('C\t'))
        chunk = self.feed / 'chunks' / ('chunk-' + row[2] + '.gz')
        original = chunk.read_bytes()
        chunk.write_bytes(original[:-1])
        self.assertNotEqual(self.run_update(TEST_NETWORK='yes').returncode, 0)
        self.assertEqual(self.current(), OLD)
        chunk.unlink()
        self.assertNotEqual(self.run_update(TEST_NETWORK='yes').returncode, 0)
        self.assertEqual(self.current(), OLD)
        # Correct compressed hash but wrong decompressed body must also fail.
        changed = gzip.compress(b'short', mtime=0)
        chunk.write_bytes(changed)
        bad_row = row[:]
        bad_row[3] = str(len(changed))
        bad_row[4] = hashlib.sha256(changed).hexdigest()
        self.rewrite_index(index.replace('\t'.join(row), '\t'.join(bad_row), 1))
        self.assertNotEqual(self.run_update(TEST_NETWORK='yes').returncode, 0)
        self.assertEqual(self.current(), OLD)

    def test_incremental_missing_index_preserves_app(self):
        self.incremental_feed()
        (self.feed / 'chunk-index.tsv').unlink()
        self.assertNotEqual(self.run_update(TEST_NETWORK='yes').returncode, 0)
        self.assertEqual(self.current(), OLD)

    def test_incremental_last_row_without_newline_is_processed(self):
        self.incremental_feed()
        self.rewrite_index((self.feed / 'chunk-index.tsv').read_text().rstrip('\n'))
        result = self.run_update(TEST_NETWORK='yes')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.app / 'Contents/Resources/No One Is Real.pck').read_bytes(), self.new_pck)


    def test_enable_updates_registers_existing_app_without_network(self):
        bootstrap = self.root / 'bootstrap with spaces'
        bootstrap.mkdir()
        shutil.copy2(SCRIPT, bootstrap / 'update-macos.sh')
        wrapper = bootstrap / 'run.sh'
        setup = MOCKS[:MOCKS.index('if [ "${TEST_NETWORK:-}"')]
        setup += r'''
AGENT="$TEST_ROOT/Launch Agents/com.santos.nooneisreal.update.plist"
plutil() {
    local destination="${@: -1}"
    if [ "$1" = -create ]; then : > "$destination"; else printf '%s\n' "$*" >> "$destination"; fi
}
launchctl() { printf '%s\n' "$*" >> "$TEST_ROOT/registrations"; }
open() { echo 'Unexpected app launch' >&2; return 1; }
install_agent --enable-only
'''
        wrapper.write_text(setup)
        env = dict(os.environ, TEST_SCRIPT=str(SCRIPT), TEST_ROOT=str(self.root), TEST_PY=sys.executable)
        result = subprocess.run(['/bin/bash', str(wrapper)], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse((self.root / 'downloads').exists())
        installed = self.root / 'User Data/Updater/update-macos.sh'
        self.assertEqual(installed.read_bytes(), SCRIPT.read_bytes())
        self.assertEqual(stat.S_IMODE(installed.stat().st_mode), 0o700)
        self.assertIn('bootstrap gui/', (self.root / 'registrations').read_text())
        self.assertIn(OLD, result.stdout)
        self.assertEqual(self.current(), OLD)

    def test_first_install_offline_registers_and_opens_app(self):
        shutil.rmtree(self.app)
        shutil.copy2(SCRIPT, self.feed / 'update-macos.sh')
        wrapper = self.feed / 'run.sh'
        setup = MOCKS[:MOCKS.index('if [ "${TEST_NETWORK:-}"')]
        setup += r'''
AGENT="$TEST_ROOT/Launch Agents/com.santos.nooneisreal.update.plist"
plutil() {
    local destination="${@: -1}"
    if [ "$1" = -create ]; then : > "$destination"; else printf '%s\n' "$*" >> "$destination"; fi
}
launchctl() { printf '%s\n' "$*" >> "$TEST_ROOT/registrations"; }
open() { printf '%s\n' "$1" > "$TEST_ROOT/opened"; }
fetch() { echo 'Unexpected network request' >&2; return 1; }
install_agent
'''
        wrapper.write_text(setup)
        env = dict(os.environ, TEST_SCRIPT=str(SCRIPT), TEST_ROOT=str(self.root), TEST_PY=sys.executable)
        result = subprocess.run(['/bin/bash', str(wrapper)], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.current(), NEW)
        self.assertIn('bootstrap gui/', (self.root / 'registrations').read_text())
        self.assertEqual((self.root / 'opened').read_text().strip(), str(self.app))
        self.assertEqual((self.root / 'User Data/Updater/update-macos.sh').read_bytes(), SCRIPT.read_bytes())

    def test_local_builder_uses_pinned_commit_without_touching_checkout(self):
        repo = self.root / 'repo with spaces'
        (repo / 'game').mkdir(parents=True)
        (repo / 'tools/distribution').mkdir(parents=True)
        (repo / 'game/project.godot').write_text('committed project')
        preset = SCRIPT.parents[2] / 'game/export_presets.cfg'
        shutil.copy2(preset, repo / 'game/export_presets.cfg')
        # Boundary stub verifies the real builder supplies its offline installer inputs.
        (repo / 'tools/distribution/update-macos.sh').write_text(r'''
set -eu
[ "$1" = --install ]
dir=$(dirname "$0")
[ -s "$dir/NoOneIsReal-macos.zip" ]
cp "$dir/manifest.json" "$TEST_ROOT/built-manifest.json"
''')
        def git(*args):
            return subprocess.check_output(['git', '-C', str(repo), *args], text=True).strip()
        git('init', '-q'); git('add', '.')
        git('-c', 'user.name=Test', '-c', 'user.email=test@example.com', 'commit', '-qm', 'Fixture')
        revision = git('rev-parse', 'HEAD')
        (repo / 'game/project.godot').write_text('uncommitted user edits')
        home = self.root / 'Mac Home'
        template = home / 'Library/Application Support/Godot/export_templates/4.7.stable/macos.zip'
        template.parent.mkdir(parents=True); template.write_bytes(b'fixture template')
        fake_godot = self.root / 'godot fixture'
        fake_godot.write_text(r'''#!/bin/bash
if [ "$1" = --version ]; then echo 4.7.stable.fixture; exit; fi
[ "$(cat "$3/project.godot")" = 'committed project' ] || exit 2
grep -F "$TEST_REVISION" "$3/export_presets.cfg" >/dev/null || exit 3
if [ "$4" = --export-release ]; then printf 'export fixture' > "$6"; fi
'''); fake_godot.chmod(0o755)
        helper = self.root / 'native_mock.py'
        helper.write_text("""import json,sys,os
args=sys.argv[1:]
if args[0]=='stat': print(os.stat(args[-1]).st_size)
elif args[0]=='-create': open(args[-1],'w').write('{}')
elif args[0]=='-insert':
 p=args[-1]; d=json.load(open(p)); d[args[1]]=int(args[3]) if args[2]=='-integer' else args[3]; json.dump(d,open(p,'w'))
""")
        script = self.root / 'local-installer.sh'
        script.write_text(SCRIPT.with_name('install-local-macos.sh').read_text().replace('[ -w /Applications ]', '[ -w "$TEST_ROOT/Applications" ]'))
        command = r'''
uname() { echo Darwin; }; pgrep() { return 1; }
plutil() { "$TEST_PY" "$TEST_ROOT/native_mock.py" "$@"; }
stat() { "$TEST_PY" "$TEST_ROOT/native_mock.py" stat "$@"; }
export -f uname pgrep plutil stat
/bin/bash "$TEST_ROOT/local-installer.sh" "$TEST_REPO" "$TEST_REVISION"
'''
        env = dict(os.environ, HOME=str(home), TEST_ROOT=str(self.root), TEST_PY=sys.executable,
                   TEST_REPO=str(repo), TEST_REVISION=revision, GODOT_BIN=str(fake_godot))
        result = subprocess.run(['/bin/bash', '-c', command], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        manifest = json.loads((self.root / 'built-manifest.json').read_text())
        self.assertEqual(manifest['revision'], revision)
        self.assertEqual(manifest['sha256'], hashlib.sha256(b'export fixture').hexdigest())
        self.assertEqual((repo / 'game/project.godot').read_text(), 'uncommitted user edits')
        self.assertEqual(git('status', '--porcelain'), 'M game/project.godot')


if __name__ == '__main__':
    unittest.main(verbosity=2)
