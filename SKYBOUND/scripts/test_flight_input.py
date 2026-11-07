"""Exercise real X11 keyboard events against the visible flight scene on Linux."""
import ctypes
import ctypes.util
import os
from pathlib import Path
import selectors
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / '.tools'
BINARY = TOOLS / 'godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'
PORTABLE = TOOLS / 'portable/root'


def main():
    if sys.platform != 'linux':
        print('X11 input check requires Linux', file=sys.stderr)
        return 2
    import tempfile
    with tempfile.TemporaryDirectory(prefix='skybound-flight-input-') as directory:
        output = Path(directory)
        runtime = output / 'runtime'
        runtime.mkdir(mode=0o700)
        env = os.environ.copy()
        env.update({'XDG_RUNTIME_DIR': str(runtime), 'XDG_DATA_HOME': str(TOOLS / 'flight-data'),
                    'XDG_CONFIG_HOME': str(TOOLS / 'flight-config'), 'XDG_CACHE_HOME': str(TOOLS / 'flight-cache'),
                    'VK_DRIVER_FILES': str(PORTABLE / 'usr/share/vulkan/icd.d/lvp_icd.json'),
                    'LD_LIBRARY_PATH': str(PORTABLE / 'usr/lib/x86_64-linux-gnu') + (os.pathsep + env['LD_LIBRARY_PATH'] if env.get('LD_LIBRARY_PATH') else ''),
                    'SKYBOUND_FLIGHT_INPUT_TEST': '1'})
        with (output / 'xvfb.log').open('w') as xlog, (output / 'flight.log').open('w') as log:
            server = subprocess.Popen([str(PORTABLE / 'usr/bin/Xvfb'), '-displayfd', '1', '-screen', '0', '1920x1080x24', '-nolisten', 'tcp', '-ac'], stdout=subprocess.PIPE, stderr=xlog, env=env)
            game = None
            display = None
            try:
                with selectors.DefaultSelector() as selector:
                    selector.register(server.stdout, selectors.EVENT_READ)
                    if not selector.select(timeout=15):
                        raise RuntimeError('Xvfb readiness timeout')
                number = server.stdout.readline().decode().strip()
                if not number.isdecimal():
                    raise RuntimeError('No X display number')
                env['DISPLAY'] = ':' + number
                command = [str(BINARY), '--display-driver', 'x11', '--audio-driver', 'Dummy', '--fixed-fps', '60', '--path', str(ROOT / 'benchmarks/godot'), '--rendering-method', 'forward_plus', '--rendering-driver', 'vulkan', 'res://flight/flight.tscn']
                game = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, env=env)
                x11 = ctypes.CDLL(ctypes.util.find_library('X11'))
                xtest = ctypes.CDLL(ctypes.util.find_library('Xtst'))
                x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
                x11.XOpenDisplay.restype = ctypes.c_void_p
                x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
                x11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
                x11.XDefaultRootWindow.restype = ctypes.c_ulong
                x11.XQueryTree.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.POINTER(ctypes.c_ulong)), ctypes.POINTER(ctypes.c_uint)]
                x11.XFetchName.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.POINTER(ctypes.c_void_p)]
                x11.XFree.argtypes = [ctypes.c_void_p]
                x11.XSetInputFocus.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int, ctypes.c_ulong]
                x11.XStringToKeysym.argtypes = [ctypes.c_char_p]
                x11.XStringToKeysym.restype = ctypes.c_ulong
                x11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
                x11.XKeysymToKeycode.restype = ctypes.c_uint
                x11.XFlush.argtypes = [ctypes.c_void_p]
                xtest.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
                display = x11.XOpenDisplay(env['DISPLAY'].encode())
                if not display:
                    raise RuntimeError('Cannot open X display')
                deadline = time.monotonic() + 90
                window = None
                while time.monotonic() < deadline and game.poll() is None:
                    text = (output / 'flight.log').read_text(errors='replace')
                    if 'ERROR:' in text:
                        raise RuntimeError('Flight startup error: ' + text[-1500:])
                    root = x11.XDefaultRootWindow(display)
                    root_return, parent = ctypes.c_ulong(), ctypes.c_ulong()
                    children = ctypes.POINTER(ctypes.c_ulong)()
                    count = ctypes.c_uint()
                    if x11.XQueryTree(display, root, ctypes.byref(root_return), ctypes.byref(parent), ctypes.byref(children), ctypes.byref(count)):
                        for index in range(count.value):
                            name = ctypes.c_void_p()
                            if x11.XFetchName(display, children[index], ctypes.byref(name)) and name.value:
                                title = ctypes.string_at(name).decode(errors='replace')
                                x11.XFree(name)
                                if 'SKYBOUND' in title:
                                    window = children[index]
                                    break
                        if children:
                            x11.XFree(children)
                    if window and 'FLIGHT_READY ' in text:
                        break
                    time.sleep(0.05)
                if not window:
                    raise RuntimeError('Flight window did not become ready')
                x11.XSetInputFocus(display, window, 1, 0)
                s_key = x11.XKeysymToKeycode(display, x11.XStringToKeysym(b's'))
                c_key = x11.XKeysymToKeycode(display, x11.XStringToKeysym(b'c'))
                if not s_key or not c_key:
                    raise RuntimeError('Cannot map keyboard keys')
                xtest.XTestFakeKeyEvent(display, s_key, 1, 0)
                x11.XFlush(display)
                while time.monotonic() < deadline and game.poll() is None:
                    if 'FLIGHT_KEY_RESPONSE pitch_up' in (output / 'flight.log').read_text(errors='replace'):
                        break
                    time.sleep(0.05)
                else:
                    raise RuntimeError('Pitch key did not change the aircraft attitude')
                xtest.XTestFakeKeyEvent(display, s_key, 0, 0)
                xtest.XTestFakeKeyEvent(display, c_key, 1, 0)
                xtest.XTestFakeKeyEvent(display, c_key, 0, 0)
                x11.XFlush(display)
                result = game.wait(timeout=max(1, deadline - time.monotonic()))
                text = (output / 'flight.log').read_text(errors='replace')
                if result or 'ERROR:' in text or 'FLIGHT_INPUT_TEST_PASS' not in text:
                    raise RuntimeError('Real input test failed: ' + text[-1500:])
                print('FLIGHT_X11_INPUT_TEST_PASS: physical S pitches up; C switches camera')
                return 0
            finally:
                if display:
                    x11.XCloseDisplay(display)
                if game is not None and game.poll() is None:
                    game.terminate()
                    try:
                        game.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        game.kill()
                        game.wait()
                server.terminate()
                try:
                    server.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait()


if __name__ == '__main__':
    raise SystemExit(main())
