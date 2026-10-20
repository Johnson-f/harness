import Foundation
import SQLite3

public struct IncomingRow: Sendable {
    public let rowID: Int64
    public let guid: String
    public let handle: String
    public let text: String?
    public let attributedBody: Data?
    public let sentAt: Date

    /// Decodes lazily so that bodies from senders outside the allowlist are never unarchived.
    public var messageText: String? {
        let raw = text.flatMap { $0.isEmpty ? nil : $0 } ?? attributedBody.flatMap(AttributedBody.decode)
        // U+FFFC is the placeholder Messages inserts where an attachment sits.
        let cleaned = raw?
            .replacingOccurrences(of: "\u{FFFC}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned?.isEmpty == false ? cleaned : nil
    }
}

/// Read-only access to the Messages database (`~/Library/Messages/chat.db`).
public final class ChatDB {
    private let db: OpaquePointer

    // associated_message_type != 0 are tapbacks/reactions; item_type != 0 are
    // group events like renames and member changes.
    private static let incomingSQL = """
        SELECT m.ROWID, m.guid, h.id, m.text, m.attributedBody, m.date
        FROM message m
        JOIN handle h ON h.ROWID = m.handle_id
        WHERE m.ROWID > ?
          AND m.is_from_me = 0
          AND m.associated_message_type = 0
          AND m.item_type = 0
        ORDER BY m.ROWID
        LIMIT 100
        """

    public init(path: String) throws {
        var connection: OpaquePointer?
        guard sqlite3_open_v2(path, &connection, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, let connection else {
            sqlite3_close(connection)
            throw Self.accessError(path)
        }
        db = connection
        do {
            _ = try query("SELECT 1 FROM message LIMIT 1") { _ in () }
        } catch {
            throw Self.accessError(path)
        }
    }

    deinit {
        sqlite3_close(db)
    }

    public func latestRowID() throws -> Int64 {
        try query("SELECT IFNULL(MAX(ROWID), 0) FROM message") { sqlite3_column_int64($0, 0) }.first ?? 0
    }

    public func incomingRows(after rowID: Int64) throws -> [IncomingRow] {
        try query(Self.incomingSQL, binding: rowID) { stmt in
            IncomingRow(
                rowID: sqlite3_column_int64(stmt, 0),
                guid: Self.string(stmt, 1) ?? "",
                handle: Self.normalizedHandle(Self.string(stmt, 2) ?? ""),
                text: Self.string(stmt, 3),
                attributedBody: Self.data(stmt, 4),
                sentAt: Date(timeIntervalSinceReferenceDate: Double(sqlite3_column_int64(stmt, 5)) / 1_000_000_000)
            )
        }
    }

    private func query<T>(_ sql: String, binding value: Int64? = nil, row: (OpaquePointer) -> T) throws -> [T] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw HarnessError("SQLite prepare failed: \(String(cString: sqlite3_errmsg(db)))")
        }
        defer { sqlite3_finalize(statement) }

        if let value { sqlite3_bind_int64(statement, 1, value) }

        var results: [T] = []
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW: results.append(row(statement))
            case SQLITE_DONE: return results
            default: throw HarnessError("SQLite step failed: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
    }

    private static func string(_ stmt: OpaquePointer, _ column: Int32) -> String? {
        sqlite3_column_text(stmt, column).map { String(cString: $0) }
    }

    private static func data(_ stmt: OpaquePointer, _ column: Int32) -> Data? {
        guard let bytes = sqlite3_column_blob(stmt, column) else { return nil }
        return Data(bytes: bytes, count: Int(sqlite3_column_bytes(stmt, column)))
    }

    private static func normalizedHandle(_ handle: String) -> String {
        (try? Handles.normalize(handle)) ?? handle
    }

    private static func accessError(_ path: String) -> HarnessError {
        HarnessError(
            "Cannot read \(path). Grant Full Disk Access to the app running this process "
                + "(System Settings → Privacy & Security → Full Disk Access), then quit and reopen it."
        )
    }
}
