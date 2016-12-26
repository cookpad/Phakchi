import Foundation

private let adminHeaders = [
    "X-Pact-Mock-Service": "true",
    "Content-Type": "application/json",
]
typealias CompletionHandler = (Data?, HTTPURLResponse?, Error?) -> Void
typealias VerificationCompletionHandler = (Bool) -> Void

protocol BaseServiceClient {
    var baseURL: URL { get }
}

extension BaseServiceClient {
    func makePactRequest(to endpoint: String,
                         method: HTTPMethod,
                         headers: [String: String] = adminHeaders) -> URLRequest {
        let endpointURL = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: endpointURL)
        request.httpMethod = method.rawValue.uppercased()
        for (k, v) in headers {
            request.addValue(v, forHTTPHeaderField: k)
        }
        return request
    }

    func resumeSessionTask(_ request: URLRequest, completionHandler: CompletionHandler? = nil) {
        let configure = URLSessionConfiguration.default
        let session = URLSession(configuration: configure)
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            DispatchQueue.main.async {
                let httpResponse = response as? HTTPURLResponse ?? nil
                completionHandler?(data, httpResponse, error)
            }
        })
        task.resume()
    }
}

struct MockServiceClient: BaseServiceClient {
    let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func registerInteraction(_ interaction: Interaction, completionHandler: CompletionHandler? = nil) {
        registerInteractions([interaction], completionHandler: completionHandler)
    }

    func registerInteractions(_ interactions: [Interaction], completionHandler: CompletionHandler? = nil) {
        let params = ["interactions": interactions.map { $0.pactJSON }]

        let JSONData = params.JSONData
        var request = makePactRequest(to: "interactions", method: .put)
        request.httpBody = JSONData
        resumeSessionTask(request as URLRequest, completionHandler: completionHandler)
    }

    func verify(_ completionHandler: VerificationCompletionHandler? = nil) {
        let request = makePactRequest(to: "interactions/verification", method: .get)
        resumeSessionTask(request as URLRequest) { (_, response, _) in
            completionHandler?(response?.statusCode == 200)
        }
    }

    func cleanInteractions(_ completionHandler: CompletionHandler? = nil) {
        let request = makePactRequest(to: "interactions", method: .delete)
        resumeSessionTask(request as URLRequest, completionHandler: completionHandler)
    }

    func writePact(for providerName: String,
                   consumerName: String,
                   exportPath: URL?,
                   completionHandler: CompletionHandler? = nil) {
        var request = makePactRequest(to: "pact", method: .post)
        var param: JSONObject = [
            "consumer": [
                "name": consumerName
            ],
            "provider": [
                "name": providerName
            ],
            ]
        if let exportPath = exportPath {
            if exportPath.isFileURL {
                param["pact_dir"] = exportPath.path
            }
        }
        request.httpBody = param.JSONData
        resumeSessionTask(request as URLRequest, completionHandler: completionHandler)
    }

    func close(handler completionHandler: CompletionHandler? = nil) {
        let request = makePactRequest(to: "session", method: .delete)
        resumeSessionTask(request as URLRequest, completionHandler: completionHandler)
    }
}

struct ControlServiceClient: BaseServiceClient {
    typealias CreateSessionCompletionHandler = (Session?) -> Void
    private let defaultControlServerURL = URL(string: "http://localhost:8080")!

    let baseURL: URL

    init() {
        baseURL = defaultControlServerURL
    }

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    private func makeMockServerHeader(for consumerName: String, providerName: String) -> [String: String] {
        return [
            "X-Pact-Consumer": consumerName,
            "X-Pact-Provider": providerName,
        ]
    }

    func start(session consumerName: String, providerName: String, completionHandler: @escaping CreateSessionCompletionHandler) {
        let request = makePactRequest(to: "",
                                      method: .post,
                                      headers: makeMockServerHeader(for: consumerName, providerName: providerName))
        resumeSessionTask(request as URLRequest) { (_, response, _) in
            if let response = response,
                let location = response.allHeaderFields["X-Pact-Mock-Service-Location"] as? String,
                let baseURL = URL(string: location) {
                let session: Session = Session(consumerName: consumerName, providerName: providerName, baseURL: baseURL)
                completionHandler(session)
            } else {
                completionHandler(nil)
            }
        }
    }
}
