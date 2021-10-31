//
//  WebView.swift
//  SparklyExample
//
//  Created by Till Hainbach on 30.10.21.
//

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

#if DEBUG

struct WebView_Previews: PreviewProvider {

  static var previews: some View {
    WebView(request: .init(url: URL(string: "https://tillhainbach.github.io/Sparkly/")!))
  }
}

#endif
