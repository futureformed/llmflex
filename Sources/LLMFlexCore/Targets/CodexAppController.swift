import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Detect and control the Codex.app desktop process. UI uses this to show a
/// "restart Codex.app" banner and offer one-click relaunch after a switch.
public struct CodexAppController: Sendable {
    public let bundleIdentifier: String

    public init(bundleIdentifier: String = "com.openai.codex") {
        self.bundleIdentifier = bundleIdentifier
    }

    public func isRunning() -> Bool {
        #if canImport(AppKit)
        return !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
        #else
        return false
        #endif
    }

    public func quit() {
        #if canImport(AppKit)
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier) {
            app.terminate()
        }
        #endif
    }

    public func relaunch() {
        #if canImport(AppKit)
        let proc = Process()
        proc.launchPath = "/usr/bin/open"
        proc.arguments = ["-a", "Codex"]
        try? proc.run()
        #endif
    }
}
