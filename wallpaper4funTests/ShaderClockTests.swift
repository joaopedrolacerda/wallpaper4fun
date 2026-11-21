import Foundation
import Testing
@testable import wallpaper4fun

struct ShaderClockTests {
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    @Test("o primeiro tique começa do zero")
    func firstTickIsZero() {
        #expect(ShaderClock().tick(start, speed: 1) == 0)
    }

    @Test("acumula o tempo passado entre os tiques")
    func accumulates() {
        let clock = ShaderClock()
        _ = clock.tick(start, speed: 1)
        _ = clock.tick(start + 0.05, speed: 1)
        #expect(clock.tick(start + 0.1, speed: 1) == 0.1)
    }

    @Test("a velocidade multiplica o tempo")
    func speedMultiplies() {
        let clock = ShaderClock()
        _ = clock.tick(start, speed: 2)
        #expect(clock.tick(start + 0.05, speed: 2) == 0.1)
    }

    @Test("um intervalo grande (pausa) não faz a animação pular")
    func clampsLongGaps() {
        let clock = ShaderClock()
        _ = clock.tick(start, speed: 1)
        #expect(clock.tick(start + 60, speed: 1) == Float(ShaderClock.maxStep))
    }
}
