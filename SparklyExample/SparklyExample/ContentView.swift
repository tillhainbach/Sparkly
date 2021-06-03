//
//  ContentView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 03.06.21.
//

import SwiftUI

final class ViewModel: ObservableObject {

  func openSettings() {
    // noop
  }
}

struct ContentView: View {
  @ObservedObject var viewModel: ViewModel

  var body: some View {
    VStack {
      Text("Hello, Sparkly 💫")
        .padding()
      Button("Open Settings", action: viewModel.openSettings)
        .onCommand(.init(extendedGraphemeClusterLiteral: "⌘,"), perform: viewModel.openSettings)
    }
    .frame(width: 400, height: 400)
  }

}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(viewModel: ViewModel())
  }
}