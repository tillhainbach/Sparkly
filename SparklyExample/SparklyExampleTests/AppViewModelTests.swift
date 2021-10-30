//
//  AppViewModelTest.swift
//  SparklyExampleTests
//
//  Created by Till Hainbach on 09.06.21.
//
import Combine
import CombineSchedulers
import SparklyClient
import XCTest

@testable import SparklyExample

class AppViewModelTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []
  var testScheduler = DispatchQueue.test

  func testUserInitiatedUpdateCheck() throws {

    // Mocks
    // application mocks the boot of the application
    let application = PassthroughSubject<Notification, Never>()

    var activeWindow: Window?

    let appViewModel = AppViewModel(
      updaterClient: .mockUserInitiatedUpdateCheck(scheduler: testScheduler),
      applicationDidFinishLaunching: application.eraseToAnyPublisher(),
      windowManager: .init(
        openWindow: { activeWindow = Window(rawValue: $0) },
        closeWindow: {
          guard activeWindow == Window(rawValue: $0) && activeWindow != nil else {
            XCTFail()
            return
          }
          activeWindow = nil
        }
      )
    )

    // assert on fixtures
    XCTAssertFalse(appViewModel.canCheckForUpdates)

    // mock application launch
    application.send(Notification(name: NSApplication.didFinishLaunchingNotification))

    // assert appViewModel can check for updates
    XCTAssertTrue(appViewModel.canCheckForUpdates)

    appViewModel.checkForUpdates()
    XCTAssertFalse(appViewModel.canCheckForUpdates)
    XCTAssert(appViewModel.updateViewModel?.updateState == .checking)
    XCTAssert(activeWindow == .updateCheck)

    testScheduler.advance()
    XCTAssert(appViewModel.updateViewModel?.updateState == .found(.mock, state: .mock))
    XCTAssert(activeWindow == .updateCheck)

    appViewModel.updaterClient.send(.reply(.install))
    XCTAssert(appViewModel.updateViewModel?.updateState == .downloading(total: 4, completed: 0))
    XCTAssert(activeWindow == .updateCheck)

    testScheduler.advance()
    XCTAssert(appViewModel.updateViewModel?.updateState == .downloading(total: 4, completed: 3))
    XCTAssert(activeWindow == .updateCheck)

    testScheduler.advance(by: .seconds(1))
    XCTAssert(appViewModel.updateViewModel?.updateState == .downloading(total: 4, completed: 4))
    XCTAssert(activeWindow == .updateCheck)

    testScheduler.advance(by: .seconds(1))
    XCTAssert(appViewModel.updateViewModel?.updateState == .extracting(completed: 0.0))
    XCTAssert(activeWindow == .updateCheck)

    testScheduler.advance(by: .seconds(1))
    XCTAssert(appViewModel.updateViewModel?.updateState == .extracting(completed: 1.0))
    XCTAssert(activeWindow == .updateCheck)

    testScheduler.advance(by: .seconds(1))
    XCTAssert(appViewModel.updateViewModel?.updateState == .installing)
    XCTAssert(activeWindow == .updateCheck)

    testScheduler.advance(by: .seconds(1))
    XCTAssert(appViewModel.updateViewModel?.updateState == .readyToRelaunch)
    XCTAssert(activeWindow == .updateCheck)

    appViewModel.updaterClient.send(.reply(.install))
    XCTAssertNil(appViewModel.updateViewModel)
    XCTAssertNil(activeWindow)
  }

}
