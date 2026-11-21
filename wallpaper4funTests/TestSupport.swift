import Foundation

/// `UserDefaults` isolado, apagado ao ser destruído. Nunca use `.standard` nos testes.
final class TemporaryDefaults {
    let defaults: UserDefaults
    private let suiteName = "tests.\(UUID().uuidString)"

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

/// Pasta temporária própria de cada teste, apagada ao ser destruída.
final class TemporaryFolder {
    let url = FileManager.default.temporaryDirectory
        .appending(path: "tests-\(UUID().uuidString)", directoryHint: .isDirectory)

    init() {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    func makeFile(named name: String, contents: String = "video") throws -> URL {
        let file = url.appending(path: name)
        try Data(contents.utf8).write(to: file)
        return file
    }
}
