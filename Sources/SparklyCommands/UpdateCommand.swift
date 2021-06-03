//
//  SwiftUIView.swift
//  
//
//  Created by Till Hainbach on 03.06.21.
//

import Combine
import SwiftUI
import SUUpdaterClient

public final class UpdateCommandViewModel: ObservableObject {

  @Published var canCheckForUpdates = false
  let updaterClient: SUUpdaterClient
  var cancellables: AnyCancellable?

  public init(updaterClient: SUUpdaterClient) {
    self.updaterClient = updaterClient

    connectToUpdater()
  }

  func checkForUpdates() {
    updaterClient.send(.checkForUpdates)
  }

  private func connectToUpdater() {
    cancellables = updaterClient.updaterEventPublisher
      .sink(receiveValue: { [weak self] event in
        switch event {
        case let .canCheckForUpdates(canCheckForUpdates):
          self?.canCheckForUpdates = canCheckForUpdates
        }
      })
  }
}

public struct UpdateCommand: Commands {

  @ObservedObject var viewModel: UpdateCommandViewModel

  public init(viewModel: UpdateCommandViewModel) {
    self.viewModel = viewModel
  }

  struct BodyView: View {

    @ObservedObject var viewModel: UpdateCommandViewModel

    var body: some View {
      Button("Check for updates") {
        viewModel.checkForUpdates()
      }
      .disabled(!viewModel.canCheckForUpdates)
      .keyboardShortcut("U", modifiers: .command)
    }
  }

  public var body: some Commands {
    CommandGroup(after: .appInfo) {
      BodyView(viewModel: viewModel)
    }

  }
}
