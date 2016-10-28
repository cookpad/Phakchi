import Foundation

typealias JSONObject = [String: Any]

public protocol PactEncodable {
    var pactJSON: Any { get }
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
    public var pactJSON: Any {
        return self
    }
}

extension Double: PactEncodable {
    public var pactJSON: Any {
        return self
    }
}

extension Bool: PactEncodable {
    public var pactJSON: Any {
        return self
    }
}

extension String: PactEncodable {
    public var pactJSON: Any {
        return self as Any
    }
}

extension Array where Element: PactEncodable {
    public var pactJSON: Any {
        return self.map { $0.pactJSON } as Any
    }
}

extension Dictionary: PactEncodable {
    public var pactJSON: Any {
        return self as Any
    }
}
