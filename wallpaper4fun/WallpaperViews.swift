import SwiftUI

/// Como a animação deve tocar. Agrupa pausa e velocidade, usadas por todos os tipos (DRY).
struct Playback: Equatable {
    var paused: Bool
    var speed: Double
}

/// O que aparece dentro de cada janela de wallpaper (e na prévia do painel).
/// Não conhece os tipos concretos: pede ao registro (open-closed).
struct WallpaperContent: View {
    let manager: WallpaperManager
    var registry: WallpaperSourceRegistry = .standard

    private var playback: Playback {
        Playback(paused: manager.effectivePaused, speed: manager.settings.speed)
    }

    var body: some View {
        registry.source(id: manager.settings.sourceID)
            .wallpaper(manager: manager, playback: playback)
    }
}
