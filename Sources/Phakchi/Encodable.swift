import Foundation

typealias JSONObject = [String: PactJSON]

public protocol PactEncodable {
    var pactJSON: PactJSON { get }
}

extension String: PactEncodable {
    public var pactJSON: PactJSON {
        return self
    }
}

extension Dictionary: PactEncodable {
    public var pactJSON: PactJSON {
        var jsonObject: [Key: PactJSON] = [:]
        for (key, value) in self {
            if let value = value as? PactEncodable {
                jsonObject[key] = value.pactJSON
            }
        }
        return jsonObject
    }
}

public protocol PactJSON {
    var json: PactJSON { get }
}

extension PactJSON {
    var JSONData: Data {
        if let data = try? JSONSerialization.data(withJSONObject: json, options: []) {
            return data
        }
        fatalError("Could not deserialize JSON")
    }
}

extension Int: PactJSON {
    public var json: PactJSON {
        return self
    }
}

extension Double: PactJSON {
    public var json: PactJSON {
        return self
    }
}

extension Bool: PactJSON {
    public var json: PactJSON {
        return self
    }
}

extension String: PactJSON {
    public var json: PactJSON {
        return self
    }
}

extension Array: PactJSON {
    public var json: PactJSON {
        return flatMap { element -> PactJSON? in
            if let element = element as? PactJSON {
                return element.json
            }
            return nil
        }
    }
}

extension Dictionary: PactJSON {
    public var json: PactJSON {
        var jsonObject: [Key: PactJSON] = [:]
        for (key, value) in self {
            if let value = value as? PactJSON {
                jsonObject[key] = value.json
            }
        }
        return jsonObject
    }
}
