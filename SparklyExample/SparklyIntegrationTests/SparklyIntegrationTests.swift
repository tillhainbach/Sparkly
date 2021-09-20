//
//  SparklyIntegrationTests.swift
//  SparklyIntegrationTests
//
//  Created by Till Hainbach on 10.06.21.
//
import Combine
import SUUpdaterClient
import SUUpdaterClientLive
import XCTest

class SparklyIntegrationTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  func test_StandardSparkle_DidStartOnApplicationLaunch() throws {
    let testBundle = Bundle(for: type(of: self))

    let client = SUUpdaterClient.standard(hostBundle: testBundle, applicationBundle: testBundle)

    var canCheckForUpdates = false

    client.updaterEventPublisher
      .sink { event in
        print(event)
        switch event {
        case .canCheckForUpdates(let newCanCheckForUpdates):
          canCheckForUpdates = newCanCheckForUpdates
          break
        default:
          XCTFail("Wrong event was sent")
        }
      }
      .store(in: &cancellables)

    XCTAssertFalse(canCheckForUpdates)

    // start updater
    client.send(.startUpdater)

    XCTAssertTrue(canCheckForUpdates)

    // client.send(.checkForUpdates)
  }

  func test_LiveSparkle_HappyPathFlow() throws {
    let testBundle = Bundle(for: type(of: self))

    let client = SUUpdaterClient.live(
      hostBundle: testBundle,
      applicationBundle: testBundle,
      developerSettings: .happyPath
    )

    var canCheckForUpdates: [Bool] = [false]
    var receivedEvents: [SUUpdaterClient.UpdaterEvents] = []

    client.updaterEventPublisher
      .sink { event in
        receivedEvents.append(event)
        switch event {
        case .canCheckForUpdates(let newCanCheckForUpdates):
          canCheckForUpdates.append(newCanCheckForUpdates)
          break
        case .updateCheckInitiated(cancellation: _):
          break

        case .didFindValidUpdate(update: _):
          break

        case .didFinishLoading(appcast: _):
          break

        case .updateFound(update: _, state: _, reply: _):
          break

        default:
          XCTFail("Wrong event was sent \(event)")
        }
      }
      .store(in: &cancellables)

    XCTAssertEqual(canCheckForUpdates, [false])

    // start updater
    client.send(.startUpdater)

    XCTAssertEqual(canCheckForUpdates, [false, true])
    XCTAssertEqual(receivedEvents, [.canCheckForUpdates(true)])

    client.send(.checkForUpdates)

    wait(for: [XCTestExpectation(description: "Some description")], timeout: 2)
  }

}

extension SUDeveloperSettings {
  static let happyPath: Self = .init(
    allowedSystemProfileKeys: { fatalError() },
    feedParameters: { _ in [] },
    feedURLString: { return "https://tillhainbach.github.io/Sparkly/happy-path-appcast.xml" },
    handleAppcast: { _ in fatalError() },
    retrieveDecryptionPassword: { fatalError() },
    retrieveBestValidUpdate: { _ in nil },  // let Sparkle handle picking the Update
    shouldAllowInstallerInteraction: { updateCheck in
      switch updateCheck {
      case .checkUpdates:
        return true
      case .checkUpdatesInBackground:
        return true
      case .checkUpdateInformation:
        return true
      }
    },
    updaterMayCheckForUpdates: { true },
    compareVersions: nil,
    updaterShouldPostponeRelaunchForUpdate: { _, _ in fatalError() },
    updaterWillInstallUpdateOnQuit: { _, _ in fatalError() },
    updaterShouldDownloadReleaseNotes: { true },
    updaterShouldPromptForPermissionToCheckForUpdates: { fatalError() },
    updaterShouldRelaunchApplication: { fatalError() }
  )
}
