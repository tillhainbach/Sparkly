//
//  File.swift
//  
//
//  Created by Till Hainbach on 09.06.21.
//

import Sparkle
import SUUpdaterClient

extension SPUUpdater {
  func updateSettings(from userSettings: SUUpdaterUserSettings) {
    self.automaticallyChecksForUpdates = userSettings.automaticallyCheckForUpdates
    self.automaticallyDownloadsUpdates = userSettings.automaticallyDownloadUpdates
    self.sendsSystemProfile = userSettings.sendSystemProfile
    self.updateCheckInterval = userSettings.updateInterval.toTimeInterval()
  }
}