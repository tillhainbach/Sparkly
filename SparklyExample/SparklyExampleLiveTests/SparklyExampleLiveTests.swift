//
//  SparklyExampleLiveTests.swift
//  SparklyExampleLiveTests
//
//  Created by Till Hainbach on 25.09.21.
//

import Combine
import SparklyClientLive
import SwiftUI
import XCTest

class SparklyExampleLiveTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  let client = UpdaterClient.live(hostBundle: .main, applicationBundle: .main)

  func test_LiveSparkle_HappyPathFlow() {

    var canCheckForUpdates: [Bool] = [false]
    var receivedEvents: [UpdaterClient.Event] = []

    let baseDescription = "Expect the update client to send "
    let expectUpdateCheckInitiated = expectation(
      description: baseDescription + "`updateCheckInitiated`"
    )
    let expectUpdateFound = expectation(description: baseDescription + "`updateFound`")
    let expectDownloadInFlight = expectation(description: baseDescription + "`downloadInFlight`")
    let expectExtracting = expectation(description: baseDescription + "`extracting`")
    let expectInstalling = expectation(description: baseDescription + "`installing`")
    let expectReadyToRelaunch = expectation(description: baseDescription + "`readyToRelaunch`")

    client.updaterEventPublisher
      .sink { event in
        receivedEvents.append(event)
        switch event {
        case .canCheckForUpdates(let newCanCheckForUpdates):
          canCheckForUpdates.append(newCanCheckForUpdates)
          break

        case .updateCheck(.checking):
          expectUpdateCheckInitiated.fulfill()

        case .updateCheck(.found(_, _)):
          self.client.send(.reply(.install))
          expectUpdateFound.fulfill()

        case .updateCheck(.downloading(let total, let completed)):
          if total == completed && total != 0 {
            expectDownloadInFlight.fulfill()
            XCTAssertEqual(4_474_762, total)
          }

        case .updateCheck(.extracting(let completed)):
          if completed == 1.0 {
            expectExtracting.fulfill()
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

    XCTAssertEqual(canCheckForUpdates, [false, true, false])
    XCTAssertEqual(
      receivedEvents,
      [.canCheckForUpdates(true), .canCheckForUpdates(false), .updateCheck(.checking)]
    )

    wait(for: [expectUpdateFound], timeout: 2)

    XCTAssertEqual(canCheckForUpdates, [false, true, false])

    if let event = receivedEvents.last, case .updateCheck(.found(_, _)) = event {
      XCTAssertTrue(true)
    } else {
      XCTAssertTrue(false)
    }

    wait(for: [expectDownloadInFlight], timeout: 2)

    if let event = receivedEvents.last,
      case .updateCheck(.downloading(let total, let completed)) = event
    {
      XCTAssertEqual(total, completed)
    } else {
      XCTAssertTrue(false)
    }

    wait(for: [expectExtracting, expectInstalling, expectReadyToRelaunch], timeout: 20.0)
  }

  func test_LiveSparkle_canCancelUpdateCheck() {

    let expectDismissUpdateInstallation = expectation(
      description: "Expect `dismissUpdateInstallation to be send"
    )

    client.updaterEventPublisher
      .sink { event in
        switch event {
        case .failure(_):
          XCTFail("Should not fail!")

        case .canCheckForUpdates(_), .showUpdateReleaseNotes(_), .permissionRequest:
          break

        case .dismissUpdateInstallation:
          expectDismissUpdateInstallation.fulfill()

        case .terminationSignal:
          break

        case .updateCheck(let state):
          if state == .checking {
            self.client.send(.cancel)
          }

        }
      }
      .store(in: &cancellables)

    client.send(.startUpdater)
    client.send(.checkForUpdates)
    wait(for: [expectDismissUpdateInstallation], timeout: 3.0)

  }

}
