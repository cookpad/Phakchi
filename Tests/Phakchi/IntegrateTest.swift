import XCTest
@testable import Phakchi

class IntegrateTestCase: XCTestCase {
    let controlServer: ControlServer = ControlServer()
    var session: Session!

    override func setUp() {
        super.setUp()
        let exp = expectation(description: "session was started")
        controlServer.startSession(consumerName: "consumer", providerName: "provider") { session in
            self.session = session
            exp.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func makeRequestURL(forEndpoint endpoint: String) -> URL {
        return session.baseURL.appendingPathComponent(endpoint)
    }

    func testSetExportPath() {
        self.session.exportPath = URL(fileURLWithPath: "./tmp/pacts/foo/bar")
    }

    func testSingleton() {
        let server0 = ControlServer.default
        let server1 = ControlServer.default
        let server2 = ControlServer()
        XCTAssert(server0 === server1)
        XCTAssert(server0 !== server2)
    }

    func testSession() {
        let session = controlServer.session(forConsumerName: "consumer", providerName: "provider")
        XCTAssert(session === self.session)
        XCTAssertNil(controlServer.session(forConsumerName: "invalid_consumer", providerName: "invalid_provider"))
    }

    func testMockServiceRunWithInvalid() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectationToRun = expectation(description: "contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .get, path: "/v1/recipes")
            .willRespondWith(status: 200)

        session.run(completionBlock: { (isValid) in
            XCTAssertFalse(isValid)
            expectationToRun.fulfill()
        },
                    executionBlock: { (completeTest) in
                        completeTest()
        })
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testMockServiceRunWithValid() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectationToRun = expectation(description: "contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .get, path: "/v1/recipes")
            .willRespondWith(status: 200)

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectationToRun.fulfill()
        },
                    executionBlock: { (completeTest) in
                        let configuration = URLSessionConfiguration.default
                        let session = URLSession(configuration: configuration)
                        let requestURL = self.makeRequestURL(forEndpoint: "/v1/recipes")
                        var request = URLRequest(url: requestURL)
                        request.httpMethod = HTTPMethod.get.rawValue
                        session.dataTask(with: request) { (_, _, _) in
                            completeTest()
                            }.resume()
        })
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testMockServiceRunWithHeaderUsingMatcher() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectationToRun = expectation(description: "contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .get, path: "/v1/recipes")
            .willRespondWith(status: 200,
                             headers: ["Content-Type": Matcher.term(generate: "application/json",
                                                                     matcher: "application/json")],
                             body: nil)

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectationToRun.fulfill()
        },
                    executionBlock: { (completeTest) in
                        let configuration = URLSessionConfiguration.default
                        let session = URLSession(configuration: configuration)
                        let requestURL = self.makeRequestURL(forEndpoint: "/v1/recipes")
                        var request = URLRequest(url: requestURL)
                        request.httpMethod = HTTPMethod.get.rawValue
                        session.dataTask(with: request) { (_, _, _) in
                            completeTest()
                            }.resume()
        })
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testMockServiceRunWithPathUsingMatcher() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectationToRun = expectation(description: "contract is valid")

        let path = Matcher.like("/v1/recipes")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .get, path: path)
            .willRespondWith(status: 200,
                             headers: ["Content-Type": Matcher.term(generate: "application/json",
                                                                     matcher: "application/json")],
                             body: nil)

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectationToRun.fulfill()
        },
                    executionBlock: { (completeTest) in
                        let configuration = URLSessionConfiguration.default
                        let session = URLSession(configuration: configuration)
                        let requestURL = self.makeRequestURL(forEndpoint: "/v1/recipes")
                        var request = URLRequest(url: requestURL)
                        request.httpMethod = HTTPMethod.get.rawValue
                        session.dataTask(with: request) { (_, _, _) in
                            completeTest()
                            }.resume()
        })
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testMockServiceRunWithQuery() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectationToRun = expectation(description: "contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .get,
                  path: "/v1/recipes",
                  query: ["keyword": "carrot"])
            .willRespondWith(status: 200)

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectationToRun.fulfill()
        }, executionBlock: { (completeTest) in
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration)
            var components = URLComponents(url: self.session.baseURL, resolvingAgainstBaseURL: false)!
            components.path = "/v1/recipes"
            components.query = "keyword=carrot"
            var request = URLRequest(url: components.url!)
            request.httpMethod = HTTPMethod.get.rawValue
            session.dataTask(with: request) { (_, _, _) in
                completeTest()
                }.resume()
        })
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testMockServiceRunWithTerm() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectationToRun = expectation(description: "contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .get,
                  path: "/v1/recipes",
                  query: ["keyword": Matcher.term(generate: "carrot", matcher: "^[a-z]+")])
            .willRespondWith(status: 200)

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectationToRun.fulfill()
        },
                    executionBlock: { (completeTest) in
                        let configuration = URLSessionConfiguration.default
                        let session = URLSession(configuration: configuration)
                        var components = URLComponents(url: self.session.baseURL, resolvingAgainstBaseURL: false)!
                        components.path = "/v1/recipes"
                        components.query = "keyword=eggplant" // should be match
                        var request = URLRequest(url: components.url!)
                        request.httpMethod = HTTPMethod.get.rawValue
                        session.dataTask(with: request) { (_, _, _) in
                            completeTest()
                            }.resume()
        })
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testMockServiceRunWithDefaultRequestAndResponseHeader() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectationToRun = expectation(description: "contract is valid")
        session.defaultRequestHeader = [
            "Auth": "authtoken"
        ]
        session.defaultResponseHeader = [
            "Content-Type": "application/json"
        ]

        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .get,
                  path: "/v1/recipes",
                  query: ["keyword": Matcher.term(generate: "carrot", matcher: "^[a-z]+")])
            .willRespondWith(status: 200)

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectationToRun.fulfill()
        },
                    executionBlock: { (completeTest) in
                        let configuration = URLSessionConfiguration.default
                        let session = URLSession(configuration: configuration)
                        var components = URLComponents(url: self.session.baseURL, resolvingAgainstBaseURL: false)!
                        components.path = "/v1/recipes"
                        components.query = "keyword=eggplant" // should be match
                        var request = URLRequest(url: components.url!)
                        request.httpMethod = HTTPMethod.get.rawValue
                        request.addValue("authtoken", forHTTPHeaderField: "Auth")
                        session.dataTask(with: request) { (_, _, _) in
                            completeTest()
                            }.resume()
        })
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testMockServiceRunWithLike() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectationToRun = expectation(description: "contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .get,
                  path: "/v1/recipes",
                  query: ["keyword": Matcher.like("carrot")])
            .willRespondWith(status: 200,
                             headers: ["Content-Type": "application/json"],
                             body: ["count": Matcher.like(10)])

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectationToRun.fulfill()
        },
                    executionBlock: { (completeTest) in
                        let configuration = URLSessionConfiguration.default
                        let session = URLSession(configuration: configuration)
                        var components = URLComponents(url: self.session.baseURL, resolvingAgainstBaseURL: false)!
                        components.path = "/v1/recipes"
                        components.query = "keyword=eggplant" // should be match
                        var request = URLRequest(url: components.url!)
                        request.httpMethod = HTTPMethod.get.rawValue
                        session.dataTask(with: request) { (_, _, _) in
                            completeTest()
                            }.resume()
        })
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testMockServiceRunWithEachLike() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectationToRun = expectation(description: "contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .get,
                  path: "/v1/recipes")
            .willRespondWith(status: 200,
                             headers: ["Content-Type": "application/json"],
                             body: Matcher.eachLike([
                                "title": Matcher.like("Curry"),
                                "calorie": Matcher.like(100)]))

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectationToRun.fulfill()
        },
                    executionBlock: { (completeTest) in
                        let configuration = URLSessionConfiguration.default
                        let session = URLSession(configuration: configuration)
                        var components = URLComponents(url: self.session.baseURL, resolvingAgainstBaseURL: false)!
                        components.path = "/v1/recipes"
                        var request = URLRequest(url: components.url!)
                        request.httpMethod = HTTPMethod.get.rawValue
                        session.dataTask(with: request) { (_, _, _) in
                            completeTest()
                            }.resume()
        })
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testCloseSession() {
        let expectationToRun = expectation(description: "session is closed")
        XCTAssertTrue(session.isOpen)
        session.close {
            XCTAssertFalse(self.session.isOpen)
            expectationToRun.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testCleanSession() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectationToRun = expectation(description: "contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .get, path: "/v1/recipes")
            .willRespondWith(status: 200)

        session.run(completionBlock: { (isValid) in
            XCTAssertFalse(isValid)
            expectationToRun.fulfill()
        },
                    executionBlock: { (completeTest) in
                        completeTest()
        })
        waitForExpectations(timeout: 10.0, handler: nil)

        XCTAssertEqual(session.interactions.count, 1)

        let cleanUpExpectation = expectation(description: "interactions are cleaned")
        session.clean {
            XCTAssertEqual(self.session.interactions.count, 0)
            cleanUpExpectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    override func tearDown() {
        super.tearDown()

        let expectationToRun = expectation(description: "session is closed")
        self.session.close {
            expectationToRun.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

}
