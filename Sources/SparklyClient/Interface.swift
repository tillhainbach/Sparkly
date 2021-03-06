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
  public let publisher: AnyPublisher<Event, Never>

  /// Initialize the UpdaterClient.
  public init(
    send: @escaping (Action) -> Void,
    publisher: AnyPublisher<Event, Never>
  ) {
    self.send = send
    self.publisher = publisher
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

    /// Show the user the current presented update or its progress in utmost focus
    case focusUpdate

    /// Show an updater permission request to the user
    case permissionRequest

    /// This event emits if the updater wants to show release notes
    case showUpdateReleaseNotes(DownloadData)

    /// This event is emitted if the updater sends a signal to terminate the host application.
    case terminationSignal

    /// This event is emitted if the state of the current update check changes.
    case updateCheck(UpdateCheckState)

    /// This event is emitted after an update has been successfully installed and the application has been relaunched.
    ///
    /// > This will only be invoked if the updater process is still alive, which is typically not the case if
    /// > the updater's lifetime is tied to the application it is updating.
    case updateInstalledAndRelaunched(Bool)

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
    case setPermission(automaticUpdateChecks: Bool, sendSystemProfile: Bool)
  }
}

/// The state of an update check.
public enum UpdateCheckState: Equatable {
  case checking
  case downloading(total: Double, completed: Double)
  case extracting(completed: Double)
  case found(AppcastItem, state: UserUpdateState)
  case installing
  case readyToRelaunch
}

extension UpdaterClient {
  public final class Interface {
    let eventSubject = PassthroughSubject<Event, Never>()
    let actionSubject = PassthroughSubject<Action, Never>()
    var cancellable: AnyCancellable?
    var handleAction: (Action) -> Void = { _ in }

    init() {
      self.cancellable = actionSubject.sink { [weak self] in self?.handleAction($0) }
    }

    func send(_ event: Event) {
      eventSubject.send(event)
    }

    var client: UpdaterClient {
      return .init(
        send: actionSubject.send(_:),
        publisher:
          eventSubject
          .handleEvents(receiveCancel: { self.cancellable?.cancel() })
          .eraseToAnyPublisher()
      )
    }
  }
}
