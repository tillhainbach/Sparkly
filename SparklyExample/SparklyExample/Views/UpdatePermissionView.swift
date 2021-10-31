//
//  UpdatePermissionView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 28.09.21.
//

import SwiftUI

final class UpdatePermissionViewModel: ObservableObject {
  @Published var sendSystemProfile: Bool
  let appName: String
  let response: (Bool, Bool) -> Void

  init(
    sendSystemProfile: Bool = false,
    appName: String = Bundle.main.appName,
    response: @escaping (Bool, Bool) -> Void
  ) {
    self.appName = appName
    self.response = response
    self.sendSystemProfile = sendSystemProfile
  }

  func checkAutomaticallyButtonTapped() {
    self.response(true, sendSystemProfile)
  }

  func dontCheckAutomaticallyButtonTapped() {
    self.response(false, sendSystemProfile)
  }
}

struct UpdatePermissionView: View {
  @ObservedObject var viewModel: UpdatePermissionViewModel

  var body: some View {
    VStack {
      HStack {
        Image(systemName: "arrow.down.app.fill")
          .resizable()
          .frame(width: 80, height: 80)
          .padding(.trailing)
        VStack(alignment: .leading) {
          Text("Check for updates automatically?")
            .font(.headline)
            .padding(.bottom, 1)

          Text("Should \(viewModel.appName) automatically check for updates?")
          Text("You can always check for updates manually from the \(viewModel.appName) menu.")

          Toggle("send anonymous system profile infos", isOn: $viewModel.sendSystemProfile)
            .font(.footnote)
        }
      }

      HStack {
        Spacer()
        Button("Don't Check", action: viewModel.dontCheckAutomaticallyButtonTapped)

        Button("Check automatically", action: viewModel.checkAutomaticallyButtonTapped)
          .buttonStyle(DefaultButtonStyle())
          .keyboardShortcut(.defaultAction)

      }

    }
    .padding()
    .frame(maxWidth: 500, minHeight: 180)
  }

}

struct UpdatePermissionView_Previews: PreviewProvider {
  static var previews: some View {
    UpdatePermissionView(viewModel: .init(response: noop(_:_:)))
  }
}
