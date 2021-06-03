//
//  SparklyExampleApp.swift
//  SparklyExample
//
//  Created by Till Hainbach on 03.06.21.
//

import SwiftUI
import SparklyCommands
import SUUpdaterClient

@main
struct SparklyExampleApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView(viewModel: ViewModel())
    }
    .commands {
      UpdateCommand(viewModel: UpdateCommandViewModel(updaterClient: .happyPath))
    }
  }
}
