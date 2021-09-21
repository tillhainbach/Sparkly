//
//  File.swift
//
//
//  Created by Till Hainbach on 08.06.21.
//
import Combine
import Foundation
@_exported import SparklyClient
import Sparkle

extension UpdaterClient {
  /// Create a *standard* version of an UpdaterClient which interacts with the *real* SparkleUpdater.
  ///
  /// The `standard`-Client uses the `SPUStandardUserDriver` internally. This is a *plug&play* version of
  /// `Sparkly`, where  `Sparkle`'s standard UI is used.
  public static func standard(hostBundle: Bundle, applicationBundle: Bundle) -> Self {

    // The UserDriver: forwards delegate methods to publishers
    class UserDriver: NSObject, SPUUserDriver {
      let userDriver: SPUUserDriver

      init(hostBundle: Bundle) {
        self.userDriver = SPUStandardUserDriver(hostBundle: hostBundle, delegate: nil)
        super.init()
      }

      func show(
        _ request: SPUUpdatePermissionRequest,
        reply: @escaping (SUUpdatePermissionResponse) -> Void
      ) {
        userDriver.show(request, reply: reply)
      }

      func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) {
        userDriver.showUserInitiatedUpdateCheck(cancellation: cancellation)
      }

      func showUpdateFound(
        with appcastItem: SUAppcastItem,
        state: SPUUserUpdateState,
        reply: @escaping (SPUUserUpdateChoice) -> Void
      ) {
        userDriver.showUpdateFound(with: appcastItem, state: state, reply: reply)
      }

      func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {
        userDriver.showUpdateReleaseNotes(with: downloadData)
      }

      func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {
        userDriver.showUpdateReleaseNotesFailedToDownloadWithError(error)
      }

      func showUpdateNotFoundWithError(_ error: Error, acknowledgement: @escaping () -> Void) {
        userDriver.showUpdateNotFoundWithError(error, acknowledgement: acknowledgement)
      }

      func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        userDriver.showUpdaterError(error, acknowledgement: acknowledgement)
      }

      func showDownloadInitiated(cancellation: @escaping () -> Void) {
        userDriver.showDownloadInitiated(cancellation: cancellation)
      }

      func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
        userDriver.showDownloadDidReceiveExpectedContentLength(expectedContentLength)
      }

      func showDownloadDidReceiveData(ofLength length: UInt64) {
        userDriver.showDownloadDidReceiveData(ofLength: length)
      }

      func showDownloadDidStartExtractingUpdate() {
        userDriver.showDownloadDidStartExtractingUpdate()
      }

      func showExtractionReceivedProgress(_ progress: Double) {
        userDriver.showExtractionReceivedProgress(progress)
      }

      func showInstallingUpdate() {
        userDriver.showInstallingUpdate()
      }

      func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
        userDriver.showReady(toInstallAndRelaunch: reply)
      }

      func showSendingTerminationSignal() {
        userDriver.showSendingTerminationSignal()
      }

      func showUpdateInstalledAndRelaunched(
        _ relaunched: Bool,
        acknowledgement: @escaping () -> Void
      ) {
        userDriver.showUpdateInstalledAndRelaunched(relaunched, acknowledgement: acknowledgement)
      }

      func showUpdateInFocus() {
        userDriver.showUpdateInFocus()
      }

      func dismissUpdateInstallation() {
        userDriver.dismissUpdateInstallation()
      }
    }

    let actionSubject = PassthroughSubject<UpdaterAction, Never>()
    let eventSubject = PassthroughSubject<UpdaterEvent, Never>()

    // init sparkle updater
    let updater = SPUUpdater(
      hostBundle: hostBundle,
      applicationBundle: applicationBundle,
      userDriver: UserDriver(hostBundle: hostBundle),
      delegate: nil
    )

    // listen on canCheckForUpdates
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
            eventSubject.send(.canCheckForUpdates(updater.canCheckForUpdates))
          } catch {
            eventSubject.send(.didFailOnStart(error as NSError))
          }
          break

        case .checkForUpdates:
          updater.checkForUpdates()
          break
        case .updateUserSettings(let userSettings):
          updater.updateSettings(from: userSettings)

        case .setHTTPHeaders(let newHTTPHeaders):
          updater.httpHeaders = newHTTPHeaders

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
