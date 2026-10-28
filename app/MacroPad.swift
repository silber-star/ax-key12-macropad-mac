// 매크로 키보드 설정 앱
// 빌드: app/build.sh  →  매크로 키보드/매크로 키보드 설정.app
// 앱은 자기 옆(매크로 키보드 폴더)의 keyboard.json, mapping.yaml, tool/ 을 쓴다.

import SwiftUI
import AppKit

// MARK: - 데이터

struct KeyAction: Codable, Equatable {
    var action: String
    var label: String
    var app: String? = nil   // 앱 실행 키면 .app 경로 (action은 F13 같은 키, 실행기 앱이 받아서 연다)
}

struct Knob: Codable, Equatable {
    var ccw: KeyAction
    var press: KeyAction
    var cw: KeyAction
}

struct Layer: Codable, Equatable {
    var name: String
    var buttons: [[KeyAction]]   // 3줄 × 4칸
    var knobs: [Knob]          // 위 노브, 아래 노브
}

struct Config: Codable, Equatable {
    var layers: [Layer]
}

enum KnobPart: String, CaseIterable { case ccw, press, cw }

enum Slot: Hashable {
    case button(Int, Int)
    case knob(Int, KnobPart)
}

func b(_ action: String, _ label: String) -> KeyAction { KeyAction(action: action, label: label) }

// 지금 키보드에 올라가 있는 배치 (mapping.yaml과 같음)
let defaultConfig = Config(layers: [
    Layer(name: "코딩", buttons: [
        [b("cmd-p", "파일 찾기"), b("cmd-shift-p", "명령 팔레트"), b("cmd-b", "사이드바"), b("ctrl-grave", "터미널")],
        [b("cmd-slash", "주석"), b("alt-shift-f", "코드 정리"), b("f12", "정의로 이동"), b("cmd-d", "같은 단어 선택")],
        [b("cmd-c", "복사"), b("cmd-v", "붙여넣기"), b("alt-up", "줄 위로"), b("alt-down", "줄 아래로")],
    ], knobs: [
        Knob(ccw: b("cmd-minus", "축소"), press: b("cmd-0", "원래 크기"), cw: b("cmd-equal", "확대")),
        Knob(ccw: b("cmd-z", "실행 취소"), press: b("cmd-s", "저장"), cw: b("cmd-shift-z", "다시 실행")),
    ]),
    Layer(name: "편집", buttons: [
        [b("cmd-c", "복사"), b("cmd-v", "붙여넣기"), b("cmd-x", "잘라내기"), b("cmd-a", "전체 선택")],
        [b("cmd-z", "실행 취소"), b("cmd-shift-z", "다시 실행"), b("cmd-s", "저장"), b("cmd-f", "찾기")],
        [b("cmd-shift-4", "영역 캡처"), b("cmd-shift-5", "화면 녹화"), b("cmd-t", "새 탭"), b("cmd-tab", "직전 앱")],
    ], knobs: [
        Knob(ccw: b("cmd-minus", "축소"), press: b("cmd-0", "원래 크기"), cw: b("cmd-equal", "확대")),
        Knob(ccw: b("left", "프레임 뒤로"), press: b("space", "재생/정지"), cw: b("right", "프레임 앞으로")),
    ]),
    Layer(name: "미디어·시스템", buttons: [
        [b("prev", "이전 곡"), b("play", "재생/정지"), b("next", "다음 곡"), b("mute", "음소거")],
        [b("cmd-space", "Spotlight"), b("ctrl-up", "Mission Control"), b("ctrl-down", "앱 창 모아보기"), b("cmd-shift-3", "전체 캡처")],
        [b("ctrl-left", "왼쪽 데스크톱"), b("ctrl-right", "오른쪽 데스크톱"), b("macbrightnessdown", "화면 어둡게"), b("macbrightnessup", "화면 밝게")],
    ], knobs: [
        Knob(ccw: b("volumedown", "볼륨 작게"), press: b("mute", "음소거"), cw: b("volumeup", "볼륨 크게")),
        Knob(ccw: b("wheelup", "스크롤 위"), press: b("click", "클릭"), cw: b("wheeldown", "스크롤 아래")),
    ]),
])

