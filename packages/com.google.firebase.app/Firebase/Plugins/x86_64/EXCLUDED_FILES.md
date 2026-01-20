# Excluded Large Files

The following files exceed GitHub's 100MB file size limit and are excluded from this repository:

- `FirebaseCppApp-13_6_0.bundle` (186MB) - macOS desktop plugin
- `FirebaseCppApp-13_6_0.so` (119MB) - Linux desktop plugin

## Impact

**Mobile development (iOS/Android)**: Not affected. All mobile plugins are included.

**Desktop development (Windows)**: Not affected. The Windows DLL is under 100MB and included.

**Desktop development (macOS/Linux)**: These platforms require the excluded files.

## Workaround for macOS/Linux Desktop

If you need macOS or Linux desktop support, download the files manually:

1. Download from Google's registry:
   ```
   https://dl.google.com/games/registry/unity/com.google.firebase.app/com.google.firebase.app-13.6.0.tgz
   ```

2. Extract and copy the x86_64 files to:
   ```
   Packages/com.google.firebase.app/Firebase/Plugins/x86_64/
   ```

Or use the official Firebase Unity SDK installer instead of this UPM repository.
