import SwiftUI
import AppKit
import AVFoundation

// MARK: - Tipo de wallpaper

struct VideoSource: WallpaperSource {
    nonisolated static let id = "video"
    var id: String { Self.id }
    let title = "Vídeo"
    var locator: BundledVideoLocating = BundleVideoLocator(bundle: .main)

    func wallpaper(manager: WallpaperManager, playback: Playback) -> AnyView {
        guard let url = manager.videoURL else { return AnyView(Color.black) }
        return AnyView(VideoWallpaperView(url: url, playback: playback))
    }

    func controls(manager: WallpaperManager) -> AnyView {
        AnyView(VideoGallery(manager: manager, locator: locator, onChooseFile: { chooseVideo(for: manager) }))
    }

    private func chooseVideo(for manager: WallpaperManager) {
        guard let url = VideoPicker.chooseVideo() else { return }
        manager.importVideo(from: url)
    }
}

// MARK: - Views

/// Vídeos do app em miniatura, o vídeo importado e o botão para escolher outro arquivo.
private struct VideoGallery: View {
    let manager: WallpaperManager
    let locator: BundledVideoLocating
    let onChooseFile: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(VideoCatalog.all) { bundledTile($0) }
                    if let imported = manager.importedVideoURL { importedTile(imported) }
                }
            }
            Button("Escolher outro vídeo…", action: onChooseFile)
        }
    }

    private func bundledTile(_ video: BundledVideo) -> some View {
        GalleryTile(title: video.title, isSelected: manager.settings.bundledVideoID == video.id) {
            ThumbnailImage(url: locator.thumbnailURL(for: video))
        } action: {
            manager.selectBundledVideo(id: video.id)
        }
    }

    private func importedTile(_ url: URL) -> some View {
        GalleryTile(title: url.deletingPathExtension().lastPathComponent, isSelected: manager.settings.bundledVideoID == nil) {
            Image(systemName: "film").font(.title2).frame(maxWidth: .infinity, maxHeight: .infinity).background(.quaternary)
        } action: {
            manager.selectImportedVideo()
        }
    }
}

/// Uma miniatura clicável com título e borda de seleção.
private struct GalleryTile<Preview: View>: View {
    let title: String
    let isSelected: Bool
    @ViewBuilder let preview: () -> Preview
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                preview()
                    .frame(width: 96, height: 54)
                    .clipShape(.rect(cornerRadius: 6))
                    .overlay { selectionBorder }
                Text(title).font(.caption).lineLimit(1).frame(width: 96)
            }
        }
        .buttonStyle(.plain)
    }

    private var selectionBorder: some View {
        RoundedRectangle(cornerRadius: 6).strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 3)
    }
}

private struct ThumbnailImage: View {
    let url: URL?

    var body: some View {
        if let url, let image = NSImage(contentsOf: url) {
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
        } else {
            Color.black
        }
    }
}

struct VideoWallpaperView: NSViewRepresentable {
    let url: URL
    let playback: Playback

    func makeNSView(context: Context) -> LoopingPlayerView { LoopingPlayerView() }

    func updateNSView(_ view: LoopingPlayerView, context: Context) {
        view.load(url)
        view.apply(playback)
    }

    static func dismantleNSView(_ view: LoopingPlayerView, coordinator: ()) {
        view.stop()
    }
}

/// Toca um vídeo mudo em loop, preenchendo a tela.
final class LoopingPlayerView: NSView {
    private let player = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private var currentURL: URL?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não é usado") }

    override func makeBackingLayer() -> CALayer {
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    func load(_ url: URL) {
        guard url != currentURL else { return }
        currentURL = url
        player.removeAllItems()
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
    }

    func apply(_ playback: Playback) {
        guard !playback.paused else { return player.pause() }
        player.defaultRate = Float(playback.speed)
        player.play()
    }

    func stop() {
        player.pause()
        looper = nil
        currentURL = nil
        player.removeAllItems()
    }
}
