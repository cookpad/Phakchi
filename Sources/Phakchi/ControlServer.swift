import Foundation

public class ControlServer {
    public static let `default` = ControlServer()
    public typealias StartSessionCompletionBlock = (Session?) -> Void
    // want to make concealed setter from external
    private var _sessions: [Session] = []
    public var sessions: [Session] {
        return _sessions
    }
    private let mockServiceClient = ControlServiceClient()

    public func startSession(withConsumerName consumerName: String,
                           providerName: String,
                           completionBlock: StartSessionCompletionBlock? = nil) {
        mockServiceClient.startSession(withConsumerName: consumerName,
                                       providerName: providerName) { session in
                                        if let session = session {
                                            self._sessions.append(session)
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
