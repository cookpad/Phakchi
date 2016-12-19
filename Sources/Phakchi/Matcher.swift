import Foundation

struct TermMatcher: PactEncodable {
    let valueForGeneration: String
    let pattern: String

    var pactJSON: JSONElement {
        return [
            "json_class": "Pact::Term",
            "data": [
                "generate": valueForGeneration,
                "matcher": [
                    "json_class": "Regexp",
                    "o": 0,
                    "s": pattern,
                ]
            ]
        ]
    }
}

struct LikeMatcher<T: JSONElement>: PactEncodable {
    let value: T

    var pactJSON: JSONElement {
        return [
            "json_class": "Pact::SomethingLike",
            "contents": value.json,
        ]
    }
}

struct EachLikeMatcher<T: JSONElement>: PactEncodable {
    let value: T
    let minimumCount: Int

    var pactJSON: JSONElement {
        return [
            "json_class": "Pact::ArrayLike",
            "contents": value.json,
            "min": minimumCount,
        ]
    }
}

public struct Matcher {
    public static func term(generate: String, matcher: String) -> PactEncodable {
        return TermMatcher(valueForGeneration: generate, pattern: matcher)
    }

    public static func like<T: JSONElement>(_ value: T) -> PactEncodable {
        return LikeMatcher(value: value)
    }

    public static func eachLike<T: JSONElement>(_ value: T, min: Int = 1) -> PactEncodable {
        return EachLikeMatcher(value: value, minimumCount: min)
    }
}
