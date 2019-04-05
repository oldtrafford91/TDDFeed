import XCTest

class RemoteFeedLoader {
  
}

class HTTPClient {
  var requestedURL: URL?
}

class RemoteFeedLoaderTest: XCTestCase {
  func test_doesNotRequestDataFromURL() {
    let client = HTTPClient()
    _ = RemoteFeedLoader()
    XCTAssertNil(client.requestedURL)
  }
}
