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
  public enum UpdaterEvents: Equatable {

    /// This event is emitted if the updater failed on start. Holds the corresponding error as an associated value.
    case didFailOnStart(_ error: NSError)
    /// This event is emitted whenever the updater's `canCheckForUpdates`-property changes.
    /// Useful for en- or disabling UI-Elements that allow a manual update check.
    case canCheckForUpdates(Bool)

    /// This event emits updater errors.
    ///
    /// Use this event to show an alert to the user. Additionally, you nee to hook up the acknowledge callback to the
    /// `Cancel Update` or `Dismiss` button to tell the updater that the error was shown and acknowledged.
    case showUpdaterError(_ error: NSError, acknowledgement: Callback<Void>)

    /// This event emits if the updater wants to show realease notes
    case showUpdateReleaseNotes(SUDownloadData)

    /// This event emits when an update check is initiated
    ///
    /// Use this event to notify the user that an update was initiated. Use the Callback to hook up a `Cancel`-button
    case updateCheckInitiated(cancellation: Callback<Void>)

    /// This event emits when a valid update hast been found
    ///
    /// Use this event if you want to do
    case updateFound(
          update: AppcastItem,
          state: SUUserUpdateState,
          reply: Callback<SUUserUpdateState.Choice>
         )

    /// Called when aborting or finishing an update.
    case dismissUpdateInstallation
  }

  // MARK: - Interface Actions

  /// Actions that can be sent to the updater.
  public enum UpdaterActions: Equatable {
    case checkForUpdates
    case startUpdater
    case updateUserSettings(SUUpdaterUserSettings)
  }

  // MARK: - private cancellable

  // hold on to the cancellables so that it is not immediately destructured...
  private var cancellables: Set<AnyCancellable>

}

public struct Callback<T>: Equatable {

  // set all callbacks to be the same
  public static func == (lhs: Callback<T>, rhs: Callback<T>) -> Bool {
    return true
  }

  public let run: (T) -> Void

  public init(_ callback: @escaping (T) -> Void) {
    run = callback
  }
}


/// Wrapped for [SPUUserUpdateState](https://github.com/sparkle-project/Sparkle/blob/c6f1cd4e3cbdf4fbd3b12f779dd677775a77f60f/Sparkle/SPUUserUpdateState.h)
public struct SUUserUpdateState: Equatable {

  public var stage: Stage
  public var userInitiated: Bool

  public init(stage: SUUserUpdateState.Stage, userInitiated: Bool) {
    self.stage = stage
    self.userInitiated = userInitiated
  }

  public enum Stage {
    /// The update has not been downloaded.
    case notDownloaded

    /// The update has already been downloaded but not begun installing.
    case downloaded

    /// The update has already been downloaded and began installing in the background.
    case installing
  }

  public enum Choice {
    case skip
    case install
    case dismiss
  }

}

public struct SUDownloadData: Equatable {

  public let data: Data
  public let url: URL
  public let textEncodingName: String?
  public let mimeType: String?

  public init(data: Data, url: URL, textEncodingName: String?, mimeType: String?) {
    self.data = data
    self.url = url
    self.textEncodingName = textEncodingName
    self.mimeType = mimeType
  }
}
