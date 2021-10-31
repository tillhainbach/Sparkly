//
//  UpdateViewModelTests.swift
//  SparklyExampleTests
//
//  Created by Till Hainbach on 27.09.21.
//

import SnapshotTesting
import SparklyClient
import SwiftUI
import XCTest

@testable import SparklyExample

class UpdateViewModelTests: XCTestCase {

  func testUpdateViewModel() throws {
    var replies: [UserUpdateState.Choice] = []
    var cancelCalls = 0

    let viewModel = UpdateViewModel(
      updateState: .checking,
      cancelUpdate: { cancelCalls += 1 },
      send: { choice in replies.append(choice) }
    )

    viewModel.assert(on: .checking) { cancelCalls == 1 && replies == [] }
    viewModel.assert(on: .found(.mock, state: .mock)) {
      cancelCalls == 1 && replies == [.dismiss, .install, .skip]
    }

    replies = []

    viewModel.assert(on: .downloading(total: 0.0, completed: 0.0)) {
      cancelCalls == 2 && replies == []
    }

    viewModel.assert(on: .extracting(completed: 0.0)) { cancelCalls == 3 && replies == [] }
    viewModel.assert(on: .installing) { cancelCalls == 4 && replies == [] }
    viewModel.assert(on: .readyToRelaunch) { cancelCalls == 4 && replies == [.install] }

  }

  func testUserInitiatedUpdateCheck() {
    let viewModel = UpdateViewModel(
      updateState: .checking,
      cancelUpdate: noop,
      send: noop(_:)
    )

    let updateView = UpdateView(viewModel: viewModel)
    assertSnapshot(matching: updateView, as: .image)

    viewModel.updateState = .found(.mock, state: .mock)
    assertSnapshot(matching: updateView, as: .image)

    viewModel.updateState = .downloading(total: 4, completed: 3)
    assertSnapshot(matching: updateView, as: .image)

    viewModel.updateState = .downloading(total: 4, completed: 4)
    assertSnapshot(matching: updateView, as: .image)

    viewModel.updateState = .extracting(completed: 0.0)
    assertSnapshot(matching: updateView, as: .image)

    viewModel.updateState = .extracting(completed: 1.0)
    assertSnapshot(matching: updateView, as: .image)

    viewModel.updateState = .installing
    assertSnapshot(matching: updateView, as: .image)

    viewModel.updateState = .readyToRelaunch
    assertSnapshot(matching: updateView, as: .image)
  }

}
