import Foundation

enum VolumeStatus: Equatable, Sendable {
    case ok
    case missing
    case denied
    case failed(String)

    var menuText: String {
        switch self {
        case .ok: return "OK"
        case .missing: return "not mounted"
        case .denied: return "needs Files & Folders access"
        case .failed(let reason): return reason
        }
    }
}

struct PingResult: Equatable, Sendable {
    var statuses: [String: VolumeStatus]
    var at: Date
}

enum DrivePinger {
    static func ping(config: Config) -> PingResult {
        var statuses: [String: VolumeStatus] = [:]
        for path in config.volumes {
            statuses[path] = pingOne(path: path, touchFileName: config.touchFileName)
        }
        return PingResult(statuses: statuses, at: Date())
    }

    private static func pingOne(path: String, touchFileName: String) -> VolumeStatus {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
            AppLog.line("\(path): not mounted")
            return .missing
        }

        let url = URL(fileURLWithPath: path).appendingPathComponent(touchFileName)
        do {
            if fm.fileExists(atPath: url.path) {
                try fm.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
            } else {
                let created = fm.createFile(
                    atPath: url.path,
                    contents: Data(),
                    attributes: [.posixPermissions: 0o644]
                )
                if !created {
                    throw CocoaError(.fileWriteNoPermission)
                }
            }
            AppLog.line("\(path): ok")
            return .ok
        } catch {
            let ns = error as NSError
            if ns.domain == NSCocoaErrorDomain, ns.code == NSFileWriteNoPermissionError || ns.code == NSFileReadNoPermissionError {
                AppLog.error("\(path): permission denied — \(ns.localizedDescription)")
                return .denied
            }
            AppLog.error("\(path): \(ns.localizedDescription)")
            return .failed(ns.localizedDescription)
        }
    }
}
