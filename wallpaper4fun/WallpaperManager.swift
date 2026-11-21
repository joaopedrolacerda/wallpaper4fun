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
    /// Vídeo importado pelo usuário, guardado mesmo quando um vídeo do app está escolhido.
    private(set) var importedVideoURL: URL?
    private(set) var screensAsleep = false
    private(set) var lastError: String?

    var effectivePaused: Bool { settings.isPaused || screensAsleep }

    /// O vídeo que deve tocar: o do app escolhido ou, se nenhum, o importado.
    var videoURL: URL? {
        guard let id = settings.bundledVideoID else { return importedVideoURL }
        return VideoCatalog.video(id: id).flatMap(bundledVideos.videoURL(for:))
    }

    @ObservationIgnored private let store: SettingsStore
    @ObservationIgnored private let library: VideoLibrary
    @ObservationIgnored private let bundledVideos: BundledVideoLocating
    @ObservationIgnored private let display: WallpaperDisplay
    @ObservationIgnored private var isStarted = false

    init(store: SettingsStore, library: VideoLibrary, bundledVideos: BundledVideoLocating, display: WallpaperDisplay) {
        self.store = store
        self.library = library
        self.bundledVideos = bundledVideos
        self.display = display
        settings = store.load()
        importedVideoURL = settings.videoFileName.flatMap(library.video(named:))
    }

    func start() {
        isStarted = true
        applyEnabledState()
    }

    func screensDidSleep() { screensAsleep = true }
    func screensDidWake() { screensAsleep = false }

    func importVideo(from source: URL) {
        do {
            let imported = try library.importVideo(from: source, replacing: importedVideoURL)
            importedVideoURL = imported
            lastError = nil
            chooseVideo(bundledID: nil, importedFileName: imported.lastPathComponent)
        } catch {
            lastError = "Não foi possível importar o vídeo: \(error.localizedDescription)"
        }
    }

    func selectBundledVideo(id: String) {
        chooseVideo(bundledID: id, importedFileName: settings.videoFileName)
    }

    func selectImportedVideo() {
        chooseVideo(bundledID: nil, importedFileName: settings.videoFileName)
    }

    /// Muda tudo de uma vez, para salvar e notificar uma vez só.
    private func chooseVideo(bundledID: String?, importedFileName: String?) {
        var updated = settings
        updated.bundledVideoID = bundledID
        updated.videoFileName = importedFileName
        updated.sourceID = VideoSource.id
        settings = updated
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
