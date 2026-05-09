import SwiftUI
import Combine
import UIKit

public struct Song: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var artist: String
    public var duration: TimeInterval
    public var artworkURL: URL?
    public var lyrics: [LyricLine]

    public init(id: UUID = .init(), title: String, artist: String, duration: TimeInterval, artworkURL: URL? = nil, lyrics: [LyricLine] = []) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.artworkURL = artworkURL
        self.lyrics = lyrics
    }

    // MARK: - Demo Data
    static let samples: [Song] = [
        Song(title: "Blinding Lights", artist: "The Weeknd", duration: 200, artworkURL: URL(string: "https://cataas.com/cat?width=600&height=600")),
        Song(title: "Levitating", artist: "Dua Lipa", duration: 203, artworkURL: URL(string: "https://cataas.com/cat?width=600&height=600")),
        Song(title: "Stay", artist: "Kid LAROI", duration: 141, artworkURL: URL(string: "https://cataas.com/cat?width=600&height=600")),
        Song(title: "good 4 u", artist: "Olivia Rodrigo", duration: 178, artworkURL: URL(string: "https://cataas.com/cat?width=600&height=600")),
        Song(title: "Heat Waves", artist: "Glass Animals", duration: 239, artworkURL: URL(string: "https://cataas.com/cat?width=600&height=600")),
    ]
}

public struct LyricLine: Equatable {
    public let time: TimeInterval
    public let text: String
}


final class PlayerManager: ObservableObject {
    static let shared = PlayerManager()

    @Published var currentSong: Song? = nil
    @Published var queue: [Song] = []
    @Published var isPlaying: Bool = false
    @Published var progress: TimeInterval = 0
    @Published var isExpanded: Bool = false
    @Published var artwork: UIImage? = nil
    @Published var placeholderArtwork: UIImage? = nil
    @Published var currentLyric: String? = nil

    private var timerCancellable: AnyCancellable?
    private var artworkTask: Task<Void, Never>?
    private let tickInterval: TimeInterval = 0.5

    private init() {}

    func setQueue(_ songs: [Song], startAt index: Int = 0, playImmediately: Bool = false) {
        queue = songs
        if queue.indices.contains(index) {
            currentSong = queue.remove(at: index)
            progress = 0
            loadArtwork()
        } else {
            currentSong = nil
            progress = 0
            artwork = nil
        }
        isPlaying = playImmediately
        if isPlaying { startTimer() } else { stopTimer() }
    }

    func addToQueue(_ song: Song) {
        queue.append(song)
        if currentSong == nil {
            currentSong = queue.removeFirst()
            progress = 0
            loadArtwork()
        }
    }

    // Playback control
    func play() {
        guard currentSong != nil else {
            next()
            return
        }
        isPlaying = true
        startTimer()
    }

    func pause() {
        isPlaying = false
        stopTimer()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func next() {
        if !queue.isEmpty {
            currentSong = queue.removeFirst()
            progress = 0
            loadArtwork()
            if isPlaying { startTimer() }
            updateLyrics()
            return
        }

        // no more songs then stop
        stop()
    }

    func previous() {
        // loop current song
        progress = 0
        updateLyrics()
    }

    func stop() {
        isPlaying = false
        progress = 0
        stopTimer()
    }

    func seek(to time: TimeInterval) {
        guard let duration = currentSong?.duration else { return }
        progress = min(max(0, time), duration)
        updateLyrics()
    }

    // ART!
    func loadArtwork() {
        artworkTask?.cancel()
        artwork = nil
        guard let url = currentSong?.artworkURL else {
            ensurePlaceholderLoaded()
            return
        }

        artworkTask = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = UIImage(data: data) {
                    await MainActor.run {
                        self?.artwork = img
                    }
                }
            } catch {
                // ignore failures silently
                await MainActor.run {
                    self?.ensurePlaceholderLoaded()
                }
            }
        }
    }

    func ensurePlaceholderLoaded() {
        guard placeholderArtwork == nil else { return }
        // Load a single placeholder cat image and cache it for both mini and expanded
        artworkTask?.cancel()
        artworkTask = Task { [weak self] in
            do {
                let url = URL(string: "https://cataas.com/cat?width=600&height=600")!
                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = UIImage(data: data) {
                    await MainActor.run {
                        self?.placeholderArtwork = img
                        // only set artwork if no real artwork is present
                        if self?.artwork == nil {
                            self?.artwork = img
                        }
                    }
                }
            } catch {
                // ignore
            }
        }
    }

    //  Lyric with realtime  SYNC
    // https://www.apple.com/newsroom/2022/12/apple-introduces-apple-music-sing/
    private func updateLyrics() {
        guard let lines = currentSong?.lyrics, !lines.isEmpty else {
            currentLyric = nil
            return
        }

        let idx = (lines.indices).last { lines[$0].time <= progress } ?? nil
        currentLyric = idx.map { lines[$0].text }
    }


    private func startTimer() {
        stopTimer()
        timerCancellable = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func tick() {
        guard isPlaying, let duration = currentSong?.duration else { return }
        progress += tickInterval
        if progress >= duration {
            next()
        }
        updateLyrics()
    }
}


// /Helpers
extension Collection where Index == Int {
    fileprivate func last(where predicate: (Element) -> Bool) -> Int? {
        for i in stride(from: count - 1, through: 0, by: -1) {
            if predicate(self[i]) { return i }
        }
        return nil
    }
}