// 고를 수 있는 동작 목록
let presets: [(String, [(String, String)])] = [
    ("자주 쓰는 것", [("복사", "cmd-c"), ("붙여넣기", "cmd-v"), ("잘라내기", "cmd-x"), ("실행 취소", "cmd-z"),
                   ("다시 실행", "cmd-shift-z"), ("저장", "cmd-s"), ("전체 선택", "cmd-a"), ("찾기", "cmd-f"),
                   ("새 탭", "cmd-t"), ("탭 닫기", "cmd-w"), ("직전 앱", "cmd-tab"), ("확대", "cmd-equal"),
                   ("축소", "cmd-minus"), ("원래 크기", "cmd-0")]),
    ("시스템", [("Spotlight", "cmd-space"), ("Mission Control", "ctrl-up"), ("앱 창 모아보기", "ctrl-down"),
              ("왼쪽 데스크톱", "ctrl-left"), ("오른쪽 데스크톱", "ctrl-right"), ("영역 캡처", "cmd-shift-4"),
              ("전체 캡처", "cmd-shift-3"), ("화면 녹화", "cmd-shift-5"), ("화면 밝게", "macbrightnessup"),
              ("화면 어둡게", "macbrightnessdown")]),
    ("미디어", [("재생/정지", "play"), ("다음 곡", "next"), ("이전 곡", "prev"), ("음소거", "mute"),
              ("볼륨 크게", "volumeup"), ("볼륨 작게", "volumedown")]),
    ("마우스", [("스크롤 위", "wheelup"), ("스크롤 아래", "wheeldown"), ("클릭", "click"), ("오른쪽 클릭", "rclick")]),
    ("VS Code", [("파일 찾기", "cmd-p"), ("명령 팔레트", "cmd-shift-p"), ("주석", "cmd-slash"),
                ("코드 정리", "alt-shift-f"), ("터미널", "ctrl-grave"), ("사이드바", "cmd-b"),
                ("정의로 이동", "f12"), ("같은 단어 선택", "cmd-d"), ("줄 위로", "alt-up"), ("줄 아래로", "alt-down")]),
]

// 맥 키 코드 → 설정 도구의 키 이름
let keyNames: [UInt16: String] = [
    0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x", 8: "c", 9: "v", 11: "b", 12: "q", 13: "w",
    14: "e", 15: "r", 16: "y", 17: "t", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "equal",
    25: "9", 26: "7", 27: "minus", 28: "8", 29: "0", 30: "rightbracket", 31: "o", 32: "u", 33: "leftbracket",
    34: "i", 35: "p", 36: "enter", 37: "l", 38: "j", 39: "quote", 40: "k", 41: "semicolon", 42: "backslash",
    43: "comma", 44: "slash", 45: "n", 46: "m", 47: "dot", 48: "tab", 49: "space", 50: "grave",
    51: "backspace", 53: "escape", 64: "f17", 79: "f18", 80: "f19", 90: "f20", 96: "f5", 97: "f6", 98: "f7",
    99: "f3", 100: "f8", 101: "f9", 103: "f11", 105: "f13", 106: "f16", 107: "f14", 109: "f10", 111: "f12",
    113: "f15", 115: "home", 116: "pageup", 117: "delete", 118: "f4", 119: "end", 120: "f2", 121: "pagedown",
    122: "f1", 123: "left", 124: "right", 125: "down", 126: "up",
]

// MARK: - 파일·도구

let baseURL = Bundle.main.bundleURL.deletingLastPathComponent()
let jsonURL = baseURL.appendingPathComponent("keyboard.json")
let yamlURL = baseURL.appendingPathComponent("mapping.yaml")
let toolDir = baseURL.appendingPathComponent("tool")
let launcherListURL = baseURL.appendingPathComponent("launcher.json")
let launcherAppURL = baseURL.appendingPathComponent("매크로 키보드 실행기.app")

// 앱 실행 키에 나눠 줄 키. 맥은 F20까지만 알아듣고, F14·F15는 화면 밝기로 쓰일 수 있어서 뺐다.
let launchKeys: [String] = {
    let f = ["f13", "f16", "f17", "f18", "f19", "f20"]
    return ["", "shift-", "ctrl-", "alt-"].flatMap { m in f.map { m + $0 } }
}()

func appIcon(_ path: String) -> NSImage { NSWorkspace.shared.icon(forFile: path) }

func yamlString(_ s: String) -> String {
    "\"" + s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
}

func makeYAML(_ c: Config) -> String {
    var out = """
    # 이 파일은 '매크로 키보드 설정' 앱이 만든다. 직접 고치지 말고 앱에서 바꾼다.
    # 방향: 노브가 오른쪽, Layer 버튼이 위쪽. buttons는 위에서부터 3줄 × 왼쪽부터 4칸, knobs는 위·아래 순서.
    orientation: normal
    rows: 3
    columns: 4
    knobs: 2

    layers:

    """
    for (i, layer) in c.layers.enumerated() {
        out += "  # 레이어 \(i + 1): \(layer.name)\n  - buttons:\n"
        for row in layer.buttons {
            let items = row.map { yamlString($0.action) }.joined(separator: ", ")
            let labels = row.map { $0.label }.joined(separator: " / ")
            out += "      - [\(items)]  # \(labels)\n"
        }
        out += "    knobs:\n"
        for (k, knob) in layer.knobs.enumerated() {
            out += "      - ccw: \(yamlString(knob.ccw.action))  # \(k == 0 ? "위" : "아래") 노브: \(knob.ccw.label)\n"
            out += "        press: \(yamlString(knob.press.action))  # \(knob.press.label)\n"
            out += "        cw: \(yamlString(knob.cw.action))  # \(knob.cw.label)\n"
        }
        out += "\n"
    }
    return out
}

