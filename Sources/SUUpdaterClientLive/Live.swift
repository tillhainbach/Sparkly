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
  public static func live(
    hostBundle: Bundle,
    applicationBundle: Bundle,
    developerSettings: SUDeveloperSettings
  ) -> Self {

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
        eventSubject.send(.updateCheckInitiated(cancellation: Callback(cancellation)))
      }

      func showUpdateFound(
        with appcastItem: SUAppcastItem,
        state: SPUUserUpdateState,
        reply: @escaping (SPUUserUpdateChoice) -> Void
      ) {
        guard let userState = SUUserUpdateState(rawValue: state) else {
          return
        }

        eventSubject.send(
          .updateFound(
            update: AppcastItem(rawValue: appcastItem),
            state: userState,
            reply: Callback { choice in
              reply(choice.toSparkle())
            }
          )
        )
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
      var developerSettings: SUDeveloperSettings

      init(
        eventSubject: PassthroughSubject<UpdaterEvents, Never>,
        developerSettings: SUDeveloperSettings
      ) {
        self.eventSubject = eventSubject
        self.developerSettings = developerSettings
        super.init()
      }

      // Developer Settings

      func updaterMayCheck(forUpdates updater: SPUUpdater) -> Bool {
        return developerSettings.updaterMayCheckForUpdates()
      }

      func allowedSystemProfileKeys(for updater: SPUUpdater) -> [String] {
        return developerSettings.allowedSystemProfileKeys()
      }

      func feedParameters(
        for updater: SPUUpdater,
        sendingSystemProfile sendingProfile: Bool
      ) -> [[String : String]] {
        return developerSettings.feedParameters(sendingProfile)
      }

      func feedURLString(for updater: SPUUpdater) -> String? {
        return developerSettings.feedURLString()
        //fatalError("Unimplemented")
      }

      func bestValidUpdate(in appcast: SUAppcast, for updater: SPUUpdater) -> SUAppcastItem? {
        let appcastItem = developerSettings.retrieveBestValidUpdate(Appcast(rawValue: appcast))
        return appcastItem?.toSparkle()
      }

      func updater(
        _ updater: SPUUpdater,
        shouldAllowInstallerInteractionFor updateCheck: SPUUpdateCheck
      ) -> Bool {

        return developerSettings.shouldAllowInstallerInteraction(
          UpdateCheck(rawValue: updateCheck)
        )

      }

      func versionComparator(for updater: SPUUpdater) -> SUVersionComparison? {
        guard let compareVersions = developerSettings.compareVersions else {
          return nil

        }

        return VersionComparison(compareVersions: compareVersions)

      }

      func decryptionPassword(for updater: SPUUpdater) -> String? {
        developerSettings.retrieveDecryptionPassword()
      }

      func updater(
        _ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem,
        untilInvokingBlock installHandler: @escaping () -> Void
      ) -> Bool {
        developerSettings.updaterShouldPostponeRelaunchForUpdate(
          AppcastItem(rawValue: item),
          installHandler
        )

      }

      func updater(
        _ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem,
        immediateInstallationBlock immediateInstallHandler: @escaping () -> Void
      ) -> Bool {
        developerSettings.updaterWillInstallUpdateOnQuit(
          AppcastItem(rawValue: item),
          immediateInstallHandler
        )

      }

      func updaterShouldDownloadReleaseNotes(_ updater: SPUUpdater) -> Bool {
        developerSettings.updaterShouldDownloadReleaseNotes()
      }

      func updaterShouldPromptForPermissionToCheck(forUpdates updater: SPUUpdater) -> Bool {
        developerSettings.updaterShouldPromptForPermissionToCheckForUpdates()
      }

      func updaterShouldRelaunchApplication(_ updater: SPUUpdater) -> Bool {
        developerSettings.updaterShouldRelaunchApplication()
      }

      // Events
      func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        eventSubject.send(.didFinishLoading(appcast: .init(rawValue: appcast)))
      }

      func updater(_ updater: SPUUpdater, willScheduleUpdateCheckAfterDelay delay: TimeInterval) {
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
        eventSubject.send(.didFindValidUpdate(update: .init(rawValue: item)))

      }

      func updater(_ updater: SPUUpdater, userDidSkipThisVersion item: SUAppcastItem) {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        fatalError("Unimplemented")

      }

      func updater(_ updater: SPUUpdater, willDownloadUpdate item: SUAppcastItem, with request: NSMutableURLRequest) {
        fatalError("Unimplemented")

      }

      func userDidCancelDownload(_ updater: SPUUpdater) {
        fatalError("Unimplemented")

      }

      func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
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

    var updaterDelegate: UpdaterDelegate? = UpdaterDelegate(
      eventSubject: eventSubject,
      developerSettings: developerSettings
    )
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

extension UpdateCheck {
  init(rawValue: SPUUpdateCheck) {
    switch rawValue {
    case .backgroundScheduled:
      self = .backgroundScheduled
      break
    case .userInitiated:
      self = .userInitiated
      break
    @unknown default:
      self = .userInitiated
    }
  }
}

final class VersionComparison: SUVersionComparison {
  let compareVersions: (String, String) -> ComparisonResult

  init(compareVersions: @escaping (String, String) -> ComparisonResult) {
    self.compareVersions = compareVersions
  }

  func compareVersion(_ versionA: String, toVersion versionB: String) -> ComparisonResult {
    return self.compareVersions(versionA, versionB)
  }


}

extension AppcastItem {
  init(rawValue: SUAppcastItem) {
    self.init(
      versionString: rawValue.versionString,
      displayVersionString: rawValue.displayVersionString,
      fileURL: rawValue.fileURL,
      contentLength: rawValue.contentLength,
      infoURL: rawValue.infoURL,
      isInformationOnlyUpdate: rawValue.isInformationOnlyUpdate,
      title: rawValue.title,
      dateString: rawValue.dateString,
      date: rawValue.date,
      releaseNotesURL: rawValue.releaseNotesURL,
      itemDescription: rawValue.itemDescription,
      minimumSystemVersion: rawValue.minimumSystemVersion,
      maximumSystemVersion: rawValue.maximumSystemVersion,
      installationType: rawValue.installationType,
      phasedRolloutInterval: rawValue.phasedRolloutInterval,
      propertiesDictionary: rawValue.propertiesDictionary as! [AnyHashable: AnyHashable]
    )
  }

  func toSparkle() -> SUAppcastItem {
    fatalError()
  }
}

extension Appcast {

  init(rawValue: SUAppcast) {
    self.init(items: rawValue.items.map { .init(rawValue: $0) })
  }
}

extension SUUserUpdateState.Stage {
  init?(rawValue: SPUUserUpdateStage) {
    switch rawValue {
    case .downloaded:
      self = .downloaded
      break
    case .notDownloaded:
      self = .notDownloaded
      break
    case .installing:
      self = .installing
      break
    case .informational:
      return nil
    @unknown default:
      return nil
    }
  }
}

extension SUUserUpdateState.Choice {
  func toSparkle() -> SPUUserUpdateChoice {
    switch self {
    case .skip:
      return .skip
    case .install:
      return .install
    case .dismiss:
      return .dismiss
    }
  }
}

extension SUUserUpdateState {
  init?(rawValue: SPUUserUpdateState) {
    guard let stage = SUUserUpdateState.Stage(rawValue: rawValue.stage) else {
      return nil
    }

    self.init(stage: stage, userInitiated: rawValue.userInitiated)
  }
}
