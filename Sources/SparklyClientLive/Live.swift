//
//  File.swift
//
//
//  Created by Till Hainbach on 03.06.21.
//
import Combine
import Foundation
import Sparkle
@_exported import SparklyClient

extension UpdaterClient {
  /// Create a *live* version of an UpdaterClient which interacts with the *real* SparkleUpdater.
  public static func live(
    hostBundle: Bundle,
    applicationBundle: Bundle,
    delegate: SPUUpdaterDelegate? = nil
  ) -> Self {

    // The UserDriver: forwards delegate methods to publishers
    class UserDriver: NSObject, SPUUserDriver {
      enum Callback {
        case cancel(with: () -> Void)
        case acknowledge(with: () -> Void)
        case reply(with: (SPUUserUpdateChoice) -> Void)
      }

      let eventSubject: PassthroughSubject<Event, Never>
      var currentCallback: Callback?
      var permissionRequest: ((SUUpdatePermissionResponse) -> Void)?
      var totalDownloadData = 0.0
      var totalDataReceived = 0.0

      init(eventSubject: PassthroughSubject<Event, Never>) {
        self.eventSubject = eventSubject
        super.init()
      }

      func show(
        _ request: SPUUpdatePermissionRequest,
        reply: @escaping (SUUpdatePermissionResponse) -> Void
      ) {
        self.permissionRequest = reply
        eventSubject.send(.permissionRequest)
      }

      func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) {
        self.currentCallback = .cancel(with: cancellation)
        eventSubject.send(.updateCheck(.checking))
      }

      func showUpdateFound(
        with appcastItem: SUAppcastItem,
        state: SPUUserUpdateState,
        reply: @escaping (SPUUserUpdateChoice) -> Void
      ) {
        guard let userState = UserUpdateState(rawValue: state) else {
          return
        }

        self.currentCallback = .reply(with: reply)
        eventSubject.send(
          .updateCheck(.found(AppcastItem(rawValue: appcastItem), state: userState))
        )
      }

      func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {
        eventSubject.send(.showUpdateReleaseNotes(.init(rawValue: downloadData)))
      }

      func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {
        eventSubject.send(.failure(error as NSError))
      }

      func showUpdateNotFoundWithError(_ error: Error, acknowledgement: @escaping () -> Void) {
        self.currentCallback = .acknowledge(with: acknowledgement)
        eventSubject.send(.failure(error as NSError))
      }

      func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        self.currentCallback = .acknowledge(with: acknowledgement)
        eventSubject.send(.failure(error as NSError))
      }

      func showDownloadInitiated(cancellation: @escaping () -> Void) {
        self.currentCallback = .cancel(with: cancellation)
        eventSubject.send(.updateCheck(.downloading(total: 0, completed: 0)))
      }

      func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
        self.totalDownloadData = Double(expectedContentLength)
        self.totalDataReceived = 0.0
        eventSubject.send(
          .updateCheck(.downloading(total: self.totalDownloadData, completed: 0))
        )
      }

      func showDownloadDidReceiveData(ofLength length: UInt64) {
        self.totalDataReceived += Double(length)
        eventSubject.send(
          .updateCheck(
            .downloading(total: self.totalDownloadData, completed: self.totalDataReceived)
          )
        )
      }

      func showDownloadDidStartExtractingUpdate() {
        eventSubject.send(.updateCheck(.extracting(completed: 0)))
      }

      func showExtractionReceivedProgress(_ progress: Double) {
        eventSubject.send(.updateCheck(.extracting(completed: progress)))
      }

      func showInstallingUpdate() {
        eventSubject.send(.updateCheck(.installing))
      }

      func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
        self.currentCallback = .reply(with: reply)
        eventSubject.send(.updateCheck(.readyToRelaunch))
      }

      func showSendingTerminationSignal() {
        eventSubject.send(.terminationSignal)
      }

      func showUpdateInstalledAndRelaunched(
        _ relaunched: Bool,
        acknowledgement: @escaping () -> Void
      ) {
        self.currentCallback = .acknowledge(with: acknowledgement)
        eventSubject.send(.updateInstalledAndRelaunched(relaunched))
      }

      func showUpdateInFocus() {
        eventSubject.send(.focusUpdate)
      }

      func dismissUpdateInstallation() {
        eventSubject.send(.dismissUpdateInstallation)
      }
    }

    let actionSubject = PassthroughSubject<Action, Never>()
    let eventSubject = PassthroughSubject<Event, Never>()
    let userDriver = UserDriver(eventSubject: eventSubject)

    // init sparkle updater
    let updater = SPUUpdater(
      hostBundle: hostBundle,
      applicationBundle: applicationBundle,
      userDriver: userDriver,
      delegate: delegate
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

        case .cancel:
          if case .cancel(let cancellation) = userDriver.currentCallback {
            cancellation()
            userDriver.currentCallback = nil
          }

        case .reply(let choice):
          if case .reply(let reply) = userDriver.currentCallback {
            reply(choice.toSparkle())
            userDriver.currentCallback = nil
          }

        case .setPermission(let automaticUpdateChecks, let sendSystemProfile):
          userDriver.permissionRequest?(
            .init(
              automaticUpdateChecks: automaticUpdateChecks,
              sendSystemProfile: sendSystemProfile
            )
          )

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
