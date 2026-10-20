import Foundation

public enum Handles {
    public static func normalize(_ raw: String) throws -> String {
        let handle = raw.trimmingCharacters(in: .whitespaces)
        if handle.contains("@") { return handle.lowercased() }

        let phone = handle.filter { $0.isNumber || $0 == "+" }
        guard phone.wholeMatch(of: /\+\d{7,15}/) != nil else {
            throw HarnessError("Phone handle \"\(raw)\" must be in international form, e.g. +2349012345678")
        }
        return phone
    }

    public static func parseList(_ raw: String) throws -> Set<String> {
        let entries = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return Set(try entries.filter { !$0.isEmpty }.map(normalize))
    }
}
