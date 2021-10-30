//
//  UpdateView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 18.09.21.
//

import Combine
import SparklyClient
import SwiftUI

final class UpdateViewModel: ObservableObject {
  enum Route {
    case status(StatusViewState)
    case found(FoundUpdateViewModel)
  }

  @Published var downloadData: DownloadData?
  @Published var updateState: UpdateCheckState
  var route: Route {
    switch updateState {
    case .checking:
      return .status(.init(status: "Checking for Updates", action: cancel))

    case .downloading(let total, let value):
      return .status(.init(status: "Update in flight", value: value, total: total, action: cancel))

    case .extracting(let completed):
      let total = completed == 0.0 ? 0.0 : 1.0
      return .status(
        .init(status: "Update Extracting", value: completed, total: total, action: cancel)
      )

    case .found(let update, _):
      return .found(.init(update: update, downloadData: downloadData, reply: reply))

    case .installing:
      return .status(.init(status: "Installing...", action: cancel))

    case .readyToRelaunch:
      return .status(
        .init(
          status: "Ready to install",
          buttonLabel: "Install and Relaunch",
          value: 1.0,
          total: 1.0,
          action: { self.reply(.install) }
        )
      )
    }
  }

  private let reply: (UserUpdateState.Choice) -> Void
  private let cancel: () -> Void

  init(
    updateState: UpdateCheckState = .checking,
    cancelUpdate: @escaping () -> Void,
    send: @escaping (UserUpdateState.Choice) -> Void
  ) {
    self.cancel = cancelUpdate
    self.reply = send
    self.updateState = updateState
  }

}

struct UpdateView: View {
  @ObservedObject var viewModel: UpdateViewModel

  var body: some View {
    Group {
      switch viewModel.route {
      case .status(let viewState):
        StatusView(state: viewState)
      case .found(let foundUpdateViewModel):
        FoundUpdateView(viewModel: foundUpdateViewModel)
      }
    }
    .padding()
  }
}

extension UpdateViewModel {
  static func preview(state: UpdateCheckState) -> Self {
    .init(updateState: state, cancelUpdate: noop, send: noop(_:))
  }
}

struct UpdateView_Previews: PreviewProvider {

  static var previews: some View {
    UpdateView(viewModel: .preview(state: .checking))
    UpdateView(viewModel: .preview(state: .found(.mock, state: .mock)))
    UpdateView(viewModel: .preview(state: .downloading(total: 0, completed: 0)))
    UpdateView(viewModel: .preview(state: .extracting(completed: 0.0)))
    UpdateView(viewModel: .preview(state: .readyToRelaunch))
  }
}
