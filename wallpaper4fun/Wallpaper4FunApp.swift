import SwiftUI
import AppKit

/// Monta as peças do app e liga a lógica (`WallpaperManager`) ao AppKit.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let manager: WallpaperManager
    private let presenter = DesktopWindowPresenter()
    private var systemEvents: SystemEventObserver?

    override init() {
        manager = WallpaperManager(
            store: SettingsStore(defaults: .standard),
            library: VideoLibrary(folder: VideoLibrary.appFolder),
            display: presenter
        )
        super.init()
        presenter.makeContent = { [manager] in
            NSHostingView(rootView: WallpaperContent(manager: manager))
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.isRunningTests else { return }
        systemEvents = SystemEventObserver(manager: manager)
        manager.start()
    }

    // Fechar a janela de controle não encerra o app: o wallpaper continua rodando.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    /// Os testes rodam dentro do app; nesse caso não abrimos as janelas do desktop.
    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}

@main struct Wallpaper4FunApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("wallpaper4fun", id: "main") {
            ContentView(manager: appDelegate.manager)
        }
        .windowResizability(.contentSize)

        MenuBarExtra("wallpaper4fun", systemImage: "sparkles.tv") {
            MenuBarContent(manager: appDelegate.manager)
        }
    }
}

private struct MenuBarContent: View {
    @Bindable var manager: WallpaperManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Toggle("Wallpaper ativo", isOn: $manager.settings.isEnabled)
        Toggle("Pausar", isOn: $manager.settings.isPaused)
            .disabled(!manager.settings.isEnabled)
        Divider()
        Button("Abrir painel…", action: openPanel)
        Divider()
        Button("Sair") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func openPanel() {
        openWindow(id: "main")
        NSApp.activate()
    }
}
