import Foundation
import ObjCExceptionCatcher

/// Decodes `message.attributedBody`: an NSAttributedString in the legacy typedstream format.
/// Recent macOS versions often leave `message.text` NULL and store the text only here.
public enum AttributedBody {
    public static func decode(_ data: Data) -> String? {
        var text: String?
        // NSUnarchiver is deprecated but is the only system decoder for typedstream, and it
        // raises an NSException (fatal in Swift) on truncated data instead of returning nil.
        let exception = HarnessCatchException {
            text = (NSUnarchiver.unarchiveObject(with: data) as? NSAttributedString)?.string
        }
        return exception == nil ? text : nil
    }
}
