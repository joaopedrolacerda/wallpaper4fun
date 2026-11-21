import SwiftUI
import AppKit

/// Painel de controle do wallpaper. Só monta a interface; as regras ficam no `WallpaperManager`.
struct ContentView: View {
    @Bindable var manager: WallpaperManager
    var registry: WallpaperSourceRegistry = .standard
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PreviewArea(manager: manager)
            kindPicker
            sourcePicker
            OptionsForm(settings: $manager.settings)
            errorMessage
            closeButton
        }
        .padding(24)
        .frame(width: 520)
        .onAppear { updateDock(panelVisible: true) }
        .onDisappear { updateDock(panelVisible: false) }
    }

    private var kindPicker: some View {
        Picker("Tipo", selection: $manager.settings.sourceID) {
            ForEach(registry.sources, id: \.id) { Text($0.title).tag($0.id) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    /// Cada tipo de wallpaper traz os próprios controles (open-closed).
    private var sourcePicker: some View {
        registry.source(id: manager.settings.sourceID).controls(manager: manager)
    }

    @ViewBuilder private var errorMessage: some View {
        if let error = manager.lastError {
            Text(error).foregroundStyle(.red).font(.callout)
        }
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button { dismissWindow(id: "main") } label: {
                Label("Fechar e ir pra barra de menus", systemImage: "menubar.arrow.up.rectangle")
            }
            .keyboardShortcut("w")
        }
    }

    private func updateDock(panelVisible: Bool) {
        DockPolicy.apply(panelVisible: panelVisible, hideDockWhenClosed: manager.settings.hideDockWhenClosed)
    }
}

// MARK: - Partes do painel

private struct PreviewArea: View {
    let manager: WallpaperManager

    var body: some View {
        WallpaperContent(manager: manager)
            .aspectRatio(16 / 10, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 12))
            .overlay { disabledBadge }
    }

    @ViewBuilder private var disabledBadge: some View {
        if !manager.settings.isEnabled {
            Text("Wallpaper desligado")
                .font(.headline)
                .padding(8)
                .background(.regularMaterial, in: .capsule)
        }
    }
}

private struct OptionsForm: View {
    @Binding var settings: WallpaperSettings

    var body: some View {
        Form {
            Toggle("Wallpaper ativo", isOn: $settings.isEnabled)
            Toggle("Pausar animação", isOn: $settings.isPaused)
            Toggle("Ao fechar, ficar só na barra de menus", isOn: $settings.hideDockWhenClosed)
            LabeledContent("Velocidade") { speedSlider }
        }
        .formStyle(.columns)
    }

    private var speedSlider: some View {
        Slider(value: $settings.speed, in: 0.25...3) {
            Text("Velocidade")
        } minimumValueLabel: {
            Image(systemName: "tortoise")
        } maximumValueLabel: {
            Image(systemName: "hare")
        }
    }
}

// MARK: - Preview

private final class SilentDisplay: WallpaperDisplay {
    func show() {}
    func hide() {}
}

#Preview {
    ContentView(manager: WallpaperManager(
        store: SettingsStore(defaults: UserDefaults(suiteName: "preview")!),
        library: VideoLibrary(folder: .temporaryDirectory),
        bundledVideos: BundleVideoLocator(bundle: .main),
        display: SilentDisplay()
    ))
}
