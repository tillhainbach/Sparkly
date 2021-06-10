//
//  File.swift
//
//
//  Created by Till Hainbach on 03.06.21.
//
import Combine
import Foundation
import SUUpdaterClient
import Sparkle

extension SUUpdaterClient {
  /// Create a *live* version of an UpdaterClient which interacts with the *real* SparkleUpdater.
  public static func live(hostBundle: Bundle, applicationBundle: Bundle) -> Self {

    // The UserDriver: forwards delegate methods to publishers
    class UserDriver: NSObject, SPUUserDriver {
      let eventSubject: PassthroughSubject<UpdaterEvents, Never>

      init(eventSubject: PassthroughSubject<UpdaterEvents, Never>) {
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
        fatalError("Unimplemented")
      }

      func showUpdateFound(
        with appcastItem: SUAppcastItem,
        state: SPUUserUpdateState,
        reply: @escaping (SPUUserUpdateChoice) -> Void
      ) {
        fatalError("Unimplemented")
      }

      func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {
        fatalError("Unimplemented")
      }

      func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {
        fatalError("Unimplemented")
      }

      func showUpdateNotFoundWithError(_ error: Error, acknowledgement: @escaping () -> Void) {
        eventSubject.send(.showUpdaterError(error as NSError, acknowledgement: .init(acknowledgement)))
      }

      func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        eventSubject.send(.showUpdaterError(error as NSError, acknowledgement: .init(acknowledgement)))
      }

      func showDownloadInitiated(cancellation: @escaping () -> Void) {
        fatalError("Unimplemented")
      }

      func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
        fatalError("Unimplemented")
      }

      func showDownloadDidReceiveData(ofLength length: UInt64) {
        fatalError("Unimplemented")
      }

      func showDownloadDidStartExtractingUpdate() {
        fatalError("Unimplemented")
      }

      func showExtractionReceivedProgress(_ progress: Double) {
        fatalError("Unimplemented")
      }

      func showInstallingUpdate() {
        fatalError("Unimplemented")
      }

      func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
        fatalError("Unimplemented")
      }

      func showSendingTerminationSignal() {
        fatalError("Unimplemented")
      }

      func showUpdateInstalledAndRelaunched(
        _ relaunched: Bool,
        acknowledgement: @escaping () -> Void
      ) {
        fatalError("Unimplemented")
      }

      func showUpdateInFocus() {
        fatalError("Unimplemented")
      }

      func dismissUpdateInstallation() {
        fatalError("Unimplemented")
      }
    }

    class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
      let eventSubject: PassthroughSubject<UpdaterEvents, Never>

      init(eventSubject: PassthroughSubject<UpdaterEvents, Never>) {
        self.eventSubject = eventSubject
        super.init()
      }

      func allowedSystemProfileKeys(for updater: SPUUpdater) -> [String] {
        fatalError("Unimplemented")
      }

      func feedParameters(for updater: SPUUpdater, sendingSystemProfile sendingProfile: Bool) -> [[String : String]] {
        fatalError("Unimplemented")
      }

      func feedURLString(for updater: SPUUpdater) -> String? {
        fatalError("Unimplemented")
      }

      func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        fatalError("Unimplemented")
      }

      func updater(_ updater: SPUUpdater, willScheduleUpdateCheckAfterDelay delay: TimeInterval) {
        fatalError("Unimplemented")
      }

      func updaterMayCheck(forUpdates updater: SPUUpdater) -> Bool {
        fatalError("Unimplemented")
      }

      func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, didExtractUpdate item: SUAppcastItem) {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, willExtractUpdate item: SUAppcastItem) {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        fatalError("Unimplemented")

      }

      func bestValidUpdate(in appcast: SUAppcast, for updater: SPUUpdater) -> SUAppcastItem? {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, userDidSkipThisVersion item: SUAppcastItem) {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, shouldAllowInstallerInteractionFor updateCheck: SPUUpdateCheck) -> Bool {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, willDownloadUpdate item: SUAppcastItem, with request: NSMutableURLRequest) {
        fatalError("Unimplemented")

      }

      func userDidCancelDownload(_ updater: SPUUpdater) {
        fatalError("Unimplemented")

      }

      func versionComparator(for updater: SPUUpdater) -> SUVersionComparison? {
        fatalError("Unimplemented")

      }

      func decryptionPassword(for updater: SPUUpdater) -> String? {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem, untilInvokingBlock installHandler: @escaping () -> Void) -> Bool {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem, immediateInstallationBlock immediateInstallHandler: @escaping () -> Void) -> Bool {
        fatalError("Unimplemented")

      }

      func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        fatalError("Unimplemented")
      }

      func updaterShouldDownloadReleaseNotes(_ updater: SPUUpdater) -> Bool {
        fatalError("Unimplemented")
      }

      func updaterShouldPromptForPermissionToCheck(forUpdates updater: SPUUpdater) -> Bool {
        fatalError("Unimplemented")
      }

      func updaterShouldRelaunchApplication(_ updater: SPUUpdater) -> Bool {
        fatalError("Unimplemented")
      }

      func updaterWillIdleSchedulingUpdates(_ updater: SPUUpdater) {
        fatalError("Unimplemented")
      }

      func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        fatalError("Unimplemented")
      }

    }

    let actionSubject = PassthroughSubject<UpdaterActions, Never>()
    let eventSubject = PassthroughSubject<UpdaterEvents, Never>()

    var updaterDelegate: UpdaterDelegate? = UpdaterDelegate(eventSubject: eventSubject)
    // init sparkle updater
    let updater = SPUUpdater(
      hostBundle: hostBundle,
      applicationBundle: applicationBundle,
      userDriver: UserDriver(eventSubject: eventSubject),
      delegate: updaterDelegate
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
        }
      }
      .store(in: &cancellables)

    return Self(
      send: actionSubject.send(_:),
      updaterEventPublisher:
        eventSubject
        .handleEvents(receiveCancel: { updaterDelegate = nil })
        .eraseToAnyPublisher(),
      cancellables: cancellables
    )
  }
}
