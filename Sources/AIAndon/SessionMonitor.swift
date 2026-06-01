import Foundation

enum AndonState {
    case busy
    case idle
    case inactive
    case noSession
}

class SessionMonitor {
    private let sessionsPath: String

    init() {
        sessionsPath = NSString(string: "~/.claude/sessions").expandingTildeInPath
    }

    func updateState() -> AndonState {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: sessionsPath) else {
            return .noSession
        }

        let jsonFiles = files.filter { $0.hasSuffix(".json") }
        guard !jsonFiles.isEmpty else { return .noSession }

        var hasBusy = false
        var hasIdle = false

        for file in jsonFiles {
            let path = (sessionsPath as NSString).appendingPathComponent(file)
            guard let data = FileManager.default.contents(atPath: path),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? String else {
                continue
            }

            switch status {
            case "busy":
                hasBusy = true
            case "idle":
                hasIdle = true
            default:
                break
            }
        }

        if hasBusy { return .busy }
        if hasIdle { return .idle }
        return .inactive
    }
}
