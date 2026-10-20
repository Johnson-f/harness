import Foundation
import HarnessCore

func reply(to text: String, from sender: String) -> String {
    "echo: \(text)"
}

func runDaemon() throws {
    let config = try Config.load()
    let chatDB = try ChatDB(path: config.chatDBPath)
    let cursor = try Cursor(stateDirectory: config.stateDirectory)

    var lastRowID = try cursor.read() ?? chatDB.latestRowID()
    try cursor.write(lastRowID)
    print("Listening for iMessages from \(config.allowedHandles.sorted().joined(separator: ", ")) (after row \(lastRowID))")

    while true {
        for row in try chatDB.incomingRows(after: lastRowID) {
            lastRowID = row.rowID
            // Advance before handling: once the agent can run commands, a crash mid-task
            // must not re-run that task on restart.
            try cursor.write(lastRowID)

            guard config.allowedHandles.contains(row.handle) else {
                print("Ignoring message from \(row.handle)")
                continue
            }
            guard let text = row.messageText else { continue }

            print("← \(row.handle): \(text)")
            let response = reply(to: text, from: row.handle)
            do {
                try IMessageSender.send(response, to: row.handle)
                print("→ \(row.handle): \(response)")
            } catch {
                print("Failed to reply to \(row.guid): \(error)")
            }
        }
        Thread.sleep(forTimeInterval: config.pollInterval)
    }
}

func runSend(_ arguments: [String]) throws {
    guard let target = arguments.first, arguments.count > 1 else {
        throw HarnessError("Usage: harness send <handle> <message...>")
    }
    try IMessageSender.send(arguments.dropFirst().joined(separator: " "), to: Handles.normalize(target))
    print("Sent.")
}

setvbuf(stdout, nil, _IOLBF, 0)
let arguments = Array(CommandLine.arguments.dropFirst())

do {
    switch arguments.first {
    case nil, "run": try runDaemon()
    case "send": try runSend(Array(arguments.dropFirst()))
    default: throw HarnessError("Usage: harness [run | send <handle> <message...>]")
    }
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(1)
}
