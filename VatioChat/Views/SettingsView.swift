import SwiftUI

/// Which agent the app talks to, and as whom. Saving builds a new client and
/// a new chat, because a `VatioChat` is tied to its workspace and visitor token.
@MainActor
struct SettingsView: View {
    @ObservedObject var store: ChatStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft = AppSettings()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Workspace", text: $draft.workspace)
                    TextField("Publishable key (vatpub_…)", text: $draft.token)
                        .font(.body.monospaced())
                    TextField("Base URL", text: $draft.baseURL)
                        .keyboardType(.URL)
                } header: {
                    Text("Agent")
                } footer: {
                    Text("The publishable key must allow this app's origin, \(store.origin). Create one with `vatio keys create publishable --origin \(store.origin)`.")
                }

                Section {
                    SecureField("Visitor token (optional)", text: $draft.visitorToken)
                } header: {
                    Text("Signed-in user")
                } footer: {
                    Text("A JWT your backend signs for a signed-in user, so the agent knows who they are and can use private tools. In a real app it comes from your backend after your own sign-in; paste one here to test them.")
                }

                Section {
                    Button("Use Vatio's agent") {
                        store.apply(AppSettings())
                        dismiss()
                    }
                }

                Section("About") {
                    Text("Vatio Chat is an open-source, ChatGPT-style app for a Vatio agent, and a reference for putting one in your own iOS app.")
                    Link("Source code on GitHub", destination: AppConfig.repositoryURL)
                    Link("iOS SDK documentation", destination: AppConfig.docsURL)
                    LabeledContent("Origin") {
                        Text(store.origin).textSelection(.enabled)
                    }
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.apply(draft.trimmed)
                        dismiss()
                    }
                    .disabled(!draft.trimmed.isValid)
                }
            }
            .onAppear { draft = store.settings }
        }
    }
}
