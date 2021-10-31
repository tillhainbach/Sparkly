//
//  SwiftUIView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 30.10.21.
//

import SwiftUI

struct StatusViewState {
  var status: String
  var buttonLabel: String = "Cancel"
  var value: Double = 0.0
  var total: Double = 0.0
  let action: () -> Void
}

struct StatusView: View {
  let state: StatusViewState

  var body: some View {
    HStack(alignment: .top) {
      Image(systemName: "arrow.down.app.fill")
        .resizable()
        .frame(width: 40, height: 40)
        .padding(.trailing)
      VStack(alignment: .leading) {
        Text(state.status)
          .font(.headline)
        ProgressView(value: state.value, total: state.total)
        HStack {
          Spacer()
          Button(state.buttonLabel, action: state.action)
        }
      }
    }
    .frame(width: 250, height: 100)
  }
}

#if DEBUG

struct StatusView_Previews: PreviewProvider {
  static var previews: some View {
    StatusView(state: .init(status: "Download", action: noop))
  }
}

#endif
