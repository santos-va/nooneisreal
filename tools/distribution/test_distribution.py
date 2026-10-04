#!/usr/bin/env python3
"""Adversarial updater tests on Linux/macOS; OS services mocked, filesystem real.
These tests do not claim Gatekeeper, codesign or LaunchAgent acceptance on a Mac.
"""
import hashlib
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
update "$TEST_ROOT/feed"
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


if __name__ == '__main__':
    unittest.main(verbosity=2)
