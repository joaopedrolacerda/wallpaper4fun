import Foundation

/// Um vídeo que vem dentro do app. Os arquivos são `Videos/<id>.mp4` e a miniatura `Videos/<id>.jpg`.
nonisolated struct BundledVideo: Identifiable, Hashable {
    let id: String
    let title: String
}

/// Vídeos padrão do app. Para adicionar um: coloque `<id>.mp4` e `<id>.jpg` em
/// `wallpaper4fun/Videos/` e inclua uma entrada aqui; nada mais precisa mudar (open-closed).
enum VideoCatalog {
    nonisolated static let defaultID = "cat-sunset"

    static let all: [BundledVideo] = [
        BundledVideo(id: defaultID, title: "Gato no pôr do sol"),
        BundledVideo(id: "motorcycle", title: "Moto na estrada"),
        BundledVideo(id: "appa", title: "Appa na lua"),
        BundledVideo(id: "red-planet", title: "Planeta vermelho"),
        BundledVideo(id: "fractal", title: "Fractal violeta"),
    ]

    static func video(id: String) -> BundledVideo? {
        all.first { $0.id == id }
    }
}

/// Onde ficam os arquivos dos vídeos do app. Em produção, dentro do bundle; nos testes, um dublê.
protocol BundledVideoLocating {
    func videoURL(for video: BundledVideo) -> URL?
    func thumbnailURL(for video: BundledVideo) -> URL?
}

struct BundleVideoLocator: BundledVideoLocating {
    let bundle: Bundle

    func videoURL(for video: BundledVideo) -> URL? { resource(video.id, "mp4") }
    func thumbnailURL(for video: BundledVideo) -> URL? { resource(video.id, "jpg") }

    /// O Xcode pode copiar a pasta `Videos` achatada ou inteira; procura nos dois lugares.
    private func resource(_ name: String, _ ext: String) -> URL? {
        bundle.url(forResource: name, withExtension: ext)
            ?? bundle.url(forResource: name, withExtension: ext, subdirectory: "Videos")
    }
}
