import Foundation

private let kBaseURLKey = "nova_server_base_url"
private let kAppGroup = "group.alexlam.Nova"
private var cachedBaseURL: String?

var baseURL: String {
    get {
        if let cached = cachedBaseURL { return cached }
        let defaults = UserDefaults(suiteName: kAppGroup) ?? UserDefaults.standard
        if let saved = defaults.string(forKey: kBaseURLKey), !saved.isEmpty {
            cachedBaseURL = saved
            return saved
        }
        let defaultURL = "http://localhost:3000"
        cachedBaseURL = defaultURL
        return defaultURL
    }
    set {
        cachedBaseURL = newValue
        let defaults = UserDefaults(suiteName: kAppGroup) ?? UserDefaults.standard
        defaults.set(newValue, forKey: kBaseURLKey)
    }
}

struct SongDTO: Codable, Identifiable {
    let id: String
    let trackName: String
    let artistName: String
    let album: String?
    let year: Int?
    let coverUrl: String?
    let duration: Int?
    let status: String
    let source: String?
    let filePath: String?
    /// YouTube URL for search results not yet imported
    let youtubeUrl: String?
}

struct YouTubeImportResponse: Codable {
    let ok: Bool
    let song: SongDTO
    let duplicate: Bool?
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .networkError(let msg): return msg
        case .decodingError: return "Failed to decode response"
        }
    }
}

func importYouTubeFromURL(url: String) async throws -> SongDTO {
    guard let apiURL = URL(string: "\(baseURL)/api/youtube") else {
        throw APIError.invalidURL
    }

    var req = URLRequest(url: apiURL)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try JSONEncoder().encode(["url": url])

    let (data, resp) = try await URLSession.shared.data(for: req)
    guard let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 200 else {
        throw APIError.networkError("Server error")
    }
    let result = try JSONDecoder().decode(YouTubeImportResponse.self, from: data)
    return result.song
}

func searchSongs(query: String) async throws -> [SongDTO] {
    guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: "\(baseURL)/api/search?q=\(encoded)") else {
        throw APIError.invalidURL
    }
    let (data, resp) = try await URLSession.shared.data(from: url)
    guard let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 200 else {
        throw APIError.networkError("Server error")
    }
    return try JSONDecoder().decode([SongDTO].self, from: data)
}

func deleteSong(id: String) async throws {
    guard let apiURL = URL(string: "\(baseURL)/api/songs/\(id)") else {
        throw APIError.invalidURL
    }
    var req = URLRequest(url: apiURL)
    req.httpMethod = "DELETE"
    let (_, resp) = try await URLSession.shared.data(for: req)
    guard let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 200 else {
        throw APIError.networkError("Server error")
    }
}
