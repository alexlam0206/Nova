import SwiftUI
import Combine
import AVFoundation
import MediaPlayer

public struct Song: Identifiable, Equatable {
    public let id: UUID
    public var serverId: String?
    public var source: String?
    public var title: String
    public var artist: String
    public var duration: TimeInterval
    public var artworkURL: URL?
    public var audioURL: URL?
    public var lyrics: [LyricLine]

    public init(id: UUID = .init(), serverId: String? = nil, source: String? = nil, title: String, artist: String, duration: TimeInterval,
                artworkURL: URL? = nil, audioURL: URL? = nil, lyrics: [LyricLine] = []) {
        self.id = id
        self.serverId = serverId
        self.source = source
        self.title = title
        self.artist = artist
        self.duration = duration
        self.artworkURL = artworkURL
        self.audioURL = audioURL
        self.lyrics = lyrics
    }
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
    @Published var isFavorited: Bool = false

    private var avPlayer: AVPlayer? = nil
    private var timeObserver: Any? = nil
    private var artworkTask: Task<Void, Never>?

    private init() {
        setupRemoteCommands()
    }

    func setQueue(_ songs: [Song], startAt index: Int = 0, playImmediately: Bool = false) {
        cleanupPlayer()
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
        if playImmediately { play() }
        updateNowPlayingInfo()
    }

    func addToQueue(_ song: Song) {
        queue.append(song)
        if currentSong == nil {
            currentSong = queue.removeFirst()
            progress = 0
            loadArtwork()
        }
    }

    func play() {
        guard currentSong != nil else { next(); return }
        if avPlayer == nil { loadAVPlayer() }
        avPlayer?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    func pause() {
        avPlayer?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func next() {
        cleanupPlayer()
        if !queue.isEmpty {
            currentSong = queue.removeFirst()
            progress = 0
            loadArtwork()
            if isPlaying { play() }
            updateLyrics()
            updateNowPlayingInfo()
            return
        }
        stop()
    }

    func previous() {
        progress = 0
        avPlayer?.seek(to: .zero)
        updateLyrics()
    }

    func stop() {
        cleanupPlayer()
        isPlaying = false
        progress = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        avPlayer?.seek(to: cmTime)
        progress = time
    }

    func toggleFavorite() {
        isFavorited.toggle()
    }

    func playSong(at index: Int) {
        guard queue.indices.contains(index) else { return }
        currentSong = queue[index]
        progress = 0
        loadArtwork()
        play()
    }

    private func loadAVPlayer() {
        guard let url = currentSong?.audioURL else { return }
        cleanupPlayer()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("audio session error: \(error)")
        }

        avPlayer = AVPlayer(url: url)
        let interval = CMTime(seconds: 2.0, preferredTimescale: 600)
        timeObserver = avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.progress = time.seconds
            self?.updateNowPlayingInfo()
        }
    }

    private func cleanupPlayer() {
        if let obs = timeObserver { avPlayer?.removeTimeObserver(obs); timeObserver = nil }
        avPlayer?.pause()
        avPlayer = nil
    }

    private func setupRemoteCommands() {
        let cmd = MPRemoteCommandCenter.shared()
        cmd.playCommand.addTarget { [weak self] _ in self?.play(); return .success }
        cmd.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        cmd.togglePlayPauseCommand.addTarget { [weak self] _ in self?.togglePlayPause(); return .success }
        cmd.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        cmd.previousTrackCommand.addTarget { [weak self] _ in self?.previous(); return .success }
        cmd.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let e = event as? MPChangePlaybackPositionCommandEvent { self?.seek(to: e.positionTime) }
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: currentSong?.title ?? "",
            MPMediaItemPropertyArtist: currentSong?.artist ?? "",
            MPMediaItemPropertyPlaybackDuration: currentSong?.duration ?? 0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: progress,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        if let img = artwork {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size, requestHandler: { _ in img })
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func loadArtwork() {
        artworkTask?.cancel()
        artwork = nil
        guard let url = currentSong?.artworkURL else { return }

        artworkTask = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = UIImage(data: data) {
                    await MainActor.run { self?.artwork = img }
                }
            } catch { }
        }
    }

    private func updateLyrics() {
        guard let lines = currentSong?.lyrics, !lines.isEmpty else {
            currentLyric = nil
            return
        }
        let idx = (lines.indices).last { lines[$0].time <= progress }
        currentLyric = idx.map { lines[$0].text }
    }
}