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
  public enum UpdaterEvents {
    case canCheckForUpdates(Bool)
    case didFailOnStart
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