func runTool(_ args: [String]) -> (Int32, String) {
    let p = Process()
    p.executableURL = toolDir.appendingPathComponent("ch57x-keyboard-tool")
    p.currentDirectoryURL = toolDir
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    do { try p.run() } catch { return (-1, "도구를 실행할 수 없어요: \(error.localizedDescription)") }
    p.waitUntilExit()
    let text = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    return (p.terminationStatus, text.trimmingCharacters(in: .whitespacesAndNewlines))
}

func keyboardConnected() -> Bool {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
    p.arguments = ["-p", "IOUSB", "-l", "-w0"]
    let pipe = Pipe()
    p.standardOutput = pipe
    guard (try? p.run()) != nil else { return false }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (String(data: data, encoding: .utf8) ?? "").contains("\"idVendor\" = 4489")
}

// MARK: - 상태

final class Store: ObservableObject {
    @Published var config: Config
    @Published var layer = 0
    @Published var selected: Slot = .button(0, 0)
    @Published var recording = false
    @Published var connected = false
    @Published var status = ""
    @Published var busy = false
    var saved: Config
    private var monitor: Any?
    private var timer: Timer?

    init() {
        let loaded = (try? Data(contentsOf: jsonURL)).flatMap { try? JSONDecoder().decode(Config.self, from: $0) }
        config = loaded ?? defaultConfig
        saved = loaded ?? defaultConfig
        connected = keyboardConnected()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            DispatchQueue.global().async {
                let c = keyboardConnected()
                DispatchQueue.main.async { self?.connected = c }
            }
        }
    }

    var dirty: Bool { config != saved }

    var current: KeyAction {
        get {
            switch selected {
            case let .button(r, c): return config.layers[layer].buttons[r][c]
            case let .knob(k, .ccw): return config.layers[layer].knobs[k].ccw
            case let .knob(k, .press): return config.layers[layer].knobs[k].press
            case let .knob(k, .cw): return config.layers[layer].knobs[k].cw
            }
        }
        set {
            switch selected {
            case let .button(r, c): config.layers[layer].buttons[r][c] = newValue
            case let .knob(k, .ccw): config.layers[layer].knobs[k].ccw = newValue
            case let .knob(k, .press): config.layers[layer].knobs[k].press = newValue
            case let .knob(k, .cw): config.layers[layer].knobs[k].cw = newValue
            }
        }
    }

    var allActions: [KeyAction] {
        config.layers.flatMap { l in l.buttons.flatMap { $0 } + l.knobs.flatMap { [$0.ccw, $0.press, $0.cw] } }
    }

    // 앱을 골라서 이 칸을 '앱 실행' 키로 만든다
    func chooseApp() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.prompt = "고르기"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let others = allActions.filter { $0 != current }
        // 같은 앱이 이미 다른 칸에 있으면 같은 키를 쓰고, 아니면 아무도 안 쓰는 키를 고른다
        let key = others.first { $0.app == url.path }?.action
            ?? launchKeys.first { k in !others.contains { $0.action == k } }
        guard let key else { status = "앱 실행 키가 다 찼어요 (최대 \(launchKeys.count)개)."; return }
        current = KeyAction(action: key, label: url.deletingPathExtension().lastPathComponent, app: url.path)
        status = "저장하고 키보드에 올리면 이 키로 앱이 열려요. 실행기 앱이 켜져 있어야 해요."
    }

    func writeLauncherList() throws {
        var seen = Set<String>()
        let items = allActions.compactMap { a -> [String: String]? in
            guard let app = a.app, seen.insert(a.action).inserted else { return nil }
            return ["key": a.action, "app": app, "name": a.label]
        }
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try enc.encode(items).write(to: launcherListURL)
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name("com.ethan.macropad.reload"), object: nil, deliverImmediately: true)
        // 앱 실행 키가 있는데 실행기가 꺼져 있으면 켠다
        let running = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.ethan.macropad.launcher").isEmpty
        if !items.isEmpty, !running, FileManager.default.fileExists(atPath: launcherAppURL.path) {
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = false
            NSWorkspace.shared.openApplication(at: launcherAppURL, configuration: cfg)
        }
    }

    func startRecording() {
        current.app = nil
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            guard let self, self.recording else { return e }
            if e.keyCode == 53 && e.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                self.stopRecording()   // Esc만 누르면 녹화 취소
                return nil
            }
            guard let key = keyNames[e.keyCode] else { return nil }
            var mods: [String] = []
            let f = e.modifierFlags
            if f.contains(.control) { mods.append("ctrl") }
            if f.contains(.option) { mods.append("alt") }
            if f.contains(.shift) { mods.append("shift") }
            if f.contains(.command) { mods.append("cmd") }
            self.current.action = (mods + [key]).joined(separator: "-")
            self.stopRecording()
            return nil
        }
    }

    func stopRecording() {
        recording = false
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil
    }

    @discardableResult
    func save() -> Bool {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            try enc.encode(config).write(to: jsonURL)
            try makeYAML(config).write(to: yamlURL, atomically: true, encoding: .utf8)
            try writeLauncherList()
            saved = config
            status = "저장했어요. (아직 키보드에는 안 올라감)"
            return true
        } catch {
            status = "저장 실패: \(error.localizedDescription)"
            return false
        }
    }

    // 처음 배치(defaultConfig)와 달라진 칸 목록: 업로드가 정말 바뀐 걸 올리는지 확인용
    func changes() -> [String] {
        var out: [String] = []
        for (i, (now, old)) in zip(config.layers, defaultConfig.layers).enumerated() {
            for r in 0..<3 { for c in 0..<4 where now.buttons[r][c].action != old.buttons[r][c].action {
                out.append("레이어\(i + 1) \(r + 1)줄\(c + 1)칸: \(old.buttons[r][c].action) → \(now.buttons[r][c].action)")
            } }
            for k in 0..<2 {
                let parts: [(String, KeyAction, KeyAction)] = [("↺", now.knobs[k].ccw, old.knobs[k].ccw),
                    ("누름", now.knobs[k].press, old.knobs[k].press), ("↻", now.knobs[k].cw, old.knobs[k].cw)]
                for (name, a, b) in parts where a.action != b.action {
                    out.append("레이어\(i + 1) \(k == 0 ? "위" : "아래") 노브 \(name): \(b.action) → \(a.action)")
                }
            }
        }
        return out
    }

    func validate() -> Bool {
        let (code, text) = runTool(["validate", yamlURL.path])
        status = code == 0 ? "검사 통과" : "검사 실패: \(text)"
        return code == 0
    }

    func upload() {
        guard save(), validate() else { return }
        guard connected else { status = "키보드가 연결되지 않았어요. 맥북 본체 포트에 데이터 선으로 꽂아 주세요."; return }
        busy = true
        status = "키보드에 올리는 중… 비밀번호 창이 뜨면 입력해 주세요."
        // 관리자 권한(root)으로 도는 도구는 iCloud Drive 파일을 못 읽는다(맥 개인정보 보호) → 임시 폴더에 복사해서 올린다
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("macropad-upload")
        let tmpTool = tmp.appendingPathComponent("ch57x-keyboard-tool")
        let tmpYAML = tmp.appendingPathComponent("mapping.yaml")
        do {
            try? FileManager.default.removeItem(at: tmp)
            try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: toolDir.appendingPathComponent("ch57x-keyboard-tool"), to: tmpTool)
            try FileManager.default.copyItem(at: yamlURL, to: tmpYAML)
        } catch {
            busy = false
            status = "임시 폴더에 복사 실패: \(error.localizedDescription)"
            return
        }
        let q = { (p: String) in p.replacingOccurrences(of: "'", with: "'\\''").wrapped }
        let changed = changes()
        let cmd = "\(q(tmpTool.path)) upload \(q(tmpYAML.path)) 2>&1"
        let script = "do shell script \"\(cmd.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\" with administrator privileges"
        DispatchQueue.global().async {
            var err: NSDictionary?
            let out = NSAppleScript(source: script)?.executeAndReturnError(&err).stringValue ?? ""
            // 무엇을 올렸는지 확인용 기록
            let log = "[\(Date())]\n도구 출력: \(out)\n오류: \(err?.description ?? "없음")\n"
                + "처음 배치와 달라진 칸 \(changed.count)개:\n" + changed.map { "  " + $0 + "\n" }.joined() + "\n"
                + ((try? String(contentsOf: tmpYAML, encoding: .utf8)) ?? "")
            try? log.write(to: baseURL.appendingPathComponent("tool/last-upload.log"), atomically: true, encoding: .utf8)
            DispatchQueue.main.async {
                self.busy = false
                if let err {
                    let msg = err[NSAppleScript.errorMessage] as? String ?? "알 수 없는 오류"
                    self.status = (err[NSAppleScript.errorNumber] as? Int) == -128 ? "취소했어요." : "올리기 실패: \(msg)"
                } else {
                    self.status = "키보드에 올렸어요! 처음 배치와 달라진 칸 \(changed.count)개. 바로 눌러 보세요."
                        + (out.isEmpty ? "" : " (\(out))")
                }
            }
        }
    }
}

