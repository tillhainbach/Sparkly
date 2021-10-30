//
//  TestSupport.swift
//  SparklyExampleTests
//
//  Created by Till Hainbach on 30.10.21.
//
import Combine
import CombineSchedulers
import SnapshotTesting
import SparklyClient
import SwiftUI
import XCTest

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

extension UpdateViewModel {
  func assert(
    on state: UpdateCheckState,
    afterActionCalled asserting: () -> Bool,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    self.updateState = state
    switch self.route {
    case .status(let viewState):
      viewState.action()

    case .found(let foundUpdateViewModel):
      foundUpdateViewModel.reply(.dismiss)
      foundUpdateViewModel.reply(.install)
      foundUpdateViewModel.reply(.skip)
    }
    XCTAssert(asserting(), file: file, line: line)

  }
}

extension UpdaterClient {
  static func mockUserInitiatedUpdateCheck(scheduler: TestSchedulerOf<DispatchQueue>) -> Self {
    let mockUpdater = PassthroughSubject<UpdaterClient.Action, Never>()
    let publisher = PassthroughSubject<UpdaterClient.Event, Never>()
    var cancellables: Set<AnyCancellable> = []

    var currentState: UpdateCheckState!

    mockUpdater
      .sink { action in
        switch action {
        case .checkForUpdates:
          publisher.send(.canCheckForUpdates(false))
          currentState = .checking
          publisher.send(.updateCheck(currentState))
          scheduler.schedule {
            currentState = .found(.mock, state: .mock)
            publisher.send(.updateCheck(currentState))
          }

        case .startUpdater:
          publisher.send(.canCheckForUpdates(true))

        case .setPermission:
          XCTFail("Received unexpected action: \(action)")

        case .setHTTPHeaders(_):
          break

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
              scheduler.scheduleSequentially(
                { publisher.send(.updateCheck(.downloading(total: 4, completed: 3))) },
                { publisher.send(.updateCheck(.downloading(total: 4, completed: 4))) },
                { publisher.send(.updateCheck(.extracting(completed: 0.0))) },
                { publisher.send(.updateCheck(.extracting(completed: 1.0))) },
                { publisher.send(.updateCheck(.installing)) },
                {
                  currentState = .readyToRelaunch
                  publisher.send(.updateCheck(.readyToRelaunch))
                }
              )
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

extension TestScheduler {
  public func scheduleSequentially(_ actions: () -> Void...) {
    actions.enumerated()
      .forEach { index, action in
        self.schedule(after: self.now.advanced(by: .seconds(index)), action)
      }
  }
}
