// 매크로 키보드 실행기 (메뉴 막대에만 보이는 작은 백그라운드 앱)
// 빌드: app/build.sh  →  매크로 키보드/매크로 키보드 실행기.app
// 설정 앱이 저장한 launcher.json을 읽어서, 키보드가 보내는 F13~F20 키를 받으면 그 앱을 연다.
// Carbon 단축키(RegisterEventHotKey)를 써서 '손쉬운 사용' 권한 없이 동작한다.

import AppKit
import Carbon.HIToolbox
import ServiceManagement

struct LaunchItem: Codable {
    var key: String    // 예: "f13", "shift-f16"
    var app: String    // .app 경로
    var name: String
}

// 설정 도구 키 이름 → 맥 키 코드 (맥은 F20까지만 있다)
let fKeyCodes: [String: Int] = [
    "f13": kVK_F13, "f14": kVK_F14, "f15": kVK_F15, "f16": kVK_F16,
    "f17": kVK_F17, "f18": kVK_F18, "f19": kVK_F19, "f20": kVK_F20,
]

let baseURL = Bundle.main.bundleURL.deletingLastPathComponent()
let listURL = baseURL.appendingPathComponent("launcher.json")
let reloadNote = Notification.Name("com.ethan.macropad.reload")

// "ctrl-shift-f13" → (키 코드, Carbon 수정자)
func parse(_ key: String) -> (UInt32, UInt32)? {
    var mods: UInt32 = 0
    var code: Int?
    for part in key.split(separator: "-").map(String.init) {
        switch part {
        case "cmd": mods |= UInt32(cmdKey)
        case "shift": mods |= UInt32(shiftKey)
        case "alt": mods |= UInt32(optionKey)
        case "ctrl": mods |= UInt32(controlKey)
        default: code = fKeyCodes[part]
        }
    }
    guard let code else { return nil }
    return (UInt32(code), mods)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var refs: [EventHotKeyRef] = []
    var items: [LaunchItem] = []

    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "square.grid.3x3.fill", accessibilityDescription: "매크로 키보드 실행기")

        // 단축키가 눌리면 여기로 온다
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, user in
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            let me = Unmanaged<AppDelegate>.fromOpaque(user!).takeUnretainedValue()
            me.open(Int(id.id))
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)

        // 설정 앱이 저장하면 다시 읽는다
        DistributedNotificationCenter.default().addObserver(forName: reloadNote, object: nil, queue: .main) { [weak self] _ in
            self?.reload()
        }
        reload()
    }

    func reload() {
        refs.forEach { UnregisterEventHotKey($0) }
        refs = []
        items = (try? Data(contentsOf: listURL)).flatMap { try? JSONDecoder().decode([LaunchItem].self, from: $0) } ?? []
        var failed: [String] = []
        for (i, item) in items.enumerated() {
            guard let (code, mods) = parse(item.key) else { failed.append(item.key); continue }
            var ref: EventHotKeyRef?
            let id = EventHotKeyID(signature: OSType(0x4D504144), id: UInt32(i))   // 'MPAD'
            if RegisterEventHotKey(code, mods, id, GetApplicationEventTarget(), 0, &ref) == noErr, let ref {
                refs.append(ref)
            } else {
                failed.append(item.key)
            }
        }
        buildMenu(failed: failed)
    }

    func open(_ i: Int) {
        guard items.indices.contains(i) else { return }
        let url = URL(fileURLWithPath: items[i].app)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            if let error { NSLog("실행 실패 \(url.path): \(error.localizedDescription)") }
        }
    }

    func buildMenu(failed: [String]) {
        let menu = NSMenu()
        menu.addItem(withTitle: "매크로 키보드 실행기", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        if items.isEmpty {
            menu.addItem(withTitle: "연결된 앱 없음 (설정 앱에서 '앱 실행' 고르기)", action: nil, keyEquivalent: "")
        }
        for item in items {
            let mi = NSMenuItem(title: "\(item.key.uppercased())  →  \(item.name)", action: nil, keyEquivalent: "")
            let icon = NSWorkspace.shared.icon(forFile: item.app)
            icon.size = NSSize(width: 16, height: 16)
            mi.image = icon
            menu.addItem(mi)
        }
        if !failed.isEmpty {
            menu.addItem(withTitle: "⚠️ 등록 실패: \(failed.joined(separator: ", "))", action: nil, keyEquivalent: "")
        }
        menu.addItem(.separator())
        let login = NSMenuItem(title: "로그인할 때 자동으로 켜기", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        let r = NSMenuItem(title: "다시 읽기", action: #selector(reloadMenu), keyEquivalent: "r")
        r.target = self
        menu.addItem(r)
        menu.addItem(withTitle: "종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc func reloadMenu() { reload() }

    @objc func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch {
            let a = NSAlert()
            a.messageText = "자동 켜기 설정 실패"
            a.informativeText = error.localizedDescription + "\n시스템 설정 → 일반 → 로그인 항목에서 직접 추가할 수 있어요."
            a.runModal()
        }
        reload()
    }
}

@main
struct LauncherMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)   // Dock에 안 보이게
        app.run()
    }
}
