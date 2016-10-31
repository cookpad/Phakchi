import Foundation

public class Session {
    public typealias TestExecutionBlock = (@escaping (Void) -> Void) -> Void
    public typealias TestCompletionBlock = (Bool) -> Void
    public typealias CleanCompletionBlock = (Void) -> Void
    public typealias CloseCompletionBlock = (Void) -> Void

    public let consumerName: String
    public let providerName: String
    public fileprivate(set) var isOpen: Bool
    public var baseURL: URL {
        get {
            return mockServiceClient.baseURL as URL
        }
    }
    public var exportPath: URL? = nil

    private let mockServiceClient: MockServiceClient
    private let builder = InteractionBuilder()
    private(set) var interactions: [Interaction] = []
    public var defaultRequestHeader: Headers? {
        get {
            return builder.defaultRequestHeaders
        }
        set {
            builder.defaultRequestHeaders = newValue
        }
    }
    public var defaultResponseHeader: Headers? {
        get {
            return builder.defaultResponseHeaders
        }
        set {
            builder.defaultResponseHeaders = newValue
        }
    }

    required public init(consumerName: String, providerName: String, baseURL: URL) {
        self.consumerName = consumerName
        self.providerName = providerName
        self.mockServiceClient = MockServiceClient(baseURL: baseURL)
        self.isOpen = true
    }

    public func given(_ providerState: String) -> Self {
        _ = builder.given(providerState)
        return self
    }

    public func uponReceiving(_ description: String) -> Self {
        _ = builder.uponReceiving(description)
        return self
    }

    public func with(method: HTTPMethod, path: PactEncodable, query: Query? = nil, headers: Headers? = nil, body: Body? = nil) -> Self {
        _ = builder.with(method, path: path, query: query, headers: headers, body: body)
        return self
    }

    public func willRespondWith(status: Int, headers: Headers? = nil, body: Body? = nil) -> Self {
        _ = builder.willRespondWith(status, headers: headers, body: body)
        if let interaction = builder.buildInteraction() {
            interactions.append(interaction)
            builder.clean()
        }
        return self
    }

    public func run(completionBlock: TestCompletionBlock? = nil, executionBlock: @escaping TestExecutionBlock) {
        if !isOpen {
            print("This Pact session is already closed")
            return
        }

        mockServiceClient.registerInteractions(interactions) { (data, response, error) in
            let completeTest = {
                self.mockServiceClient.verify { (isValid) in
                    if isValid {
                        self.mockServiceClient.writePact(for: self.providerName,
                                                consumerName: self.consumerName,
                                                  exportPath: self.exportPath) { (data, response, error) in
                                                      completionBlock?(isValid)
                        }
                    } else {
                        completionBlock?(isValid)
                    }
                }
            }
            executionBlock(completeTest)
        }
    }

    public func clean(_ completionBlock: CleanCompletionBlock? = nil) {
        mockServiceClient.cleanInteractions { (data, response, error) in
            self.interactions.removeAll()
            completionBlock?()
        }
    }

    public func close(_ completionBlock: CloseCompletionBlock? = nil) {
        mockServiceClient.close { (data, response, error) in
            self.isOpen = false
            completionBlock?()
        }
    }
}
