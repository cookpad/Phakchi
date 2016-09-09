import Foundation

public class ControlServer {
    public static let defaultServer = ControlServer()
    public typealias StartSessionCompletionBlock = (Session?) -> Void
    public private(set) var sessions: [Session] = []
    private let mockServiceClient = ControlServiceClient()

    public func startSession(withConsumerName consumerName: String,
                                              providerName: String,
                                              completionBlock: StartSessionCompletionBlock? = nil) {
        mockServiceClient.startSession(withConsumerName: consumerName,
                                       providerName: providerName) { (session) in
                                        if let session = session {
                                            self.sessions.append(session)
                                        }
                                        completionBlock?(session)
        }
    }

    public func session(forConsumerName consumerName: String,
                                        providerName: String) -> Session? {
        return sessions.filter { session in
            session.consumerName == consumerName &&
                session.providerName == providerName
            }.first
    }
}
