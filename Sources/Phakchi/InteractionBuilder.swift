import Foundation

typealias ProviderState = String
typealias InteractionBuilderCallback = (Interaction) -> Void

class InteractionBuilder {
    private var providerState: ProviderState?
    private var description: String?

    private var requestExpectation: Interaction.Request?
    private var responseExpectation: Interaction.Response?
    var defaultRequestHeaders: Headers?
    var defaultResponseHeaders: Headers?

    required init() {

    }

    private func makeHeaders(_ headers: Headers?, defaultHeaders: Headers?) -> Headers? {
        guard let defaultHeaders = defaultHeaders else {
            return headers
        }

        guard let headers = headers else {
            return defaultHeaders
        }

        var newHeaders = defaultHeaders
        for (k, v) in headers {
            newHeaders[k] = v
        }
        return newHeaders
    }

    func given(_ providerState: String) -> Self {
        self.providerState = providerState
        return self
    }

    func uponReceiving(_ description: String) -> Self {
        self.description = description
        return self
    }

    func with(_ method: HTTPMethod,
              path: PactEncodable,
              query: Query? = nil,
              headers: Headers? = nil,
              body: Body? = nil) -> Self {
        let newHeaders = makeHeaders(headers, defaultHeaders: defaultRequestHeaders)
        requestExpectation = Interaction.Request(method: method,
                                                 path: path,
                                                 query: query,
                                                 headers: newHeaders,
                                                 body: body)
        return self
    }

    func willRespondWith(_ status: Int,
                         headers: Headers? = nil,
                         body: Body? = nil) -> Self {
        let newHeaders = makeHeaders(headers, defaultHeaders:defaultResponseHeaders)
        responseExpectation = Interaction.Response(status: status, headers: newHeaders, body: body)
        return self
    }

    func buildInteraction() -> Interaction? {
        if !isValid {
            return nil
        }
        guard let description = description, let request = requestExpectation, let response = responseExpectation else {
            return nil
        }
        let interaction = Interaction(
            description: description,
            providerState: providerState,
            request: request,
            response: response
        )
        return interaction
    }

    func clean() {
        self.description = ""
        self.providerState = nil
        self.requestExpectation = nil
        self.responseExpectation = nil
    }

    var isValid: Bool {
        return description != nil && requestExpectation != nil && responseExpectation != nil
    }
}
