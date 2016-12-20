import XCTest
@testable import Phakchi

class MatcherTestCase: XCTestCase {
    func testTerm() {
        let term = Matcher.term(generate: "02/11/2013", matcher: "\\d{2}\\/\\d{2}\\/\\d{4}").pactJSON as! [String: AnyObject]
        XCTAssertEqual(term["json_class"] as? String, "Pact::Term")

        let data = term["data"] as! [String: AnyObject]
        XCTAssertEqual(data["generate"] as? String, "02/11/2013")

        let matcher = data["matcher"] as! [String: AnyObject]
        XCTAssertEqual(matcher["json_class"] as? String, "Regexp")
        XCTAssertEqual(matcher["o"] as? Int, 0)
        XCTAssertEqual(matcher["s"] as? String, "\\d{2}\\/\\d{2}\\/\\d{4}")
    }

    func testLike() {
        let like = Matcher.like(10).pactJSON as! JSONObject
        XCTAssertEqual(like["json_class"] as! String, "Pact::SomethingLike")
        XCTAssertEqual(like["contents"] as! Int, 10)
    }

    func testEachLike() {
        let eachLike = Matcher.eachLike(["name": "foo"], min: 10).pactJSON as! [String: AnyObject]
        XCTAssertEqual(eachLike["json_class"] as? String, "Pact::ArrayLike")

        let contents = eachLike["contents"] as! [String: AnyObject]
        XCTAssertEqual(contents["name"] as? String, "foo")
        XCTAssertEqual(eachLike["min"] as? Int, 10)
    }
}
