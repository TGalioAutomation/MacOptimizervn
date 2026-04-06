import AIModelKit
import Foundation

/// Smoke checks for `AIModelParsing` when XCTest is unavailable (e.g. Command Line Tools only).
@main
enum AIModelKitVerify {
    static func main() {
        guard AIModelParsing.parseByteCount("4.7 GB") == 4_700_000_000 else {
            fatalError("parseByteCount decimal GB failed")
        }
        let gibExpected = Int64(4.7 * Double(1_024 * 1_024 * 1_024))
        guard AIModelParsing.parseByteCount("4.7 GiB") == gibExpected else {
            fatalError("parseByteCount GiB failed")
        }

        let sample = """
        NAME                    ID              SIZE      MODIFIED
        llama3:latest           abc123def       4.7 GB    2 days ago
        mistral:7b              fedcba987       500 MB    3 weeks ago
        """
        let items = AIModelParsing.parseOllamaList(sample, root: nil)
        guard items.count == 2,
              items[0].name == "llama3:latest",
              items[0].size == 4_700_000_000,
              items[1].name == "mistral:7b"
        else {
            fatalError("parseOllamaList sample failed")
        }

        fputs("AIModelKitVerify: OK\n", stderr)
    }
}
