# Sparkly 💫

[![Lint](https://github.com/tillhainbach/Sparkly/actions/workflows/lint.yaml/badge.svg?branch=main)](https://github.com/tillhainbach/Sparkly/actions/workflows/lint.yaml)
[![Lint Commit Messages](https://github.com/tillhainbach/Sparkly/actions/workflows/commitlint.yaml/badge.svg)](https://github.com/tillhainbach/Sparkly/actions/workflows/commitlint.yaml)

Sparkly is a light-weight, combine-based wrapper around the [Sparkle](www.sparkle-project.org)
auto-update framework. It's main goal is to abstract away the complexity of the framework, make it easier to use
with SwiftUI and to increase the ability for unit-testing (e.g. ease of mocking sparkle).

## Usage

Sparkly provides a simple interface struct called `SUUpdaterClient`. This client is responsible for routing actions
to and events from Sparkle. All actions and events are modelled as enums with associated values.
ViewModels, or your preferred flavour, can send actions to sparkle using the `SUUpdaterClient.send(_:)`
closure and subscript to updater events on the `SUUpdaterClient.updateEventPublisher` publisher.

> NOTE: Sparky is currently under development. Not all actions and event are implemented
> and the interface may change.

## Example

see the example app in [SparklyExample](./SparklyExample). It's a SwiftUI-based mac app that uses Sparkly to interact with Sparkle

## Installation

Use SwiftPackageManager. Add the following to your dependecies

```swift
dependencies: [
  // Dependencies declare other packages that this package depends on.
  .package(url: "https://github.com/tillhainbach/Sparkly.git", from: "0.1.0)
],
```

## License

Sparkly is licensed under the MIT license. See [LICENSE](./LICENSE) for further details.
