//
//  SparklyExampleTests.swift
//  SparklyExampleTests
//
//  Created by Till Hainbach on 03.06.21.
//
import Combine
import SUUpdaterClient
import XCTest

@testable import SparklyExample

class SettingsViewTests: XCTestCase {

  func testDidCallOnSettingsChanged() throws {
    let startSettings = SUUpdaterUserSettings(
      automaticallyCheckForUpdates: false,
      updateInterval: .daily,
      automaticallyDownloadUpdates: false,
      sendSystemProfile: true
    )
    let targetSettings = SUUpdaterUserSettings(
      automaticallyCheckForUpdates: true,
      updateInterval: .weekly,
      automaticallyDownloadUpdates: true,
      sendSystemProfile: true
    )

    var newSettings: SUUpdaterUserSettings? = nil

    let settingsViewModel = SparkleSettingsViewModel(
      updaterSettings: .init(
        automaticallyCheckForUpdates: false,
        updateInterval: .daily,
        automaticallyDownloadUpdates: false,
        sendSystemProfile: true
      ),
      onSettingsChanged: { newSettings = $0 }
    )

    XCTAssertEqual(settingsViewModel.updaterSettings, startSettings)

    settingsViewModel.updaterSettings = targetSettings

    XCTAssertEqual(newSettings, targetSettings)

  }

}
