# AX-KEY12 MacroPad for macOS

A small macOS setup for the cheap **AX-KEY12** macro pad (12 keys + 2 knobs, USB `1189:8840`), whose official configuration software only runs on Windows.

윈도우 전용 설정 프로그램 없이 맥에서 AX-KEY12 매크로 키보드(12키 + 노브 2개)를 설정하는 앱입니다.

## What's inside

| | |
|---|---|
| `app/MacroPad.swift` | SwiftUI settings app: click a key or knob, set its name and action (type it, record a shortcut, or pick from a list), then upload it to the keyboard |
| `app/Launcher.swift` | Menu-bar helper: lets a key open an app, like a Stream Deck. Keys are mapped to F13–F20, and the helper listens for them with Carbon hot keys (no Accessibility permission needed) |
| `app/make-icon.swift` | Draws the app icon |
| `app/build.sh` | Builds both apps next to the repo root |
| `mapping.yaml`, `keyboard.json` | My current 3-layer layout (coding / editing / media) |
| `사용법.md` | Usage notes and the full layout table (Korean) |

## Requirements

- macOS 14+, Xcode command line tools (`swiftc`)
- `brew install libusb`
- [ch57x-keyboard-tool](https://github.com/kriomant/ch57x-keyboard-tool) (MIT) by kriomant — download the macOS release and put the binary at `tool/ch57x-keyboard-tool`. It is not included in this repo.

## Build & use

```bash
cd app && ./build.sh
open "../매크로 키보드 설정.app"
```

- Plug the keyboard into a **data-capable** USB port on the Mac itself (some hub USB-C ports only charge).
- Uploading needs administrator rights (libusb on macOS), so the app asks for your password each time.
- For app-launch keys, keep **매크로 키보드 실행기.app** running (it can start at login from its menu).
