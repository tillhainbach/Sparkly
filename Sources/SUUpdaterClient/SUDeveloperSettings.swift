//
//  File.swift
//  
//
//  Created by Till Hainbach on 24.06.21.
//

import Foundation

/// A Model representing settings that are relevant for application developers.
public struct SUDeveloperSettings {
  public init(
    allowedSystemProfileKeys: @escaping () -> [String],
    feedParameters: @escaping (Bool) -> [[String : String]],
    feedURLString: @escaping () -> String?,
    handleAppcast: @escaping (Appcast) -> Appcast,
    retrieveDecryptionPassword: @escaping () -> String?,
    retrieveBestValidUpdate: @escaping (Appcast) -> AppcastItem?,
    shouldAllowInstallerInteraction: @escaping (UpdateCheck) -> Bool,
    updaterMayCheckForUpdates: @escaping () -> Bool,
    compareVersions: Optional<(String, String) -> ComparisonResult>,
    updaterShouldPostponeRelaunchForUpdate: @escaping (AppcastItem, () -> Void) -> Bool,
    updaterWillInstallUpdateOnQuit: @escaping (AppcastItem, () -> Void) -> Bool,
    updaterShouldDownloadReleaseNotes: @escaping () -> Bool,
    updaterShouldPromptForPermissionToCheckForUpdates: @escaping () -> Bool,
    updaterShouldRelaunchApplication: @escaping () -> Bool
  ) {
    self.allowedSystemProfileKeys = allowedSystemProfileKeys
    self.feedParameters = feedParameters
    self.feedURLString = feedURLString
    self.retrieveDecryptionPassword = retrieveDecryptionPassword
    self.retrieveBestValidUpdate = retrieveBestValidUpdate
    self.shouldAllowInstallerInteraction = shouldAllowInstallerInteraction
    self.updaterMayCheckForUpdates = updaterMayCheckForUpdates
    self.compareVersions = compareVersions
    self.updaterShouldPostponeRelaunchForUpdate = updaterShouldPostponeRelaunchForUpdate
    self.updaterWillInstallUpdateOnQuit = updaterWillInstallUpdateOnQuit
    self.updaterShouldDownloadReleaseNotes = updaterShouldDownloadReleaseNotes
    self.updaterShouldPromptForPermissionToCheckForUpdates = updaterShouldPromptForPermissionToCheckForUpdates
    self.updaterShouldRelaunchApplication = updaterShouldRelaunchApplication

    self.handleAppcast = handleAppcast
  }


  public var allowedSystemProfileKeys: () -> [String]
  public var feedParameters: (Bool) -> [[String: String]]
  public var feedURLString: () -> String?
  public var retrieveDecryptionPassword: () -> String?
  public var retrieveBestValidUpdate: (Appcast) -> AppcastItem?
  public var shouldAllowInstallerInteraction: (UpdateCheck) -> Bool
  public var updaterMayCheckForUpdates: () -> Bool
  public var compareVersions: Optional<(String, String) -> ComparisonResult>

  public var updaterShouldPostponeRelaunchForUpdate: (AppcastItem, () -> Void) -> Bool
  public var updaterWillInstallUpdateOnQuit: (AppcastItem, () -> Void) -> Bool
  public var updaterShouldDownloadReleaseNotes: () -> Bool
  public var updaterShouldPromptForPermissionToCheckForUpdates: () -> Bool
  public var updaterShouldRelaunchApplication: () -> Bool

  public var handleAppcast: (Appcast) -> Appcast

}

public enum UpdateCheck {
  case userInitiated
  case backgroundScheduled
}

public struct Appcast: Equatable {
  public var items: [AppcastItem]

  public init(items: [AppcastItem]) {
    self.items = items
  }
}
public struct AppcastItem: Equatable {
  public init(
    versionString: String,
    displayVersionString: String?,
    fileURL: URL?,
    contentLength: UInt64,
    infoURL: URL?,
    isInformationOnlyUpdate: Bool,
    title: String?,
    dateString: String?,
    date: Date?,
    releaseNotesURL: URL?,
    itemDescription: String?,
    minimumSystemVersion: String?,
    maximumSystemVersion: String?,
    installationType: String?,
    phasedRolloutInterval: NSNumber?,
    propertiesDictionary: [AnyHashable: AnyHashable]
  ) {
    self.versionString = versionString
    self.displayVersionString = displayVersionString
    self.fileURL = fileURL
    self.contentLength = contentLength
    self.infoURL = infoURL
    self.isInformationOnlyUpdate = isInformationOnlyUpdate
    self.title = title
    self.dateString = dateString
    self.date = date
    self.releaseNotesURL = releaseNotesURL
    self.itemDescription = itemDescription
    self.minimumSystemVersion = minimumSystemVersion
    self.maximumSystemVersion = maximumSystemVersion
    self.installationType = installationType
    self.phasedRolloutInterval = phasedRolloutInterval
    self.propertiesDictionary = propertiesDictionary
  }

  public let versionString: String
  public let displayVersionString: String?
  public let fileURL: URL?
  public let contentLength: UInt64
  public let infoURL: URL?
  public let isInformationOnlyUpdate: Bool
  public let title: String?
  public let dateString: String?
  public let date: Date?
  public let releaseNotesURL: URL?
  public let itemDescription: String?
  public let minimumSystemVersion: String?
  public let maximumSystemVersion: String?
  public let installationType: String?
  public let phasedRolloutInterval: NSNumber?

  public let propertiesDictionary: [AnyHashable: AnyHashable]


}
