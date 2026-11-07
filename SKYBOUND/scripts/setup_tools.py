"""Download pinned official tools into .tools; no system changes or SDKs."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import shutil
import subprocess
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def download(url, destination, expected, algorithm):
    if destination.exists() and hashlib.file_digest(destination.open('rb'), algorithm).hexdigest() == expected:
        return
    partial = destination.with_suffix(destination.suffix + '.part')
    try:
        with urllib.request.urlopen(url, timeout=120) as source, partial.open('wb') as output:
            shutil.copyfileobj(source, output)
        if hashlib.file_digest(partial.open('rb'), algorithm).hexdigest() != expected:
            raise RuntimeError('Artifact checksum mismatch: ' + destination.name)
        partial.replace(destination)
    finally:
        partial.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--software-renderer', action='store_true', help='Debian 13 amd64 only: portable Xvfb, Vulkan tools and Mesa')
    args = parser.parse_args()
    if platform.system() != 'Linux' or platform.machine() != 'x86_64':
        parser.error('This bootstrap is pinned for Linux x86_64. On Windows use an official Godot 4.7.2 console binary and --godot.')
    tools = ROOT / '.tools'
    tools.mkdir(exist_ok=True)
    manifest = json.loads((ROOT / 'scripts/toolchain.lock.json').read_text())
    package = manifest['godot']['linux_x86_64']
    archive = tools / Path(package['url']).name
    download(package['url'], archive, package['sha512'], 'sha512')
    target = tools / 'godot-4.7.2'
    target.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        for member in bundle.infolist():
            if not (target / member.filename).resolve().is_relative_to(target.resolve()):
                raise RuntimeError('Unsafe archive path')
        bundle.extractall(target)
    binary = target / 'Godot_v4.7.2-stable_linux.x86_64'
    binary.chmod(0o755)
    subprocess.run([str(binary), '--version'], check=True)
    if args.software_renderer:
        os_release = Path('/etc/os-release').read_text()
        if 'ID=debian' not in os_release or 'VERSION_ID="13"' not in os_release:
            parser.error('Portable graphics packages require Debian 13; dependencies are not installed automatically')
        folder = tools / 'portable/debs'
        folder.mkdir(parents=True, exist_ok=True)
        for package in manifest['optional_debian13_software_graphics']:
            archive = folder / Path(package['url']).name
            download(package['url'], archive, package['sha256'], 'sha256')
            subprocess.run(['dpkg-deb', '-x', str(archive), str(tools / 'portable/root')], check=True)
            print(package['name'], package['version'], 'verified and unpacked')
    print('No system programs installed. Binary:', binary)


if __name__ == '__main__':
    main()
