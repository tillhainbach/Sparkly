//
//  File.swift
//
//
//  Created by Till Hainbach on 03.06.21.
//
import Combine
import Foundation
@_exported import SparklyClient
import Sparkle

extension UpdaterClient {
  /// Create a *live* version of an UpdaterClient which interacts with the *real* SparkleUpdater.
  public static func live(
    hostBundle: Bundle,
    applicationBundle: Bundle
  ) -> Self {

    // The UserDriver: forwards delegate methods to publishers
    class UserDriver: NSObject, SPUUserDriver {
      let eventSubject: PassthroughSubject<UpdaterEvent, Never>

      init(eventSubject: PassthroughSubject<UpdaterEvent, Never>) {
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
        guard let userState = UserUpdateState(rawValue: state) else {
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
        eventSubject.send(.showUpdateReleaseNotes(.init(rawValue: downloadData)))
//        fatalError("Unimplemented")
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
        eventSubject.send(.downloadInitiated(cancellation: Callback(cancellation)))
      }

      func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
        fatalError("Unimplemented")
      }

      func showDownloadDidReceiveData(ofLength length: UInt64) {
        eventSubject.send(.didReceiveData(length: length))
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
        eventSubject.send(.dismissUpdateInstallation)
      }
    }

    let actionSubject = PassthroughSubject<UpdaterAction, Never>()
    let eventSubject = PassthroughSubject<UpdaterEvent, Never>()

    // init sparkle updater
    let updater = SPUUpdater(
      hostBundle: hostBundle,
      applicationBundle: applicationBundle,
      userDriver: UserDriver(eventSubject: eventSubject),
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

extension UpdateCheck {
  init?(rawValue: SPUUpdateCheck) {
    switch rawValue {
    case .updates:
      self = .checkUpdates
      break
    case .updatesInBackground:
      self = .checkUpdatesInBackground
      break
    case .updateInformation:
      self = .checkUpdateInformation
      break
    @unknown default:
      return nil
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

//extension Appcast {
//
//  init(rawValue: SUAppcast) {
//    self.init(items: rawValue.items.map { .init(rawValue: $0) })
//  }
//}

extension UserUpdateState.Stage {
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
    @unknown default:
      return nil
    }
  }
}

extension UserUpdateState.Choice {
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

extension UserUpdateState {
  init?(rawValue: SPUUserUpdateState) {
    guard let stage = UserUpdateState.Stage(rawValue: rawValue.stage) else {
      return nil
    }

    self.init(stage: stage, userInitiated: rawValue.userInitiated)
  }
}

extension DownloadData {
  init(rawValue: SPUDownloadData) {
    self.init(data: rawValue.data, url: rawValue.url, textEncodingName: rawValue.textEncodingName, mimeType: rawValue.mimeType)
  }
}
