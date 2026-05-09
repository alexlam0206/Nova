import SwiftUI

struct TabContent: View {
    var safeAreaBottomPadding: CGFloat
    var tab: Tabs = .home

    var body: some View {
        switch tab {
        case .home:    HomeContent(padding: safeAreaBottomPadding)
        case .new:     NewContent(padding: safeAreaBottomPadding)
        case .radio:   RadioContent(padding: safeAreaBottomPadding)
        case .library: LibraryContent(padding: safeAreaBottomPadding)
        case .search:  SearchContent(padding: safeAreaBottomPadding)
        }
    }
}

struct HomeContent: View {
    var padding: CGFloat
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    Text("Recently Played")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(Song.samples.prefix(3)) { song in
                                SongCard(song: song, cardSize: 140)
                            }
                        }
                        .padding(.horizontal)
                    }
                    Text("Made For You")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(Song.samples) { song in
                                SongCard(song: song, cardSize: 160)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .background(Color.clear)
            .navigationTitle("Home")
            .safeAreaPadding(.bottom, padding)
        }
    }
}

struct NewContent: View {
    var padding: CGFloat
    var body: some View {
        NavigationStack {
            List {
                ForEach(Song.samples) { song in
                    SongRow(song: song)
                }
            }
            .listStyle(.plain)
            .navigationTitle("What's New")
            .safeAreaPadding(.bottom, padding)
        }
    }
}

struct RadioContent: View {
    var padding: CGFloat
    var body: some View {
        NavigationStack {
            List(0..<5) { i in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .foregroundStyle(.secondary)
                        }
                    VStack(alignment: .leading) {
                        Text("Station \(i + 1)")
                            .font(.headline)
                        Text("Live")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Radio")
            .safeAreaPadding(.bottom, padding)
        }
    }
}

struct LibraryContent: View {
    var padding: CGFloat
    @EnvironmentObject private var player: PlayerManager

    var body: some View {
        NavigationStack {
            List {
                ForEach(Song.samples) { song in
                    SongRow(song: song)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Library")
            .safeAreaPadding(.bottom, padding)
        }
    }
}

struct SearchContent: View {
    var padding: CGFloat
    @State private var query = ""
    @State private var isImporting = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            List {
                if isImporting {
                    HStack {
                        ProgressView()
                        Text("Importing...")
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Text("Paste a YouTube URL to import a song")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Song or YouTube URL")
            .onSubmit(of: .search) {
                handleSearch()
            }
            .alert("Notice", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .safeAreaPadding(.bottom, padding)
        }
    }

    private var isYouTubeURL: Bool {
        let patterns = ["youtube.com", "youtu.be"]
        let lower = query.lowercased()
        return patterns.contains { lower.contains($0) }
    }

    private func handleSearch() {
        guard !query.isEmpty else { return }
        if isYouTubeURL {
            importYouTubeSong(query)
        } else {
            alertMessage = "Text search coming soon"
            showAlert = true
            query = ""
        }
    }

    private func importYouTubeSong(_ url: String) {
        isImporting = true
        Task {
            do {
                try await importYouTubeFromURL(url: url)
                await MainActor.run {
                    isImporting = false
                    alertMessage = "Song imported!"
                    showAlert = true
                    query = ""
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

struct SongCard: View {
    let song: Song
    let cardSize: CGFloat
    @EnvironmentObject private var player: PlayerManager

    var body: some View {
        Button(action: { playSong() }) {
            VStack(alignment: .leading, spacing: 8) {
                RemoteImageView(urlString: "https://cataas.com/cat?width=\(Int(cardSize))&height=\(Int(cardSize))", width: cardSize, height: cardSize)
                    .clipShape(RoundedRectangle(cornerRadius: cardSize / 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    Text(song.artist)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: cardSize)
        }
        .buttonStyle(.plain)
    }

    private func playSong() {
        if let idx = Song.samples.firstIndex(where: { $0.id == song.id }) {
            player.setQueue(Song.samples, startAt: idx, playImmediately: true)
        }
    }
}

struct SongRow: View {
    let song: Song
    @EnvironmentObject private var player: PlayerManager

    var body: some View {
        Button(action: { playSong() }) {
            HStack(spacing: 12) {
                RemoteImageView(urlString: "https://cataas.com/cat?width=96&height=96", width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(song.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(formatTime(TimeInterval(song.duration)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func playSong() {
        if let idx = Song.samples.firstIndex(where: { $0.id == song.id }) {
            player.setQueue(Song.samples, startAt: idx, playImmediately: true)
        }
    }
}