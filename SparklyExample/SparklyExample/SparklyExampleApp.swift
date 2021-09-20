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
  @Published var updateCheckInProgress = false
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

        case .willScheduleUpdateCheckAfter(let delay):
          print("Next Update Check scheduled at \(Date().addingTimeInterval(delay).toString())")

        case .updateCheckInitiated(_):
          self?.updateCheckInProgress = true

        case .dismissUpdateInstallation:
          self?.updateCheckInProgress = false

        case .showUpdateReleaseNotes(_),
          .updateFound(_, _, _),
          .didFinishLoading(_),
          .didFindValidUpdate(_):
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
  @StateObject private var appViewModel = liveUpdater

  var body: some Scene {
    WindowGroup {
      if self.appViewModel.updateCheckInProgress {
        UpdateView(
          viewModel: .init(
            automaticallyCheckForUpdates: Binding(
              get: {
                let settings = SUUpdaterUserSettings.init(from: UserDefaults.standard)
                return settings.automaticallyCheckForUpdates
              },
              set: {
                var settings = SUUpdaterUserSettings.init(from: UserDefaults.standard)
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

extension SparklyExampleApp {
  static let standardUpdater = AppViewModel(
    updaterClient: .standard(hostBundle: .main, applicationBundle: .main),
    applicationDidFinishLaunching: NotificationCenter.default
      .publisher(for: NSApplication.didFinishLaunchingNotification)
      .eraseToAnyPublisher()
  )
}

extension SparklyExampleApp {
  static let liveUpdater = AppViewModel(
    updaterClient: .live(
      hostBundle: .main,
      applicationBundle: .main,
      developerSettings: .noop
    ),
    applicationDidFinishLaunching: NotificationCenter.default
      .publisher(for: NSApplication.didFinishLaunchingNotification)
      .eraseToAnyPublisher()
  )
}

extension SUDeveloperSettings {
  static let noop: Self = .init(
    allowedSystemProfileKeys: { return [] },
    feedParameters: { _ in [[:]] },
    feedURLString: { return nil },
    handleAppcast: { $0 },
    retrieveDecryptionPassword: { return nil },
    retrieveBestValidUpdate: { _ in return nil },
    shouldAllowInstallerInteraction: { _ in false },
    updaterMayCheckForUpdates: { return true },
    compareVersions: nil,
    updaterShouldPostponeRelaunchForUpdate: { _, _ in return true },
    updaterWillInstallUpdateOnQuit: { _, _ in return true },
    updaterShouldDownloadReleaseNotes: { return true },
    updaterShouldPromptForPermissionToCheckForUpdates: { return true },
    updaterShouldRelaunchApplication: { return true }
  )
}
