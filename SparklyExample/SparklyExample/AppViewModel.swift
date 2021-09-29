//
//  AppViewModel.swift
//  SparklyExample
//
//  Created by Till Hainbach on 27.09.21.
//

import Combine
import SparklyClient
import SwiftUI

struct ErrorAlert: Identifiable {
  let id = UUID()
  let title: String
  let message: String
  let dismiss: () -> Void
}

enum Window: String, CaseIterable {
  case main = "main"
  case updatePermissionRequest = "update-permission-request"
  case updateCheck = "update-check"
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
            self?.newWindow(.updateCheck)
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

        case .permissionRequest:
          print("Received Permission Request!")
          self?.newWindow(.updatePermissionRequest)
        }
      }
      .store(in: &cancellables)
  }

  private func newWindow(_ window: Window) {
    guard let urlScheme = Bundle.main.urlScheme else { return }
    if let url = URL(string: "\(urlScheme)://\(window.rawValue)") {
      print("Will open Window \(url.description)")
      NSWorkspace.shared.open(url)
    }
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

  func sendPermission(automaticallyCheckForUpdate: Bool, sendSystemProfile: Bool) {
    self.updaterClient.send(
      .setPermission(
        automaticUpdateChecks: automaticallyCheckForUpdate,
        sendSystemProfile: sendSystemProfile
      )
    )
    newWindow(.main)
  }
}
