import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    private let statusLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        statusLabel.text = "Importing..."
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicator)
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        processSharedItems()
    }

    private func processSharedItems() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            showStatus("No content shared")
            return
        }

        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                    if let url = item as? URL {
                        Task { await self?.importURL(url.absoluteString) }
                    }
                }
                return
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
                    if let text = item as? String,
                       text.contains("youtube.com") || text.contains("youtu.be") || text.contains("music.youtube.com") {
                        Task { await self?.importURL(text) }
                    }
                }
                return
            }
        }
        showStatus("No YouTube URL found")
    }

    private func importURL(_ urlString: String) async {
        let base = UserDefaults(suiteName: "group.alexlam.Nova")?.string(forKey: "nova_server_base_url") ?? "http://localhost:3000"
        guard let apiURL = URL(string: "\(base)/api/youtube") else {
            showStatus("Invalid server URL")
            return
        }

        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(["url": urlString])

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                struct Response: Codable {
                    let ok: Bool
                    let song: SongData
                    let duplicate: Bool?
                }
                struct SongData: Codable {
                    let trackName: String
                }
                if let json = try? JSONDecoder().decode(Response.self, from: data) {
                    showStatus(json.duplicate == true ? "\(json.song.trackName) already in library" : "Added: \(json.song.trackName)")
                } else {
                    showStatus("Done")
                }
            } else {
                showStatus("Server error")
            }
        } catch {
            showStatus("Connection failed")
        }
    }

    private func showStatus(_ msg: String) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.statusLabel.text = msg
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.extensionContext?.completeRequest(returningItems: nil)
            }
        }
    }
}