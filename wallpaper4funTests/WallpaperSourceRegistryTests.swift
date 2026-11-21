import SwiftUI
import Testing
@testable import wallpaper4fun

/// Um tipo de wallpaper inventado, para provar que dá pra estender sem mexer no código existente.
private struct FakeSource: WallpaperSource {
    let id = "fake"
    let title = "Fake"
    func wallpaper(manager: WallpaperManager, playback: Playback) -> AnyView { AnyView(Color.clear) }
    func controls(manager: WallpaperManager) -> AnyView { AnyView(EmptyView()) }
}

struct WallpaperSourceRegistryTests {
    private let registry = WallpaperSourceRegistry.standard

    @Test("o registro padrão tem shader e vídeo, nessa ordem")
    func standardSources() {
        #expect(registry.sources.map(\.id) == [ShaderSource.id, VideoSource.id])
    }

    @Test("os ids dos tipos não se repetem")
    func uniqueIDs() {
        let ids = registry.sources.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("todo tipo tem um título")
    func titlesNotEmpty() {
        #expect(registry.sources.allSatisfy { !$0.title.isEmpty })
    }

    @Test("encontra o tipo pelo id")
    func findsByID() {
        #expect(registry.source(id: VideoSource.id).id == VideoSource.id)
    }

    @Test("id desconhecido cai no primeiro tipo")
    func unknownFallsBackToFirst() {
        #expect(registry.source(id: "nao-existe").id == ShaderSource.id)
    }

    @Test("um tipo novo funciona só sendo registrado")
    func extendsWithNewSource() {
        let extended = WallpaperSourceRegistry(sources: registry.sources + [FakeSource()])
        #expect(extended.source(id: "fake").title == "Fake")
    }

    @Test("o tipo padrão das configurações existe no registro")
    func defaultSettingsSourceIsRegistered() {
        #expect(registry.sources.contains { $0.id == WallpaperSettings.default.sourceID })
    }
}