extension String {
    var wrapped: String { "'" + self + "'" }   // 셸 작은따옴표로 감싸기
}


// MARK: - 디자인
// 참고: Elgato Stream Deck 앱(왼쪽 프로필 목록 · 가운데 기기 · 오른쪽 속성 패널),
//       Dribbble 'Deck Craft' 설정 화면(어두운 배경 위 기기 렌더 + 떠 있는 카드 패널)

enum Theme {
    static let bg = Color(red: 0.067, green: 0.071, blue: 0.082)         // 창 배경
    static let panel = Color(red: 0.094, green: 0.098, blue: 0.114)      // 사이드바·패널
    static let card = Color(red: 0.125, green: 0.129, blue: 0.149)       // 카드
    static let line = Color.white.opacity(0.07)
    static let text = Color.white.opacity(0.92)
    static let sub = Color.white.opacity(0.55)
    static let faint = Color.white.opacity(0.32)
    // 레이어마다 색 하나
    static let accents: [Color] = [
        Color(red: 0.42, green: 0.56, blue: 1.00),   // 코딩: 파랑
        Color(red: 1.00, green: 0.62, blue: 0.30),   // 편집: 주황
        Color(red: 0.32, green: 0.86, blue: 0.62),   // 미디어: 초록
    ]
}

