import Foundation

/// Tudo que o usuário escolhe no painel. É salvo inteiro, num lugar só.
nonisolated struct WallpaperSettings: Codable, Equatable {
    var sourceID = ShaderSource.id
    var shaderID = ShaderStyle.aurora.id
    var speed: Double = 1
    var isPaused = false
    var isEnabled = true
    var hideDockWhenClosed = true
    /// Vídeo importado pelo usuário (nome do arquivo na `VideoLibrary`).
    var videoFileName: String?
    /// Vídeo do app escolhido (`VideoCatalog`). `nil` = usar o vídeo importado.
    var bundledVideoID: String? = VideoCatalog.defaultID

    static let `default` = WallpaperSettings()
}

/// Lê e grava `WallpaperSettings` como JSON no `UserDefaults`.
struct SettingsStore {
    static let key = "wallpaperSettings"
    let defaults: UserDefaults

    func load() -> WallpaperSettings {
        guard let data = defaults.data(forKey: Self.key),
              let settings = try? JSONDecoder().decode(WallpaperSettings.self, from: data)
        else { return .default }
        return settings
    }

    func save(_ settings: WallpaperSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
