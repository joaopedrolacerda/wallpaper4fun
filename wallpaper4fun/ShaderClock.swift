import Foundation

/// Acumula o tempo da animação, assim mudar a velocidade ou pausar não faz a imagem "pular".
final class ShaderClock {
    /// Maior passo aceito entre dois quadros; intervalos maiores (pausa, sono) contam só isso.
    static let maxStep: TimeInterval = 0.1

    private var last: Date?
    private var elapsed: TimeInterval = 0

    func tick(_ date: Date, speed: Double) -> Float {
        if let last { elapsed += step(from: last, to: date) * speed }
        last = date
        return Float(elapsed)
    }

    private func step(from last: Date, to date: Date) -> TimeInterval {
        min(date.timeIntervalSince(last), Self.maxStep)
    }
}
