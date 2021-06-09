//
//  File.swift
//  
//
//  Created by Till Hainbach on 09.06.21.
//

import Foundation

/// A model for sparkle settings that are relevant for the user.
///
/// This does not 1-to-1 correspond to Sparkle's `SPUUpdaterSettings` but is rather
/// an opinionated selections of settings that might be of interest to user's of an application.
public struct SUUpdaterUserSettings: Equatable {

  /// Enable or Disable automatic update checks.
  public var automaticallyCheckForUpdates: Bool

  /// Set the interval for which updates are checked.
  public var updateInterval: SUUpdateIntervals

  /// Enable or Disable automatic downloading and installation of updates.
  public var automaticallyDownloadUpdates: Bool

  /// Allow sending of anonymous system profile data.
  public var sendSystemProfile: Bool

  /// Initialize SUUpdaterUserSettings
  public init(
    automaticallyCheckForUpdates: Bool = true,
    updateInterval: SUUpdateIntervals = .daily,
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
public enum SUUpdateIntervals: String, CaseIterable, Identifiable, Equatable {
  case daily = "Daily"
  case weekly = "Weekly"
  case biweekly = "Biweekly"
  case monthly = "Monthly"

  /// The id for each case.
  public var id: Self {
    return self
  }
}

extension SUUpdateIntervals {
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

  public init(from timeInterval: TimeInterval) {
    self = timeInterval <= Self.day
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
