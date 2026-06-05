import SwiftUI
import LLMFlexCore

@main
struct LLMFlexApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverView(model: model)
        } label: {
            Image(nsImage: BrandGlyph.menuBar)
        }
        .menuBarExtraStyle(.window)

        // Editor opens in a real Window so it survives clicking away to
        // copy an API key from another app. dismissWindow closes it.
        Window("Edit profile", id: AppModel.editorWindowID) {
            ProfileEditor(model: model, profile: model.editingProfile)
                .frame(width: Theme.Metric.popoverWidth)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Feedback form — its own Window so it survives clicking away, same as
        // the editor. Separate id/token so the two never cross-wire.
        Window("Send feedback", id: AppModel.feedbackWindowID) {
            FeedbackView(model: model)
                .frame(width: Theme.Metric.popoverWidth)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
