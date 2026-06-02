import Foundation

enum AndonState {
    case busy
    case idle
    case inactive
    case noSession
}

struct SessionInfo: Equatable {
    let id: String
    let pid: Int
    let cwd: String
    let status: AndonState
}

class SessionMonitor {
    private let sessionsPath: String

    init() {
        sessionsPath = NSString(string: "~/.claude/sessions").expandingTildeInPath
    }

    func updateState() -> [SessionInfo] {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: sessionsPath) else {
            return []
        }

        let jsonFiles = files.filter { $0.hasSuffix(".json") }
        guard !jsonFiles.isEmpty else { return [] }

        var sessions: [SessionInfo] = []

        for file in jsonFiles {
            let path = (sessionsPath as NSString).appendingPathComponent(file)
            guard let data = FileManager.default.contents(atPath: path),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? String,
                  let sessionId = json["sessionId"] as? String,
                  let pid = json["pid"] as? Int else {
                continue
            }

            let cwd = json["cwd"] as? String ?? ""

            guard kill(pid_t(pid), 0) == 0 else { continue }

            let sessionStatus: AndonState
            switch status {
            case "busy":
                sessionStatus = .busy
            case "idle":
                sessionStatus = .idle
            default:
                sessionStatus = .inactive
            }

            sessions.append(SessionInfo(id: sessionId, pid: pid, cwd: cwd, status: sessionStatus))
        }

        return sessions.sorted { $0.id < $1.id }
    }

    static func aggregateState(_ sessions: [SessionInfo]) -> AndonState {
        if sessions.isEmpty { return .noSession }
        if sessions.contains(where: { $0.status == .idle }) { return .idle }
        if sessions.allSatisfy({ $0.status == .busy }) { return .busy }
        return .inactive
    }
}
