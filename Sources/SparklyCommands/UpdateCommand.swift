//
//  SwiftUIView.swift
//
//
//  Created by Till Hainbach on 03.06.21.
//

import Combine
import SUUpdaterClient
import SwiftUI

/// Command struct that adds the check for updates command to the menu bar.
///
/// Use command  + shift + U for keyboard shortcut to trigger update checks.
public struct UpdateCommand: Commands {

  @Binding var canCheckForUpdates: Bool
  let checkForUpdates: () -> Void

  /// Intiliaze UpdateCommand.
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

  /// Body of UpdateCommand.
  public var body: some Commands {
    CommandGroup(after: .appInfo) {
      BodyView(canCheckForUpdates: $canCheckForUpdates, checkForUpdates: checkForUpdates)
    }

  }
}
