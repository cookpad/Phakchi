import Foundation

typealias JSONObject = [String: AnyObject]

public protocol PactEncodable {
    var pactJSON: AnyObject { get }
}

extension PactEncodable {
    var JSONData: NSData {
        if let data = try? NSJSONSerialization.dataWithJSONObject(pactJSON, options: []) {
            return data
        }
        fatalError("Could not deserialize JSON")
    }
}

extension Int: PactEncodable {
    public var pactJSON: AnyObject {
        return self
    }
}

extension Double: PactEncodable {
    public var pactJSON: AnyObject {
        return self
    }
}

extension Bool: PactEncodable {
    public var pactJSON: AnyObject {
        return self
    }
}

extension String: PactEncodable {
    public var pactJSON: AnyObject {
        return self
    }
}

extension Array where Element: AnyObject {
    public var pactJSON: AnyObject {
        return self
    }
}

extension Dictionary: PactEncodable {
    public var pactJSON: AnyObject {
        return self as! AnyObject
    }
}
