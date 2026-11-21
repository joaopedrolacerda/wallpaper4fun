import Foundation
import Testing
@testable import wallpaper4fun

/// Dublê das janelas do desktop: só registra o que foi pedido.
final class FakeDisplay: WallpaperDisplay {
    private(set) var isShowing = false
    private(set) var showCount = 0

    func show() {
        isShowing = true
        showCount += 1
    }

    func hide() {
        isShowing = false
    }
}

struct WallpaperManagerTests {
    private let defaults = TemporaryDefaults()
    private let videos = TemporaryFolder()
    private let source = TemporaryFolder()
    private let display = FakeDisplay()

    private var store: SettingsStore { SettingsStore(defaults: defaults.defaults) }
    private var library: VideoLibrary { VideoLibrary(folder: videos.url) }

    private func makeManager() -> WallpaperManager {
        WallpaperManager(store: store, library: library, display: display)
    }

    // MARK: Configurações

    @Test("começa com as configurações salvas")
    func loadsSavedSettings() {
        var saved = WallpaperSettings.default
        saved.shaderID = "waves"
        store.save(saved)

        #expect(makeManager().settings == saved)
    }

    @Test("mudar uma configuração salva na hora")
    func persistsChanges() {
        let manager = makeManager()
        manager.settings.speed = 2

        #expect(store.load().speed == 2)
    }

    // MARK: Ligar e desligar

    @Test("ao iniciar ativo, mostra o wallpaper")
    func startShowsWhenEnabled() {
        makeManager().start()
        #expect(display.isShowing)
    }

    @Test("ao iniciar desligado, não mostra o wallpaper")
    func startDoesNotShowWhenDisabled() {
        var saved = WallpaperSettings.default
        saved.isEnabled = false
        store.save(saved)

        makeManager().start()

        #expect(!display.isShowing)
    }

    @Test("antes de iniciar, mudar configurações não mexe nas janelas")
    func nothingShownBeforeStart() {
        let manager = makeManager()
        manager.settings.isEnabled = true
        #expect(display.showCount == 0)
    }

    @Test("desligar esconde e religar mostra de novo")
    func togglingEnabled() {
        let manager = makeManager()
        manager.start()

        manager.settings.isEnabled = false
        #expect(!display.isShowing)

        manager.settings.isEnabled = true
        #expect(display.isShowing)
    }

    @Test("mudar outras configurações não recria as janelas")
    func otherChangesDoNotReshow() {
        let manager = makeManager()
        manager.start()

        manager.settings.shaderID = "plasma"
        manager.settings.speed = 3

        #expect(display.showCount == 1)
    }

    // MARK: Pausa

    @Test("fica pausado quando o usuário pausa")
    func pausedByUser() {
        let manager = makeManager()
        manager.settings.isPaused = true
        #expect(manager.effectivePaused)
    }

    @Test("pausa quando as telas dormem e volta quando acordam")
    func pausedWhileScreensSleep() {
        let manager = makeManager()
        #expect(!manager.effectivePaused)

        manager.screensDidSleep()
        #expect(manager.effectivePaused)

        manager.screensDidWake()
        #expect(!manager.effectivePaused)
    }

    // MARK: Vídeo

    @Test("importar um vídeo passa a usá-lo como wallpaper")
    func importVideoSelectsIt() throws {
        let manager = makeManager()

        manager.importVideo(from: try source.makeFile(named: "praia.mov"))

        #expect(manager.videoURL == videos.url.appending(path: "praia.mov"))
        #expect(manager.settings.sourceID == VideoSource.id)
        #expect(manager.settings.videoFileName == "praia.mov")
        #expect(manager.lastError == nil)
    }

    @Test("falha ao importar mostra um erro e não troca o vídeo")
    func importFailureSetsError() {
        let manager = makeManager()

        manager.importVideo(from: source.url.appending(path: "nao-existe.mov"))

        #expect(manager.lastError != nil)
        #expect(manager.videoURL == nil)
        #expect(manager.settings.sourceID == ShaderSource.id)
    }

    @Test("um import que dá certo limpa o erro anterior")
    func successClearsError() throws {
        let manager = makeManager()
        manager.importVideo(from: source.url.appending(path: "nao-existe.mov"))

        manager.importVideo(from: try source.makeFile(named: "praia.mov"))

        #expect(manager.lastError == nil)
    }

    @Test("ao abrir, recupera o vídeo salvo")
    func restoresSavedVideo() throws {
        makeManager().importVideo(from: try source.makeFile(named: "praia.mov"))

        #expect(makeManager().videoURL == videos.url.appending(path: "praia.mov"))
    }

    @Test("se o vídeo salvo sumiu, fica sem vídeo")
    func missingSavedVideo() {
        var saved = WallpaperSettings.default
        saved.videoFileName = "sumiu.mov"
        store.save(saved)

        #expect(makeManager().videoURL == nil)
    }
}
