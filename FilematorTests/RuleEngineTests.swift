import XCTest
@testable import Filemator

final class RuleEngineTests: XCTestCase {
    func test_firstMatch_returnsFirstMatchingRule_stoppingEvaluation() {
        let pdfRule = Rule(name: "PDFs", extensions: ["pdf"], nameContains: nil, destination: URL(fileURLWithPath: "/tmp/pdfs"))
        let catchAllRule = Rule(name: "Everything", extensions: [], nameContains: nil, destination: URL(fileURLWithPath: "/tmp/everything"))

        let match = RuleEngine.firstMatch(for: URL(fileURLWithPath: "/tmp/report.pdf"), in: [pdfRule, catchAllRule])

        XCTAssertEqual(match?.name, "PDFs")
    }

    func test_firstMatch_fallsThroughToLaterRule_whenEarlierDoesNotMatch() {
        let pdfRule = Rule(name: "PDFs", extensions: ["pdf"], nameContains: nil, destination: URL(fileURLWithPath: "/tmp/pdfs"))
        let catchAllRule = Rule(name: "Everything", extensions: [], nameContains: nil, destination: URL(fileURLWithPath: "/tmp/everything"))

        let match = RuleEngine.firstMatch(for: URL(fileURLWithPath: "/tmp/photo.png"), in: [pdfRule, catchAllRule])

        XCTAssertEqual(match?.name, "Everything")
    }

    func test_firstMatch_returnsNil_whenNoRuleMatches() {
        let pdfRule = Rule(name: "PDFs", extensions: ["pdf"], nameContains: nil, destination: URL(fileURLWithPath: "/tmp/pdfs"))

        let match = RuleEngine.firstMatch(for: URL(fileURLWithPath: "/tmp/photo.png"), in: [pdfRule])

        XCTAssertNil(match)
    }

    func test_matches_checksNameContains_caseInsensitive() {
        let invoiceRule = Rule(name: "Invoices", extensions: [], nameContains: "invoice", destination: URL(fileURLWithPath: "/tmp/invoices"))

        XCTAssertTrue(invoiceRule.matches(fileURL: URL(fileURLWithPath: "/tmp/INVOICE_march.pdf")))
        XCTAssertFalse(invoiceRule.matches(fileURL: URL(fileURLWithPath: "/tmp/receipt.pdf")))
    }
}
