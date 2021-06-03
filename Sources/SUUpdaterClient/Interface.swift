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
    cancellable: AnyCancellable
  ) {
    self.send = send
    self.updaterEventPublisher = updaterEventPublisher
    self.cancellable = cancellable
  }

  // MARK: - Interface Events
  public enum UpdaterEvents {
    case canCheckForUpdates(Bool)
  }

  // MARK: - Interface Actions
  public enum UpdaterActions {
    case checkForUpdates
  }

  // MARK: - private cancellable
  private var cancellable: AnyCancellable  // hold on to the cancellable so that it is not immediately destructured...
}
