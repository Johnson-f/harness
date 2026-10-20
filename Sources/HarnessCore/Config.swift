import Foundation

public struct Config {
    public let allowedHandles: Set<String>
    public let chatDBPath: String
    public let stateDirectory: URL
    public let pollInterval: TimeInterval

    /// Process environment wins over `.env` in the working directory.
    public static func load(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        dotEnvURL: URL = URL(fileURLWithPath: ".env")
    ) throws -> Config {
        let values = parseDotEnv(at: dotEnvURL).merging(environment) { _, process in process }
        let home = FileManager.default.homeDirectoryForCurrentUser

        let allowedHandles = try Handles.parseList(values["HARNESS_ALLOWED_HANDLES"] ?? "")
        guard !allowedHandles.isEmpty else {
            throw HarnessError("HARNESS_ALLOWED_HANDLES is empty. Set it in .env to your phone number and/or Apple ID email.")
        }

        return Config(
            allowedHandles: allowedHandles,
            chatDBPath: values["HARNESS_CHAT_DB"] ?? home.appendingPathComponent("Library/Messages/chat.db").path,
            stateDirectory: values["HARNESS_STATE_DIR"].map { URL(fileURLWithPath: $0) }
                ?? home.appendingPathComponent(".harness"),
            pollInterval: values["HARNESS_POLL_INTERVAL_MS"].flatMap(Double.init).map { $0 / 1000 } ?? 1
        )
    }

    static func parseDotEnv(at url: URL) -> [String: String] {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
        var values: [String: String] = [:]
        for line in contents.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("#"), let equals = trimmed.firstIndex(of: "=") else { continue }
            let key = trimmed[..<equals].trimmingCharacters(in: .whitespaces)
            let value = trimmed[trimmed.index(after: equals)...]
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            values[key] = value
        }
        return values
    }
}
