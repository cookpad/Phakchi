import XCTest
@testable import Phakchi

class InteractionBuilderTestCase: XCTestCase {
    var builder: InteractionBuilder!

    override func setUp() {
        super.setUp()
        self.builder = InteractionBuilder()
    }

    fileprivate func makeInteractionWithRequestHeaders(_ headers: Headers?) -> Interaction! {
        self.builder.uponReceiving("Hello")
            .with(.get, path: "/integrates",
                  query: nil, headers:
                headers,
                  body: nil)
            .willRespondWith(status: 200)
        return self.builder.makeInteraction()
    }

    fileprivate func makeInteractionWithResponseHeaders(_ headers: Headers?) -> Interaction! {
        self.builder.uponReceiving("Hello")
            .with(.get, path: "/integrates")
            .willRespondWith(status: 200, headers: headers, body: nil)
        return self.builder.makeInteraction()
    }

    func testIsValid() {
        XCTAssertFalse(self.builder.isValid)
        XCTAssertFalse(self.builder.uponReceiving("Hello").isValid)
        XCTAssertFalse(self.builder
            .uponReceiving("Hello")
            .with(.get, path: "/integrates/")
            .isValid)
        XCTAssertTrue(self.builder.uponReceiving("Hello")
            .with(.get, path: "/integrates/")
            .willRespondWith(status: 200)
            .isValid)
    }

    func testDefaultRequestHeader() {
        self.builder.defaultRequestHeaders = [
            "Content-Type": "application/json",
            "Authorization": "authtoken"
        ]

        let interaction0 = makeInteractionWithRequestHeaders(["Host": "example.com"])
        XCTAssertEqual(interaction0?.request.headers?["Authorization"] as? String, "authtoken")
        XCTAssertEqual(interaction0?.request.headers?["Host"] as? String, "example.com")

        self.builder.defaultRequestHeaders = [
            "Content-Type": "application/json",
            "Authorization": "authtoken"
        ]

        let interaction1 = makeInteractionWithRequestHeaders(["Content-Type": "text/plain"])
        XCTAssertEqual(interaction1?.request.headers?["Content-Type"] as? String, "text/plain")
        XCTAssertEqual(interaction1?.request.headers?["Authorization"] as? String, "authtoken")

        self.builder.defaultRequestHeaders = [
            "Content-Type": "application/json",
            "Authorization": "authtoken"
        ]

        let interaction2 = makeInteractionWithRequestHeaders(nil)
        XCTAssertEqual(interaction2?.request.headers?["Content-Type"] as? String, "application/json")
        XCTAssertEqual(interaction2?.request.headers?["Authorization"] as? String, "authtoken")

        self.builder.defaultRequestHeaders = nil
        let interaction3 = makeInteractionWithRequestHeaders(["Content-Type": "text/plain"])
        XCTAssertEqual(interaction3?.request.headers?["Content-Type"] as? String, "text/plain")

        self.builder.defaultRequestHeaders = nil
        let interaction4 = makeInteractionWithRequestHeaders(nil)
        XCTAssertNil(interaction4?.request.headers)
    }

    func testDefaultResponseHeader() {
        self.builder.defaultResponseHeaders = [
            "Content-Type": "application/json",
            "Authorization": "authtoken"
        ]

        let interaction0 = makeInteractionWithResponseHeaders(["Host": "example.com"])
        XCTAssertEqual(interaction0?.response.headers?["Content-Type"] as? String, "application/json")
        XCTAssertEqual(interaction0?.response.headers?["Authorization"] as? String, "authtoken")
        XCTAssertEqual(interaction0?.response.headers?["Host"] as? String, "example.com")

        self.builder.defaultResponseHeaders = [
            "Content-Type": "application/json",
            "Authorization": "authtoken"
        ]

        let interaction1 = makeInteractionWithResponseHeaders(["Content-Type": "text/plain"])
        XCTAssertEqual(interaction1?.response.headers?["Content-Type"] as? String, "text/plain")
        XCTAssertEqual(interaction1?.response.headers?["Authorization"] as? String, "authtoken")

        self.builder.defaultResponseHeaders = [
            "Content-Type": "application/json",
            "Authorization": "authtoken"
        ]

        let interaction2 = makeInteractionWithResponseHeaders(nil)
        XCTAssertEqual(interaction2?.response.headers?["Content-Type"] as? String, "application/json")
        XCTAssertEqual(interaction2?.response.headers?["Authorization"] as? String, "authtoken")

        self.builder.defaultResponseHeaders = nil
        let interaction3 = makeInteractionWithResponseHeaders(["Content-Type": "text/plain"])
        XCTAssertEqual(interaction3?.response.headers?["Content-Type"] as? String, "text/plain")

        self.builder.defaultResponseHeaders = nil
        let interaction4 = makeInteractionWithResponseHeaders(nil)
        XCTAssertNil(interaction4?.response.headers)
    }

}
