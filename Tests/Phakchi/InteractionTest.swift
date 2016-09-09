import XCTest
@testable import Phakchi

class InteractionTestCase: XCTestCase {

    func testRequest() {
        let request = Interaction.Request(method: .GET, path: "/v1/endpoint", query: nil, headers: nil, body: nil)
        let params = request.pactJSON
        XCTAssertEqual(params["method"], "GET")
        XCTAssertEqual(params["path"], "/v1/endpoint")
        XCTAssertNil(params["body"])
    }

    func testRequestWithBody() {
        let request = Interaction.Request(method: .GET, path: "/v1/endpoint", query: nil, headers: nil, body: ["hoge": "fuga"])
        let params = request.pactJSON as! JSONObject
        XCTAssertEqual(params["method"] as? String, "GET")
        XCTAssertEqual(params["path"] as? String, "/v1/endpoint")
        XCTAssertNotNil(params["body"])
        let body = params["body"] as! JSONObject
        XCTAssertEqual(body["hoge"] as? String, "fuga")
    }

    func testResponse() {
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let params = response.pactJSON
        XCTAssertEqual(params["status"], 200)
        XCTAssertNil(params["headers"])
        XCTAssertNil(params["body"])
    }

    func testResponseWithBody() {
        let response = Interaction.Response(status: 200, headers: nil, body: ["message": "success"])
        let params = response.pactJSON as! [String: AnyObject]
        XCTAssertEqual(params["status"] as? Int, 200)
        XCTAssertNil(params["headers"])
        XCTAssertNotNil(params["body"])
        let body = params["body"] as! JSONObject
        XCTAssertEqual(body["message"] as? String, "success")
    }

    func testInteraction() {
        let request = Interaction.Request(method: .GET, path: "/v1/endpoint", query: nil, headers: nil, body: ["hoge": "fuga"])
        let response = Interaction.Response(status: 200, headers: nil, body: ["message": "success"])
        let interaction0 = Interaction(description: "Description", providerState: nil, request: request, response: response)
        XCTAssertEqual(interaction0.description, "Description")
        XCTAssertNil(interaction0.providerState)
        XCTAssertEqual(interaction0.request.path.pactJSON as? String, "/v1/endpoint")
        XCTAssertEqual(interaction0.response.status, 200)

        let interaction1 = Interaction(description: "Description",
                                       providerState: "Provider state",
                                       request: request,
                                       response: response)
        XCTAssertEqual(interaction1.description, "Description")
        XCTAssertEqual(interaction1.providerState, "Provider state")
        XCTAssertEqual(interaction1.request.path.pactJSON as? String, "/v1/endpoint")
        XCTAssertEqual(interaction1.response.status, 200)
    }
}
