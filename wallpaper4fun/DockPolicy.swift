import AppKit

/// Decide se o app aparece no Dock ou só na barra de menus.
enum DockPolicy {
    static func activationPolicy(panelVisible: Bool, hideDockWhenClosed: Bool) -> NSApplication.ActivationPolicy {
        panelVisible || !hideDockWhenClosed ? .regular : .accessory
    }

    static func apply(panelVisible: Bool, hideDockWhenClosed: Bool) {
        NSApp.setActivationPolicy(activationPolicy(panelVisible: panelVisible, hideDockWhenClosed: hideDockWhenClosed))
    }
}
