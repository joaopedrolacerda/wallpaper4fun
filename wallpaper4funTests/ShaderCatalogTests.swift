import Testing
@testable import wallpaper4fun

struct ShaderCatalogTests {
    @Test("o catálogo tem Aurora, Ondas e Plasma")
    func standardShaders() {
        #expect(ShaderCatalog.all.map(\.id) == ["aurora", "waves", "plasma"])
    }

    @Test("os ids dos shaders não se repetem")
    func uniqueIDs() {
        let ids = ShaderCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("todo shader tem um título")
    func titlesNotEmpty() {
        #expect(ShaderCatalog.all.allSatisfy { !$0.title.isEmpty })
    }

    @Test("encontra o shader pelo id")
    func findsByID() {
        #expect(ShaderCatalog.style(id: "plasma").title == "Plasma")
    }

    @Test("id desconhecido cai no primeiro shader")
    func unknownFallsBackToFirst() {
        #expect(ShaderCatalog.style(id: "nao-existe") == ShaderCatalog.all[0])
    }

    @Test("o shader padrão das configurações existe no catálogo")
    func defaultSettingsShaderExists() {
        #expect(ShaderCatalog.all.contains { $0.id == WallpaperSettings.default.shaderID })
    }
}
