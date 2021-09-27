//
//  SparklyExampleApp.swift
//  SparklyExample
//
//  Created by Till Hainbach on 03.06.21.
//

import Combine
import Sparkly
import SwiftUI

@main
struct SparklyExampleApp: App {
  // You can switch between pre-configured instances `liveUpdater` and `standardUpdater`
  // for testing purposes.
  @StateObject private var appViewModel = liveUpdater

  var body: some Scene {
    WindowGroup {
      Group {
        if self.appViewModel.updateCheckInProgress {
          UpdateView(
            viewModel: .init(
              automaticallyCheckForUpdates: appViewModel.bindingForSetting(
                on: \.automaticallyCheckForUpdates
              ),
              updateEventPublisher: appViewModel.updaterClient.updaterEventPublisher,
              cancelUpdate: appViewModel.cancel,
              send: { appViewModel.updaterClient.send(.reply($0)) }
            )
          )
        } else {
          ContentView(viewModel: ViewModel())
        }
      }
      .alert(item: $appViewModel.errorAlert) { errorAlert in
        Alert(
          title: Text(errorAlert.title),
          message: Text(errorAlert.message),
          dismissButton: .default(Text("Ok"), action: errorAlert.dismiss)
        )
      }
    }
    Settings {
      SettingsView(
        viewModel: SparkleSettingsViewModel(
          updaterSettings: .init(from: UserDefaults.standard),
          onSettingsChanged: appViewModel.updateSettings(_:)
        )
      )
    }
    .commands {
      UpdateCommand(
        viewModel: UpdateCommandViewModel(
          canCheckForUpdates: appViewModel.$canCheckForUpdates.eraseToAnyPublisher(),
          checkForUpdates: appViewModel.checkForUpdates
        )
      )
    }
  }
}

extension SparklyExampleApp {
  static let applicationDidFinishLaunchingPublisher = NotificationCenter.default
    .publisher(for: NSApplication.didFinishLaunchingNotification)
    .eraseToAnyPublisher()
}

extension SparklyExampleApp {
  static let standardUpdater = AppViewModel(
    updaterClient: .standard(hostBundle: .main, applicationBundle: .main),
    applicationDidFinishLaunching: applicationDidFinishLaunchingPublisher
  )
}

extension SparklyExampleApp {
  static let liveUpdater = AppViewModel(
    updaterClient: .live(hostBundle: .main, applicationBundle: .main),
    applicationDidFinishLaunching: applicationDidFinishLaunchingPublisher
  )
}
