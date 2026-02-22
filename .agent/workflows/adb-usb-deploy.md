---
description: ADB USB deployment and screen casting for Flutter on Android
---

# ADB USB Deployment & Screen Casting

## Prerequisites
- Phone connected via USB with **USB Debugging** enabled
- ADB path: `C:\Users\jorge\AppData\Local\Android\sdk\platform-tools\adb.exe`
- scrcpy installed via winget (v3.3.4+)

## Step 1: Verify Device Connected
// turbo
```
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" devices -l
```
Expected output: your device serial number with `device` status (not `unauthorized`).

If it shows `unauthorized`: unlock your phone and tap **Allow** on the USB debugging prompt.

## Step 2: Run Flutter App on Phone
// turbo
```
flutter run -d ZLW8SSBMCEFIVGOV
```
Replace `ZLW8SSBMCEFIVGOV` with your device serial if it changes (check `flutter devices`).

## Step 3: Start Screen Casting (scrcpy)
Open a **new terminal** and run:
// turbo
```
scrcpy --serial ZLW8SSBMCEFIVGOV
```

### Useful scrcpy options:
| Flag | Effect |
|------|--------|
| `--max-size 1080` | Limit resolution |
| `--bit-rate 4M` | Limit bitrate |
| `--stay-awake` | Keep phone awake while casting |
| `--turn-screen-off` | Turn phone screen off while casting to PC |
| `--record screen.mp4` | Record to file |
| `--no-audio` | Disable audio mirroring |

### Full quality example:
```
scrcpy --serial ZLW8SSBMCEFIVGOV --stay-awake --max-size 1920
```

## Step 4 (Optional): Add ADB to PATH permanently
Run this once in PowerShell:
```powershell
$p = "$env:LOCALAPPDATA\Android\sdk\platform-tools"
$cur = [System.Environment]::GetEnvironmentVariable('Path','User')
if ($cur -notlike "*platform-tools*") {
    [System.Environment]::SetEnvironmentVariable('Path', "$cur;$p", 'User')
}
```
Then restart your terminal. After that you can run `adb` directly.

## Troubleshooting
- **Device shows `unauthorized`**: On the phone, revoke USB debugging authorizations in Developer Options and reconnect.
- **Device not found**: Try a different USB cable or port. Some cables are charge-only.
- **scrcpy fails**: Ensure the phone screen is unlocked when launching scrcpy.
