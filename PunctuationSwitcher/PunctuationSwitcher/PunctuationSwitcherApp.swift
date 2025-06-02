import SwiftUI

@main
struct PunctuationSwitcherApp: App {
    // AppDelegateを保持する
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // ウィンドウなしのメニューだけのAppにする
        Settings {
            EmptyView()
        }
    }
}
