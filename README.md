# Phakchi

[![Build Status](https://travis-ci.org/cookpad/Phakchi.svg?branch=master)](https://travis-ci.org/cookpad/Phakchi)
[![Language](https://img.shields.io/badge/language-Swift%202.2%7C2.3-orange.svg)](https://swift.org)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) 

Pact consumer client library in Swift

`Phakchi` provides a DSL in Swift for creating pact files.

See the [Pact](https://github.com/realestate-com-au/pact) README for detail.

## Installation

### Carthage

Add the following line to your `Cartfile.private`.

```
github "cookpad/Phakchi"
```

For information on how to use Carthage, please refer to the official Carthage documentation.

### CocoaPods

Add this statements to your `Podfile`.

```ruby
use_framework!
target 'YourApplicationTests' do
    pod 'Phakchi'
end
```

For information on how to use CocoaPods, please refer to the official CocoaPods documentation.

## Usage

### Setup

Before you write your Pact definitions, you have to configure the mock server.

First, add `Gemfile` on project root

```ruby
source "https://rubygems.org"

gem "pact-mock_service"
```

Next, edit your test scheme and add the following to the `Pre-actions` section. (You might have to make changes to the PATH setting.)

```sh
PATH=$HOME/.rbenv/shims:$PATH
BUNDLE_GEMFILE="$SRCROOT"/Gemfile bundle exec "$SRCROOT"/Carthage/Checkouts/Phakchi/scripts/start_control_server.sh
```

And set `Provide build settings from` to your test target.

In the same way, you should run the `stop_control_server` script post testing.

```sh
PATH=$HOME/.rbenv/shims:$PATH
BUNDLE_GEMFILE="$SRCROOT"/Gemfile bundle exec "$SRCROOT"/Carthage/Checkouts/Phakchi/scripts/stop_control_server.sh
```

### Describe contracts using XCTest

First, Phakchi connects to the control server.
The control server is able to launch mock servers.
Launched mock servers are represented as instances of `Session`.

Then you need to describe the interactions you are going to have with the mock server.
Once the interactions are described, you then send a request to the mock server, check that the response is correct, and if your validation passes, a Pact file will be generated.

Below you will find an example for writing contracts for an API to fetch recipes with XCTest.
The request to the API is done by `RecipeClient`'s `fetchRecipes(keyword)` method.

```swift
import XCTest
import Phakchi

class RecipeClientPact: XCTestCase {
    let controlServer: ControlServer = ControlServer.defaultServer
    var session: Session!

    override func setUp() {
        super.setUp()

        // Launch a mock server
        let expectation = expectationWithDescription("session was started")
        controlServer.startSession(withConsumerName: "consumer", providerName: "provider") { session in
            self.session = session
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testFetchRecipes() {
        XCTAssertEqual(controlServer.sessions.count, 1)
        let expectation = expectationWithDescription("contract is valid")
        session.given("There are 2 recipes")
            .uponReceiving("a request for recipe")
            .willRespondWith(status: 200, body: Matcher.eachLike(["recipes": ["name": "Tuna", "description": "Delicious"]], min: 10))

        session.run(completionBlock: { isValid in
            // This block will be executed after completion
            XCTAssertTrue(isValid)
            expectation.fulfill()
        }, executionBlock: { completeTest in
            RecipeClient.fetchRecipes(from: ”Sushi") { (recipes, error) in
                // Expected to return 10 Sushi objects
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

#### Note

If you get the error below when trying to launch mock servers, you should set `Allow Arbitrary Loads` to `YES` in the `Info.plist` of your application target.

```
App Transport Security has blocked a cleartext HTTP (http://) resource load since it is insecure. Temporary exceptions can be configured via your app's Info.plist file.
```

### Matcher

As described in the above example code, you can use helpers to match using regular expressions.

- term
- like
- eachLike (Supported in [pact-specification V2](https://github.com/realestate-com-au/pact/wiki/v2-flexible-matching) only)

You can have a look at [this documentation](https://github.com/realestate-com-au/pact/wiki/Regular-expressions-and-type-matching-with-Pact) for more details.

### Requirements

- iOS 8+
- Swift 2.2/2.3
- Xcode 7+

