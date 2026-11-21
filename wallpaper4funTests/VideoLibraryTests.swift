import Foundation
import Testing
@testable import wallpaper4fun

struct VideoLibraryTests {
    private let source = TemporaryFolder()
    private let storage = TemporaryFolder()
    private var library: VideoLibrary { VideoLibrary(folder: storage.url) }

    @Test("importar copia o vídeo para a pasta da biblioteca")
    func importCopiesIntoFolder() throws {
        let video = try source.makeFile(named: "praia.mov")

        let imported = try library.importVideo(from: video)

        #expect(imported == storage.url.appending(path: "praia.mov"))
        #expect(FileManager.default.fileExists(atPath: imported.path))
        #expect(FileManager.default.fileExists(atPath: video.path), "o original continua onde estava")
    }

    @Test("importar cria a pasta da biblioteca se ela não existir")
    func importCreatesFolder() throws {
        let video = try source.makeFile(named: "praia.mov")
        let library = VideoLibrary(folder: storage.url.appending(path: "nova", directoryHint: .isDirectory))

        let imported = try library.importVideo(from: video)

        #expect(FileManager.default.fileExists(atPath: imported.path))
    }

    @Test("importar um vídeo novo apaga o anterior")
    func importReplacesPrevious() throws {
        let first = try library.importVideo(from: source.makeFile(named: "a.mov"))

        _ = try library.importVideo(from: source.makeFile(named: "b.mov"), replacing: first)

        #expect(!FileManager.default.fileExists(atPath: first.path))
    }

    @Test("importar um vídeo com o mesmo nome substitui o conteúdo")
    func importOverwritesSameName() throws {
        let first = try library.importVideo(from: source.makeFile(named: "a.mov", contents: "velho"))
        let newer = try source.makeFile(named: "a.mov", contents: "novo")

        let imported = try library.importVideo(from: newer, replacing: first)

        #expect(try String(contentsOf: imported, encoding: .utf8) == "novo")
    }

    @Test("importar um arquivo que não existe lança erro")
    func importMissingFileThrows() {
        let missing = source.url.appending(path: "nao-existe.mov")
        #expect(throws: (any Error).self) { try library.importVideo(from: missing) }
    }

    @Test("encontra um vídeo salvo pelo nome")
    func findsSavedVideo() throws {
        let imported = try library.importVideo(from: source.makeFile(named: "praia.mov"))
        #expect(library.video(named: "praia.mov") == imported)
    }

    @Test("não encontra vídeo que não está na pasta")
    func missingVideoIsNil() {
        #expect(library.video(named: "sumiu.mov") == nil)
    }
}
