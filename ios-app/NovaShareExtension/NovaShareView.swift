import SwiftUI
import UniformTypeIdentifiers

struct NovaShareView: View {
    let items: [NSItemProvider]
    let completion: () -> Void

    @State private var status: String = "Importing..."
    @State private var done: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    Text(status)
                        .font(.headline)
                } else {
                    ProgressView()
                    Text(status)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("Nova")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { completion() }
                }
            }
            .task {
                await importURL()
            }
        }
    }

    private func importURL() async {
        for item in items {
            if item.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                do {
                    if let url = try await item.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                        await importSong(url: url.absoluteString)
                        return
                    }
                } catch {}
            }
            if item.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                do {
                    if let text = try await item.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                        if text.contains("youtube.com") || text.contains("youtu.be") || text.contains("music.youtube.com") {
                            await importSong(url: text)
                            return
                        }
                    }
                } catch {}
            }
        }
        status = "No YouTube URL found"
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        done = true
    }

    private func importSong(url: String) async {
        let base = UserDefaults.standard.string(forKey: "nova_server_base_url") ?? "http://localhost:3000"
        guard let apiURL = URL(string: "\(base)/api/youtube") else {
            status = "Invalid server URL"
            done = true
            return
        }
        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try? JSONEncoder().encode(["url": url])
        req.httpBody = body

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                if let json = try? JSONDecoder().decode(ImportResponse.self, from: data) {
                    status = json.duplicate == true ? "\(json.song.trackName) already in library" : "Added: \(json.song.trackName)"
                } else {
                    status = "Song added to library"
                }
            } else {
                status = "Server error"
            }
        } catch {
            status = "Connection failed"
        }
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        done = true
    }
}

struct ImportResponse: Codable {
    let ok: Bool
    let song: SongInfo
    let duplicate: Bool?
}

struct SongInfo: Codable {
    let trackName: String
}

#Preview {
    NovaShareView(items: [], completion: {})
}