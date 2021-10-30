//
//  File.swift
//
//
//  Created by Till Hainbach on 03.06.21.
//
#if DEBUG

import Combine
import Dispatch
import CombineSchedulers

extension UpdaterClient {
  /// A mock updater that sends a permission request after a one second delay.
  public static var requestForPermission: Self {
    let interface = Interface()
    interface.handleAction = { action in
        switch action {
        case .setHTTPHeaders(_):
          break
          
        case .checkForUpdates:
          break

        case .startUpdater:
          interface.send(.canCheckForUpdates(true))
          DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(1))) {
            interface.send(.permissionRequest)
          }

        case .cancel:
          break

        case .reply:
          break

        case .setPermission:
          break
        }

      }

    return interface.client
  }
}

extension UpdaterClient {

  /// A mock updater client that checks for an update for 5 seconds and then fails.
  public static var failsToCheckForUpdates: Self {
    let interface = Interface()
    var currentWork: DispatchWorkItem?

    interface.handleAction = { action in
        switch action {
        case .setHTTPHeaders(let newHTTPHeaders):
          print("Updating headers for \(newHTTPHeaders)")

        case .checkForUpdates:
          interface.send(.canCheckForUpdates(false))
          interface.send(.updateCheck(.checking))
          currentWork = DispatchWorkItem {
            interface.send(.failure(.init(domain: "UpdaterClient", code: 4000, userInfo: ["Info": "Failing Updater!"])))
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: currentWork!)

        case .startUpdater:
          interface.send(.canCheckForUpdates(true))

        case .cancel:
          interface.send(.dismissUpdateInstallation)
          interface.send(.canCheckForUpdates(true))
          currentWork?.cancel()

        case .reply:
          break

        case .setPermission:
          break
        }

      }

    return interface.client
  }

}

#endif
