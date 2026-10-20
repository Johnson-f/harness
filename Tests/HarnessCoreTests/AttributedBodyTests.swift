import Foundation
import Testing
@testable import HarnessCore

private func archive(_ text: String) -> Data {
    NSArchiver.archivedData(withRootObject: NSAttributedString(string: text))
}

@Suite struct AttributedBodyTests {
    @Test(arguments: ["hello agent", "café ☕️ 👍🏽", String(repeating: "check the server logs ", count: 40)])
    func decodesArchivedText(_ text: String) {
        #expect(AttributedBody.decode(archive(text)) == text)
    }

    @Test func returnsNilForGarbage() {
        #expect(AttributedBody.decode(Data("garbage".utf8)) == nil)
    }

    @Test func returnsNilInsteadOfCrashingOnTruncatedData() {
        let data = archive("hello there")
        #expect(AttributedBody.decode(data.prefix(data.count - 8)) == nil)
    }
}
