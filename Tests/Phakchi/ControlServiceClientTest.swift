import XCTest
@testable import Phakchi

class ControlServiceClientTestCase: XCTestCase {
    var controlServiceClient: ControlServiceClient!

    override func setUp() {
        super.setUp()
        self.controlServiceClient = ControlServiceClient()
    }

    func testStartSession() {
        var session: Session!
        let exp = expectation(description: "session was started")
        let controlServiceClient = ControlServiceClient()
        controlServiceClient.startSession(withConsumerName: "consumer name",
                                          providerName: "provider name") { (newSession) in
                                            session = newSession
                                            XCTAssertEqual(session.consumerName, "consumer name")
                                            XCTAssertEqual(session.providerName, "provider name")
                                            XCTAssertNotNil(session)
                                            exp.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

}
