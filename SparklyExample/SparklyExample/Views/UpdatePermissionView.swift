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

  var body: some View {
    VStack {
      Text("Update Permission")

      Toggle("Send Sytem Profile Infos", isOn: $sendSystemProfile)

      HStack {
        Button("Check Updates automatically") {
          respondAndClose(autoCheck: true)
        }

        Button("Don't Check Updates automatically") {
          respondAndClose(autoCheck: false)
        }
      }
    }
    .padding()
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
