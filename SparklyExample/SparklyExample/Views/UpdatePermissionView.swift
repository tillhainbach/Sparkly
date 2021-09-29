//
//  UpdatePermissionView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 28.09.21.
//

import SwiftUI

struct UpdatePermissionView: View {
  @State private var sendSystemProfile = false
  let response: (Bool, Bool) -> Void

  let appName = Bundle.main.appName

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

          Text("Should \(appName) automatically check for updates?")
          Text("You can always check for updates manually from the \(appName) menu.")

          Toggle("send anonymous system profile infos", isOn: $sendSystemProfile)
            .font(.footnote)
        }
      }

      HStack {
        Spacer()
        Button("Don't Check") {
          respondAndClose(autoCheck: false)
        }

        Button("Check automatically") {
          respondAndClose(autoCheck: true)
        }
        .buttonStyle(DefaultButtonStyle())
        .keyboardShortcut(.defaultAction)

      }

    }
    .padding()
    .frame(maxWidth: 500, minHeight: 180)
  }

  func respondAndClose(autoCheck: Bool) {
    response(autoCheck, sendSystemProfile)
    NSApplication.shared.keyWindow?.close()
  }
}

struct UpdatePermissionView_Previews: PreviewProvider {
  static var previews: some View {
    UpdatePermissionView(response: noop(_:_:))
  }
}
