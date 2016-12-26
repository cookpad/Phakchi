import Foundation

typealias JSONObject = [String: Any]

public protocol PactEncodable {
    var pactJSON: Any { get }
}

extension PactEncodable {
    public var pactJSON: Any {
        return self
    }
}

extension Int: PactEncodable { }
extension String: PactEncodable { }

extension Array: PactEncodable {
    public var pactJSON: Any {
        return flatMap { element -> Any? in
            if let element = element as? PactEncodable {
                return element.pactJSON
            }
            return nil
        }
    }
}

extension Dictionary: PactEncodable {
    public var pactJSON: Any {
        var jsonObject: [Key: Any] = [:]
        for (key, value) in self {
            if let value = value as? PactEncodable {
                jsonObject[key] = value.pactJSON
            }
        }
        return jsonObject
    }

    var JSONData: Data {
        if let data = try? JSONSerialization.data(withJSONObject: pactJSON, options: []) {
            return data
        }
        fatalError("Could not deserialize JSON")
    }
}
