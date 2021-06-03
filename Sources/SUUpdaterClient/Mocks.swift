//
//  File.swift
//
//
//  Created by Till Hainbach on 03.06.21.
//

import Combine
import Dispatch
import Foundation

extension SUUpdaterClient {
  /// A Mock SUUpdaterClient that simulate a *happy path*.
  public static var happyPath: Self {
    let eventSubject = PassthroughSubject<UpdaterEvents, Never>()
    let actionSubject = PassthroughSubject<UpdaterActions, Never>()
    var cancellables: Set<AnyCancellable> = []

    actionSubject
      .sink(receiveValue: { action in
        switch action {

        case .checkForUpdates:
          print("checking for updates")
          break
        case .startUpdater:
          print("updater did start")
        }

      })
      .store(in: &cancellables)

    let updaterEventPublisher = Publishers.Concatenate(
      prefix: Just(.canCheckForUpdates(true)).delay(for: 0.5, scheduler: DispatchQueue.main),
      suffix: eventSubject.eraseToAnyPublisher()
    )

    return Self(
      send: actionSubject.send(_:),
      updaterEventPublisher: updaterEventPublisher.eraseToAnyPublisher(),
      cancellables: cancellables
    )
  }
}
