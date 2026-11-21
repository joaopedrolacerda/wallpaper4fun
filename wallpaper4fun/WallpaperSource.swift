import SwiftUI

/// Um tipo de wallpaper (shader, vídeo, ...).
///
/// Open-closed: para criar um tipo novo, escreva um tipo que conforma a este
/// protocolo e registre-o em `WallpaperSourceRegistry.standard`. Nenhuma view,
/// painel ou `switch` existente precisa mudar.
protocol WallpaperSource {
    /// Identificador salvo nas configurações. Não mude depois de publicado.
    var id: String { get }
    var title: String { get }

    /// O que aparece na tela (e na prévia do painel).
    func wallpaper(manager: WallpaperManager, playback: Playback) -> AnyView

    /// Controles específicos deste tipo, mostrados no painel.
    func controls(manager: WallpaperManager) -> AnyView
}

/// Lista dos tipos de wallpaper disponíveis. Único ponto de registro.
struct WallpaperSourceRegistry {
    let sources: [any WallpaperSource]

    static let standard = WallpaperSourceRegistry(sources: [
        ShaderSource(),
        VideoSource(),
    ])

    /// Um id desconhecido (ex.: tipo removido) cai no primeiro tipo da lista.
    func source(id: String) -> any WallpaperSource {
        sources.first { $0.id == id } ?? sources[0]
    }
}
