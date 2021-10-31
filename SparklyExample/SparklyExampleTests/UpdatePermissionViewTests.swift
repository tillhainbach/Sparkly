//
//  UpdatePermissionViewTests.swift
//  SparklyExampleTests
//
//  Created by Till Hainbach on 31.10.21.
//

import XCTest

final class UpdatePermissionViewTests: XCTestCase {

  func testAutomaticUpdatePermissionCanBeGranted() throws {
    var sendSystemProfile = false
    var automaticallyCheckForUpdates: Bool?

    let viewModel = UpdatePermissionViewModel(
      response: {
        automaticallyCheckForUpdates = $0
        sendSystemProfile = $1
      }
    )

    XCTAssertNil(automaticallyCheckForUpdates)
    XCTAssertFalse(sendSystemProfile)

    viewModel.checkAutomaticallyButtonTapped()
    XCTAssertFalse(sendSystemProfile)
    XCTAssertTrue(try XCTUnwrap(automaticallyCheckForUpdates))

  }

  func testAutomaticUpdatePermissionCanBeDenied() throws {
    var sendSystemProfile = false
    var automaticallyCheckForUpdates: Bool?

    let viewModel = UpdatePermissionViewModel(
      response: {
        automaticallyCheckForUpdates = $0
        sendSystemProfile = $1
      }
    )

    XCTAssertNil(automaticallyCheckForUpdates)
    XCTAssertFalse(sendSystemProfile)

    viewModel.dontCheckAutomaticallyButtonTapped()
    XCTAssertFalse(sendSystemProfile)
    XCTAssertFalse(try XCTUnwrap(automaticallyCheckForUpdates))

  }
}
