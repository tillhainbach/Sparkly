//
//  FoundUpdateView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 19.09.21.
//

import Combine
import SparklyClient
import SwiftUI

final class FoundUpdateViewModel: ObservableObject {
  @Published var downloadData: DownloadData?
  let currentVersion: String
  let reply: (UserUpdateState.Choice) -> Void
  let update: AppcastItem

  init(
    update: AppcastItem,
    currentVersion: String = Bundle.main.appVersion,
    downloadData: DownloadData? = nil,
    reply: @escaping (UserUpdateState.Choice) -> Void
  ) {
    self.currentVersion = currentVersion
    self.downloadData = downloadData
    self.update = update
    self.reply = reply
  }

  func skipUpdateButtonTapped() {
    self.reply(.skip)
  }

  func remindMeLaterButtonTapped() {
    self.reply(.dismiss)
  }

  func installUpdateButtonTapped() {
    self.reply(.install)
  }
}

struct FoundUpdateView: View {

  @AppStorage(UpdaterSettingsKeys.automaticallyDownloadUpdates.rawValue)
  var automaticallyDownloadUpdates: Bool = false

  @ObservedObject var viewModel: FoundUpdateViewModel

  var body: some View {
    HStack {
      VStack {
        Image(systemName: "arrow.down.app.fill")
          .resizable()
          .frame(width: 40, height: 40)
        Spacer()
      }
      VStack(alignment: .leading) {
        HStack {
          VStack(alignment: .leading) {
            Text("A new Version of Example")
              .font(.headline)
            Text("Example \(viewModel.update.displayVersionString ?? "") is now available -")
              + Text("you have \(viewModel.currentVersion). Would you like to download it now?")
          }
        }
        .padding(.bottom)

        if let downloadData = viewModel.downloadData {
          VStack(alignment: .leading) {
            Text("Release Notes:")
              .font(.subheadline)
            WebView(request: URLRequest(url: downloadData.url))
          }
        } else {
          Spacer()
        }
        HStack {
          Toggle(
            "Automatically download and install updates in the future",
            isOn: $automaticallyDownloadUpdates
          )
        }
        HStack {
          Button("Skip This Version", action: viewModel.skipUpdateButtonTapped)
          Spacer()
          Button("Remind Me Later", action: viewModel.remindMeLaterButtonTapped)
          Button("Install Update", action: viewModel.installUpdateButtonTapped)
        }
      }
    }
    .frame(minWidth: 500, minHeight: 300)
  }
}

#if DEBUG

struct FoundUpdateView_Previews: PreviewProvider {
  static var previews: some View {
    FoundUpdateView(viewModel: .init(update: .mock, downloadData: .mock, reply: noop(_:)))
      .padding()
  }
}

#endif
