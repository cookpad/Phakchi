import Foundation

struct TermMatcher: PactEncodable {
    let valueForGeneration: String
    let pattern: String

    var pactJSON: AnyObject {
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

struct LikeMatcher<T: PactEncodable>: PactEncodable {
    let value: T

    var pactJSON: AnyObject {
        return [
            "json_class": "Pact::SomethingLike",
            "contents": value.pactJSON,
        ]
    }
}

struct EachLikeMatcher<T: PactEncodable>: PactEncodable {
    let value: T
    let minimumCount: Int

    var pactJSON: AnyObject {
        return [
            "json_class": "Pact::ArrayLike",
            "contents": value.pactJSON,
            "min": minimumCount,
        ]
    }
}

public struct Matcher {
    public static func term(generate generate: String, matcher: String) -> PactEncodable {
        return TermMatcher(valueForGeneration: generate, pattern: matcher)
    }

    public static func like<T: PactEncodable>(value: T) -> PactEncodable {
        return LikeMatcher(value: value)
    }

    public static func eachLike<T: PactEncodable>(value: T, min: Int = 1) -> PactEncodable {
        return EachLikeMatcher(value: value, minimumCount: min)
    }
}
