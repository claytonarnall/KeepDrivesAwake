# KeepDrivesAwake

Menu bar app that keeps selected external drives from spinning down.

This replaces the old Script Editor applet. That version ran `do shell script "touch …"` every 30 seconds, which made macOS ask for **Removable Volumes** access over and over. This app writes the keep-awake file **in-process** with `FileManager`, uses a stable bundle ID (`ca.arnall.KeepDrivesAwake`), and declares `NSRemovableVolumesUsageDescription`.

## Requirements

- macOS 14+
- Swift 6 (Xcode or Command Line Tools)

## Build

```sh
./scripts/package-app.sh
```

That writes `dist/KeepDrivesAwake.app`. Copy it to `/Applications` and open it.

Quit the old `/Applications/KeepDrivesAwake.app` (the AppleScript one) first so they do not fight over the same file.

## First launch

macOS should ask **once** for access to removable volumes. Allow it.

If it still loops:

1. System Settings → Privacy & Security → Files and Folders (or Removable Volumes)
2. Enable KeepDrivesAwake
3. Do not grant the old Script Editor applet instead of this app

## Config

`~/Library/Application Support/KeepDrivesAwake/config.json`

Created on first launch. Default:

```json
{
  "intervalSeconds" : 30,
  "touchFileName" : ".keep_drives_awake",
  "volumes" : [
    "/Volumes/Big Daddy"
  ]
}
```

Add more paths as needed. Do **not** add Time Machine volumes.

Menu bar: Ping now, Open log, Open config, Quit.

Log: `~/Library/Logs/KeepDrivesAwake.log`

The keep-awake file is **not** deleted on quit.

## Why not AppleScript

- Ad-hoc Script Editor identity (`AppletStub`) does not hold TCC
- `do shell script` is another process, so Allow often does not apply to the next `touch`
- Missing `NSRemovableVolumesUsageDescription`
