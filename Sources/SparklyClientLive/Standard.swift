//
//  File.swift
//
//
//  Created by Till Hainbach on 08.06.21.
//
import Combine
import Foundation
import Sparkle
@_exported import SparklyClient

extension UpdaterClient {
  /// Create a *standard* version of an UpdaterClient which interacts with the *real* SparkleUpdater.
  ///
  /// The `standard`-Client uses the `SPUStandardUserDriver` internally. This is a *plug&play* version of
  /// `Sparkly`, where  `Sparkle`'s standard UI is used.
  public static func standard(hostBundle: Bundle, applicationBundle: Bundle) -> Self {

    let actionSubject = PassthroughSubject<Action, Never>()
    let eventSubject = PassthroughSubject<Event, Never>()
    let userDriver = SPUStandardUserDriver(hostBundle: hostBundle, delegate: nil)

    // init sparkle updater
    let updater = SPUUpdater(
      hostBundle: hostBundle,
      applicationBundle: applicationBundle,
      userDriver: userDriver,
      delegate: nil
    )

    var cancellables: Set<AnyCancellable> = []

    updater.publisher(for: \.canCheckForUpdates)
      .sink { eventSubject.send(.canCheckForUpdates($0)) }
      .store(in: &cancellables)

    actionSubject
      .sink { action in
        switch action {
        case .startUpdater:
          do {
            try updater.start()
          } catch {
            eventSubject.send(.failure(error as NSError))
          }

        case .checkForUpdates:
          updater.checkForUpdates()

        case .setHTTPHeaders(let newHTTPHeaders):
          updater.httpHeaders = newHTTPHeaders

        case .cancel, .reply, .setPermission:
          break
        }
      }
      .store(in: &cancellables)

    return Self(
      send: actionSubject.send(_:),
      publisher:
        eventSubject
        .handleEvents(receiveCancel: { cancellables.removeAll() })
        .eraseToAnyPublisher()
    )
  }
}
