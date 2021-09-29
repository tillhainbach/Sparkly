//
//  SparkleSettingsView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 09.06.21.
//
import Combine
import SparklyClient
import SwiftUI

/// A View to set user-specific Sparkle settings.
public struct SettingsView: View {

  @AppStorage(UpdaterSettingsKeys.automaticallyCheckForUpdatesKey.rawValue)
  var automaticallyCheckForUpdates: Bool = false

  @AppStorage(UpdaterSettingsKeys.automaticallyDownloadUpdates.rawValue)
  var automaticallyDownloadUpdates: Bool = false

  @AppStorage(UpdaterSettingsKeys.sendSystemProfile.rawValue)
  var sendSystemProfile: Bool = false

  @AppStorage(UpdaterSettingsKeys.updateInterval.rawValue)
  var updateInterval: UpdateInterval = .daily

  /// The body of the settings view.
  public var body: some View {

    Form {
      VStack(alignment: .leading) {
        Section(
          header: Text("Check for Updates"),
          footer: Text("Choose if updates should be checked for automatically")
            + Text(" and specify the interval")
        ) {

          Toggle(
            "Automatically check for updates",
            isOn: $automaticallyCheckForUpdates
          )

          if automaticallyCheckForUpdates {
            Picker("Update interval", selection: $updateInterval) {
              ForEach(UpdateInterval.allCases) {
                Text($0.rawValue)
              }
            }
            .frame(width: 300)
          }
        }

        Section {
          Toggle(
            "Automatically download Updates",
            isOn: $automaticallyDownloadUpdates
          )
        }

        Section {
          Toggle("Send System profile", isOn: $sendSystemProfile)
        }
      }
    }
    .padding()
    .frame(minWidth: 300, minHeight: 300, alignment: .topLeading)
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
