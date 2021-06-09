//
//  SparklyExampleApp.swift
//  SparklyExample
//
//  Created by Till Hainbach on 03.06.21.
//
import Combine
import SUUpdaterClient
import SUUpdaterClientLive
import SparklyCommands
import SwiftUI

final class AppViewModel: ObservableObject {

  @Published var canCheckForUpdates = false
  let updaterClient: SUUpdaterClient
  var cancellables: Set<AnyCancellable> = []

  init(
    updaterClient: SUUpdaterClient,
    applicationDidFinishLaunching: AnyPublisher<Notification, Never>
  ) {
    self.updaterClient = updaterClient
    connectToUpdater()
    applicationDidFinishLaunching
      .sink { [weak self] notification in

        // Just to be super sure
        if notification.name == NSApplication.didFinishLaunchingNotification {
          self?.updaterClient.send(.startUpdater)
        }
      }
      .store(in: &cancellables)

  }

  func checkForUpdates() {
    guard canCheckForUpdates else { return }
    updaterClient.send(.checkForUpdates)
  }

  func updateSettings(_ settings: SUUpdaterUserSettings) {
    updaterClient.send(.updateUserSettings(settings))
  }

  private func connectToUpdater() {
    updaterClient.updaterEventPublisher
      .sink { [weak self] event in
        switch event {
        case .canCheckForUpdates(let canCheckForUpdates):
          self?.canCheckForUpdates = canCheckForUpdates
        default:

          break
        }
      }
      .store(in: &cancellables)
  }
}

@main
struct SparklyExampleApp: App {
  @StateObject private var appViewModel = AppViewModel(
    updaterClient: .standard(hostBundle: .main, applicationBundle: .main),
    applicationDidFinishLaunching: NotificationCenter.default
      .publisher(for: NSApplication.didFinishLaunchingNotification)
      .eraseToAnyPublisher()
  )

  var body: some Scene {
    WindowGroup {
      ContentView(viewModel: ViewModel())
    }
    Settings {
      SparkleSettingsView(
        viewModel: SparkleSettingsViewModel(
          updaterSettings: SUUpdaterUserSettings.init(from: UserDefaults.standard),
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
