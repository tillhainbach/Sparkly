//
//  File.swift
//
//
//  Created by Till Hainbach on 03.06.21.
//

import Combine
import Foundation

/// SUUpdaterClient: Client-side Interface for Sparkle.
public struct UpdaterClient {

  /// Use this closure to send actions to the updater.
  public let send: (Action) -> Void

  /// A publisher that emits events from the updater.
  public let updaterEventPublisher: AnyPublisher<Event, Never>

  // hold on to the cancellables so that it is not immediately destructured...
  private var cancellables: Set<AnyCancellable>

  /// Initialize the UpdaterClient.
  public init(
    send: @escaping (Action) -> Void,
    updaterEventPublisher: AnyPublisher<Event, Never>,
    cancellables: Set<AnyCancellable>
  ) {
    self.send = send
    self.updaterEventPublisher = updaterEventPublisher
    self.cancellables = cancellables
  }

}

// MARK: - Interface Events

extension UpdaterClient {
  /// Events that the updater can emit.
  ///
  /// A detailed documentation of the corresponding `SPUUserDriver` methods can be found in the
  /// [header file](https://github.com/sparkle-project/Sparkle/blob/2.x/Sparkle/SPUUserDriver.h).
  public enum Event: Equatable {

    /// This event is emitted whenever the updater's `canCheckForUpdates`-property changes.
    /// Useful for en- or disabling UI-Elements that allow a manual update check.
    case canCheckForUpdates(Bool)

    /// Called when aborting an update.
    case dismissUpdateInstallation

    /// This event is emitted if the updater fails. Holds the corresponding error as an associated value.
    ///
    /// The `failure` event is totally agnostic to which caused the failure. It's up to the subscriber to handle the error
    /// and e.g. show an appropriate alert. Some errors by need to be acknowledged by sending  `Action.cancel` to the updater
    case failure(_ error: NSError)

    /// This event emits if the updater wants to show release notes
    case showUpdateReleaseNotes(DownloadData)

    /// This event is emitted if the updater sends a signal to terminate the host application.
    case terminationSignal

    /// This event is emitted if the state of the current update check changes.
    case updateCheck(UpdateCheckState)

  }
}

// MARK: - Interface Actions

extension UpdaterClient {
  /// Actions that can be sent to the updater.
  public enum Action: Equatable {
    case cancel
    case checkForUpdates
    case reply(UserUpdateState.Choice)
    case setHTTPHeaders([String: String])
    case startUpdater
    case updateUserSettings(UpdaterSettings)
  }
}

/// The state of an update check
public enum UpdateCheckState: Equatable {
  case checking
  case downloading(total: Double, completed: Double)
  case extracting(completed: Double)
  case found(AppcastItem, state: UserUpdateState)
  case installing
  case readyToRelaunch
}