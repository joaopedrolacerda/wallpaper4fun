import Foundation
import Observation

/// Quem mostra o wallpaper na tela. Em produção são as janelas do desktop
/// (`DesktopWindowPresenter`); nos testes, um dublê.
protocol WallpaperDisplay: AnyObject {
    func show()
    func hide()
}

/// Estado do app e regras de quando mostrar, pausar e trocar o wallpaper.
/// Não conhece AppKit: tudo que fala com o sistema chega por injeção.
@Observable
final class WallpaperManager {
    var settings: WallpaperSettings {
        didSet { settingsDidChange(from: oldValue) }
    }
    private(set) var videoURL: URL?
    private(set) var screensAsleep = false
    private(set) var lastError: String?

    var effectivePaused: Bool { settings.isPaused || screensAsleep }

    @ObservationIgnored private let store: SettingsStore
    @ObservationIgnored private let library: VideoLibrary
    @ObservationIgnored private let display: WallpaperDisplay
    @ObservationIgnored private var isStarted = false

    init(store: SettingsStore, library: VideoLibrary, display: WallpaperDisplay) {
        self.store = store
        self.library = library
        self.display = display
        settings = store.load()
        videoURL = settings.videoFileName.flatMap(library.video(named:))
    }

    func start() {
        isStarted = true
        applyEnabledState()
    }

    func screensDidSleep() { screensAsleep = true }
    func screensDidWake() { screensAsleep = false }

    func importVideo(from source: URL) {
        do {
            let imported = try library.importVideo(from: source, replacing: videoURL)
            select(video: imported)
        } catch {
            lastError = "Não foi possível importar o vídeo: \(error.localizedDescription)"
        }
    }

    private func select(video url: URL) {
        videoURL = url
        settings.videoFileName = url.lastPathComponent
        settings.sourceID = VideoSource.id
        lastError = nil
    }

    private func settingsDidChange(from old: WallpaperSettings) {
        store.save(settings)
        if old.isEnabled != settings.isEnabled { applyEnabledState() }
    }

    private func applyEnabledState() {
        guard isStarted else { return }
        settings.isEnabled ? display.show() : display.hide()
    }
}
