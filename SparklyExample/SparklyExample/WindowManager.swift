//
//  WindowManager.swift
//  SparklyExample
//
//  Created by Till Hainbach on 29.10.21.
//

import SwiftUI

struct WindowManager {
  var openWindow: (String) -> Void
  var closeWindow: (String) -> Void
}

extension WindowManager {
  static let live = Self(
    openWindow: {
      guard let url = (Bundle.main.urlScheme?.appending("://\($0)")).flatMap(URL.init) else {
        return
      }
      NSWorkspace.shared.open(url)
    },
    closeWindow: { title in
      NSApplication.shared.windows.first(where: { $0.title == title })?.close()
    }
  )
}

enum Window: String, CaseIterable {
  case updatePermissionRequest = "update-permission-request"
  case updateCheck = "update-check"

  var title: String { self.rawValue.kebabToTitle() }
}