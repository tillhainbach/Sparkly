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
  @Published var downloadData: DownloadData?
  @Published var updateState: UpdateCheckState?

  var state: UserUpdateState?
  private let send: (UserUpdateState.Choice) -> Void
  let cancelUpdate: () -> Void

  private var cancellable: AnyCancellable?

  init(
    updateEventPublisher: AnyPublisher<UpdaterClient.Event, Never>,
    cancelUpdate: @escaping () -> Void,
    send: @escaping (UserUpdateState.Choice) -> Void
  ) {
    self.cancelUpdate = cancelUpdate
    self.send = send
    self.cancellable = updateEventPublisher.removeDuplicates()
      .sink { [weak self] in
        self?.handleEvent(event: $0)
      }
  }

  func reply(_ choice: UserUpdateState.Choice) {
    switch self.updateState {
    case .found(_, _), .readyToRelaunch:
      self.send(choice)

    default:
      break
    }
  }

  private func handleEvent(event: UpdaterClient.Event) {
    switch event {
    case .showUpdateReleaseNotes(let downloadData):
      self.downloadData = downloadData

    case .updateCheck(let state):
      self.updateState = state

    default:
      break
    }
  }

  func readyToInstallTapped() {
    NSApplication.shared.keyWindow?.close()
    self.reply(.install)
  }
}

struct BasicStatusView<P, B>: View where P: View, B: View {

  let status: String
  let progress: () -> P
  let button: () -> B

  init(
    status: String,
    progress: @escaping () -> P,
    button: @escaping () -> B
  ) {
    self.status = status
    self.progress = progress
    self.button = button
  }

  var body: some View {
    HStack(alignment: .top) {
      Image(systemName: "arrow.down.app.fill")
        .resizable()
        .frame(width: 40, height: 40)
        .padding(.trailing)
      VStack(alignment: .leading) {
        Text(status)
          .font(.headline)
        progress()
        HStack {
          Spacer()
          self.button()
        }
      }
    }
    .frame(width: 250, height: 100)
  }
}

struct UpdateView: View {
  @ObservedObject var viewModel: UpdateViewModel

  var body: some View {
    Group {
      switch viewModel.updateState {
      case .checking:
        BasicStatusView(
          status: "Checking for Updates",
          progress: { ProgressView(value: 0.0, total: 0.0) },
          button: { Button("Cancel", action: viewModel.cancelUpdate) }
        )

      case .found(let update, _):
        FoundUpdateView(
          downloadData: $viewModel.downloadData,
          update: update,
          skipUpdate: { viewModel.reply(.skip) },
          remindMeLater: { viewModel.reply(.dismiss) },
          installUpdate: { viewModel.reply(.install) }
        )

      case .downloading(let total, let completed):
        BasicStatusView(
          status: "Update in flight",
          progress: { ProgressView(value: completed, total: total) },
          button: { Button("Cancel", action: viewModel.cancelUpdate) }
        )

      case .extracting(let completed):
        BasicStatusView(
          status: "Update Extracting",
          progress: {
            ProgressView(
              value: completed,
              total: completed == 0.0 ? 0.0 : 1.0
            )
          },
          button: { Button("Cancel", action: viewModel.cancelUpdate) }
        )

      case .installing:
        BasicStatusView(
          status: "Installing...",
          progress: { ProgressView(value: 0, total: 0) },
          button: { Button("Cancel", action: noop) }
        )

      case .readyToRelaunch:
        BasicStatusView(
          status: "Ready to install",
          progress: { ProgressView(value: 1, total: 1) },
          button: { Button("Install and Relaunch", action: viewModel.readyToInstallTapped) }
        )

      case .none:
        EmptyView()
      }
    }
    .padding()
  }
}

struct UpdateView_Previews: PreviewProvider {
  static func defaultViewModel() -> UpdateViewModel {
    UpdateViewModel(
      updateEventPublisher: Empty().eraseToAnyPublisher(),
      cancelUpdate: noop,
      send: noop(_:)
    )
  }

  static let initiatedViewModel = defaultViewModel()

  static var foundViewModel: UpdateViewModel {
    let viewModel = defaultViewModel()
    viewModel.updateState = .found(.mock, state: .init(stage: .installing, userInitiated: false))
    return viewModel
  }

  static var inFlightViewModel: UpdateViewModel {
    let viewModel = defaultViewModel()
    viewModel.updateState = .downloading(total: 0, completed: 0)
    return viewModel
  }

  static var extractingViewModel: UpdateViewModel {
    let viewModel = defaultViewModel()
    viewModel.updateState = .extracting(completed: 0.0)
    return viewModel
  }

  static var readyToInstallViewModel: UpdateViewModel {
    let viewModel = defaultViewModel()
    viewModel.updateState = .readyToRelaunch
    return viewModel
  }

  static var previews: some View {
    UpdateView(viewModel: initiatedViewModel)
    UpdateView(viewModel: foundViewModel)
    UpdateView(viewModel: inFlightViewModel)
    UpdateView(viewModel: extractingViewModel)
    UpdateView(viewModel: readyToInstallViewModel)
  }
}