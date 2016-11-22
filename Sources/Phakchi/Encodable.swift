import Foundation

typealias JSONObject = [String: PactEncodable]

public protocol PactEncodable {
    var pactJSON: PactEncodable { get }
}

extension PactEncodable {
    var JSONData: Data {
        if let data = try? JSONSerialization.data(withJSONObject: pactJSON, options: []) {
            return data
        }
        fatalError("Could not deserialize JSON")
    }
}

extension Int: PactEncodable {
    public var pactJSON: PactEncodable {
        return self
    }
}

extension Double: PactEncodable {
    public var pactJSON: PactEncodable {
        return self
    }
}

extension Bool: PactEncodable {
    public var pactJSON: PactEncodable {
        return self
    }
}

extension String: PactEncodable {
    public var pactJSON: PactEncodable {
        return self
    }
}

extension Array: PactEncodable {
    public var pactJSON: PactEncodable {
        return flatMap { element -> PactEncodable? in
            if let element = element as? PactEncodable {
                return element.pactJSON
            }
            return nil
        }
    }
}

extension Dictionary: PactEncodable {
    public var pactJSON: PactEncodable {
        var jsonObject: [Key: PactEncodable] = [:]
        for (key, value) in self {
            if let value = value as? PactEncodable {
                jsonObject[key] = value.pactJSON
            }
        }
        return jsonObject
    }
}
