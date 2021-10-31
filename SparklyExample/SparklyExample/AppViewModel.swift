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
}

final class AppViewModel: ObservableObject {

  @Published var canCheckForUpdates = false
  @Published var errorAlert: ErrorAlert? = nil
  let updaterClient: UpdaterClient
  var updateViewModel: UpdateViewModel?
  lazy var updatePermissionViewModel = UpdatePermissionViewModel(
    response: self.sendPermission(automaticallyCheckForUpdate:sendSystemProfile:)
  )

  var cancellables: Set<AnyCancellable> = []
  var currentWindow: Window?
  let windowManager: WindowManager

  init(
    updaterClient: UpdaterClient,
    applicationDidFinishLaunching: AnyPublisher<Notification, Never>,
    windowManager: WindowManager = .live
  ) {
    self.windowManager = windowManager
    self.updaterClient = updaterClient
    self.updaterClient.updaterEventPublisher
      .sink { [weak self] in self?.handle(event: $0) }
      .store(in: &cancellables)

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

  func cancel() {
    updaterClient.send(.cancel)
  }

  func alertDismissButtonTapped() {
    self.updaterClient.send(.cancel)
    self.errorAlert = nil
    if let currentWindow = currentWindow {
      closeWindow(currentWindow)
    }

  }

  func sendPermission(automaticallyCheckForUpdate: Bool, sendSystemProfile: Bool) {
    self.updaterClient.send(
      .setPermission(
        automaticUpdateChecks: automaticallyCheckForUpdate,
        sendSystemProfile: sendSystemProfile
      )
    )
    closeWindow(.updatePermissionRequest)
  }

  private func handle(event: UpdaterClient.Event) {
    switch event {
    case .canCheckForUpdates(let canCheckForUpdates):
      self.canCheckForUpdates = canCheckForUpdates

    case .dismissUpdateInstallation:
      self.closeWindow(.updateCheck)
      self.updateViewModel = nil

    case .failure(let error):
      self.errorAlert = .init(
        title: "Update Error",
        message: error.localizedDescription
      )

    case .focusUpdate:
      focusCurrentWindow()

    case .permissionRequest:
      self.openWindow(.updatePermissionRequest)

    case .showUpdateReleaseNotes(let data):
      self.updateViewModel?.downloadData = data

    case .terminationSignal:
      break

    case .updateCheck(.checking):
      self.updateViewModel = .init(
        updateState: .checking,
        cancelUpdate: self.cancel,
        send: { self.updaterClient.send(.reply($0)) }
      )
      self.openWindow(.updateCheck)

    case .updateCheck(let newState):
      self.updateViewModel?.updateState = newState

    case .updateInstalledAndRelaunched:
      self.errorAlert = .init(
        title: "Update Successfully Installed",
        message: "New update was installed!"
      )
    }

  }

  private func closeWindow(_ window: Window) {
    windowManager.closeWindow(window.title)
    currentWindow = nil
  }

  private func openWindow(_ window: Window) {
    currentWindow = window
    windowManager.openWindow(window.rawValue)
  }

  private func focusCurrentWindow() {
    guard let currentWindow = currentWindow else {
      return
    }

    windowManager.openWindow(currentWindow.rawValue)
  }

}

extension AppViewModel {
  static let applicationDidFinishLaunchingPublisher = NotificationCenter.default
    .publisher(for: NSApplication.didFinishLaunchingNotification)
    .eraseToAnyPublisher()
}

#if DEBUG
extension AppViewModel {
  static let requestForPermission = AppViewModel(
    updaterClient: .requestForPermission,
    applicationDidFinishLaunching: applicationDidFinishLaunchingPublisher
  )
}

extension AppViewModel {
  static let failsToCheckForUpdates = AppViewModel(
    updaterClient: .failsToCheckForUpdates,
    applicationDidFinishLaunching: applicationDidFinishLaunchingPublisher
  )
}
#endif
