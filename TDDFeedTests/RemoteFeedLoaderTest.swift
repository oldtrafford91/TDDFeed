import XCTest

class RemoteFeedLoader {
  let url: URL
  let client: HTTPClient
  init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }
  func load() {
    client.get(from: url)
  }
}

protocol HTTPClient {
  func get(from url: URL)
}

class HTTPClientSpy: HTTPClient {
  var requestedURL: URL?
  
  func get(from url: URL) {
    requestedURL = url
  }
}

class RemoteFeedLoaderTest: XCTestCase {
  func test_doesNotRequestDataFromURL() {
    let url = URL(string: "aurl")!
    let client = HTTPClientSpy()
    _ = RemoteFeedLoader(url: url, client: client)
    XCTAssertNil(client.requestedURL)
  }
  
  func test_load_requestDataFromURL() {
    let url = URL(string: "aurl")!
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)
    
    sut.load()
    
    XCTAssertEqual(client.requestedURL, url)
  }
}
