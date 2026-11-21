import Foundation
import Testing
@testable import wallpaper4fun

struct SettingsStoreTests {
    private let temp = TemporaryDefaults()
    private var store: SettingsStore { SettingsStore(defaults: temp.defaults) }

    @Test("sem nada salvo, carrega as configurações padrão")
    func loadsDefaultsWhenEmpty() {
        #expect(store.load() == .default)
    }

    @Test("o padrão é o tipo shader com Aurora, ativo, sem pausa, velocidade 1 e escondendo o Dock")
    func defaultValues() {
        let settings = WallpaperSettings.default
        #expect(settings.sourceID == ShaderSource.id)
        #expect(settings.shaderID == "aurora")
        #expect(settings.isEnabled)
        #expect(!settings.isPaused)
        #expect(settings.speed == 1)
        #expect(settings.hideDockWhenClosed)
        #expect(settings.videoFileName == nil)
    }

    @Test("salvar e carregar devolve as mesmas configurações")
    func roundTrip() {
        var settings = WallpaperSettings.default
        settings.sourceID = VideoSource.id
        settings.shaderID = "plasma"
        settings.speed = 2.5
        settings.isPaused = true
        settings.videoFileName = "praia.mov"

        store.save(settings)

        #expect(store.load() == settings)
    }

    @Test("dados corrompidos voltam para o padrão")
    func corruptedDataFallsBackToDefault() {
        temp.defaults.set(Data("lixo".utf8), forKey: SettingsStore.key)
        #expect(store.load() == .default)
    }
}
