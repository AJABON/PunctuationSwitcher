import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    var statusItem: NSStatusItem!
    var menu: NSMenu! // ← let を var に
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // ステータスアイテムの作成
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let image = NSImage(named: "icon") // PDFまたは透過PNG
                image?.isTemplate = true // メニューバーで自動で白黒切り替え
                button.image = image
        }

        // メニューの作成
        menu = NSMenu()
        menu.delegate = self // ← これを追加

        let items = [
            ("テン, マル [、。]", 0),
            ("カン, マル [，。]", 1),
            ("テン, ピリ [、．]", 2),
            ("カン, ピリ [，．]", 3)
        ]

        for (title, value) in items {
            let item = NSMenuItem(title: title, action: #selector(changePunctuation(_:)), keyEquivalent: "")
            item.tag = value
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "終了", action: #selector(terminate), keyEquivalent: "q")
        quitItem.tag = -1 // ← 追加：終了には特別な tag を明示
        menu.addItem(quitItem)

        statusItem.menu = menu

        updateMenuState()
    }
    
    @objc func changePunctuation(_ sender: NSMenuItem) {
        let command = "defaults write com.apple.inputmethod.Kotoeri JIMPrefPunctuationTypeKey -int \(sender.tag); killall -HUP JapaneseIM-RomajiTyping"
        _ = try? shell(command)
        updateMenuState()
        
        showNotification(title: "句読点の種類", body: "\(sender.title) に変更しました")
    }

    @objc func updateMenuState() {
        let current = getCurrentPunctuationSetting()
        for item in menu.items {
            if item.isSeparatorItem || item.tag == -1 { // ← 「終了」は除外
                item.state = .off // ← 明示的に終了はチェックを外す
                continue
            }
            item.state = (item.tag == current) ? .on : .off
        }
    }

    func getCurrentPunctuationSetting() -> Int {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", "com.apple.inputmethod.Kotoeri", "JIMPrefPunctuationTypeKey"]

        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(output ?? "") ?? -1
    }

    @objc func terminate() {
        NSApplication.shared.terminate(nil)
    }

    func shell(_ command: String) throws -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 即時通知
        )

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    // メニューが開く直前にチェック状態を更新
    func menuWillOpen(_ menu: NSMenu) {
        updateMenuState()
    }
}
