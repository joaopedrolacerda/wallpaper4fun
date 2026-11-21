import AppKit
import Testing
@testable import wallpaper4fun

struct DockPolicyTests {
    @Test("com o painel aberto, o ícone fica no Dock")
    func panelVisible() {
        #expect(DockPolicy.activationPolicy(panelVisible: true, hideDockWhenClosed: true) == .regular)
    }

    @Test("painel fechado com a opção ligada: só a barra de menus")
    func closedAndHiding() {
        #expect(DockPolicy.activationPolicy(panelVisible: false, hideDockWhenClosed: true) == .accessory)
    }

    @Test("painel fechado com a opção desligada: continua no Dock")
    func closedNotHiding() {
        #expect(DockPolicy.activationPolicy(panelVisible: false, hideDockWhenClosed: false) == .regular)
    }
}
