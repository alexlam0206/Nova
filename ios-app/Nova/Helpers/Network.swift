import Foundation

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
}

struct YouTubeImportResponse: Codable {
    let ok: Bool
    let song: SongDTO
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

func importYouTubeFromURL(url: String) async throws {
    let baseURL = "http://localhost:3000"
    guard let apiURL = URL(string: "\(baseURL)/api/youtube") else {
        throw APIError.invalidURL
    }

    var req = URLRequest(url: apiURL)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try JSONEncoder().encode(["url": url])

    let (_, resp) = try await URLSession.shared.data(for: req)
    guard let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 200 else {
        throw APIError.networkError("Server error")
    }
}