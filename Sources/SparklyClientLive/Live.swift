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
        eventSubject.send(.updateCheckInitiated)
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
          .updateFound(
            update: AppcastItem(rawValue: appcastItem),
            state: userState
          )
        )
      }

      func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {
        eventSubject.send(.showUpdateReleaseNotes(.init(rawValue: downloadData)))
      }

      func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {
        fatalError("Unimplemented")
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
        eventSubject.send(.downloadInFlight(total: 0, completed: 0))
      }

      func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
        self.totalDownloadData = Double(expectedContentLength)
        self.totalDataReceived = 0.0
        eventSubject.send(.downloadInFlight(total: self.totalDownloadData, completed: 0))
      }

      func showDownloadDidReceiveData(ofLength length: UInt64) {
        self.totalDataReceived += Double(length)
        eventSubject.send(.downloadInFlight(total: self.totalDownloadData, completed: self.totalDataReceived))
      }

      func showDownloadDidStartExtractingUpdate() {
        eventSubject.send(.extractingUpdate(completed: 0))
      }

      func showExtractionReceivedProgress(_ progress: Double) {
        eventSubject.send(.extractingUpdate(completed: progress))
      }

      func showInstallingUpdate() {
        eventSubject.send(.installing)
      }

      func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
        replyCallback = reply
        eventSubject.send(.readyToRelaunch)
      }

      func showSendingTerminationSignal() {
        eventSubject.send(.terminationSignal)
//        fatalError("Unimplemented")
      }

      func showUpdateInstalledAndRelaunched(
        _ relaunched: Bool,
        acknowledgement: @escaping () -> Void
      ) {
        #if DEBUG
        print("""
        `showUpdateInstalledAndRelaunched` is currently not implemented.
        If you will like you need it, please file an issue on https://github.com/tillhainbach/Sparkly
        """)
        #endif
      }

      func showUpdateInFocus() {
        #if DEBUG
        print("""
        `showUpdateInFocus` is currently not implemented.
        If you will like you need it, please file an issue on https://github.com/tillhainbach/Sparkly
        """)
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
          break

        case .reply(let choice):
          userDriver.replyCallback?(choice.toSparkle())
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

//extension UpdateCheck {
//  init?(rawValue: SPUUpdateCheck) {
//    switch rawValue {
//    case .updates:
//      self = .checkUpdates
//      break
//    case .updatesInBackground:
//      self = .checkUpdatesInBackground
//      break
//    case .updateInformation:
//      self = .checkUpdateInformation
//      break
//    @unknown default:
//      return nil
//    }
//  }
//}

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
