//
//  SparklyExampleApp.swift
//  SparklyExample
//
//  Created by Till Hainbach on 03.06.21.
//

import Combine
import Sparkly
import SwiftUI

struct ErrorAlert: Identifiable {
  let id = UUID()
  let title: String
  let message: String
  let dismiss: () -> Void
}

final class AppViewModel: ObservableObject {

  @Published var canCheckForUpdates = false
  @Published var updateCheckInProgress = false
  @Published var errorAlert: ErrorAlert? = nil
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

  func updateSettings(_ settings: UpdaterSettings) {
    updaterClient.send(.updateUserSettings(settings))
  }

  func cancel() {
    updaterClient.send(.cancel)
  }

  private func connectToUpdater() {
    updaterClient.updaterEventPublisher
      .sink { [weak self] event in
        switch event {

        case .canCheckForUpdates(let canCheckForUpdates):
          self?.canCheckForUpdates = canCheckForUpdates

        case .updateCheck(let state):
          if state == .checking {
            self?.updateCheckInProgress = true
          }

        case .dismissUpdateInstallation, .terminationSignal:
          self?.updateCheckInProgress = false

        case .showUpdateReleaseNotes:
          break

        case .failure(let error):
          self?.errorAlert = .init(
            title: "Update Error",
            message: error.localizedDescription,
            dismiss: { self?.updaterClient.send(.cancel) }
          )

        }
      }
      .store(in: &cancellables)
  }

  func bindingForSetting<Value>(
    on keyPath: WritableKeyPath<UpdaterSettings, Value>
  ) -> Binding<Value> {
    Binding(
      get: {
        let settings = UpdaterSettings.init(from: UserDefaults.standard)
        return settings[keyPath: keyPath]
      },
      set: { [weak self] in
        var settings = UpdaterSettings.init(from: UserDefaults.standard)
        settings[keyPath: keyPath] = $0
        self?.updateSettings(settings)
      }
    )
  }
}

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
