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
  public static var happyPath: Self {
    let eventSubject = PassthroughSubject<UpdaterEvents, Never>()
    let actionSubject = PassthroughSubject<UpdaterActions, Never>()

    let cancellable = actionSubject
      .sink(receiveValue: { action in
        switch action {

        case .checkForUpdates:
          print("checking for updates")
          break
        }

      })

    let updaterEventPublisher = Publishers.Concatenate(
      prefix: Just(.canCheckForUpdates(true)).delay(for: 0.5, scheduler: DispatchQueue.main),
      suffix: eventSubject.eraseToAnyPublisher()
    )

    return Self(
      send: actionSubject.send(_:),
      updaterEventPublisher: updaterEventPublisher.eraseToAnyPublisher(),
      cancellable: cancellable
    )
  }
}
