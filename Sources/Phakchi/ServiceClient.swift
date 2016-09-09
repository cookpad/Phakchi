import Foundation

private let adminHeaders = [
    "X-Pact-Mock-Service": "true",
    "Content-Type": "application/json",
]
typealias CompletionHandler = (NSData?, NSHTTPURLResponse?, NSError?) -> Void
typealias VerificationCompletionHandler = (Bool) -> Void

protocol BaseServiceClient {
    var baseURL: NSURL { get }
}

extension BaseServiceClient {
    typealias buildRequestBlock = (NSMutableURLRequest) -> Void
    private func buildPactRequest(to endpoint: String,
                                     method: HTTPMethod,
                                     headers: [String: String] = adminHeaders,
                                     block: buildRequestBlock? = nil) -> NSMutableURLRequest {
        #if swift(>=2.3)
            guard let endpointURL = baseURL.URLByAppendingPathComponent(endpoint) else {
            fatalError("Invalid endpoint \(endpoint)")
            }
        #else
            let endpointURL = baseURL.URLByAppendingPathComponent(endpoint)
        #endif
        let request = NSMutableURLRequest(URL: endpointURL)
        request.HTTPMethod = method.rawValue
        for (k, v) in headers {
            request.addValue(v, forHTTPHeaderField: k)
        }
        block?(request)
        return request
    }

    private func resumeSessionTask(request: NSURLRequest, completionHandler: CompletionHandler?) {
        let configure = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configure)
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler?(data, response as? NSHTTPURLResponse, error)
            }
        }
        task.resume()
    }
}

struct MockServiceClient: BaseServiceClient {
    let baseURL: NSURL

    init(baseURL: NSURL) {
        self.baseURL = baseURL
    }

    func registerInteraction(interaction: Interaction, completionHandler: CompletionHandler? = nil) {
        registerInteractions([interaction], completionHandler: completionHandler)
    }

    func registerInteractions(interactions: [Interaction], completionHandler: CompletionHandler? = nil) {
        let params = ["interactions" : interactions.map { $0.pactJSON }]

        let JSONData = params.JSONData
        let request = buildPactRequest(to: "interactions", method: .PUT) { (request) in
            request.HTTPBody = JSONData
        }
        resumeSessionTask(request, completionHandler: completionHandler)
    }

    func verify(completionHandler: VerificationCompletionHandler) {
        let request = buildPactRequest(to: "interactions/verification", method: .GET)
        resumeSessionTask(request) { (data, response, error) in
            completionHandler(response?.statusCode == 200)
        }
    }

    func cleanInteractions(completionHandler: CompletionHandler? = nil) {
        let request = buildPactRequest(to: "interactions", method: .DELETE)
        resumeSessionTask(request, completionHandler: completionHandler)
    }

    func writePact(for providerName: String,
                       consumerName: String,
                       exportPath: NSURL?,
                       completionHandler: CompletionHandler? = nil) {
        let request = buildPactRequest(to: "pact", method: .POST) { (request) in
            var param: [String: AnyObject] = [
                "consumer" : [
                    "name" : consumerName
                ],
                "provider" : [
                    "name" : providerName
                ],
            ]
            if let exportPath = exportPath {
                if exportPath.fileURL {
                    if let path = exportPath.path {
                        param["pact_dir"] = path
                    }
                }
            }
            request.HTTPBody = param.JSONData
        }
        resumeSessionTask(request, completionHandler: completionHandler)
    }

    func closeSession(completionHandler: CompletionHandler? = nil) {
        let request = buildPactRequest(to: "session", method: .DELETE)
        resumeSessionTask(request, completionHandler: completionHandler)
    }
}

struct ControlServiceClient: BaseServiceClient {
    typealias CreateSessionCompletionHandler = (Session?) -> Void
    private let defaultControlServerURL = NSURL(string: "http://localhost:8080")!

    let baseURL: NSURL

    init() {
        baseURL = defaultControlServerURL
    }

    init(baseURL: NSURL) {
        self.baseURL = baseURL
    }

    private func buildStartMockServerHeader(for consumerName: String, providerName: String) -> [String: String] {
        return [
            "X-Pact-Consumer" : consumerName,
            "X-Pact-Provider" : providerName,
        ]
    }

    func startSession(withConsumerName consumerName: String, providerName: String, completionHandler: CreateSessionCompletionHandler) {
        let request = buildPactRequest(to: "",
                                       method: .POST,
                                       headers: buildStartMockServerHeader(for: consumerName, providerName: providerName))
        resumeSessionTask(request) { (data, response, error) in
            if let response = response,
                location = response.allHeaderFields["X-Pact-Mock-Service-Location"] as? String,
                let baseURL = NSURL(string: location) {
                let session: Session = Session(consumerName: consumerName, providerName: providerName, baseURL: baseURL)
                completionHandler(session)
            } else {
                completionHandler(nil)
            }
        }
    }
}
