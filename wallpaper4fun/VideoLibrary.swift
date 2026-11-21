import Foundation

/// Guarda os vídeos escolhidos numa pasta do app. Copiar o arquivo evita
/// perder o acesso a ele depois de reiniciar, já que o app roda em sandbox.
struct VideoLibrary {
    let folder: URL
    var fileManager: FileManager = .default

    static let appFolder = URL.applicationSupportDirectory
        .appending(path: "Wallpapers", directoryHint: .isDirectory)

    func importVideo(from source: URL, replacing previous: URL? = nil) throws -> URL {
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = folder.appending(path: source.lastPathComponent)
        removeIfPresent(previous)
        removeIfPresent(destination)
        try fileManager.copyItem(at: source, to: destination)
        return destination
    }

    func video(named name: String) -> URL? {
        let url = folder.appending(path: name)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    private func removeIfPresent(_ url: URL?) {
        guard let url, fileManager.fileExists(atPath: url.path) else { return }
        try? fileManager.removeItem(at: url)
    }
}
