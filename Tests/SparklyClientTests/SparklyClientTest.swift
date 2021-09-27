import XCTest

@testable import SparklyClient

final class SparklyTests: XCTestCase {
  func testUpdaterIntervalsConvertToTimeInterval() throws {

    var target: TimeInterval = 0

    // using for-loop and switch so that the compiler warns use to update the unit-test
    // whenever a new supported interval is added.
    for interval in UpdateInterval.allCases {
      switch interval {
      case .daily:
        target = 86_400
        break
      case .weekly:
        target = 604_800
        break
      case .biweekly:
        target = 1_209_600
        break
      case .monthly:
        target = 2_592_000
        break
      }

      XCTAssertEqual(interval.toTimeInterval(), target)
    }

  }
}
