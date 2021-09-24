//
//  FoundUpdateView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 19.09.21.
//

import Combine
import SparklyClient
import SwiftUI
import WebKit

extension Bundle {
  var appVersion: String {
    Self.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
  }
}

struct WebView: NSViewRepresentable {
  let request: URLRequest

  func makeNSView(context: Context) -> some NSView {
    let webView = WKWebView()
    webView.load(request)
    return webView
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {}

}

struct FoundUpdateView: View {

  @Binding var automaticallyCheckForUpdates: Bool
  @Binding var downloadData: DownloadData?
  let update: AppcastItem
  let skipUpdate: () -> Void
  let remindMeLater: () -> Void
  let installUpdate: () -> Void
  let currentVersion = Bundle.main.appVersion

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
            Text("Example \(update.displayVersionString ?? "") is now available -")
              + Text("you have \(currentVersion). Would you like to download it now?")
          }
        }
        .padding(.bottom)

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