// 동작 → SF Symbol 아이콘
func icon(for action: String) -> String {
    let map: [String: String] = [
        "cmd-c": "doc.on.doc", "cmd-v": "doc.on.clipboard", "cmd-x": "scissors", "cmd-a": "selection.pin.in.out",
        "cmd-z": "arrow.uturn.backward", "cmd-shift-z": "arrow.uturn.forward", "cmd-s": "square.and.arrow.down",
        "cmd-f": "magnifyingglass", "cmd-t": "plus.square.on.square", "cmd-w": "xmark.square", "cmd-tab": "rectangle.2.swap",
        "cmd-equal": "plus.magnifyingglass", "cmd-minus": "minus.magnifyingglass", "cmd-0": "1.magnifyingglass",
        "cmd-space": "sparkle.magnifyingglass", "ctrl-up": "rectangle.3.group", "ctrl-down": "rectangle.grid.2x2",
        "ctrl-left": "arrow.left.square", "ctrl-right": "arrow.right.square", "cmd-shift-4": "camera.viewfinder",
        "cmd-shift-3": "camera", "cmd-shift-5": "record.circle", "macbrightnessup": "sun.max", "macbrightnessdown": "sun.min",
        "play": "playpause.fill", "next": "forward.fill", "prev": "backward.fill", "mute": "speaker.slash.fill",
        "volumeup": "speaker.wave.3.fill", "volumedown": "speaker.wave.1.fill", "wheelup": "arrow.up", "wheeldown": "arrow.down",
        "click": "cursorarrow.click", "rclick": "cursorarrow.click.2", "cmd-p": "doc.text.magnifyingglass",
        "cmd-shift-p": "command", "cmd-slash": "number", "alt-shift-f": "wand.and.stars", "ctrl-grave": "terminal",
        "cmd-b": "sidebar.left", "f12": "arrow.turn.down.right", "cmd-d": "character.cursor.ibeam",
        "alt-up": "arrow.up.to.line", "alt-down": "arrow.down.to.line", "left": "backward.frame", "right": "forward.frame",
        "space": "playpause",
    ]
    if let name = map[action] { return name }
    if action.contains(",") { return "list.bullet" }
    return "keyboard"
}

// "cmd-shift-p" → "⌘⇧P"
func prettyKeys(_ action: String) -> String {
    let sym: [String: String] = [
        "cmd": "⌘", "shift": "⇧", "alt": "⌥", "ctrl": "⌃", "up": "↑", "down": "↓", "left": "←", "right": "→",
        "enter": "↩", "tab": "⇥", "space": "Space", "escape": "Esc", "backspace": "⌫", "delete": "⌦",
        "grave": "`", "slash": "/", "backslash": "\\", "equal": "=", "minus": "−", "comma": ",", "dot": ".",
        "semicolon": ";", "quote": "'", "leftbracket": "[", "rightbracket": "]",
        "play": "Play", "next": "Next", "prev": "Prev", "mute": "Mute", "volumeup": "Vol+", "volumedown": "Vol−",
        "wheelup": "Wheel↑", "wheeldown": "Wheel↓", "click": "Click", "rclick": "R-Click",
        "macbrightnessup": "Bright+", "macbrightnessdown": "Bright−",
    ]
    return action.split(separator: ",").map { combo in
        combo.split(separator: "-").map { part -> String in
            let p = String(part)
            return sym[p] ?? p.uppercased()
        }.joined()
    }.joined(separator: " → ")
}

// MARK: - 화면

// 키캡 하나 (실제 키보드처럼 살짝 입체)
struct KeyCap: View {
    let binding: KeyAction
    let accent: Color
    let isSelected: Bool
    let tap: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: tap) {
            VStack(spacing: 7) {
                if let app = binding.app {
                    Image(nsImage: appIcon(app)).resizable().frame(width: 28, height: 28)
                } else {
                    Image(systemName: icon(for: binding.action))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(accent)
                        .frame(height: 24)
                }
                Text(binding.label.isEmpty ? "—" : binding.label)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2).multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                Text(prettyKeys(binding.action))
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.faint).lineLimit(1)
            }
            .padding(6)
            .frame(width: 96, height: 96)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [Color(white: hover ? 0.24 : 0.21), Color(white: 0.155)],
                                         startPoint: .top, endPoint: .bottom))
            )
            .overlay(   // 위쪽 빛 반사
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.02)],
                                                 startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(accent, lineWidth: isSelected ? 2 : 0)
            )
            .shadow(color: isSelected ? accent.opacity(0.55) : .black.opacity(0.5),
                    radius: isSelected ? 12 : 4, y: isSelected ? 0 : 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .animation(.easeOut(duration: 0.12), value: hover)
    }
}

