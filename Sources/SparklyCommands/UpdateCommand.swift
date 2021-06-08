//
//  SwiftUIView.swift
//
//
//  Created by Till Hainbach on 03.06.21.
//

import Combine
import SUUpdaterClient
import SwiftUI

/// ViewModel to communicate changes from the Command
public final class UpdateCommandViewModel: ObservableObject {

  @Published var canCheckForUpdates: Bool = false
  let checkForUpdates: () -> Void

  public init(canCheckForUpdates: AnyPublisher<Bool, Never>, checkForUpdates: @escaping () -> Void) {
    self.checkForUpdates = checkForUpdates
    canCheckForUpdates
      .assign(to: &$canCheckForUpdates)
  }

}

/// Command struct that adds the check for updates command to the menu bar.
///
/// Use command  + shift + U for keyboard shortcut to trigger update checks.
public struct UpdateCommand: Commands {

  @ObservedObject var viewModel: UpdateCommandViewModel

  /// Initialize UpdateCommand.
  public init(viewModel: UpdateCommandViewModel) {
    self.viewModel = viewModel
  }

  struct BodyView: View {

    @ObservedObject var viewModel: UpdateCommandViewModel

    var body: some View {
      Button("Check for updates", action: viewModel.checkForUpdates)
        .disabled(!viewModel.canCheckForUpdates)
        .keyboardShortcut("U", modifiers: .command)
    }
  }

  /// Body of UpdateCommand.
  public var body: some Commands {
    CommandGroup(after: .appInfo) {
      BodyView(viewModel: viewModel)
    }

  }
}
