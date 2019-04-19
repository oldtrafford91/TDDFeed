import XCTest

extension XCTestCase {
  func trackMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line ) {
    addTeardownBlock { [weak instance] in
      XCTAssertNil(instance, "Instance of sut should be deallocated. Potential memory leak.")
    }
  }
}
