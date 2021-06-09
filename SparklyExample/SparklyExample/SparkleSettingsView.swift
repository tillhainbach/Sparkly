//
//  SparkleSettingsView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 09.06.21.
//
import Combine
import SUUpdaterClient
import SwiftUI

/// The view model that drives a`SparkleSettingsView`.
public final class SparkleSettingsViewModel: ObservableObject {

  /// The published `updaterSettings`.
  @Published public var updaterSettings: SUUpdaterUserSettings

  private var cancellable: AnyCancellable?

  /// Initialize `SparkleSettingsViewModel`
  /// - Parameter updaterSettings: The SUUpdaterUserSettings,
  /// - Parameter onSettingsChanged: Callback to send new settings to the updater client.
  public init(
    updaterSettings: SUUpdaterUserSettings,
    onSettingsChanged: @escaping (SUUpdaterUserSettings) -> Void
  ) {
    self.updaterSettings = updaterSettings
    cancellable = $updaterSettings.sink(receiveValue: onSettingsChanged)
  }

}

/// A View to set user-specific Sparkle settings.
public struct SparkleSettingsView: View {

  @ObservedObject var viewModel: SparkleSettingsViewModel

  /// The body of the settings view.
  public var body: some View {

    Form {
      VStack(alignment: .leading) {
        Section(
          header: Text("Check for Updates"),
          footer: Text("Choose if updates should be checked for automatically")
            + Text("and specify the interval")
        ) {

          Toggle(
            "Automatically check for updates",
            isOn: $viewModel.updaterSettings.automaticallyCheckForUpdates
          )

          if viewModel.updaterSettings.automaticallyCheckForUpdates {
            Picker("Update interval", selection: $viewModel.updaterSettings.updateInterval) {
              ForEach(SUUpdateInterval.allCases) {
                Text($0.rawValue)
              }
            }
            .frame(width: 300)
          }
        }

        Section {
          Toggle(
            "Automatically download Updates",
            isOn: $viewModel.updaterSettings.automaticallyDownloadUpdates
          )
        }

        Section {
          Toggle("Send System profile", isOn: $viewModel.updaterSettings.sendSystemProfile)
        }
      }
    }
    .padding()
    .frame(minWidth: 300, minHeight: 300, alignment: .topLeading)
  }
}

struct SparkleSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SparkleSettingsView(
      viewModel: SparkleSettingsViewModel(
        updaterSettings: SUUpdaterUserSettings(),
        onSettingsChanged: { _ in }
      )
    )
  }
}