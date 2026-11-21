import AppKit
import SwiftUI
import UniformTypeIdentifiers

// Camada fina que fala com o AppKit. Sem regras de negócio aqui:
// as decisões ficam no `WallpaperManager`, que é testado.

/// Mostra o wallpaper numa janela de desktop por monitor e acompanha a troca de monitores.
final class DesktopWindowPresenter: WallpaperDisplay {
    var makeContent: () -> NSView = { NSView() }

    private var windows: [DesktopWindow] = []
    private var isShowing = false

    init() {
        observe(NSApplication.didChangeScreenParametersNotification, on: .default) { [weak self] in
            self?.refreshIfShowing()
        }
    }

    func show() {
        isShowing = true
        rebuildWindows()
    }

    func hide() {
        isShowing = false
        closeWindows()
    }

    private func refreshIfShowing() {
        guard isShowing else { return }
        rebuildWindows()
    }

    private func rebuildWindows() {
        closeWindows()
        windows = NSScreen.screens.map(makeWindow(on:))
    }

    private func makeWindow(on screen: NSScreen) -> DesktopWindow {
        let window = DesktopWindow(screen: screen)
        window.contentView = makeContent()
        window.orderFront(nil)
        return window
    }

    private func closeWindows() {
        windows.forEach { $0.close() }
        windows.removeAll()
    }
}

/// Avisa o manager quando as telas dormem e acordam.
final class SystemEventObserver {
    init(manager: WallpaperManager) {
        let workspace = NSWorkspace.shared.notificationCenter
        observe(NSWorkspace.screensDidSleepNotification, on: workspace) { [weak manager] in
            manager?.screensDidSleep()
        }
        observe(NSWorkspace.screensDidWakeNotification, on: workspace) { [weak manager] in
            manager?.screensDidWake()
        }
    }
}

/// Registra um observer na fila principal. Um lugar só para esse padrão (DRY).
private func observe(_ name: Notification.Name, on center: NotificationCenter,
                     perform action: @escaping @MainActor () -> Void) {
    center.addObserver(forName: name, object: nil, queue: .main) { _ in
        MainActor.assumeIsolated(action)
    }
}

/// Janela sem borda no nível do desktop: atrás dos ícones e de todas as outras janelas.
final class DesktopWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        setFrame(screen.frame, display: false)
        configureAsDesktopLayer()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    private func configureAsDesktopLayer() {
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        ignoresMouseEvents = true
        isOpaque = true
        hasShadow = false
        backgroundColor = .black
        isReleasedWhenClosed = false
    }
}

/// Janela do sistema para escolher um vídeo.
enum VideoPicker {
    static func chooseVideo() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie]
        panel.allowsMultipleSelection = false
        panel.message = "Escolha um vídeo para usar como wallpaper"
        return panel.runModal() == .OK ? panel.url : nil
    }
}
