import SwiftUI

struct TabContent: View {
    var safeAreaBottomPadding: CGFloat
    var tab: Tabs = .home

    var body: some View {
        switch tab {
        case .home:    HomeContent(padding: safeAreaBottomPadding)
        case .new:     NewContent(padding: safeAreaBottomPadding)
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
        }
    }
}

struct NewContent: View {
    var padding: CGFloat
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No New Releases",
                systemImage: "sparkles",
                description: Text("Check back after importing songs")
            )
            .navigationTitle("What's New")
            .safeAreaPadding(.bottom, padding)
        }
    }
}

struct LibraryContent: View {
    var padding: CGFloat
    @EnvironmentObject private var player: PlayerManager
    @State private var librarySongs: [Song] = []
    @State private var isLoading: Bool = false
    @State private var songToDelete: Song?
    @State private var showDeleteConfirm: Bool = false

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
                        .onDelete(perform: deleteSongs)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Library")
            .safeAreaPadding(.bottom, padding)
            .alert("Delete Song", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) { songToDelete = nil }
                Button("Delete", role: .destructive) { confirmDelete() }
            } message: {
                Text("Remove \"\(songToDelete?.title ?? "")\" from library and server?")
            }
            .task { await fetchLibrarySongs() }
            .refreshable { await fetchLibrarySongs() }
        }
    }

    private func deleteSongs(at offsets: IndexSet) {
        guard let idx = offsets.first else { return }
        songToDelete = librarySongs[idx]
        showDeleteConfirm = true
    }

    private func confirmDelete() {
        guard let song = songToDelete, let sid = song.serverId else { songToDelete = nil; return }
        librarySongs.removeAll { $0.id == song.id }
        Task {
            try? await deleteSong(id: sid)
        }
        songToDelete = nil
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
                    serverId: dto.id,
                    source: dto.source,
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
    @State private var query = ""
    @State private var isImporting = false
    @State private var isSearching = false
    @State private var searchResults: [SongDTO] = []
    @State private var importingId: String? = nil
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
                            SearchResultRow(dto: dto, isImporting: importingId == dto.id)
                                .contentShape(Rectangle())
                                .onTapGesture { handleResultTap(dto) }
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
            .onChange(of: query) { _, newValue in
                if newValue.isEmpty {
                    searchResults = []
                    isSearching = false
                    isImporting = false
                }
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
                    if song.status == "ready" && song.filePath != nil {
                        addToQueue(song)
                        alertMessage = "Added: \(song.trackName)"
                    } else {
                        alertMessage = "\(song.trackName) already in library"
                    }
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

    private func handleResultTap(_ dto: SongDTO) {
        let isYouTubeResult = dto.status == "youtube" || (dto.youtubeUrl != nil && dto.filePath == nil)
        if isYouTubeResult {
            let url = dto.youtubeUrl ?? dto.source ?? ""
            guard !url.isEmpty else { return }
            importingId = dto.id
            Task {
                do {
                    let imported = try await importYouTubeFromURL(url: url)
                    await MainActor.run {
                        importingId = nil
                        if imported.filePath != nil || imported.source != nil {
                            addToQueue(imported)
                        } else {
                            alertMessage = "Import failed"
                            showAlert = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        importingId = nil
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                }
            }
        } else {
            addToQueue(dto)
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
            serverId: dto.id,
            source: dto.source,
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
    var isImporting: Bool = false
    var body: some View {
        HStack(spacing: 12) {
            if isImporting {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay { ProgressView() }
            } else if let coverUrl = dto.coverUrl {
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
            if isImporting {
                Text("Importing...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if dto.status == "youtube" || dto.youtubeUrl != nil {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
            } else if dto.filePath != nil || dto.source != nil {
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