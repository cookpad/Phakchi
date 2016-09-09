# Phakchi

Pact consumer client library in Swift

`Phakchi` provides a Swift version DSL for creating pact file.

See [Pact](https://github.com/realestate-com-au/pact) README for detail.

## Installation

### Carthage

Add this line to your `Cartfile.private` and follow Carthage instruction.

```
git 'cookpad/Phakchi'
```

### CocoaPods

Add this statements to your `Podfile`.

```ruby
use_framework!
target 'YourApplicationTests' do
    pod 'Phakchi'
end
```

## Usage

### Setup

Before you write your Pact definitions, you have to configure to launch the mock server.

Edit your test scheme and write such a snippet in `Pre-actions` section.

```sh
PATH=$HOME/.rbenv/shims:$PATH
"$SRCROOT"/Carthage/Checkouts/Phakchi/scripts/start_control_server.sh
```

In the same way, you should run `stop_control_server` script post testing.

```sh
PATH=$HOME/.rbenv/shims:$PATH
"$SRCROOT"/Carthage/Checkouts/Phakchi/scripts/stop_control_server.sh
```

### Describe contracts on XCTest

First, Phakchi connects to the control server.

Control server can launch each mock servers.

Launched mock servers are replesented as `Session` instance.

You have to define interactions to the mock server.
After this, you send request to mock server then it will be verified.
If validations are passed, Pact files will be generated.

If you would like to write contracts between the API to fetch recipes.  
Your `RecipeClient` requests to the API in `fetchRecipes(keyword)` method.
Below is the sample implementation on XCTest.

```swift
class RecipeClientPact: XCTestCase {
    let controlServer: ControlServer = ControlServer()
    var session: Session!

    override func setUp() {
        super.setUp()

        // Launch mock server
        let exp = expectationWithDescription("session was started")
        controlServer.startSession(withConsumerName: "consumer", providerName: "provider") { (session) in
            self.session = session
            exp.fulfill()
        }
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testFetchRecipes() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectation = expectationWithDescription("contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .with(method: .GET, path: "/v1/recipes", query: ["keyword": "Sushi"])
            .willRespondWith(status: 200, body: Matcher.eachLike(["recipes": ["name": "Tuna", "description", "Delicious"], min: 10]))

        session.run(completionBlock: { isValid in
            // This block will be executed after completion
            XCTAssertTrue(isValid)
            expectation.fulfill()
        },
                    executionBlock: { completeTest in
            RecipeClient.fetchRecipes(from: ”Sushi") { (recipes, error) in
                // Expect to return 10 Sushi objects
                XCTAssertEqual(recipes.count, 10)
                XCTAssertNil(error)
                XCTAssertEqual(recipes[0].name, "Tuna")
                XCTAssertEqual(recipes[0].description, "Delicious")
                completeTest() // Tell completion to the mock server
            }
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
```

### Matcher

As described in above example code, You can use helpers to match with Regular Expressions.

- term
- like
- eachLike (Supported in [pact-specification V2](https://github.com/realestate-com-au/pact/wiki/v2-flexible-matching) only)

See detail this [documentation](https://github.com/realestate-com-au/pact/wiki/Regular-expressions-and-type-matching-with-Pact) for detail

### Requirements

- iOS 8+
- Swift 2.2/2.3
- Xcode 7+

