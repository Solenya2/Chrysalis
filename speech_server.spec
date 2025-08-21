# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['speech_server.py'],
    pathex=[],
    binaries=[('/home/noro/vosk_buildenv/lib/python3.12/site-packages/vosk/libvosk.so', 'vosk')],
    datas=[('/home/noro/Downloads/Chrysalis/vosk_models/vosk-model-small-en-us-0.15', 'vosk_models/vosk-model-small-en-us-0.15')],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='speech_server',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
