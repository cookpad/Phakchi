import XCTest
@testable import Phakchi

class IntegrateTestCase: XCTestCase {
    let controlServer: ControlServer = ControlServer()
    var session: Session!

    override func setUp() {
        super.setUp()
        let exp = expectationWithDescription("session was started")
        controlServer.startSession(withConsumerName: "consumer", providerName: "provider") { (session) in
            self.session = session
            exp.fulfill()
        }
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func makeRequestURL(forEndpoint endpoint: String) -> NSURL {
        #if swift(>=2.3)
            guard let requestURL = session.baseURL.URLByAppendingPathComponent(endpoint) else { fatalError("Invalid endpoint \(endpoint)") }
            return requestURL
        #else
            return session.baseURL.URLByAppendingPathComponent(endpoint)
        #endif
    }

    func testSetExportPath() {
        self.session.exportPath = NSURL(fileURLWithPath: "./tmp/pacts/foo/bar")
    }

    func testSingleton() {
        let server0 = ControlServer.defaultServer
        let server1 = ControlServer.defaultServer
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
        let expectation = expectationWithDescription("contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .GET, path: "/v1/recipes")
            .willRespondWith(status: 200)

        session.run(completionBlock: { (isValid) in
            XCTAssertFalse(isValid)
            expectation.fulfill()
        },
                    executionBlock: { (completeTest) in
            completeTest()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testMockServiceRunWithValid() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectation = expectationWithDescription("contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .GET, path: "/v1/recipes")
            .willRespondWith(status: 200)

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectation.fulfill()
        },
                    executionBlock: { (completeTest) in
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration)
            let requestURL = self.makeRequestURL(forEndpoint: "/v1/recipes")
            let request = NSMutableURLRequest(URL: requestURL)
            request.HTTPMethod = HTTPMethod.GET.rawValue
            session.dataTaskWithRequest(request) { (data, response, error) in
                completeTest()
                }.resume()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testMockServiceRunWithHeaderUsingMatcher() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectation = expectationWithDescription("contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .GET, path: "/v1/recipes")
            .willRespondWith(status: 200,
                             headers: ["Content-Type" : Matcher.term(generate: "application/json",
                                                                      matcher: "application/json")],
                             body: nil)

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectation.fulfill()
        },
                    executionBlock: { (completeTest) in
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration)
            let requestURL = self.makeRequestURL(forEndpoint: "/v1/recipes")
            let request = NSMutableURLRequest(URL: requestURL)
            request.HTTPMethod = HTTPMethod.GET.rawValue
            session.dataTaskWithRequest(request) { (data, response, error) in
                completeTest()
                }.resume()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testMockServiceRunWithPathUsingMatcher() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectation = expectationWithDescription("contract is valid")

        let path = Matcher.like("/v1/recipes")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .GET, path: path)
            .willRespondWith(status: 200,
                             headers: ["Content-Type" : Matcher.term(generate: "application/json",
                                matcher: "application/json")],
                             body: nil)

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectation.fulfill()
        },
                    executionBlock: { (completeTest) in
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration)
            let requestURL = self.makeRequestURL(forEndpoint: "/v1/recipes")
            let request = NSMutableURLRequest(URL: requestURL)
            request.HTTPMethod = HTTPMethod.GET.rawValue
            session.dataTaskWithRequest(request) { (data, response, error) in
                completeTest()
            }.resume()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testMockServiceRunWithQuery() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectation = expectationWithDescription("contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .GET,
                path: "/v1/recipes",
                query: ["keyword": "carrot"])
            .willRespondWith(status: 200)

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectation.fulfill()
        }, executionBlock: { (completeTest) in
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration)
            let components = NSURLComponents(URL: self.session.baseURL, resolvingAgainstBaseURL: false)!
            components.path = "/v1/recipes"
            components.query = "keyword=carrot"
            let request = NSMutableURLRequest(URL: components.URL!)
            request.HTTPMethod = HTTPMethod.GET.rawValue
            session.dataTaskWithRequest(request) { (data, response, error) in
                completeTest()
            }.resume()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testMockServiceRunWithTerm() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectation = expectationWithDescription("contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .GET,
                path: "/v1/recipes",
                query: ["keyword" : Matcher.term(generate: "carrot", matcher: "^[a-z]+")])
            .willRespondWith(status: 200)

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectation.fulfill()
        },
                    executionBlock: { (completeTest) in
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration)
            let components = NSURLComponents(URL: self.session.baseURL, resolvingAgainstBaseURL: false)!
            components.path = "/v1/recipes"
            components.query = "keyword=eggplant" // should be match
            let request = NSMutableURLRequest(URL: components.URL!)
            request.HTTPMethod = HTTPMethod.GET.rawValue
            session.dataTaskWithRequest(request) { (data, response, error) in
                completeTest()
            }.resume()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testMockServiceRunWithDefaultRequestAndResponseHeader() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectation = expectationWithDescription("contract is valid")
        session.defaultRequestHeader = [
            "Auth" : "authtoken"
        ]
        session.defaultResponseHeader = [
            "Content-Type" : "application/json"
        ]

        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .GET,
                path: "/v1/recipes",
                query: ["keyword" : Matcher.term(generate: "carrot", matcher: "^[a-z]+")])
            .willRespondWith(status: 200)

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectation.fulfill()
        },
                    executionBlock: { (completeTest) in
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration)
            let components = NSURLComponents(URL: self.session.baseURL, resolvingAgainstBaseURL: false)!
            components.path = "/v1/recipes"
            components.query = "keyword=eggplant" // should be match
            let request = NSMutableURLRequest(URL: components.URL!)
            request.HTTPMethod = HTTPMethod.GET.rawValue
            request.addValue("authtoken", forHTTPHeaderField: "Auth")
            session.dataTaskWithRequest(request) { (data, response, error) in
                completeTest()
            }.resume()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testMockServiceRunWithLike() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectation = expectationWithDescription("contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .GET,
                path: "/v1/recipes",
                query: ["keyword": Matcher.like("carrot")])
            .willRespondWith(status: 200,
                             headers: ["Content-Type": "application/json"],
                             body: ["count": Matcher.like(10)])

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectation.fulfill()
        },
                    executionBlock: { (completeTest) in
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration)
            let components = NSURLComponents(URL: self.session.baseURL, resolvingAgainstBaseURL: false)!
            components.path = "/v1/recipes"
            components.query = "keyword=eggplant" // should be match
            let request = NSMutableURLRequest(URL: components.URL!)
            request.HTTPMethod = HTTPMethod.GET.rawValue
            session.dataTaskWithRequest(request) { (data, response, error) in
                completeTest()
            }.resume()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testMockServiceRunWithEachLike() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectation = expectationWithDescription("contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .GET,
                path: "/v1/recipes")
            .willRespondWith(status: 200,
                             headers: ["Content-Type": "application/json"],
                             body: Matcher.eachLike([
                                "title": Matcher.like("Curry"),
                                "calorie": Matcher.like(100)]))

        session.run(completionBlock: { (isValid: Bool) in
            XCTAssertTrue(isValid)
            expectation.fulfill()
        },
                    executionBlock: { (completeTest) in
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration)
            let components = NSURLComponents(URL: self.session.baseURL, resolvingAgainstBaseURL: false)!
            components.path = "/v1/recipes"
            let request = NSMutableURLRequest(URL: components.URL!)
            request.HTTPMethod = HTTPMethod.GET.rawValue
            session.dataTaskWithRequest(request) { (data, response, error) in
                completeTest()
            }.resume()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testCloseSession() {
        let expectation = expectationWithDescription("session is closed")
        XCTAssertTrue(session.isOpen)
        session.close {
            XCTAssertFalse(self.session.isOpen)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testCleanSession() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectation = expectationWithDescription("contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .GET, path: "/v1/recipes")
            .willRespondWith(status: 200)

        session.run(completionBlock: { (isValid) in
            XCTAssertFalse(isValid)
            expectation.fulfill()
        },
                    executionBlock: { (completeTest) in
            completeTest()
        })
        waitForExpectationsWithTimeout(5, handler: nil)

        XCTAssertEqual(session.interactions.count, 1)

        let cleanUpExpectation = expectationWithDescription("interactions are cleaned")
        session.clean {
            XCTAssertEqual(self.session.interactions.count, 0)
            cleanUpExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    override func tearDown() {
        super.tearDown()
        let exp = expectationWithDescription("session is closed")
        session.close {
            exp.fulfill()
        }
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }

}
