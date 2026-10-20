import Foundation

public enum IMessageSender {
    // Text is passed via argv rather than interpolated so quotes and newlines need no escaping.
    private static let script = """
        on run argv
          set targetHandle to item 1 of argv
          set messageText to item 2 of argv
          tell application "Messages"
            set targetService to 1st account whose service type = iMessage and enabled is true
            send messageText to participant targetHandle of targetService
          end tell
        end run
        """

    public static func send(_ text: String, to handle: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script, handle, text]
        let stderr = Pipe()
        process.standardError = stderr
        process.standardOutput = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let message = String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            throw HarnessError("osascript exited with \(process.terminationStatus): \(message.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
    }
}
