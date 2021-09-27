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
              automaticallyCheckForUpdates: Binding(
                get: {
                  let settings = UpdaterSettings.init(from: UserDefaults.standard)
                  return settings.automaticallyCheckForUpdates
                },
                set: {
                  var settings = UpdaterSettings.init(from: UserDefaults.standard)
                  settings.automaticallyCheckForUpdates = $0
                  appViewModel.updateSettings(settings)
                }
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
    updaterClient: .live(
      hostBundle: .main,
      applicationBundle: .main
    ),
    applicationDidFinishLaunching: applicationDidFinishLaunchingPublisher
  )
}

extension SparklyExampleApp {
  static let mockUpdater = AppViewModel(
    updaterClient: .appMock,
    applicationDidFinishLaunching: applicationDidFinishLaunchingPublisher
  )
}

extension UpdaterClient {
  static var appMock: Self {
    let mockUpdater = PassthroughSubject<UpdaterClient.Action, Never>()
    let publisher = PassthroughSubject<UpdaterClient.Event, Never>()
    var cancellables: Set<AnyCancellable> = []

    mockUpdater
      .sink { action in
        switch action {
        case .checkForUpdates:
          publisher.send(.canCheckForUpdates(false))
          publisher.send(.updateCheck(.checking))
          DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(1))) {
            publisher.send(.updateCheck(.extracting(completed: 0.0)))
          }
          (0...100)
            .forEach { i in
              DispatchQueue.main.asyncAfter(
                deadline: .now().advanced(by: .milliseconds(1020 + i * 100))
              ) {
                publisher.send(.updateCheck(.extracting(completed: Double(i) / 100.0)))
              }
            }

        case .startUpdater:
          publisher.send(.canCheckForUpdates(true))

        case .updateUserSettings(_):
          break

        case .setHTTPHeaders(_):
          break

        case .cancel:
          publisher.send(.dismissUpdateInstallation)
          publisher.send(.canCheckForUpdates(true))
          break

        case .reply(let response):
          switch response {
          case .skip:
            publisher.send(.dismissUpdateInstallation)
            mockUpdater.send(.cancel)

          case .install:
            break

          case .dismiss:
            publisher.send(.dismissUpdateInstallation)
            mockUpdater.send(.cancel)

          }

          break
        }

      }
      .store(in: &cancellables)

    return .init(
      send: mockUpdater.send(_:),
      updaterEventPublisher: publisher.eraseToAnyPublisher(),
      cancellables: cancellables
    )
  }
}
