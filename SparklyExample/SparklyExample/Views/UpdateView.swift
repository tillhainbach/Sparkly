//
//  UpdateView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 18.09.21.
//

import Combine
import SparklyClient
import SwiftUI

struct ProgressState {
  var done: Double
  let total: Double

  init(total: Double, done: Double = 0.0) {
    self.total = total
    self.done = done
  }
}

enum UpdateState {
  case initiated
  case found(AppcastItem)
  case inFlight(total: Double, completed: Double)
  case extracting(completed: Double)
  case installing
  case readyToInstall
}

class UpdateViewModel: ObservableObject {
  @Binding var automaticallyCheckForUpdates: Bool
  @Published var downloadData: DownloadData?
  @Published var updateState: UpdateState = .initiated
  //@Published var progress: ProgressState?

  var state: UserUpdateState?
  var reply: (UserUpdateState.Choice) -> Void
  let cancelUpdate: () -> Void

  private var cancellable: AnyCancellable?

  init(
    automaticallyCheckForUpdates: Binding<Bool>,
    updateEventPublisher: AnyPublisher<UpdaterClient.Event, Never>,
    cancelUpdate: @escaping () -> Void,
    send: @escaping (UserUpdateState.Choice) -> Void
  ) {
    self._automaticallyCheckForUpdates = automaticallyCheckForUpdates
    self.cancelUpdate = cancelUpdate
    self.reply = send
    self.cancellable = updateEventPublisher.removeDuplicates()
      .sink { [weak self] in
        self?.handleEvent(event: $0)
      }
  }

  private func handleEvent(event: UpdaterClient.Event) {
    switch event {
    case .showUpdateReleaseNotes(let downloadData):
      self.downloadData = downloadData

    case .updateCheckInitiated:
      self.updateState = .initiated

    case .updateFound(let update, let state):
      self.updateState = .found(update)
      self.state = state

    case .downloadInFlight(let total, let completed):
      self.updateState = .inFlight(total: total, completed: completed)

    case .extractingUpdate(let completed):
      self.updateState = .extracting(completed: completed)

    case .installing:
      self.updateState = .installing

    case .readyToRelaunch:
      self.updateState = .readyToInstall

    default:
      break
    }
  }
}

struct BasicStatusView<Progress, Button>: View where Progress: View, Button: View {

  let status: String
  let progress: () -> Progress
  let button: () -> Button

  init(
    status: String,
    progress: @escaping () -> Progress,
    button: @escaping () -> Button
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
      case .initiated:
        BasicStatusView(
          status: "Checking for Updates",
          progress: { ProgressView(value: 0.0, total: 0.0) },
          button: { Button("Cancel", action: viewModel.cancelUpdate) }
        )

      case .found(let update):
        FoundUpdateView(
          automaticallyCheckForUpdates: $viewModel.automaticallyCheckForUpdates,
          downloadData: $viewModel.downloadData,
          update: update,
          skipUpdate: { viewModel.reply(.skip) },
          remindMeLater: { viewModel.reply(.dismiss) },
          installUpdate: { viewModel.reply(.install) }
        )

      case .inFlight(let total, let completed):
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
          status: "Ready to install",
          progress: { ProgressView(value: 0, total: 0) },
          button: { Button("Cancel", action: noop) }
        )

      case .readyToInstall:
        BasicStatusView(
          status: "Ready to install",
          progress: { ProgressView(value: 1, total: 1) },
          button: { Button("Install and Relaunch", action: { viewModel.reply(.install) }) }
        )

      }
    }
    .padding()
  }
}

struct UpdateView_Previews: PreviewProvider {
  static func defaultViewModel() -> UpdateViewModel {
    UpdateViewModel(
      automaticallyCheckForUpdates: .constant(true),
      updateEventPublisher: Empty().eraseToAnyPublisher(),
      cancelUpdate: noop,
      send: noop(_:)
    )
  }

  static let initiatedViewModel = defaultViewModel()

  static var foundViewModel: UpdateViewModel {
    let viewModel = defaultViewModel()
    viewModel.updateState = .found(.mock)
    return viewModel
  }

  static var inFlightViewModel: UpdateViewModel {
    let viewModel = defaultViewModel()
    viewModel.updateState = .inFlight(total: 0, completed: 0)
    return viewModel
  }

  static var extractingViewModel: UpdateViewModel {
    let viewModel = defaultViewModel()
    viewModel.updateState = .extracting(completed: 0.0)
    return viewModel
  }

  static var readyToInstallViewModel: UpdateViewModel {
    let viewModel = defaultViewModel()
    viewModel.updateState = .readyToInstall
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
