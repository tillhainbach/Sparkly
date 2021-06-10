//
//  SparklyIntegrationTests.swift
//  SparklyIntegrationTests
//
//  Created by Till Hainbach on 10.06.21.
//
import Combine
import SUUpdaterClient
import SUUpdaterClientLive
import XCTest

class SparklyIntegrationTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  func test_StandardSparkle_DidStartOnApplicationLaunch() throws {
    let testBundle = Bundle(for: type(of: self))

    let client = SUUpdaterClient.standard(hostBundle: testBundle, applicationBundle: testBundle)

    var canCheckForUpdates = false

    client.updaterEventPublisher
      .sink { event in
        print(event)
        switch event {
        case .canCheckForUpdates(let newCanCheckForUpdates):
          canCheckForUpdates = newCanCheckForUpdates
          break
        default:
          XCTFail("Wrong event was sent")
        }
      }
      .store(in: &cancellables)

    XCTAssertFalse(canCheckForUpdates)

    // start updater
    client.send(.startUpdater)

    XCTAssertTrue(canCheckForUpdates)

    client.send(.checkForUpdates)
  }

}

