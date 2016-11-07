import Foundation

public class ControlServer {
    public static let `default` = ControlServer()
    public typealias StartSessionCompletionBlock = (Session?) -> Void
    // To have an internal setter
    private var _sessions: [Session] = []
    public var sessions: [Session] {
        return _sessions
    }
    private let mockServiceClient = ControlServiceClient()

    @available(*, renamed: "startSession(consumerName:providerName:completion:)")
    public func startSession(withConsumerName consumerName: String,
                             providerName: String,
                             completionBlock: StartSessionCompletionBlock? = nil) {
        fatalError()
    }

    public func startSession(consumerName: String,
                      providerName: String,
                      completion completionBlock: StartSessionCompletionBlock? = nil) {
        mockServiceClient.start(session: consumerName,
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
