import Foundation
import Testing
@testable import HarnessCore

@Suite struct ConfigTests {
    @Test func processEnvironmentOverridesDotEnv() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try """
            # comment
            HARNESS_ALLOWED_HANDLES="+2349012345678, me@icloud.com"
            HARNESS_POLL_INTERVAL_MS=500
            """.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let config = try Config.load(environment: ["HARNESS_POLL_INTERVAL_MS": "250"], dotEnvURL: url)
        #expect(config.allowedHandles == ["+2349012345678", "me@icloud.com"])
        #expect(config.pollInterval == 0.25)
    }

    @Test func requiresAnAllowlist() {
        #expect(throws: HarnessError.self) {
            try Config.load(environment: [:], dotEnvURL: URL(fileURLWithPath: "/nonexistent/.env"))
        }
    }
}
