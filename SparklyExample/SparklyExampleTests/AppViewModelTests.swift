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

  func test_startsUpdateCheckSessionAndCanBeCancelled() throws {

    // Mocks
    // application mocks the boot of the application
    let application = PassthroughSubject<Notification, Never>()
    // updater and updaterHasStarted mock the updater and its state
    let updater = PassthroughSubject<UpdaterClient.Event, Never>()

    var updaterHasStarted = false
    var updateHTTPHeadersHaveBeenSet = false

    let appViewModel = AppViewModel(
      updaterClient: .init(
        send: { action in
          switch action {
          case .startUpdater:  // application did request to start the updater
            updaterHasStarted = true  // set mock to have been started
            // notify app that the updater is ready to check for updates
            updater.send(.canCheckForUpdates(true))

          case .checkForUpdates:
            updater.send(.canCheckForUpdates(false))
            updater.send(.updateCheck(.checking))

          case .cancel:
            updater.send(.dismissUpdateInstallation)
            updater.send(.canCheckForUpdates(true))

          case .setHTTPHeaders(_):
            updateHTTPHeadersHaveBeenSet = true

          default:
            // Fail test if any other action has been sent as a response to application launch
            XCTFail("The action \(action) should not have been sent!")

          }
        },
        updaterEventPublisher: updater.eraseToAnyPublisher(),
        cancellables: []
      ),
      applicationDidFinishLaunching: application.eraseToAnyPublisher()
    )

    // assert on fixtures
    XCTAssertFalse(updaterHasStarted)
    XCTAssertTrue(updateHTTPHeadersHaveBeenSet)
    XCTAssertFalse(appViewModel.canCheckForUpdates)

    // mock application launch
    application.send(Notification(name: NSApplication.didFinishLaunchingNotification))

    // assert mock updater has been started and headers have been set.
    XCTAssertTrue(updaterHasStarted)
    XCTAssertTrue(updateHTTPHeadersHaveBeenSet)

    // assert appViewModel can check for updates
    XCTAssertTrue(appViewModel.canCheckForUpdates)

    appViewModel.checkForUpdates()

    XCTAssertFalse(appViewModel.canCheckForUpdates)

    appViewModel.cancel()

    XCTAssertTrue(appViewModel.canCheckForUpdates)
  }

}
