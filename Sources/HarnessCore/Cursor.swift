import Foundation

/// Persists the last chat.db ROWID handled, so restarts neither replay nor skip messages.
public struct Cursor {
    private let fileURL: URL

    public init(stateDirectory: URL) throws {
        try FileManager.default.createDirectory(at: stateDirectory, withIntermediateDirectories: true)
        fileURL = stateDirectory.appendingPathComponent("imessage-cursor")
    }

    public func read() -> Int64? {
        guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else { return nil }
        return Int64(contents.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    public func write(_ rowID: Int64) throws {
        try String(rowID).write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
