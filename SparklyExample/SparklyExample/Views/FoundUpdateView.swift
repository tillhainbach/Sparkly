//
//  FoundUpdateView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 19.09.21.
//

import Combine
import SUUpdaterClient
import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
  let request: URLRequest

  func makeNSView(context: Context) -> some NSView {
    let webView = WKWebView()
    webView.load(request)
    return webView
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {}

}

//final class FoundUpdateViewModel: ObservableObject {
//
//
//  init(
//    update: AppcastItem,
//    automaticallyCheckForUpdates: Binding<Bool>,
//    skipUpdate: @escaping () -> Void,
//    remindMeLater: @escaping () -> Vsoid,
//    installUpdate: @escaping () -> Void,
//  ) {
//    self.update = update
//    self.automaticallyCheckForUpdates = automaticallyCheckForUpdates
//    self.skipUpdate = skipUpdate
//    self.remindMeLater = remindMeLater
//    self.installUpdate = installUpdate
//
//  }
//
//}

struct FoundUpdateView: View {

  @Binding var automaticallyCheckForUpdates: Bool
  @Binding var downloadData: SUDownloadData?
  let update: AppcastItem
  let skipUpdate: () -> Void
  let remindMeLater: () -> Void
  let installUpdate: () -> Void

  var body: some View {
    HStack {
      VStack {
        Image(systemName: "arrow.down.app.fill")
          .resizable()
          .frame(width: 40, height: 40)
        Spacer()
      }
      VStack(alignment: .leading) {
        HStack {
          VStack(alignment: .leading) {
            Text("A new Version of Example")
              .font(.headline)
            Text(
              "Example \(update.displayVersionString ?? "") is now available - you have v1.0. Would you like to download it now?"
            )

          }
        }
        if let downloadData = downloadData {
          VStack(alignment: .leading) {
            Text("Release Notes:")
              .font(.subheadline)
            WebView(request: URLRequest(url: downloadData.url))
          }
        } else {
          Spacer()
        }
        HStack {
          Toggle(
            "Automatically download and install updates in the future",
            isOn: $automaticallyCheckForUpdates
          )
        }
        HStack {
          Button("Skip This Version", action: skipUpdate)
          Spacer()
          Button("Remind Me Later", action: remindMeLater)
          Button("Install Update", action: installUpdate)
        }
      }
    }
    .frame(minWidth: 500, minHeight: 300)
  }
}
struct FoundUpdateView_Previews: PreviewProvider {
  static var previews: some View {
    FoundUpdateView(
      automaticallyCheckForUpdates: .constant(true),
      downloadData: .constant(
        .init(
          data: "New Update".data(using: .utf8)!,
          url: URL(string: "https://tillhainbach.github.io/Sparkly/")!,
          textEncodingName: nil,
          mimeType: nil
        )
      ),
      update: .mock,
      skipUpdate: noop,
      remindMeLater: noop,
      installUpdate: noop
    )
    .padding()
  }
}

extension AppcastItem {
  static let mock: Self = .init(
    versionString: "1234",
    displayVersionString: "1.0",
    fileURL: nil,
    contentLength: 20,
    infoURL: nil,
    isInformationOnlyUpdate: false,
    title: "Update",
    dateString: Date().toString(),
    date: Date(),
    releaseNotesURL: nil,
    itemDescription: nil,
    minimumSystemVersion: nil,
    maximumSystemVersion: nil,
    installationType: nil,
    phasedRolloutInterval: nil,
    propertiesDictionary: [:]
  )
}
