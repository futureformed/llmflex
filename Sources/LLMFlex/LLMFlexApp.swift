import SwiftUI
import LLMFlexCore

@main
struct LLMFlexApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            ScaffoldPopover()
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

private struct ScaffoldPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LLM Flex")
                .font(.headline)
            Text("Phase A scaffolding — v\(LLMFlexCore.version)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
            Button("Quit") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        .padding(14)
        .frame(width: 260)
    }
}
