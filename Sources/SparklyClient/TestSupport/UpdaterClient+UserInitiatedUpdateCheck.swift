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

    var currentState: UpdateCheckState!

    let interface = Interface()
    interface.handleAction = { action in
        switch action {
        case .checkForUpdates:
          interface.send(.canCheckForUpdates(false))
          currentState = .checking
          interface.send(.updateCheck(currentState))
          scheduler.schedule {
            currentState = .found(.mock, state: .mock)
            interface.send(.updateCheck(currentState))
          }

        case .startUpdater:
          interface.send(.canCheckForUpdates(true))

        case .setPermission:
          break

        case .setHTTPHeaders(_):
          break

        case .cancel:
          interface.send(.dismissUpdateInstallation)
          interface.send(.canCheckForUpdates(true))

        case .reply(let response):
          switch response {
          case .skip:
            interface.send(.dismissUpdateInstallation)
            interface.actionSubject.send(.cancel)

          case .install:
            if case .found(_, _) = currentState {
              interface.send(.updateCheck(.downloading(total: 4, completed: 0)))
              scheduler.scheduleSequentially(
                { interface.send(.updateCheck(.downloading(total: 4, completed: 3))) },
                { interface.send(.updateCheck(.downloading(total: 4, completed: 4))) },
                { interface.send(.updateCheck(.extracting(completed: 0.0))) },
                { interface.send(.updateCheck(.extracting(completed: 1.0))) },
                { interface.send(.updateCheck(.installing)) },
                {
                  currentState = .readyToRelaunch
                  interface.send(.updateCheck(.readyToRelaunch))
                }
              )
            }

            if case .readyToRelaunch = currentState {
              interface.send(.dismissUpdateInstallation)
            }

          case .dismiss:
            interface.send(.dismissUpdateInstallation)
            interface.actionSubject.send(.cancel)

          }
        }
      }

    return interface.client
  }
}

#endif
