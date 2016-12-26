import XCTest
@testable import Phakchi

class MockServiceClientTestCase: XCTestCase {
    var client: MockServiceClient!
    var session: Session!

    override func setUp() {
        super.setUp()
        let exp = expectation(description: "session is started")
        let controlServiceClient = ControlServiceClient()
        controlServiceClient.start(session: "consumer name",
                                   providerName: "provider name") { (session) in
                                    self.session = session
                                    self.client = MockServiceClient(baseURL: self.session.baseURL)
                                    exp.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    override func tearDown() {
        super.tearDown()
        self.client.cleanInteractions()

        let expectationToRun = expectation(description: "session is closed")
        self.session.close { _ in
            expectationToRun.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testRegisterInteraction() {
        let expectationToRun = expectation(description: "interactions are registered")
        let request = Interaction.Request(method: .get, path: "/integrates/", query: nil, headers: nil, body: nil)
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let interaction = Interaction(description: "Get integrates", providerState: nil, request: request, response: response)

        self.client.registerInteraction(interaction) { (_, response, error) in
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertNil(error)
            expectationToRun.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testRegisterInteractions() {
        let expectationToRun = expectation(description: "interactions are registered")
        let request = Interaction.Request(method: .get, path: "/integrates/", query: nil, headers: nil, body: nil)
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let interaction0 = Interaction(description: "Get integrates", providerState: "", request: request, response: response)
        let interaction1 = Interaction(description: "Get integrates", providerState: "", request: request, response: response)

        self.client.registerInteractions([interaction0, interaction1]) { (_, response, error) in
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertNil(error)
            expectationToRun.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testVerify() {
        let expectationToRun = expectation(description: "contract is valid")
        let request = Interaction.Request(method: .get, path: "/integrates/", query: nil, headers: nil, body: nil)
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let interaction = Interaction(description: "Get integrates", providerState: nil, request: request, response: response)

        self.client.registerInteraction(interaction) { (_, _, _) in
            self.client.verify { (result) in
                XCTAssertFalse(result)
                expectationToRun.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testVerifyInMainThread() {
        let expectationToRun = expectation(description: "contract is valid")
        let request = Interaction.Request(method: .get, path: "/integrates/", query: nil, headers: nil, body: nil)
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let interaction = Interaction(description: "Get integrates", providerState: nil, request: request, response: response)

        self.client.registerInteraction(interaction) { (_, _, _) in
            self.client.verify { (_) in
                XCTAssertTrue(Thread.isMainThread)
                expectationToRun.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testVerifyWithValidRequest() {
        let expectationToRun = expectation(description: "contract is valid")
        let request = Interaction.Request(method: .get, path: "/integrates/", query: nil, headers: nil, body: nil)
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let interaction = Interaction(description: "Get integrates", providerState: nil, request: request, response: response)

        self.client.registerInteraction(interaction) { (_, _, _) in
            let request = URLRequest(url: self.session.baseURL.appendingPathComponent("/integrates/"))
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration)
            let task = session.dataTask(with: request) { (_, _, _) in
                self.client.verify { (result) in
                    XCTAssertTrue(result)
                    expectationToRun.fulfill()
                }
            }
            task.resume()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testClearInteractions() {
        let expectationToRun = expectation(description: "interactions are cleaned")
        let request = Interaction.Request(method: .get, path: "/integrates/", query: nil, headers: nil, body: nil)
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let interaction = Interaction(description: "Get integrates", providerState: nil, request: request, response: response)

        self.client.registerInteraction(interaction) { (_, _, _) in
            self.client.cleanInteractions { (_, response, error) in
                XCTAssertEqual(response?.statusCode, 200)
                XCTAssertNil(error)
                expectationToRun.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testWritePact() {
        let expectationToRun = expectation(description: "pact file is generated")
        self.client.writePact(for: "providerName",
                              consumerName: "consumerName",
                              exportPath: URL(fileURLWithPath: "./tmp/pacts/foo/bar")) { (_, response, error) in
                                XCTAssertEqual(response?.statusCode, 200)
                                XCTAssertNil(error)
                                expectationToRun.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }
}
