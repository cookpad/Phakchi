import XCTest
@testable import Phakchi

class ControlServiceClientTestCase: XCTestCase {
    var controlServiceClient: ControlServiceClient!

    override func setUp() {
        super.setUp()
        self.controlServiceClient = ControlServiceClient()
    }

    func testStart() {
        var session: Session!
        let expectationToStart = expectation(description: "session was started")
        let controlServiceClient = ControlServiceClient()
        controlServiceClient.start(session: "consumer name",
                                   providerName: "provider name") { newSession in
                                    session = newSession
                                    XCTAssertEqual(session.consumerName, "consumer name")
                                    XCTAssertEqual(session.providerName, "provider name")
                                    XCTAssertNotNil(session)
                                    expectationToStart.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

}
