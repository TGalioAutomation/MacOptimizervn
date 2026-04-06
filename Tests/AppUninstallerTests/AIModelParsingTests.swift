#if canImport(XCTest)
import XCTest
import AIModelKit

/// Full Xcode.app is required for `swift test` (XCTest). On Command Line Tools only, use `swift run AIModelKitVerify`.
final class AIModelParsingTests: XCTestCase {

    // MARK: - parseByteCount

    func testParseByteCount_decimalGB() {
        XCTAssertEqual(AIModelParsing.parseByteCount("4.7 GB"), 4_700_000_000)
    }

    func testParseByteCount_binaryGiB() {
        let expected = Int64(4.7 * Double(1_024 * 1_024 * 1_024))
        XCTAssertEqual(AIModelParsing.parseByteCount("4.7 GiB"), expected)
    }

    func testParseByteCount_decimalMB() {
        XCTAssertEqual(AIModelParsing.parseByteCount("500 MB"), 500_000_000)
    }

    func testParseByteCount_plainBytes() {
        XCTAssertEqual(AIModelParsing.parseByteCount("128 B"), 128)
    }

    func testParseByteCount_invalidReturnsZero() {
        XCTAssertEqual(AIModelParsing.parseByteCount(""), 0)
        XCTAssertEqual(AIModelParsing.parseByteCount("n/a"), 0)
    }

    // MARK: - parseOllamaList

    func testParseOllamaList_skipsHeaderAndParsesRows() {
        let output = """
        NAME                    ID              SIZE      MODIFIED
        llama3:latest           abc123def       4.7 GB    2 days ago
        mistral:7b              fedcba987       500 MB    3 weeks ago
        """

        let items = AIModelParsing.parseOllamaList(output, root: nil)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].name, "llama3:latest")
        XCTAssertEqual(items[0].size, 4_700_000_000)
        XCTAssertEqual(items[1].name, "mistral:7b")
        XCTAssertEqual(items[1].size, 500_000_000)
    }

    func testParseOllamaList_binaryGiBSize() {
        let output = """
        NAME    ID    SIZE     MODIFIED
        test:latest    x    2.0 GiB    1h ago
        """
        let items = AIModelParsing.parseOllamaList(output, root: nil)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].size, Int64(2.0 * Double(1_024 * 1_024 * 1_024)))
    }

    func testParseOllamaList_emptyOutput() {
        XCTAssertTrue(AIModelParsing.parseOllamaList("", root: nil).isEmpty)
    }
}
#endif
