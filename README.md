# Sparkly 💫

[![Lint](https://github.com/tillhainbach/Sparkly/actions/workflows/lint.yaml/badge.svg?branch=main)](https://github.com/tillhainbach/Sparkly/actions/workflows/lint.yaml)
[![Lint Commit Messages](https://github.com/tillhainbach/Sparkly/actions/workflows/commitlint.yaml/badge.svg)](https://github.com/tillhainbach/Sparkly/actions/workflows/commitlint.yaml)

Sparkly is a light-weight, combine-based wrapper around the [Sparkle](https://www.sparkle-project.org)
auto-update framework. It's main goal is to abstract away the complexity of the framework, make it easier to use
with SwiftUI and to increase the ability for unit-testing (e.g. ease of mocking sparkle).

## Usage

Sparkly provides a simple interface struct called `UpdaterClient`. This client is responsible for routing actions
to and events from Sparkle. All actions and events are modelled as enums with associated values.
ViewModels, or your preferred flavour, can send actions to sparkle using the `UpdaterClient.send(_:)`
closure and subscribe to updater events on the `UpdaterClient.publisher`.

> NOTE: `Sparkly` is currently under development. Not all actions and events are implemented
> and the interface may change. However, most of the `SPUUserDriver` methods
> are wrapped in events and it is possible to implement a ui-based/
> update check (see [SparklyExample](./SparklyExample))

> NOTE: `Sparkly` uses Sparkle 2 which is currently still in beta!

## Example

see the example app in [SparklyExample](./SparklyExample). It's a SwiftUI-based mac app that uses Sparkly to interact with Sparkle.

## Installation

Use SwiftPackageManager. Add the following to your dependencies.

> NOTE: This project has a dependency to Sparkle which are not yet
> fully supporting SPM on there 2.x-branch. Sparkle's XPC-services are
> not shipped with the SPM package so you have to download them yourself.

```swift
dependencies: [
  // Dependencies declare other packages that this package depends on.
  .package(url: "https://github.com/tillhainbach/Sparkly.git", .branch("main"))
],
```

## License

Sparkly is licensed under the MIT license. See [LICENSE](./LICENSE) for further details.
