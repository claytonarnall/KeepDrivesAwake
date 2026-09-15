import Foundation

struct Config: Codable, Equatable, Sendable {
    var intervalSeconds: Int
    var volumes: [String]
    var touchFileName: String

    static let `default` = Config(
        intervalSeconds: 30,
        volumes: ["/Volumes/Big Daddy"],
        touchFileName: ".keep_drives_awake"
    )

    var pollInterval: TimeInterval {
        TimeInterval(max(5, intervalSeconds))
    }
}

enum ConfigStore {
    static var supportDirectory: URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return root.appendingPathComponent("KeepDrivesAwake", isDirectory: true)
    }

    static var configURL: URL {
        supportDirectory.appendingPathComponent("config.json")
    }

    static func load() -> Config {
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            if fm.fileExists(atPath: configURL.path) {
                let data = try Data(contentsOf: configURL)
                let decoded = try JSONDecoder().decode(Config.self, from: data)
                if decoded.volumes.isEmpty {
                    return .default
                }
                return decoded
            }
            let initial = Config.default
            try save(initial)
            return initial
        } catch {
            AppLog.error("Failed to load config: \(error.localizedDescription)")
            return .default
        }
    }

    static func save(_ config: Config) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(config).write(to: configURL, options: .atomic)
    }
}
