//
//  File.swift
//
//
//  Created by Till Hainbach on 24.09.21.
//

import Sparkle
import SparklyClient

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

}

extension DownloadData {
  init(rawValue: SPUDownloadData) {
    self.init(
      data: rawValue.data,
      url: rawValue.url,
      textEncodingName: rawValue.textEncodingName,
      mimeType: rawValue.mimeType
    )
  }
}

extension SPUUpdater {
  func updateSettings(from userSettings: UpdaterSettings) {
    self.automaticallyChecksForUpdates = userSettings.automaticallyCheckForUpdates
    self.automaticallyDownloadsUpdates = userSettings.automaticallyDownloadUpdates
    self.sendsSystemProfile = userSettings.sendSystemProfile
    self.updateCheckInterval = userSettings.updateInterval.toTimeInterval()
  }
}

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
