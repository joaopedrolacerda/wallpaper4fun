import Foundation
import Testing
@testable import wallpaper4fun

struct VideoCatalogTests {
    @Test("o catálogo tem os 5 vídeos padrão, nessa ordem")
    func standardVideos() {
        #expect(VideoCatalog.all.map(\.id) == ["cat-sunset", "motorcycle", "appa", "red-planet", "fractal"])
    }

    @Test("os ids dos vídeos não se repetem")
    func uniqueIDs() {
        let ids = VideoCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("todo vídeo tem um título")
    func titlesNotEmpty() {
        #expect(VideoCatalog.all.allSatisfy { !$0.title.isEmpty })
    }

    @Test("encontra o vídeo pelo id")
    func findsByID() {
        #expect(VideoCatalog.video(id: "appa")?.title == "Appa na lua")
    }

    @Test("id desconhecido não encontra vídeo")
    func unknownIsNil() {
        #expect(VideoCatalog.video(id: "nao-existe") == nil)
    }

    @Test("o vídeo padrão das configurações existe no catálogo")
    func defaultSettingsVideoExists() {
        #expect(VideoCatalog.video(id: WallpaperSettings.default.bundledVideoID ?? "") != nil)
    }

    @Test("todo vídeo do catálogo está dentro do app, com miniatura")
    func everyVideoIsBundled() {
        let locator = BundleVideoLocator(bundle: .main)
        for video in VideoCatalog.all {
            #expect(locator.videoURL(for: video) != nil, "falta \(video.id).mp4 no app")
            #expect(locator.thumbnailURL(for: video) != nil, "falta \(video.id).jpg no app")
        }
    }
}
