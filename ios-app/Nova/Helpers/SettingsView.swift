import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var serverURL: String = baseURL

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("http://localhost:3000", text: $serverURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }

                Section {
                    Text("Use this to connect to your Nova server")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        baseURL = serverURL.trimmingCharacters(in: .whitespaces)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

@available(iOS 26.0, *)
struct SettingsView_iOS26: View {
    @Environment(\.dismiss) private var dismiss
    @State private var serverURL: String = baseURL

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("http://localhost:3000", text: $serverURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }

                Section {
                    Text("Use this to connect to your Nova server")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) {
                        baseURL = serverURL.trimmingCharacters(in: .whitespaces)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}