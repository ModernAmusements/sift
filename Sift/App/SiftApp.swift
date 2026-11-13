import SwiftUI

@main
struct SiftApp: App {
    @StateObject private var engine = ScanEngine()

    init() {
        #if DEBUG
        DemoSeed.runIfRequested()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(engine)
                .tint(Theme.ink)
                .preferredColorScheme(nil)
        }
    }
}

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetOnboarding") {
            UserDefaults.standard.removeObject(forKey: "hasOnboarded")
        }
        #endif
    }

    var body: some View {
        if hasOnboarded {
            HomeView()
        } else {
            OnboardingView {
                withAnimation(.snappy) { hasOnboarded = true }
            }
        }
    }
}
