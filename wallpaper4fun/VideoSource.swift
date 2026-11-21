import SwiftUI
import AppKit
import AVFoundation

// MARK: - Tipo de wallpaper

struct VideoSource: WallpaperSource {
    nonisolated static let id = "video"
    var id: String { Self.id }
    let title = "Vídeo"

    func wallpaper(manager: WallpaperManager, playback: Playback) -> AnyView {
        guard let url = manager.videoURL else { return AnyView(Color.black) }
        return AnyView(VideoWallpaperView(url: url, playback: playback))
    }

    func controls(manager: WallpaperManager) -> AnyView {
        AnyView(VideoSourceRow(videoURL: manager.videoURL) { chooseVideo(for: manager) })
    }

    private func chooseVideo(for manager: WallpaperManager) {
        guard let url = VideoPicker.chooseVideo() else { return }
        manager.importVideo(from: url)
    }
}

// MARK: - Views

private struct VideoSourceRow: View {
    let videoURL: URL?
    let onChoose: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "film")
            Text(videoURL?.lastPathComponent ?? "Nenhum vídeo escolhido")
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(videoURL == nil ? .secondary : .primary)
            Spacer()
            Button("Escolher vídeo…", action: onChoose)
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
