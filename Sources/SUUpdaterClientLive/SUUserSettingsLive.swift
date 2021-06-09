//
//  File.swift
//  
//
//  Created by Till Hainbach on 09.06.21.
//

import Foundation
import SUUpdaterClient

extension SUUpdaterUserSettings {
  public init(from userDefault: UserDefaults) {
    self.init(
      automaticallyCheckForUpdates: userDefault.bool(
        forKey: UserDefaultKeys.automaticallyDownloadUpdates.rawValue
      ),
      updateInterval: .init(
        from: userDefault.double(forKey: UserDefaultKeys.updateInterval.rawValue)
      ),
      automaticallyDownloadUpdates: userDefault.bool(
        forKey: UserDefaultKeys.automaticallyDownloadUpdates.rawValue
      ),
      sendSystemProfile: userDefault.bool(forKey: UserDefaultKeys.sendSystemProfile.rawValue)
    )
  }

  private enum UserDefaultKeys: String {
    case automaticallyCheckForUpdatesKey = "SUEnableAutomaticChecks"
    case updateInterval = "SUScheduledCheckInterval"
    case automaticallyDownloadUpdates = "SUAutomaticallyUpdate"
    case sendSystemProfile = "SUSendProfileInfo"
  }

}
