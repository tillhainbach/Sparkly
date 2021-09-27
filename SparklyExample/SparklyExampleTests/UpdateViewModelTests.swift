//
//  UpdateViewModelTests.swift
//  SparklyExampleTests
//
//  Created by Till Hainbach on 27.09.21.
//

import Combine
import SparklyClient
import XCTest

@testable import SparklyExample

class UpdateViewModelTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  func testUpdateViewModel() throws {

    var reply: UserUpdateState.Choice!

    let viewModel = UpdateViewModel(
      automaticallyCheckForUpdates: .constant(true),
      updateEventPublisher: Just(UpdaterClient.Event.updateCheck(.readyToRelaunch))
        .eraseToAnyPublisher(),
      cancelUpdate: noop,
      send: { reply = $0 }
    )

    viewModel.reply(.install)

    XCTAssertTrue(reply == .install)
  }

}
