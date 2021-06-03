//
//  SwiftUIView.swift
//
//
//  Created by Till Hainbach on 03.06.21.
//

import Combine
import SUUpdaterClient
import SwiftUI

public struct UpdateCommand: Commands {

  @Binding var canCheckForUpdates: Bool
  let checkForUpdates: () -> Void

  public init(canCheckForUpdates: Binding<Bool>, checkForUpdates: @escaping () -> Void) {
    self._canCheckForUpdates = canCheckForUpdates
    self.checkForUpdates = checkForUpdates
  }

  struct BodyView: View {

    @Binding var canCheckForUpdates: Bool
    let checkForUpdates: () -> Void

    var body: some View {
      Button("Check for updates", action: checkForUpdates)
        .disabled(!canCheckForUpdates)
        .keyboardShortcut("U", modifiers: .command)
    }
  }

  public var body: some Commands {
    CommandGroup(after: .appInfo) {
      BodyView(canCheckForUpdates: $canCheckForUpdates, checkForUpdates: checkForUpdates)
    }

  }
}
