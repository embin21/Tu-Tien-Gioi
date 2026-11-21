import SwiftUI

@main
struct TuTienGioiApp: App {
    @AppStorage("ttg_started") private var started = false
    var body: some Scene {
        WindowGroup {
            if started { GameHomeView() } else { LoginView() }
        }
    }
}
