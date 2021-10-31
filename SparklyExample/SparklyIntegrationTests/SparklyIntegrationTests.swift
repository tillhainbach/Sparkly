//
//  SparklyIntegrationTests.swift
//  SparklyIntegrationTests
//
//  Created by Till Hainbach on 31.10.21.
//

import Combine
import Sparkly
import SwiftUI
import XCTest

class SparklyIntegrationTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  let client = UpdaterClient.live(hostBundle: .main, applicationBundle: .main)

  func test_LiveSparkle_HappyPathFlow() {
    let expectedTotal: Double = 3_525_612

    var canCheckForUpdates: [Bool] = [false]
    var receivedEvents: [UpdaterClient.Event] = []

    let baseDescription = "Expect the update client to send "
    let expectUpdateCheckInitiated = expectation(
      description: baseDescription + "`updateCheckInitiated`"
    )
    let expectUpdateFound = expectation(description: baseDescription + "`updateFound`")
    let expectFocusUpdate = expectation(description: baseDescription + "`focusUpdate`")
    let expectDownloadStarted = expectation(description: baseDescription + "`.downloading(0, 0)`")
    let expectDownloadInFlight = expectation(
      description: baseDescription + "`.downloading(\(expectedTotal), 0)`"
    )
    let expectDownloadFinished = expectation(
      description: baseDescription + "`.downloading(\(expectedTotal), \(expectedTotal))`"
    )
    let expectExtractingFinished = expectation(description: baseDescription + "`extracting`")
    let expectInstalling = expectation(description: baseDescription + "`installing`")
    let expectReadyToRelaunch = expectation(description: baseDescription + "`readyToRelaunch`")

    client.updaterEventPublisher
      .sink { event in
        receivedEvents.append(event)
        switch event {
        case .canCheckForUpdates(let newCanCheckForUpdates):
          canCheckForUpdates.append(newCanCheckForUpdates)
          break

        case .focusUpdate:
          expectFocusUpdate.fulfill()

        case .updateCheck(.checking):
          expectUpdateCheckInitiated.fulfill()

        case .updateCheck(.found(_, _)):
          expectUpdateFound.fulfill()

        case .updateCheck(.downloading(let total, let completed)):
          switch (total, completed) {
          case (0.0, 0.0):
            expectDownloadStarted.fulfill()

          case (expectedTotal, 0.0):
            expectDownloadInFlight.fulfill()

          case (expectedTotal, expectedTotal):
            expectDownloadFinished.fulfill()

          default:
            break
          }

        case .updateCheck(.extracting(let completed)):
          if completed == 1.0 {
            expectExtractingFinished.fulfill()
          }

        case .updateCheck(.installing):
          expectInstalling.fulfill()

        case .updateCheck(.readyToRelaunch):
          expectReadyToRelaunch.fulfill()

        default:
          XCTFail("Wrong event was sent \(event)")
        }
      }
      .store(in: &cancellables)

    XCTAssertEqual(canCheckForUpdates, [false])

    client.send(.startUpdater)
    XCTAssertEqual(canCheckForUpdates, [false, true])
    XCTAssertEqual(receivedEvents, [.canCheckForUpdates(true)])

    client.send(.checkForUpdates)

    XCTAssertEqual(canCheckForUpdates, [false, true, false])
    XCTAssertEqual(receivedEvents, [.canCheckForUpdates(true), .canCheckForUpdates(false)])

    wait(for: [expectUpdateCheckInitiated], timeout: 0.1)

    XCTAssertEqual(canCheckForUpdates, [false, true, false, true])
    XCTAssertEqual(
      receivedEvents,
      [
        .canCheckForUpdates(true),
        .canCheckForUpdates(false),
        .canCheckForUpdates(true),
        .updateCheck(.checking),
      ]
    )

    wait(for: [expectUpdateFound], timeout: 2)
    XCTAssertEqual(canCheckForUpdates, [false, true, false, true])

    client.send(.checkForUpdates)
    wait(for: [expectFocusUpdate], timeout: 0.5)

    client.send(.reply(.install))

    wait(for: [expectDownloadStarted, expectDownloadInFlight, expectDownloadFinished], timeout: 2)

    wait(for: [expectExtractingFinished, expectInstalling, expectReadyToRelaunch], timeout: 20.0)
  }

  func test_LiveSparkle_canCancelUpdateCheck() {

    let expectDismissUpdateInstallation = expectation(
      description: "Expect `dismissUpdateInstallation` to be send"
    )

    client.updaterEventPublisher
      .sink { event in
        switch event {
        case .canCheckForUpdates(_):
          break

        case .dismissUpdateInstallation:
          expectDismissUpdateInstallation.fulfill()

        case .failure(_):
          XCTFail("Should not fail!")

        case .focusUpdate:
          XCTFail("Should not send `.focusUpdate`!")

        case .permissionRequest:
          XCTFail("Should not send `.permissionRequest`!")

        case .showUpdateReleaseNotes(_):
          XCTFail("Should not send `.showUpdateReleaseNotes(_)`!")

        case .terminationSignal:
          XCTFail("Should not send `.terminationSignal`!")

        case .updateCheck(let state):
          if state == .checking {
            self.client.send(.cancel)
          } else {
            XCTFail("Should not send other states!")
          }

        case .updateInstalledAndRelaunched:
          XCTFail("Should not send `.updateInstalledAndRelaunched`!")
        }
      }
      .store(in: &cancellables)

    client.send(.startUpdater)
    client.send(.checkForUpdates)
    wait(for: [expectDismissUpdateInstallation], timeout: 3.0)

  }

}
