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
  /// A convenience mock updater for ``UpdaterClient/requestForPermission(scheduler:)`` which schedules
  /// events on `DispatchQueue.main`.
  public static let requestForPermission = Self.requestForPermission(
    scheduler: DispatchQueue.main.eraseToAnyScheduler()
  )

  /// A mock updater that sends a permission request after a one second delay.
  ///
  /// This mock updater response with `canCheckForUpdates(true)` on receiving
  /// ``UpdaterClient/Action/startUpdater`` and sends a ``UpdaterClient/Event/permissionRequest``
  ///  after a delay of one second. All other ``UpdaterClient/Action``s will be ignored.
  ///
  /// - Parameter scheduler: The scheduler for scheduling the preconfigure events of this mock updater.
  /// - Returns: A mock Instance of an updater client.
  public static func requestForPermission(scheduler: AnySchedulerOf<DispatchQueue>) -> Self {
    let interface = Interface()
    interface.handleAction = { action in
      switch action {
      case .setHTTPHeaders(_):
        break

      case .checkForUpdates:
        break

      case .startUpdater:
        interface.send(.canCheckForUpdates(true))
        scheduler.schedule(after: scheduler.now.advanced(by: .seconds(1))) {
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
  /// A convenience mock updater for ``UpdaterClient/failsToCheckForUpdates(scheduler:)`` which schedules
  /// events on `DispatchQueue.main`.
  public static let failsToCheckForUpdates = Self.failsToCheckForUpdates(
    scheduler: DispatchQueue.main.eraseToAnyScheduler()
  )

  /// A mock updater client that checks for an update for 3 seconds and then fails.
  ///
  /// - Parameter scheduler: The scheduler for scheduling the preconfigure events of this mock updater.
  /// - Returns: A mock Instance of an updater client.
  public static func failsToCheckForUpdates(scheduler: AnySchedulerOf<DispatchQueue>) -> Self {
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
          let userInfo = [
            NSLocalizedDescriptionKey:
              "An error occurred in retrieving update information. Please try again later."
          ]
          interface.send(.failure(.init(domain: "UpdaterClient", code: 2001, userInfo: userInfo)))
        }
        scheduler.schedule(after: scheduler.now.advanced(by: .seconds(3)), currentWork!.perform)

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
