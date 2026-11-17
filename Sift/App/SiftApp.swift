import SwiftUI

@main
struct SiftApp: App {
    @StateObject private var engine = ScanEngine()

    init() {
        Typo.registerNavigationAppearance()
        #if DEBUG
        // Runs before any view is built, so the onboarding test always starts clean.
        if ProcessInfo.processInfo.arguments.contains("-resetOnboarding") {
            UserDefaults.standard.removeObject(forKey: "hasOnboarded")
        }
        DemoSeed.runIfRequested()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(engine)
                .font(Typo.body)
                .tint(Theme.accent)
                .preferredColorScheme(nil)
        }
    }
}

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

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
