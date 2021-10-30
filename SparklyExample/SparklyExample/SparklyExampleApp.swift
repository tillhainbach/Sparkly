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
  @StateObject private var appViewModel: AppViewModel = .liveUpdater

  var body: some Scene {
    WindowGroup {
      ContentView(viewModel: ViewModel())
        .alert(item: $appViewModel.errorAlert) { errorAlert in
          Alert(
            title: Text(errorAlert.title),
            message: Text(errorAlert.message),
            dismissButton: .default(Text("Ok"), action: appViewModel.alertDismissButtonTapped)
          )
        }
    }

    WindowGroup(Window.updateCheck.title) {
      if let updateViewModel = appViewModel.updateViewModel {
        UpdateView(viewModel: updateViewModel)
      }
    }
    .handlesExternalEvents(matching: Set(arrayLiteral: Window.updateCheck.rawValue))

    WindowGroup(Window.updatePermissionRequest.title) {
      UpdatePermissionView(viewModel: appViewModel.updatePermissionViewModel)
    }
    .handlesExternalEvents(matching: Set(arrayLiteral: Window.updatePermissionRequest.rawValue))

    Settings { SettingsView() }
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

extension AppViewModel {
  static let standardUpdater = AppViewModel(
    updaterClient: .standard(hostBundle: .main, applicationBundle: .main),
    applicationDidFinishLaunching: applicationDidFinishLaunchingPublisher
  )
}

extension AppViewModel {
  static let liveUpdater = AppViewModel(
    updaterClient: .live(hostBundle: .main, applicationBundle: .main),
    applicationDidFinishLaunching: applicationDidFinishLaunchingPublisher
  )
}
