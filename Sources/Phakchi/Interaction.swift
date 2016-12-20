import Foundation

typealias providerState = String

public typealias Query = [String: PactEncodable]
public typealias Headers = [String: PactEncodable]
public typealias Body = PactEncodable

struct Interaction: PactEncodable {
    struct Request: PactEncodable {
        let method: HTTPMethod
        let path: PactEncodable
        var query: Query?
        var headers: Headers?
        var body: Body?

        var pactJSON: Any {
            var JSON = [
                "method": method.rawValue.uppercased(),
                "path": path.pactJSON,
            ]
            if let body = body {
                JSON["body"] = body.pactJSON
            }
            if let headers = headers {
                JSON["headers"] = headers.pactJSON
            }
            if let query = query {
                JSON["query"] = query.pactJSON
            }
            return JSON
        }
    }

    struct Response: PactEncodable {
        let status: Int
        let headers: Headers?
        let body: Body?

        var pactJSON: Any {
            var JSON: JSONObject = ["status": status]
            if let headers = headers {
                JSON["headers"] = headers.pactJSON
            }
            if let body = body {
                JSON["body"] = body.pactJSON
            }
            return JSON
        }
    }

    var description: String
    var providerState: ProviderState?
    var request: Request
    var response: Response

    var pactJSON: Any {
        var param: JSONObject = [
            "description": description,
            "request": request.pactJSON,
            "response": response.pactJSON,
        ]
        if let providerState = providerState {
            param["providerState"] = providerState
        }
        return param
    }
}
