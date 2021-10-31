//
//  TestSupport.swift
//  SparklyExampleTests
//
//  Created by Till Hainbach on 30.10.21.
//
import Combine
import CombineSchedulers
import SnapshotTesting
import SparklyClient
import SwiftUI
import XCTest

extension Snapshotting where Value: SwiftUI.View, Format == NSImage {
  static var image: Self {
    Snapshotting<NSView, NSImage>.image()
      .pullback { swiftUIView in
        let controller = NSHostingController(rootView: swiftUIView)
        let view = controller.view
        view.frame.size = .init(width: 500, height: 300)

        return view
      }
  }
}

extension UpdateViewModel {
  func assert(
    on state: UpdateCheckState,
    afterActionCalled asserting: () -> Bool,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    self.updateState = state
    switch self.route {
    case .status(let viewState):
      viewState.action()

    case .found(let foundUpdateViewModel):
      foundUpdateViewModel.reply(.dismiss)
      foundUpdateViewModel.reply(.install)
      foundUpdateViewModel.reply(.skip)
    }
    XCTAssert(asserting(), file: file, line: line)

  }
}
