import XCTest
@testable import Phakchi

class MockServiceClientTestCase: XCTestCase {
    var client: MockServiceClient!
    var session: Session!

    override func setUp() {
        super.setUp()
        let exp = expectation(description: "session is started")
        let controlServiceClient = ControlServiceClient()
        controlServiceClient.startSession(withConsumerName: "consumer name",
                                          providerName: "provider name") { (session) in
                                            self.session = session
                                            self.client = MockServiceClient(baseURL: self.session.baseURL)
                                            exp.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    override func tearDown() {
        super.tearDown()
        self.client.cleanInteractions()

        let expectation = self.expectation(description: "session is closed")

        // workaround to pass test on CI
        let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.session.close { _ in
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testRegisterInteraction() {
        let expectation = self.expectation(description: "interactions are registered")
        let request = Interaction.Request(method: .GET, path: "/integrates/", query: nil, headers: nil, body: nil)
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let interaction = Interaction(description: "Get integrates", providerState: nil, request: request, response: response)

        self.client.registerInteraction(interaction) { (data, response, error) in
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testRegisterInteractions() {
        let expectation = self.expectation(description: "interactions are registered")
        let request = Interaction.Request(method: .GET, path: "/integrates/", query: nil, headers: nil, body: nil)
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let interaction0 = Interaction(description: "Get integrates", providerState: "", request: request, response: response)
        let interaction1 = Interaction(description: "Get integrates", providerState: "", request: request, response: response)

        self.client.registerInteractions([interaction0, interaction1]) { (data, response, error) in
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testVerify() {
        let expectation = self.expectation(description: "contract is valid")
        let request = Interaction.Request(method: .GET, path: "/integrates/", query: nil, headers: nil, body: nil)
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let interaction = Interaction(description: "Get integrates", providerState: nil, request: request, response: response)

        self.client.registerInteraction(interaction) { (data, response, error) in
            self.client.verify { (result) in
                XCTAssertFalse(result)
                expectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testVerifyInMainThread() {
        let expectation = self.expectation(description: "contract is valid")
        let request = Interaction.Request(method: .GET, path: "/integrates/", query: nil, headers: nil, body: nil)
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let interaction = Interaction(description: "Get integrates", providerState: nil, request: request, response: response)

        self.client.registerInteraction(interaction) { (data, response, error) in
            self.client.verify { (result) in
                XCTAssertTrue(NSThread.isMainThread())
                expectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testVerifyWithValidRequest() {
        let expectation = self.expectation(description: "contract is valid")
        let request = Interaction.Request(method: .GET, path: "/integrates/", query: nil, headers: nil, body: nil)
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let interaction = Interaction(description: "Get integrates", providerState: nil, request: request, response: response)

        self.client.registerInteraction(interaction) { (data, response, error) in
            let request = NSMutableURLRequest()
            request.URL = self.session.baseURL.URLByAppendingPathComponent("/integrates/")
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration)
            let task = session.dataTaskWithRequest(request) { (data, response, error) in
                self.client.verify { (result) in
                    XCTAssertTrue(result)
                    expectation.fulfill()
                }
            }
            task.resume()
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testClearInteractions() {
        let expectation = self.expectation(description: "interactions are cleaned")
        let request = Interaction.Request(method: .GET, path: "/integrates/", query: nil, headers: nil, body: nil)
        let response = Interaction.Response(status: 200, headers: nil, body: nil)
        let interaction = Interaction(description: "Get integrates", providerState: nil, request: request, response: response)

        self.client.registerInteraction(interaction) { (data, response, error) in
            self.client.cleanInteractions() { (data, response, error) in
                XCTAssertEqual(response?.statusCode, 200)
                XCTAssertNil(error)
                expectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testWritePact() {
        let expectation = self.expectation(description: "pact file is generated")
        self.client.writePact(for: "providerName",
                              consumerName: "consumerName",
                              exportPath: URL(fileURLWithPath: "./tmp/pacts/foo/bar")) { (data, response, error) in
                                XCTAssertEqual(response?.statusCode, 200)
                                XCTAssertNil(error)
                                expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }
}
