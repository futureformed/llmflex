import SwiftUI
import AppKit
import LLMFlexCore

/// In-app feedback form. Composes a `mailto:` to llmflex@holdtight.cc and hands
/// it to the user's mail client (they hit send). No network, no backend — the
/// only moving part is the URL encoding, which is tested in `FeedbackMailto`.
struct FeedbackView: View {
    @Bindable var model: AppModel

    @State private var category: Category = .general
    @State private var message: String = ""
    @State private var sent: Bool = false
    @State private var noMailClient: Bool = false

    @Environment(\.dismissWindow) private var dismissWindow

    enum Category: String, CaseIterable, Identifiable {
        case general = "General feedback"
        case bug = "Bug report"
        case feature = "Feature request"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            VStack(alignment: .leading, spacing: 14) {
                field("Topic") {
                    Picker("", selection: $category) {
                        ForEach(Category.allCases) { c in Text(c.rawValue).tag(c) }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                field("Message") {
                    TextEditor(text: $message)
                        .font(Theme.Fonts.body)
                        .frame(minHeight: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                        .overlay(alignment: .topLeading) {
                            if message.isEmpty {
                                Text("What's working, what's not, what you'd like to see…")
                                    .font(Theme.Fonts.body)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                Text("Opens your mail app with a message to \(FeedbackMailto.recipient). Your app version and macOS version are added to help with diagnosis.")
                    .font(Theme.Fonts.meta)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if noMailClient {
                    Label("Couldn't open a mail app. Email \(FeedbackMailto.recipient) directly.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(Theme.Fonts.meta)
                        .foregroundStyle(.orange)
                        .textSelection(.enabled)
                }
            }
            .padding(Theme.Metric.outerPadding)
            Divider()
            footer
        }
        .onAppear {
            // Fresh form each time the window is opened (it's a singleton Window,
            // so the previous send's text would otherwise linger).
            if sent {
                message = ""
                sent = false
            }
            noMailClient = false
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "envelope")
                .foregroundStyle(Theme.accent)
            Text("Send feedback")
                .font(Theme.Fonts.title)
            Spacer()
        }
        .padding(.horizontal, Theme.Metric.outerPadding)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Close") { dismissWindow(id: AppModel.feedbackWindowID) }
                .keyboardShortcut(.escape)
            Button("Compose email") { send() }
                .buttonStyle(.borderedProminent)
                .llmAccentTint()
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, Theme.Metric.outerPadding)
        .padding(.vertical, 10)
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(Theme.Fonts.label)
                .foregroundStyle(.secondary)
                .kerning(0.8)
            content()
        }
    }

    private func send() {
        let subject = "LLM Flex feedback — \(category.rawValue)"
        let body = """
        \(message.trimmingCharacters(in: .whitespacesAndNewlines))


        ——
        App version: \(Self.appVersion)
        macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        """
        guard let url = FeedbackMailto.build(subject: subject, body: body) else {
            noMailClient = true
            return
        }
        if NSWorkspace.shared.open(url) {
            sent = true
            dismissWindow(id: AppModel.feedbackWindowID)
        } else {
            noMailClient = true
        }
    }

    private static var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}
