//
//  FoundUpdateViewTests.swift
//  SparklyExampleTests
//
//  Created by Till Hainbach on 31.10.21.
//

import SparklyClient
import XCTest

@testable import SparklyExample

final class FoundUpdateViewTests: XCTestCase {

  func testUpdateCanBeSkipped() {
    var choice: UserUpdateState.Choice?

    let viewModel = FoundUpdateViewModel(
      update: .mock,
      currentVersion: "0.0.1",
      downloadData: .mock,
      reply: { answer in
        switch answer {
        case .install, .dismiss:
          XCTFail("Expected to receive a reply of \(UserUpdateState.Choice.skip) but got \(answer)")
        case .skip:
          choice = answer
        }
      }
    )

    viewModel.skipUpdateButtonTapped()
    XCTAssert(choice == .skip)
  }

  func testUpdateCanBeInstalled() {
    var choice: UserUpdateState.Choice?

    let viewModel = FoundUpdateViewModel(
      update: .mock,
      currentVersion: "0.0.1",
      downloadData: .mock,
      reply: { answer in
        switch answer {
        case .dismiss, .skip:
          XCTFail(
            "Expected to receive a reply of \(UserUpdateState.Choice.install) but got \(answer)"
          )
        case .install:
          choice = answer
        }
      }
    )

    viewModel.installUpdateButtonTapped()
    XCTAssert(choice == .install)
  }

  func testUpdateCanBeDismissed() {
    var choice: UserUpdateState.Choice?

    let viewModel = FoundUpdateViewModel(
      update: .mock,
      currentVersion: "0.0.1",
      downloadData: .mock,
      reply: { answer in
        switch answer {
        case .install, .skip:
          XCTFail(
            "Expected to receive a reply of \(UserUpdateState.Choice.dismiss) but got \(answer)"
          )
        case .dismiss:
          choice = answer
        }
      }
    )

    viewModel.remindMeLaterButtonTapped()
    XCTAssert(choice == .dismiss)
  }
}
