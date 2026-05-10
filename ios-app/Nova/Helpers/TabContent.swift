import SwiftUI

struct TabContent: View {
    var safeAreaBottomPadding: CGFloat
    var tab: Tabs = .home
    var showSettings: Binding<Bool>?

    var body: some View {
        switch tab {
        case .home:    HomeContent(padding: safeAreaBottomPadding, showSettings: showSettings)
        case .new:     NewContent(padding: safeAreaBottomPadding, showSettings: showSettings)
        case .radio:   RadioContent(padding: safeAreaBottomPadding, showSettings: showSettings)
        case .library: LibraryContent(padding: safeAreaBottomPadding, showSettings: showSettings)
        case .search:  SearchContent(padding: safeAreaBottomPadding, showSettings: showSettings)
        }
    }
}

struct HomeContent: View {
    var padding: CGFloat
    var showSettings: Binding<Bool>?
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    Text("Welcome to Nova")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    Text("Import songs via the Search tab to get started")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .background(Color.clear)
            .navigationTitle("Home")
            .safeAreaPadding(.bottom, padding)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings?.wrappedValue = true } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct NewContent: View {
    var padding: CGFloat
    var showSettings: Binding<Bool>?
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No New Releases",
                systemImage: "sparkles",
                description: Text("Check back after importing songs")
            )
            .navigationTitle("What's New")
            .safeAreaPadding(.bottom, padding)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings?.wrappedValue = true } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct RadioContent: View {
    var padding: CGFloat
    var showSettings: Binding<Bool>?
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings?.wrappedValue = true } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct LibraryContent: View {
    var padding: CGFloat
    var showSettings: Binding<Bool>?
    @EnvironmentObject private var player: PlayerManager
    @State private var librarySongs: [Song] = []
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if librarySongs.isEmpty {
                    ContentUnavailableView(
                        "No Songs",
                        systemImage: "music.note",
                        description: Text("Import songs via Search tab")
                    )
                } else {
                    List {
                        ForEach(librarySongs) { song in
                            SongRow(song: song)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Library")
            .safeAreaPadding(.bottom, padding)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings?.wrappedValue = true } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task { await fetchLibrarySongs() }
        }
    }

    private func fetchLibrarySongs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let dtos = try await searchSongs(query: "")
            librarySongs = dtos.map { dto in
                let audioURL: URL?
                if let fp = dto.filePath, !fp.isEmpty {
                    audioURL = URL(string: "\(baseURL)/api/stream/\(dto.id)")
                } else {
                    audioURL = dto.source.flatMap { URL(string: $0) }
                }
                return Song(
                    id: UUID(uuidString: dto.id) ?? UUID(),
                    title: dto.trackName,
                    artist: dto.artistName,
                    duration: TimeInterval(dto.duration ?? 0),
                    artworkURL: dto.coverUrl.flatMap { URL(string: $0) },
                    audioURL: audioURL,
                    lyrics: []
                )
            }
        } catch {
            print("failed to fetch library: \(error)")
        }
    }
}

struct SearchContent: View {
    var padding: CGFloat
    var showSettings: Binding<Bool>?
    @State private var query = ""
    @State private var isImporting = false
    @State private var isSearching = false
    @State private var searchResults: [SongDTO] = []
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            List {
                if isImporting || isSearching {
                    HStack {
                        ProgressView()
                        Text(isImporting ? "Importing..." : "Searching...")
                            .foregroundStyle(.secondary)
                    }
                }

                if !searchResults.isEmpty {
                    Section("Results") {
                        ForEach(searchResults) { dto in
                            SearchResultRow(dto: dto)
                                .onTapGesture { addToQueue(dto) }
                        }
                    }
                }

                if searchResults.isEmpty && query.isEmpty {
                    Section {
                        Text("Search songs or paste a YouTube URL")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Song or YouTube URL")
            .onSubmit(of: .search) { handleSearch() }
            .alert("Notice", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .safeAreaPadding(.bottom, padding)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings?.wrappedValue = true } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var isYouTubeURL: Bool {
        let patterns = ["youtube.com", "youtu.be"]
        return patterns.contains { query.lowercased().contains($0) }
    }

    private func handleSearch() {
        guard !query.isEmpty else { return }
        if isYouTubeURL {
            importYouTubeSong(query)
        } else {
            searchText(query)
        }
    }

    private func searchText(_ q: String) {
        isSearching = true
        searchResults = []
        Task {
            do {
                let results = try await searchSongs(query: q)
                await MainActor.run {
                    isSearching = false
                    searchResults = results
                    if results.isEmpty {
                        alertMessage = "No results"
                        showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    private func importYouTubeSong(_ url: String) {
        isImporting = true
        Task {
            do {
                let song = try await importYouTubeFromURL(url: url)
                await MainActor.run {
                    isImporting = false
                    addToQueue(song)
                    alertMessage = "Added: \(song.trackName)"
                    showAlert = true
                    query = ""
                    searchResults = []
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

    private func addToQueue(_ dto: SongDTO) {
        let audioURL: URL?
        if let fp = dto.filePath, !fp.isEmpty {
            audioURL = URL(string: "\(baseURL)/api/stream/\(dto.id)")
        } else {
            audioURL = dto.source.flatMap { URL(string: $0) }
        }
        let song = Song(
            title: dto.trackName,
            artist: dto.artistName,
            duration: TimeInterval(dto.duration ?? 0),
            artworkURL: dto.coverUrl.flatMap { URL(string: $0) },
            audioURL: audioURL
        )
        PlayerManager.shared.addToQueue(song)
        alertMessage = "Added: \(dto.trackName)"
        showAlert = true
        query = ""
        searchResults = []
    }
}

struct SearchResultRow: View {
    let dto: SongDTO
    var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = dto.coverUrl {
                RemoteImageView(urlString: coverUrl, width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(.secondary)
                    }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(dto.trackName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(dto.artistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if dto.source != nil {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                RemoteImageView(urlString: song.artworkURL?.absoluteString, width: cardSize, height: cardSize)
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
        player.setQueue([song], playImmediately: true)
    }
}

struct SongRow: View {
    let song: Song
    @EnvironmentObject private var player: PlayerManager

    var body: some View {
        Button(action: { playSong() }) {
            HStack(spacing: 12) {
                RemoteImageView(urlString: song.artworkURL?.absoluteString, width: 48, height: 48)
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
        player.setQueue([song], playImmediately: true)
    }
}