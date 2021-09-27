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
    applicationBundle: Bundle
  ) -> Self {

    // The UserDriver: forwards delegate methods to publishers
    class UserDriver: NSObject, SPUUserDriver {
      let eventSubject: PassthroughSubject<Event, Never>
      var cancelCallback: (() -> Void)?
      var replyCallback: ((SPUUserUpdateChoice) -> Void)?
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
        fatalError("Unimplemented")
      }

      func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) {
        self.cancelCallback = cancellation
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

        self.replyCallback = reply
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
        self.cancelCallback = acknowledgement
        eventSubject.send(.failure(error as NSError))
      }

      func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        self.cancelCallback = acknowledgement
        eventSubject.send(.failure(error as NSError))
      }

      func showDownloadInitiated(cancellation: @escaping () -> Void) {
        cancelCallback = cancellation
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
        replyCallback = reply
        eventSubject.send(.updateCheck(.readyToRelaunch))
      }

      func showSendingTerminationSignal() {
        eventSubject.send(.terminationSignal)
      }

      func showUpdateInstalledAndRelaunched(
        _ relaunched: Bool,
        acknowledgement: @escaping () -> Void
      ) {
        #if DEBUG
        print(
          """
          `showUpdateInstalledAndRelaunched` is currently not implemented.
          If you feel like you need it, please file an issue on https://github.com/tillhainbach/Sparkly
          """
        )
        #endif
      }

      func showUpdateInFocus() {
        #if DEBUG
        print(
          """
          `showUpdateInFocus` is currently not implemented.
          If you feel like you need it, please file an issue on https://github.com/tillhainbach/Sparkly
          """
        )
        #endif
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
      delegate: nil
    )

    var cancellables: Set<AnyCancellable> = []
    // FIXME: `.canCheckForUpdates` is not KVO-compliant, falling back to `.sessionInProgress`
    // Don't forget to send `.canCheckForUpdates` on `updater.start()`
    updater.publisher(for: \.sessionInProgress)
      .sink { _ in
        eventSubject.send(.canCheckForUpdates(updater.canCheckForUpdates))
      }
      .store(in: &cancellables)

    actionSubject
      .sink { action in
        switch action {
        case .startUpdater:
          do {
            try updater.start()
            eventSubject.send(.canCheckForUpdates(updater.canCheckForUpdates))
          } catch {
            eventSubject.send(.failure(error as NSError))
          }
          break

        case .checkForUpdates:
          updater.checkForUpdates()
          break

        case .updateUserSettings(let userSettings):
          updater.updateSettings(from: userSettings)
          break

        case .setHTTPHeaders(let newHTTPHeaders):
          updater.httpHeaders = newHTTPHeaders
          break

        case .cancel:
          userDriver.cancelCallback?()
          userDriver.cancelCallback = nil
          break

        case .reply(let choice):
          userDriver.replyCallback?(choice.toSparkle())
          userDriver.replyCallback = nil
          break
        }
      }
      .store(in: &cancellables)

    return Self(
      send: actionSubject.send(_:),
      updaterEventPublisher:
        eventSubject
        .eraseToAnyPublisher(),
      cancellables: cancellables
    )
  }
}
