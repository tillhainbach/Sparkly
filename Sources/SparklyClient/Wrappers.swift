//
//  File.swift
//
//
//  Created by Till Hainbach on 20.09.21.
//

import Foundation

// MARK: - AppcastItem

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

// MARK: - UpdaterSettings

/// A model for sparkle settings that are relevant for the user.
///
/// This does not 1-to-1 correspond to Sparkle's `SPUUpdaterSettings` but is rather
/// an opinionated selections of settings that might be of interest to users of an application.
public struct UpdaterSettings: Equatable {

  /// Enable or Disable automatic update checks.
  public var automaticallyCheckForUpdates: Bool

  /// Set the interval for which updates are checked.
  public var updateInterval: UpdateInterval

  /// Enable or Disable automatic downloading and installation of updates.
  public var automaticallyDownloadUpdates: Bool

  /// Allow sending of anonymous system profile data.
  public var sendSystemProfile: Bool

  /// Initialize SUUpdaterUserSettings.
  public init(
    automaticallyCheckForUpdates: Bool = true,
    updateInterval: UpdateInterval = .daily,
    automaticallyDownloadUpdates: Bool = false,
    sendSystemProfile: Bool = false
  ) {
    self.automaticallyCheckForUpdates = automaticallyCheckForUpdates
    self.updateInterval = updateInterval
    self.automaticallyDownloadUpdates = automaticallyDownloadUpdates
    self.sendSystemProfile = sendSystemProfile
  }
}

/// Preset of fixed update intervals.
public enum UpdateInterval: String, CaseIterable, Identifiable, Equatable {
  case daily = "Daily"
  case weekly = "Weekly"
  case biweekly = "Biweekly"
  case monthly = "Monthly"

  /// The id for each case.
  public var id: Self {
    return self
  }
}

extension UpdateInterval {
  /// Convert SUUpdateInterval to TimeInterval for passing it to the SPUUpdater.
  /// - Returns: the `TimeInterval`each case represents.
  public func toTimeInterval() -> TimeInterval {
    switch self {
    case .daily:
      return Self.day
    case .weekly:
      return Self.week
    case .biweekly:
      return Self.week * 2
    case .monthly:
      return Self.month
    }

  }

  /// Initialize an SUUpdaterInterval from a `TimeInterval`.
  /// - Parameter timeInterval: the `TimeInterval` from which to initialize.
  public init(from timeInterval: TimeInterval) {
    self =
      timeInterval <= Self.day
      ? .daily
      : timeInterval <= Self.week
        ? .weekly
        : timeInterval <= Self.week * 2
          ? .biweekly
          : .monthly
  }

  private static let day: TimeInterval = 60 * 60 * 24
  private static let week: TimeInterval = Self.day * 7
  private static let month: TimeInterval = Self.day * 30  // for simplicity set to every 30 days
}

/// Wrapper for [SPUUserUpdateState](https://github.com/sparkle-project/Sparkle/blob/c6f1cd4e3cbdf4fbd3b12f779dd677775a77f60f/Sparkle/SPUUserUpdateState.h) .
public struct UserUpdateState: Equatable {

  public var stage: Stage
  public var userInitiated: Bool

  /// Initialize UserUpdateState.
  public init(stage: UserUpdateState.Stage, userInitiated: Bool) {
    self.stage = stage
    self.userInitiated = userInitiated
  }

  /// The stage of an update.
  public enum Stage {
    /// The update has not been downloaded.
    case notDownloaded

    /// The update has already been downloaded but not begun installing.
    case downloaded

    /// The update has already been downloaded and began installing in the background.
    case installing
  }

  /// Possible user choices.
  public enum Choice {
    case skip
    case install
    case dismiss
  }

}

/// Wrapper type for `SPUDownloadData`.
public struct DownloadData: Equatable {

  /// See `SPUDownloadDate` for explanation.
  public let data: Data
  /// See `SPUDownloadDate` for explanation.
  public let url: URL
  /// See `SPUDownloadDate` for explanation.
  public let textEncodingName: String?
  /// See `SPUDownloadDate` for explanation.
  public let mimeType: String?

  /// Init DownloadData.
  public init(data: Data, url: URL, textEncodingName: String?, mimeType: String?) {
    self.data = data
    self.url = url
    self.textEncodingName = textEncodingName
    self.mimeType = mimeType
  }
}
