//
//  UpdateViewModelTests.swift
//  SparklyExampleTests
//
//  Created by Till Hainbach on 27.09.21.
//

import Combine
import CombineSchedulers
import SnapshotTesting
import SparklyClient
import SwiftUI
import XCTest

@testable import SparklyExample

class UpdateViewModelTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  func testUpdateViewModel() throws {

    var reply: UserUpdateState.Choice!

    let viewModel = UpdateViewModel(
      updateEventPublisher: Just(UpdaterClient.Event.updateCheck(.readyToRelaunch))
        .eraseToAnyPublisher(),
      cancelUpdate: noop,
      send: { reply = $0 }
    )

    viewModel.reply(.install)

    XCTAssertTrue(reply == .install)
  }

  func testUserInitiatedUpdateCheck() {
    let scheduler = DispatchQueue.test
    let client = UpdaterClient.mock(scheduler: scheduler)

    let viewModel = UpdateViewModel(
      updateEventPublisher: client.updaterEventPublisher,
      cancelUpdate: {},
      send: { _ in }
    )

    client.send(.checkForUpdates)
    let updateView = UpdateView(viewModel: viewModel)
    assertSnapshot(matching: updateView, as: .image)

    scheduler.advance(by: 1)
    assertSnapshot(matching: updateView, as: .image)

    client.send(.reply(.install))
    scheduler.advance(by: 1)
    assertSnapshot(matching: updateView, as: .image)

    scheduler.advance(by: 1)
    assertSnapshot(matching: updateView, as: .image)
    scheduler.advance(by: 1)
    assertSnapshot(matching: updateView, as: .image)
    scheduler.advance(by: 1)
    assertSnapshot(matching: updateView, as: .image)
    scheduler.advance(by: 1)
    assertSnapshot(matching: updateView, as: .image)
    scheduler.advance(by: 1)
    assertSnapshot(matching: updateView, as: .image)
  }

}

extension Snapshotting where Value: SwiftUI.View, Format == NSImage {
  static var image: Self {
    Snapshotting<NSView, NSImage>.image()
      .pullback { swiftUIView in
        let controller = NSHostingController(rootView: swiftUIView)
        let view = controller.view
        view.frame.size = .init(width: 500, height: 300)

        return view
      }
  }
}

extension UpdaterClient {
  static func mock(scheduler: TestSchedulerOf<DispatchQueue>) -> Self {
    let mockUpdater = PassthroughSubject<UpdaterClient.Action, Never>()
    let publisher = PassthroughSubject<UpdaterClient.Event, Never>()
    var cancellables: Set<AnyCancellable> = []

    var currentState: UpdateCheckState!
    var now = scheduler.now

    mockUpdater
      .sink { action in
        switch action {
        case .checkForUpdates:
          publisher.send(.canCheckForUpdates(false))
          currentState = .checking
          publisher.send(.updateCheck(currentState))
          scheduler.schedule(after: nextTime(&now)) {
            currentState = .found(
              .mock,
              state: .init(stage: .notDownloaded, userInitiated: true)
            )
            publisher.send(.updateCheck(currentState))
          }

        case .startUpdater:
          publisher.send(.canCheckForUpdates(true))

        case .setPermission, .setHTTPHeaders(_):
          XCTFail("Received unexpected action: \(action)")

        case .cancel:
          publisher.send(.dismissUpdateInstallation)
          publisher.send(.canCheckForUpdates(true))

        case .reply(let response):
          switch response {
          case .skip:
            publisher.send(.dismissUpdateInstallation)
            mockUpdater.send(.cancel)

          case .install:
            if case .found(_, _) = currentState {
              publisher.send(.updateCheck(.downloading(total: 4, completed: 0)))
              scheduler.schedule(after: nextTime(&now)) {
                publisher.send(.updateCheck(.downloading(total: 4, completed: 3)))
              }
              scheduler.schedule(after: nextTime(&now)) {
                publisher.send(.updateCheck(.downloading(total: 4, completed: 4)))
              }
              scheduler.schedule(after: nextTime(&now)) {
                publisher.send(.updateCheck(.extracting(completed: 0.0)))
              }
              scheduler.schedule(after: nextTime(&now)) {
                publisher.send(.updateCheck(.extracting(completed: 1.0)))
              }
              scheduler.schedule(after: nextTime(&now)) {
                publisher.send(.updateCheck(.installing))
              }
              scheduler.schedule(after: nextTime(&now)) {
                currentState = .readyToRelaunch
                publisher.send(.updateCheck(.readyToRelaunch))
              }
            }

            if case .readyToRelaunch = currentState {
              publisher.send(.dismissUpdateInstallation)
            }

          case .dismiss:
            publisher.send(.dismissUpdateInstallation)
            mockUpdater.send(.cancel)

          }
        }

      }
      .store(in: &cancellables)

    return .init(
      send: mockUpdater.send(_:),
      updaterEventPublisher: publisher.eraseToAnyPublisher(),
      cancellables: cancellables
    )
  }
}

func nextTime(_ now: inout DispatchQueue.SchedulerTimeType) -> DispatchQueue.SchedulerTimeType {
  now = now.advanced(by: 1)
  return now
}
