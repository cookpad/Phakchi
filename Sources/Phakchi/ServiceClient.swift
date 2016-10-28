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
    typealias buildRequestBlock = (NSMutableURLRequest) -> Void
    fileprivate func buildPactRequest(to endpoint: String,
                                      method: HTTPMethod,
                                      headers: [String: String] = adminHeaders,
                                      block: buildRequestBlock? = nil) -> NSMutableURLRequest {
        let endpointURL = baseURL.appendingPathComponent(endpoint)
        let request = NSMutableURLRequest(url: endpointURL)
        request.httpMethod = method.rawValue
        for (k, v) in headers {
            request.addValue(v, forHTTPHeaderField: k)
        }
        block?(request)
        return request
    }

    fileprivate func resumeSessionTask(_ request: URLRequest, completionHandler: CompletionHandler? = nil) {
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
        let params = ["interactions" : interactions.map { $0.pactJSON }]

        let JSONData = params.JSONData
        let request = buildPactRequest(to: "interactions", method: .put) { (request) in
            request.httpBody = JSONData
        }
        resumeSessionTask(request as URLRequest, completionHandler: completionHandler)
    }

    func verify(_ completionHandler: VerificationCompletionHandler? = nil) {
        let request = buildPactRequest(to: "interactions/verification", method: .get)
        resumeSessionTask(request as URLRequest) { (data, response, error) in
            completionHandler?(response?.statusCode == 200)
        }
    }

    func cleanInteractions(_ completionHandler: CompletionHandler? = nil) {
        let request = buildPactRequest(to: "interactions", method: .delete)
        resumeSessionTask(request as URLRequest, completionHandler: completionHandler)
    }

    func writePact(for providerName: String,
                   consumerName: String,
                   exportPath: URL?,
                   completionHandler: CompletionHandler? = nil) {
        let request = buildPactRequest(to: "pact", method: .post) { (request) in
            var param: JSONObject = [
                "consumer" : [
                    "name" : consumerName
                ],
                "provider" : [
                    "name" : providerName
                ],
                ]
            if let exportPath = exportPath {
                if exportPath.isFileURL {
                    param["pact_dir"] = exportPath.path
                }
            }
            request.httpBody = param.JSONData as Data
        }
        resumeSessionTask(request as URLRequest, completionHandler: completionHandler)
    }

    func closeSession(_ completionHandler: CompletionHandler? = nil) {
        let request = buildPactRequest(to: "session", method: .delete)
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

    private func buildStartMockServerHeader(for consumerName: String, providerName: String) -> [String: String] {
        return [
            "X-Pact-Consumer" : consumerName,
            "X-Pact-Provider" : providerName,
        ]
    }

    func startSession(withConsumerName consumerName: String, providerName: String, completionHandler: @escaping CreateSessionCompletionHandler) {
        let request = buildPactRequest(to: "",
                                       method: .post,
                                       headers: buildStartMockServerHeader(for: consumerName, providerName: providerName))
        resumeSessionTask(request as URLRequest) { (data, response, error) in
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
