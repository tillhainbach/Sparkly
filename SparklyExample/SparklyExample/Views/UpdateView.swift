//
//  UpdateView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 18.09.21.
//

import Combine
import SUUpdaterClient
import SwiftUI

struct CheckingForUpdatesView: View {
  let cancel: () -> Void

  init(cancel: Callback<Void>?) {
    self.cancel = {
      guard let cancel = cancel else { return }
      cancel.run(())
    }
  }

  var body: some View {
    VStack {
      Text("Checking for Updates")
        .font(.headline)
      ProgressView()
        .progressViewStyle(LinearProgressViewStyle())
        .frame(maxWidth: 150)
      Button("Cancel") {
        self.cancel()
      }
    }
  }
}

class UpdateViewModel: ObservableObject {
  @Binding var automaticallyCheckForUpdates: Bool
  @Published var update: AppcastItem?
  @Published var downloadData: SUDownloadData?
  var state: SUUserUpdateState?
  var reply: Callback<SUUserUpdateState.Choice>?
  var cancelUpdate: Callback<Void>?

  private var cancellable: AnyCancellable?

  init(
    automaticallyCheckForUpdates: Binding<Bool>,
    updateEventPublisher: AnyPublisher<SUUpdaterClient.UpdaterEvents, Never>
  ) {
    self._automaticallyCheckForUpdates = automaticallyCheckForUpdates
    self.cancellable = updateEventPublisher.sink { [weak self] in
      self?.handleEvent(event: $0)
    }
  }

  private func handleEvent(event: SUUpdaterClient.UpdaterEvents) {
    switch event {
    case .showUpdateReleaseNotes(let downloadData):
      self.downloadData = downloadData
    case .updateCheckInitiated(let cancellation):
      self.cancelUpdate = cancellation

    case .updateFound(let update, let state, let reply):
      self.update = update
      self.state = state
      self.reply = reply

    default:
      break
    }
  }

}

struct UpdateView: View {
  @ObservedObject var viewModel: UpdateViewModel

  var body: some View {
    if let update = viewModel.update {
      FoundUpdateView(
        automaticallyCheckForUpdates: $viewModel.automaticallyCheckForUpdates,
        downloadData: $viewModel.downloadData,
        update: update,
        skipUpdate: { viewModel.reply?.run(.skip) },
        remindMeLater: { viewModel.reply?.run(.dismiss) },
        installUpdate: { viewModel.reply?.run(.install) }
      )
      .padding()
    } else {
      CheckingForUpdatesView(cancel: self.viewModel.cancelUpdate)
        .padding()
        .frame(minWidth: 100, minHeight: 100)
    }

  }
}

struct UpdateView_Previews: PreviewProvider {
  static let basicViewModel = UpdateViewModel(
    automaticallyCheckForUpdates: .constant(false),
    updateEventPublisher: Empty().eraseToAnyPublisher()
  )

  static var viewModel: UpdateViewModel {
    let viewModel = basicViewModel
    viewModel.update = .mock
    return viewModel
  }

  static var previews: some View {
    UpdateView(viewModel: viewModel)
    UpdateView(
      viewModel: UpdateViewModel(
        automaticallyCheckForUpdates: .constant(false),
        updateEventPublisher: Empty().eraseToAnyPublisher()
      )
    )
  }
}
