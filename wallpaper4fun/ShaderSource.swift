import SwiftUI

// MARK: - Catálogo

/// Um shader de `Shaders.metal`. O `id` precisa ser igual ao nome da função Metal.
nonisolated struct ShaderStyle: Identifiable, Hashable {
    let id: String
    let title: String

    static let aurora = ShaderStyle(id: "aurora", title: "Aurora")
    static let waves = ShaderStyle(id: "waves", title: "Ondas")
    static let plasma = ShaderStyle(id: "plasma", title: "Plasma")

    func shader(size: CGSize, time: Float) -> Shader {
        Shader(function: ShaderFunction(library: .default, name: id),
               arguments: [.float2(size), .float(time)])
    }
}

/// Shaders disponíveis. Para adicionar um, escreva a função em `Shaders.metal`
/// e inclua uma entrada aqui; nada mais precisa mudar (open-closed).
enum ShaderCatalog {
    static let all: [ShaderStyle] = [.aurora, .waves, .plasma]

    /// Um id desconhecido (ex.: shader removido) cai no primeiro da lista.
    static func style(id: String) -> ShaderStyle {
        all.first { $0.id == id } ?? all[0]
    }
}

// MARK: - Tipo de wallpaper

struct ShaderSource: WallpaperSource {
    nonisolated static let id = "shader"
    var id: String { Self.id }
    let title = "Shader"

    func wallpaper(manager: WallpaperManager, playback: Playback) -> AnyView {
        AnyView(ShaderWallpaperView(style: ShaderCatalog.style(id: manager.settings.shaderID), playback: playback))
    }

    func controls(manager: WallpaperManager) -> AnyView {
        AnyView(ShaderPicker(manager: manager))
    }
}

// MARK: - Views

struct ShaderWallpaperView: View {
    /// 30 fps é suave o bastante para um fundo e gasta bem menos GPU/bateria.
    static let frameInterval: TimeInterval = 1.0 / 30

    let style: ShaderStyle
    let playback: Playback
    @State private var clock = ShaderClock()

    var body: some View {
        TimelineView(.animation(minimumInterval: Self.frameInterval, paused: playback.paused)) { context in
            shaderRectangle(time: clock.tick(context.date, speed: playback.speed))
        }
    }

    private func shaderRectangle(time: Float) -> some View {
        Rectangle().visualEffect { [style] content, proxy in
            content.colorEffect(style.shader(size: proxy.size, time: time))
        }
    }
}

private struct ShaderPicker: View {
    @Bindable var manager: WallpaperManager

    var body: some View {
        HStack(spacing: 12) {
            ForEach(ShaderCatalog.all) { style in
                Button { manager.settings.shaderID = style.id } label: { thumbnail(for: style) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func thumbnail(for style: ShaderStyle) -> some View {
        VStack(spacing: 6) {
            ShaderWallpaperView(style: style, playback: Playback(paused: false, speed: 1))
                .frame(height: 70)
                .clipShape(.rect(cornerRadius: 8))
                .overlay { selectionBorder(isSelected: style.id == manager.settings.shaderID) }
            Text(style.title).font(.callout)
        }
    }

    private func selectionBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 3)
    }
}
