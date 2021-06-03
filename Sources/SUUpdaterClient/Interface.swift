//
//  File.swift
//  
//
//  Created by Till Hainbach on 03.06.21.
//

import Combine
import Foundation

/// SUUpdaterClient: Client-side Interface for Sparkle
public struct SUUpdaterClient {

  // MARK: - Interface Methods
  public var send: (UpdaterActions) -> Void
  public var updaterEventPublisher: AnyPublisher<UpdaterEvents, Never>

  // MARK: - Initializer
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
  public enum UpdaterEvents {
    case canCheckForUpdates(Bool)
    case didFailOnStart
  }

  // MARK: - Interface Actions
  public enum UpdaterActions {
    case checkForUpdates
    case startUpdater
  }

  // MARK: - private cancellable
  private var cancellables: Set<AnyCancellable>  // hold on to the cancellables so that it is not immediately destructured...
}
