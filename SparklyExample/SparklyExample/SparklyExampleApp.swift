//
//  SparklyExampleApp.swift
//  SparklyExample
//
//  Created by Till Hainbach on 03.06.21.
//
import Combine
import Sparkly
import SwiftUI

final class AppViewModel: ObservableObject {

  @Published var canCheckForUpdates = false
  @Published var updateCheckInProgress = false
  let updaterClient: UpdaterClient
  var cancellables: Set<AnyCancellable> = []

  init(
    updaterClient: UpdaterClient,
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

    // update http headers to work with GitHub
    updaterClient.send(.setHTTPHeaders(["Accept": "application/octet-stream"]))

  }

  func checkForUpdates() {
    guard canCheckForUpdates else { return }
    updaterClient.send(.checkForUpdates)
  }

  func updateSettings(_ settings: UpdaterUserSettings) {
    updaterClient.send(.updateUserSettings(settings))
  }

  private func connectToUpdater() {
    updaterClient.updaterEventPublisher
      .sink { [weak self] event in
        switch event {

        case .canCheckForUpdates(let canCheckForUpdates):
          self?.canCheckForUpdates = canCheckForUpdates

        case .updateCheckInitiated(_):
          self?.updateCheckInProgress = true

        case .dismissUpdateInstallation:
          self?.updateCheckInProgress = false

        case .showUpdateReleaseNotes(_),
          .updateFound(_, _, _),
          .downloadInitiated(_):
          print("\(event)")

        default:
          fatalError("Received unhandled event \(event) ")
          break
        }
      }
      .store(in: &cancellables)
  }
}

@main
struct SparklyExampleApp: App {
  // You can switch between pre-configured instances `liveUpdater` and `standardUpdater`
  // for testing purposes.
  @StateObject private var appViewModel = liveUpdater

  var body: some Scene {
    WindowGroup {
      if self.appViewModel.updateCheckInProgress {
        UpdateView(
          viewModel: .init(
            automaticallyCheckForUpdates: Binding(
              get: {
                let settings = UpdaterUserSettings.init(from: UserDefaults.standard)
                return settings.automaticallyCheckForUpdates
              },
              set: {
                var settings = UpdaterUserSettings.init(from: UserDefaults.standard)
                settings.automaticallyCheckForUpdates = $0
                appViewModel.updateSettings(settings)
              }
            ),
            updateEventPublisher: appViewModel.updaterClient.updaterEventPublisher
          )
        )
      } else {
        ContentView(viewModel: ViewModel())
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
    updaterClient: .live(
      hostBundle: .main,
      applicationBundle: .main
    ),
    applicationDidFinishLaunching: applicationDidFinishLaunchingPublisher
  )
}
