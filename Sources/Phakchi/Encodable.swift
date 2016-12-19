import Foundation

typealias JSONObject = [String: JSONElement]

public protocol PactEncodable {
    var pactJSON: JSONElement { get }
}

extension String: PactEncodable {
    public var pactJSON: JSONElement {
        return self
    }
}

extension Dictionary: PactEncodable {
    public var pactJSON: JSONElement {
        var jsonObject: [Key: JSONElement] = [:]
        for (key, value) in self {
            if let value = value as? PactEncodable {
                jsonObject[key] = value.pactJSON
            }
        }
        return jsonObject
    }
}

public protocol JSONElement {
    var json: JSONElement { get }
}

extension JSONElement {
    var JSONData: Data {
        if let data = try? JSONSerialization.data(withJSONObject: json, options: []) {
            return data
        }
        fatalError("Could not deserialize JSON")
    }
}

extension Int: JSONElement {
    public var json: JSONElement {
        return self
    }
}

extension Double: JSONElement {
    public var json: JSONElement {
        return self
    }
}

extension Bool: JSONElement {
    public var json: JSONElement {
        return self
    }
}

extension String: JSONElement {
    public var json: JSONElement {
        return self
    }
}

extension Array: JSONElement {
    public var json: JSONElement {
        return flatMap { element -> JSONElement? in
            if let element = element as? JSONElement {
                return element.json
            }
            return nil
        }
    }
}

extension Dictionary: JSONElement {
    public var json: JSONElement {
        var jsonObject: [Key: JSONElement] = [:]
        for (key, value) in self {
            if let value = value as? JSONElement {
                jsonObject[key] = value.json
            }
        }
        return jsonObject
    }
}
