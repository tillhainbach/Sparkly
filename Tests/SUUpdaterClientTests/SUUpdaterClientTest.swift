import XCTest

@testable import SUUpdaterClient

final class SparklyTests: XCTestCase {
  func testSUUpdaterIntervalsConvertToTimeInterval() {

    var target: TimeInterval = 0

    // using for-loop and switch so that the compiler warns use to update the unit-test
    // whenever a new supported interval is added.
    for interval in SUUpdateInterval.allCases {
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
