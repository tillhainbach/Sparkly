//
//  File.swift
//
//
//  Created by Till Hainbach on 03.06.21.
//

import Combine
import Foundation

/// SUUpdaterClient: Client-side Interface for Sparkle.
public struct SUUpdaterClient {

  // MARK: - Interface Methods

  /// Use this closure to send actions to the updater.
  public var send: (UpdaterActions) -> Void

  /// A publisher that emits events from the updater.
  public var updaterEventPublisher: AnyPublisher<UpdaterEvents, Never>

  // MARK: - Initializer

  /// Initialize the UpdaterClient.
  public init(
    send: @escaping (UpdaterActions) -> Void,
    updaterEventPublisher: AnyPublisher<UpdaterEvents, Never>,
    cancellables: Set<AnyCancellable>
  ) {
    self.send = send
    self.updaterEventPublisher = updaterEventPublisher
    self.cancellables = cancellables
  }

  // MARK: - Interface Events

  /// Events that the updater can emit.
  ///
  /// A detailed documentation of the corresponding `SPUUserDriver` methods can be found in the [header file](https://github.com/sparkle-project/Sparkle/blob/2.x/Sparkle/SPUUserDriver.h).
  public enum UpdaterEvents {

    /// This event is emitted if the updater failed on start. Holds the corresponding error as an associated value.
    case didFailOnStart(_ error: Error)
    /// This event is emitted whenever the updater's `canCheckForUpdates`-property changes.
    /// Useful for en- or disabling UI-Elements that allow a manual update check.
    case canCheckForUpdates(Bool)


    /// This event emits updater errors.
    ///
    /// Use this event to show an alert to the user. Additionally, you nee to hook up the acknowledge callback to the
    /// `Cancel Update` or `Dismiss` button to tell the updater that the error was shown and acknowledged.
    case showUpdaterError(_ error: Error, acknowledgement: () -> Void)
  }

  // MARK: - Interface Actions

  /// Actions that can be sent to the updater.
  public enum UpdaterActions {
    case checkForUpdates
    case startUpdater
  }

  // MARK: - private cancellable

  // hold on to the cancellables so that it is not immediately destructured...
  private var cancellables: Set<AnyCancellable>
}