// 노브 동작 한 줄 (↺ / 누름 / ↻)
struct KnobRow: View {
    let symbol: String
    let caption: String
    let binding: KeyAction
    let accent: Color
    let isSelected: Bool
    let tap: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: tap) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isSelected ? .black : accent)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(isSelected ? accent : accent.opacity(0.14)))
                VStack(alignment: .leading, spacing: 1) {
                    Text(caption).font(.system(size: 9, weight: .medium)).foregroundStyle(Theme.faint)
                    Text(binding.label.isEmpty ? "—" : binding.label)
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .frame(width: 156)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(isSelected ? 0.10 : hover ? 0.06 : 0.035)))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? accent : Color.clear, lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}

// 노브 그림 (눌러서 '누름' 선택)
struct KnobDial: View {
    let accent: Color
    let isSelected: Bool
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            ZStack {
                Circle().fill(Color.black.opacity(0.45)).frame(width: 74, height: 74)   // 홈
                Circle()
                    .fill(RadialGradient(colors: [Color(white: 0.30), Color(white: 0.13)],
                                         center: .init(x: 0.35, y: 0.3), startRadius: 2, endRadius: 46))
                    .frame(width: 62, height: 62)
                    .shadow(color: .black.opacity(0.6), radius: 5, y: 3)
                Circle()   // 톱니 무늬
                    .strokeBorder(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: 3, dash: [1.2, 2.4]))
                    .frame(width: 62, height: 62)
                Capsule().fill(accent).frame(width: 3, height: 12).offset(y: -20)   // 표시선
                Circle()
                    .strokeBorder(accent, lineWidth: isSelected ? 2 : 0)
                    .frame(width: 74, height: 74)
            }
            .shadow(color: isSelected ? accent.opacity(0.5) : .clear, radius: 10)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct ContentView: View {
    @StateObject var s = Store()
    @State private var editingName = false
    @FocusState private var nameFocused: Bool

    var accent: Color { Theme.accents[s.layer % Theme.accents.count] }

    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 210)
            Rectangle().fill(Theme.line).frame(width: 1)
            VStack(spacing: 0) {
                header
                Spacer(minLength: 16)
                device
                Spacer(minLength: 16)
                statusBar
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
            .background(
                RadialGradient(colors: [accent.opacity(0.10), .clear], center: .center, startRadius: 40, endRadius: 520)
            )
            Rectangle().fill(Theme.line).frame(width: 1)
            inspector.frame(width: 300)
        }
        .background(Theme.bg)
        .foregroundStyle(Theme.text)
        .frame(minWidth: 1320, minHeight: 680)
        .preferredColorScheme(.dark)
        .tint(accent)
        .animation(.easeInOut(duration: 0.2), value: s.layer)
        .focusEffectDisabled()
        .onAppear {
            // 켜자마자 글자 칸에 커서가 깜빡이지 않게 포커스를 비운다
            DispatchQueue.main.async { NSApp.keyWindow?.makeFirstResponder(nil) }
        }
        .onChange(of: s.layer) { editingName = false }
    }

    // 왼쪽: 레이어 목록 + 연결 상태
    var sidebar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(.black)
                    .frame(width: 26, height: 26)
                    .background(RoundedRectangle(cornerRadius: 7).fill(accent))
                VStack(alignment: .leading, spacing: 0) {
                    Text("MacroPad").font(.system(size: 14, weight: .bold))
                    Text("AX-KEY12").font(.system(size: 10, weight: .medium)).foregroundStyle(Theme.faint)
                }
            }
            .padding(.top, 40).padding(.bottom, 20)

            Text("레이어").font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.faint)
                .padding(.leading, 4).padding(.bottom, 2)

            ForEach(0..<s.config.layers.count, id: \.self) { i in
                layerRow(i)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Circle().fill(s.connected ? Color.green : Color.red).frame(width: 8, height: 8)
                        .shadow(color: s.connected ? .green : .red, radius: 4)
                    Text(s.connected ? "키보드 연결됨" : "키보드 없음").font(.system(size: 12, weight: .semibold))
                }
                Text(s.connected ? "USB 1189:8840" : "맥북 본체 포트에 데이터 선으로 꽂아 주세요.")
                    .font(.system(size: 10.5)).foregroundStyle(Theme.sub)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.card))
        }
        .padding(14)
        .background(Theme.panel)
    }

    func layerRow(_ i: Int) -> some View {
        let on = s.layer == i
        let c = Theme.accents[i % Theme.accents.count]
        return Button { s.layer = i } label: {
            HStack(spacing: 10) {
                Text("\(i + 1)").font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(on ? .black : c)
                    .frame(width: 24, height: 24)
                    .background(RoundedRectangle(cornerRadius: 7).fill(on ? c : c.opacity(0.15)))
                Text(s.config.layers[i].name).font(.system(size: 13, weight: on ? .semibold : .regular))
                    .foregroundStyle(on ? Theme.text : Theme.sub)
                Spacer()
            }
            .padding(.horizontal, 8).padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(on ? Color.white.opacity(0.07) : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // 가운데 위: 레이어 이름
    var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("레이어 \(s.layer + 1)").font(.system(size: 11, weight: .semibold)).foregroundStyle(accent)
                // 평소엔 글자, 이름이나 연필을 누르면 고칠 수 있는 칸으로 바뀐다
                if editingName {
                    TextField("레이어 이름", text: $s.config.layers[s.layer].name)
                        .textFieldStyle(.plain)
                        .font(.system(size: 24, weight: .bold))
                        .frame(maxWidth: 320)
                        .focused($nameFocused)
                        .onSubmit { editingName = false }
                        .onChange(of: nameFocused) { if !nameFocused { editingName = false } }
                        .onAppear { nameFocused = true }
                } else {
                    HStack(spacing: 8) {
                        Text(s.config.layers[s.layer].name.isEmpty ? "이름 없음" : s.config.layers[s.layer].name)
                            .font(.system(size: 24, weight: .bold))
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.faint)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { editingName = true }
                    .help("레이어 이름 바꾸기")
                }
            }
            Spacer()
            if s.dirty {
                Label("저장 안 됨", systemImage: "circle.fill")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(.orange)
                    .labelStyle(DotLabel())
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Color.orange.opacity(0.12)))
            }
        }
        .padding(.top, 40)
    }

    // 가운데: 키보드 본체
    var device: some View {
        VStack(spacing: 14) {
            // 위쪽: Layer 버튼과 레이어 불빛
            HStack(spacing: 8) {
                Capsule().fill(Color(white: 0.22)).frame(width: 34, height: 12)
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.08)))
                Text("LAYER").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(Theme.faint)
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(i == s.layer ? Theme.accents[i] : Color.white.opacity(0.12))
                        .frame(width: 6, height: 6)
                        .shadow(color: i == s.layer ? Theme.accents[i] : .clear, radius: 4)
                }
                Spacer()
                Text("ON / OFF").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(Theme.faint)
            }
            .padding(.horizontal, 6)

            HStack(alignment: .center, spacing: 22) {
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { r in
                        HStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { c in
                                KeyCap(binding: s.config.layers[s.layer].buttons[r][c], accent: accent,
                                       isSelected: s.selected == .button(r, c)) { s.selected = .button(r, c) }
                            }
                        }
                    }
                }
                Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1, height: 300)
                VStack(spacing: 22) {
                    ForEach(0..<2, id: \.self) { k in knobView(k) }
                }
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.135), Color(white: 0.085)], startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                                             startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.55), radius: 30, y: 18)
        .fixedSize()
    }

    // 노브 하나: 다이얼 + 동작 3줄 (글자가 잘리지 않게 크기를 고정)
    func knobView(_ k: Int) -> some View {
        let knob = s.config.layers[s.layer].knobs[k]
        return HStack(spacing: 12) {
            VStack(spacing: 6) {
                KnobDial(accent: accent, isSelected: s.selected == .knob(k, .press)) { s.selected = .knob(k, .press) }
                Text(k == 0 ? "위 노브" : "아래 노브")
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.sub)
            }
            VStack(spacing: 5) {
                KnobRow(symbol: "arrow.counterclockwise", caption: "왼쪽으로 돌림", binding: knob.ccw, accent: accent,
                        isSelected: s.selected == .knob(k, .ccw)) { s.selected = .knob(k, .ccw) }
                KnobRow(symbol: "circle.fill", caption: "누름", binding: knob.press, accent: accent,
                        isSelected: s.selected == .knob(k, .press)) { s.selected = .knob(k, .press) }
                KnobRow(symbol: "arrow.clockwise", caption: "오른쪽으로 돌림", binding: knob.cw, accent: accent,
                        isSelected: s.selected == .knob(k, .cw)) { s.selected = .knob(k, .cw) }
            }
        }
        .fixedSize()
    }

    var statusBar: some View {
        HStack(spacing: 8) {
            if s.busy { ProgressView().controlSize(.small) }
            Text(s.status.isEmpty ? "키나 노브를 눌러서 고르세요." : s.status)
                .font(.system(size: 12)).foregroundStyle(Theme.sub).lineLimit(2)
            Spacer()
        }
        .padding(.bottom, 18)
    }

    var slotTitle: String {
        switch s.selected {
        case let .button(r, c): return "\(r + 1)줄 \(c + 1)칸"
        case let .knob(k, p):
            return "\(k == 0 ? "위" : "아래") 노브 · " + (p == .ccw ? "왼쪽으로 돌림" : p == .press ? "누름" : "오른쪽으로 돌림")
        }
    }

    // 오른쪽: 선택한 칸 설정
    var inspector: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Group {
                    if let app = s.current.app {
                        Image(nsImage: appIcon(app)).resizable().frame(width: 36, height: 36)
                    } else {
                        Image(systemName: icon(for: s.current.action))
                            .font(.system(size: 22, weight: .medium)).foregroundStyle(accent)
                    }
                }
                    .frame(width: 52, height: 52)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(accent.opacity(0.13)))
                VStack(alignment: .leading, spacing: 3) {
                    Text(slotTitle).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.sub)
                    Text(s.current.label.isEmpty ? "이름 없음" : s.current.label)
                        .font(.system(size: 17, weight: .bold)).lineLimit(1)
                    Text(prettyKeys(s.current.action)).font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.faint).lineLimit(1)
                }
            }
            .padding(.top, 40)

            field("이름") {
                TextField("예: 복사", text: Binding2(s, \.label))
                    .textFieldStyle(.plain).font(.system(size: 13))
            }
            field("동작") {
                TextField("예: cmd-shift-p", text: Binding2(s, \.action))
                    .textFieldStyle(.plain).font(.system(size: 13, design: .monospaced))
            }

            Button {
                s.recording ? s.stopRecording() : s.startRecording()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: s.recording ? "record.circle.fill" : "keyboard")
                    Text(s.recording ? "단축키를 눌러 주세요… (Esc 취소)" : "단축키 직접 눌러서 넣기")
                    Spacer()
                }
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(s.recording ? Color.red : Theme.text)
                .padding(.horizontal, 12).frame(height: 36)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(s.recording ? Color.red.opacity(0.14) : Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(s.recording ? Color.red.opacity(0.6) : Theme.line))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                ForEach(presets, id: \.0) { group in
                    Section(group.0) {
                        ForEach(group.1, id: \.1) { item in
                            Button("\(item.0)   \(prettyKeys(item.1))") { s.current = KeyAction(action: item.1, label: item.0) }
                        }
                    }
                }
            } label: {
                Label("목록에서 고르기", systemImage: "list.bullet")
            }
            .menuStyle(.button)
            .controlSize(.large)

            // 스트림덱처럼 앱 실행
            HStack(spacing: 8) {
                Button { s.chooseApp() } label: {
                    Label(s.current.app == nil ? "앱 실행하기…" : "다른 앱으로 바꾸기…", systemImage: "app.badge")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                if s.current.app != nil {
                    Button { s.current = KeyAction(action: "a", label: "") } label: { Image(systemName: "xmark") }
                        .controlSize(.large)
                        .help("앱 실행 지우기")
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("도움말").font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.faint)
                Text("cmd ⌘ · alt ⌥ · ctrl ⌃ · shift ⇧")
                Text("여러 개를 차례로: cmd-c,cmd-v")
                Text("미디어 키(play 등)는 다른 키와 섞을 수 없어요.")
                Text("앱 실행 키는 F13~F20을 써요. 메뉴 막대의 실행기 앱이 켜져 있어야 열려요.")
            }
            .font(.system(size: 11)).foregroundStyle(Theme.sub)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.card.opacity(0.6)))

            Spacer()

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Button("되돌리기") { s.config = s.saved; s.status = "마지막 저장 상태로 되돌렸어요." }
                        .disabled(!s.dirty)
                    Button("저장") { s.save() }.keyboardShortcut("s")
                    Button("검사") { if s.save() { _ = s.validate() } }
                }
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Button { s.upload() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                        Text(s.busy ? "올리는 중…" : "키보드에 올리기")
                    }
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity).frame(height: 42)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(accent))
                    .opacity(s.busy ? 0.5 : 1)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(s.busy)
            }
        }
        .padding(18)
        .background(Theme.panel)
    }

    func field<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.faint)
            content()
                .padding(.horizontal, 10).frame(height: 34)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Theme.line))
        }
    }
}

// "● 저장 안 됨" 처럼 작은 점 + 글자
struct DotLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon.font(.system(size: 6))
            configuration.title
        }
    }
}

// 선택된 칸의 이름/동작을 TextField에 연결
func Binding2(_ s: Store, _ kp: WritableKeyPath<KeyAction, String>) -> SwiftUI.Binding<String> {
    SwiftUI.Binding(get: { s.current[keyPath: kp] }, set: { s.current[keyPath: kp] = $0 })
}

@main
struct MacroPadApp: App {
    var body: some Scene {
        WindowGroup("매크로 키보드 설정") { ContentView() }
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentSize)
    }
}
