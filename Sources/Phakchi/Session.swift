import Foundation

public class Session {
    public typealias TestExecutionBlock = ((Void) -> Void) -> Void
    public typealias TestCompletionBlock = (Bool) -> Void
    public typealias CleanCompletionBlock = (Void) -> Void
    public typealias CloseCompletionBlock = (Void) -> Void

    public let consumerName: String
    public let providerName: String
    public private(set) var isOpen: Bool
    public var baseURL: NSURL {
        get {
            return mockServiceClient.baseURL
        }
    }
    public var exportPath: NSURL? = nil

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

    required public init(consumerName: String, providerName: String, baseURL: NSURL) {
        self.consumerName = consumerName
        self.providerName = providerName
        self.mockServiceClient = MockServiceClient(baseURL: baseURL)
        self.isOpen = true
    }

    public func given(providerState: String) -> Self {
        builder.given(providerState)
        return self
    }

    public func uponReceiving(description: String) -> Self {
        builder.uponReceiving(description)
        return self
    }

    public func with(method method: HTTPMethod, path: PactEncodable, query: Query? = nil, headers: Headers? = nil, body: Body? = nil) -> Self {
        builder.with(method, path: path, query: query, headers: headers, body: body)
        return self
    }

    public func willRespondWith(status status: Int, headers: Headers? = nil, body: Body? = nil) -> Self {
        builder.willRespondWith(status, headers: headers, body: body)
        if let interaction = builder.buildInteraction() {
            interactions.append(interaction)
            builder.clean()
        }
        return self
    }

    public func run(completionBlock completionBlock: TestCompletionBlock? = nil, executionBlock: TestExecutionBlock) {
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

    public func clean(completionBlock: CleanCompletionBlock? = nil) {
        mockServiceClient.cleanInteractions { (data, response, error) in
            self.interactions.removeAll()
            completionBlock?()
        }
    }

    public func close(completionBlock: CloseCompletionBlock? = nil) {
        mockServiceClient.closeSession { (data, response, error) in
            self.isOpen = false
            completionBlock?()
        }
    }
}
