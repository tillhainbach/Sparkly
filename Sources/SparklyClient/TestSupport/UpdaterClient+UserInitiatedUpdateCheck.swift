//
//  File.swift
//  
//
//  Created by Till Hainbach on 31.10.21.
//

#if DEBUG

import Combine
import CombineSchedulers
import Foundation

extension UpdaterClient {
  public static func mockUserInitiatedUpdateCheck(scheduler: TestSchedulerOf<DispatchQueue>) -> Self {
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
          break

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
      updaterEventPublisher: publisher
        .handleEvents(receiveCancel: { cancellables.removeAll() })
        .eraseToAnyPublisher()
    )
  }
}

#endif
