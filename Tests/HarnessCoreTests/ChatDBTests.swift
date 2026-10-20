import Foundation
import SQLite3
import Testing
@testable import HarnessCore

/// Builds a throwaway database with the subset of the Messages schema ChatDB reads.
private final class ChatDBFixture {
    let directory: URL
    let path: String
    private var db: OpaquePointer?

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        path = directory.appendingPathComponent("chat.db").path
        sqlite3_open(path, &db)
        exec("CREATE TABLE handle (ROWID INTEGER PRIMARY KEY, id TEXT)")
        exec("""
            CREATE TABLE message (
              ROWID INTEGER PRIMARY KEY, guid TEXT, text TEXT, attributedBody BLOB, date INTEGER,
              handle_id INTEGER, is_from_me INTEGER DEFAULT 0,
              associated_message_type INTEGER DEFAULT 0, item_type INTEGER DEFAULT 0)
            """)
        exec("INSERT INTO handle VALUES (1, '+2349012345678'), (2, 'Friend@Example.com')")
    }

    deinit {
        sqlite3_close(db)
        try? FileManager.default.removeItem(at: directory)
    }

    func insert(text: String? = nil, body: Data? = nil, handle: Int = 1, fromMe: Int = 0, associated: Int = 0, item: Int = 0) {
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, """
            INSERT INTO message (guid, text, attributedBody, date, handle_id, is_from_me, associated_message_type, item_type)
            VALUES (?, ?, ?, 782000000000000000, ?, ?, ?, ?)
            """, -1, &stmt, nil)
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(stmt, 1, UUID().uuidString, -1, transient)
        if let text { sqlite3_bind_text(stmt, 2, text, -1, transient) }
        if let body { _ = body.withUnsafeBytes { sqlite3_bind_blob(stmt, 3, $0.baseAddress, Int32(body.count), transient) } }
        for (index, value) in [handle, fromMe, associated, item].enumerated() {
            sqlite3_bind_int64(stmt, Int32(index + 4), Int64(value))
        }
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    private func exec(_ sql: String) {
        sqlite3_exec(db, sql, nil, nil, nil)
    }
}

@Suite struct ChatDBTests {
    @Test func returnsOnlyRealIncomingMessagesAfterTheCursor() throws {
        let fixture = try ChatDBFixture()
        fixture.insert(text: "old")
        let chatDB = try ChatDB(path: fixture.path)
        let cursor = try chatDB.latestRowID()

        fixture.insert(text: "do the thing")
        fixture.insert(body: NSArchiver.archivedData(withRootObject: NSAttributedString(string: "from body")))
        fixture.insert(text: "my own reply", fromMe: 1)
        fixture.insert(text: "Loved “do the thing”", associated: 2000)
        fixture.insert(item: 1)
        fixture.insert(text: "\u{FFFC}")
        fixture.insert(text: "hi", handle: 2)

        let rows = try chatDB.incomingRows(after: cursor)
        #expect(rows.map(\.handle) == ["+2349012345678", "+2349012345678", "+2349012345678", "friend@example.com"])
        #expect(rows.map(\.messageText) == ["do the thing", "from body", nil, "hi"])
        #expect(Calendar(identifier: .gregorian).component(.year, from: rows[0].sentAt) == 2025)
    }

    @Test func reportsMissingAccessClearly() {
        #expect(throws: HarnessError.self) { try ChatDB(path: "/nonexistent/chat.db") }
    }
}
