import Testing
@testable import HarnessCore

@Suite struct HandlesTests {
    @Test func stripsPhoneFormatting() throws {
        #expect(try Handles.normalize(" +234 (901) 234-5678 ") == "+2349012345678")
    }

    @Test func lowercasesEmails() throws {
        #expect(try Handles.normalize("Me@iCloud.com") == "me@icloud.com")
    }

    @Test func rejectsPhonesWithoutCountryCode() {
        #expect(throws: HarnessError.self) { try Handles.normalize("09012345678") }
    }

    @Test func parseListIgnoresBlanks() throws {
        #expect(try Handles.parseList("+2349012345678, ,me@icloud.com,") == ["+2349012345678", "me@icloud.com"])
        #expect(try Handles.parseList("").isEmpty)
    }
}
