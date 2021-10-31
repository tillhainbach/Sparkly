# Sparkly 💫

[![CI](https://github.com/tillhainbach/Sparkly/actions/workflows/ci.yaml/badge.svg)](https://github.com/tillhainbach/Sparkly/actions/workflows/ci.yaml)

Sparkly is a light-weight, combine-based wrapper around the [Sparkle](https://www.sparkle-project.org)
auto-update framework. It's main goal is to abstract away the complexity of the framework, make it easier to use
with SwiftUI and to increase the ability for unit-testing (e.g. ease of mocking sparkle).

## Usage

Sparkly provides a simple interface struct called `UpdaterClient`. This client is responsible for routing actions
to and events from Sparkle. All actions and events are modelled as enums with associated values.
ViewModels, or your preferred flavour, can send actions to sparkle using the `UpdaterClient.send(_:)`
closure and subscribe to updater events on the `UpdaterClient.publisher`.

> NOTE: `Sparkly` is currently under development. Not all actions and events are implemented
> and the interface may change. However, all of the `SPUUserDriver` methods
> are wrapped in events and it is possible to implement a ui-based
> update check (see [SparklyExample](./SparklyExample))

> NOTE: `Sparkly` uses Sparkle 2 which is currently still in beta!

## Example

See the example app in [SparklyExample](./SparklyExample).
It's a SwiftUI-based mac app that uses Sparkly to interact with Sparkle. Also have a look at
the [unit tests](./SparklyExample/SparklyExampleTests) which show case how easy you can mock
Sparkl(y|e) and get a consistent deterministic behaviour during testing and development without
having to mess around with XCUITests or manually setting user defaults.

## Installation

Use SwiftPackageManager. Add the following to your dependencies.

```swift
dependencies: [
  // Dependencies declare other packages that this package depends on.
  .package(url: "https://github.com/tillhainbach/Sparkly.git", .branch("main"))
],
```

Sparkly has a dependency on Sparkle version 2.0.0-beta.4 which is the first version that
bundles the XPC-services inside the Sparkle framework. For enabling these XPC-services see
[additional setup](https://sparkle-project.org/documentation/sandboxing/)

## Current implementation state

- ✅ SPUUserDriver: all methods emit events.
- ⚠️ SPUUpdater

  - ✅ startUpdater -> `UpdaterClient.Action.startUpdater`
  - ✅ checkForUpdates -> `UpdaterClient.Action.checkForUpdates`
  - ✅ canCheckForUpdates -> `UpdaterClient.Event.canCheckForUpdates(_:)`
  - ✅ httpHeaders -> `UpdaterClient.Action.setHttpHeaders(_:)`
  - ❌ checkForUpdatesInBackground
  - ❌ checkForUpdateInformation
  - ❌ updateCheckInterval
  - ❌ resetUpdateCycle

- ❌ SPUUpdaterDelegate: You may pass a delegate to `UpdaterClient.live(hostBundle:applicationBundle:delegate:)`

I most likely will not wrap these methods/properties:

- ❌ SPUUpdater
  - ❌ automaticallyDownloadsUpdates -> use `UserDefaults`
  - ❌ automaticallyChecksForUpdates -> use `UserDefaults`
  - ❌ sendsSystemProfile -> use `UserDefaults`
  - ❌ lastUpdateCheckDate -> use `UserDefaults`
  - ❌ feedURL -> use `UserDefaults`, `Info.plist` or `-[SPUUpdaterDelegate feedURLStringForUpdater:]`
  - ❌ setFeedURL -> this method is discouraged! Use delegate method!

## License

Sparkly is licensed under the MIT license. See [LICENSE](./LICENSE) for further details.
