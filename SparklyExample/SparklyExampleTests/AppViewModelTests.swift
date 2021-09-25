//
//  AppViewModelTest.swift
//  SparklyExampleTests
//
//  Created by Till Hainbach on 09.06.21.
//
import Combine
import SparklyClient
import XCTest

@testable import SparklyExample

class AppViewModelTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  func testAppDidStartUpdaterOnLaunch() throws {

    // Mocks
    // application mocks the boot of the application
    let application = PassthroughSubject<Notification, Never>()
    // updater and updaterHasStarted mock the updater and its state
    let updater = PassthroughSubject<UpdaterClient.Event, Never>()
    var updaterHasStarted = false

    let appViewModel = AppViewModel(
      updaterClient: .init(
        send: { action in
          switch action {
          case .startUpdater:  // application did request to start the updater
            updaterHasStarted = true  // set mock to have been started
            // notify app that the updater is ready to check for updates
            updater.send(.canCheckForUpdates(true))
            break

          case .setHTTPHeaders(_):
            break

          default:
            // Fail test if any other action has been sent as a response to application launch
            XCTFail("The action \(action) should not have been sent!")
            break
          }
        },
        updaterEventPublisher: updater.eraseToAnyPublisher(),
        cancellables: []
      ),
      applicationDidFinishLaunching: application.eraseToAnyPublisher()
    )

    // assert on fixtures
    XCTAssertFalse(updaterHasStarted)
    XCTAssertFalse(appViewModel.canCheckForUpdates)

    // mock application launch
    application.send(Notification(name: NSApplication.didFinishLaunchingNotification))

    // assert mock updater has been started
    XCTAssertTrue(updaterHasStarted)

    // assert appViewModel can check for updates
    XCTAssertTrue(appViewModel.canCheckForUpdates)

  }

  func test_LiveSparkle_HappyPathFlow() throws {

    let client = UpdaterClient.live(
      hostBundle: .main,
      applicationBundle: .main
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
