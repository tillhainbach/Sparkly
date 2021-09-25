//
//  SparklyIntegrationTests.swift
//  SparklyIntegrationTests
//
//  Created by Till Hainbach on 10.06.21.
//
import Combine
import SparklyClientLive
import XCTest
@testable import SparklyExample

class SparklyIntegrationTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  func test_StandardSparkle_DidStartOnApplicationLaunch() throws {
    let testBundle = Bundle(for: type(of: self))

    let client = UpdaterClient.standard(hostBundle: testBundle, applicationBundle: testBundle)

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

    client.send(.checkForUpdates)

    XCTAssertFalse(canCheckForUpdates)
  }

  func test_LiveSparkle_HappyPathFlow() throws {
    let testBundle = Bundle(for: type(of: self))

    let client = UpdaterClient.live(
      hostBundle: testBundle,
      applicationBundle: testBundle
    )

    var canCheckForUpdates: [Bool] = [false]
    var receivedEvents: [UpdaterClient.Event] = []

    let expectUpdateCheckInitiated = expectation(description: "Update Check was initiated")
    let expectUpdateFound = expectation(description: "Update was found")
    let expectDownloadInFlight = expectation(description: "Download is in flight.")
    let expectExtracting = expectation(description: "Extract Update")
    let expectInstalling = expectation(description: "Installing Update")

    client.updaterEventPublisher
      .sink { event in
        receivedEvents.append(event)
        switch event {
        case .canCheckForUpdates(let newCanCheckForUpdates):
          canCheckForUpdates.append(newCanCheckForUpdates)
          break

        case .updateCheckInitiated:
          expectUpdateCheckInitiated.fulfill()

        case .updateFound(_, _):
          client.send(.reply(.install))
          expectUpdateFound.fulfill()

        case .downloadInFlight(let total, let completed):
          if total == completed && total != 0 {
            expectDownloadInFlight.fulfill()
            XCTAssertEqual(1_851_383, total)
          }

        case .extractingUpdate(let completed):
          if completed == 1.0 {
            expectExtracting.fulfill()
          }

        case .installing:
          expectInstalling.fulfill()

        default:
          XCTFail("Wrong event was sent \(event)")
        }
      }
      .store(in: &cancellables)

    XCTAssertEqual(canCheckForUpdates, [false])

    // start updater
    client.send(.setHTTPHeaders(["Accept": "application/octet-stream"]))
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
      [.canCheckForUpdates(true), .canCheckForUpdates(false), .updateCheckInitiated]
    )

    wait(for: [expectUpdateFound], timeout: 0.5)

    XCTAssertEqual(canCheckForUpdates, [false, true, false])

    if let event = receivedEvents.last, case UpdaterClient.Event.updateFound(_, _) = event {
      XCTAssertTrue(true)
    } else {
      XCTAssertTrue(false)
    }

    wait(for: [expectDownloadInFlight], timeout: 2)

    if let event = receivedEvents.last, case .downloadInFlight(let total, let completed) = event {
      XCTAssertEqual(total, completed)
    } else {
      XCTAssertTrue(false)
    }

    wait(for: [expectExtracting, expectInstalling], timeout: 3.0)
  }

}
