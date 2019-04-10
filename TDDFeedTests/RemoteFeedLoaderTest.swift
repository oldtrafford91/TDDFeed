import XCTest

import TDDFeed

class RemoteFeedLoaderTest: XCTestCase {
  func test_doesNotRequestDataFromURL() {
    let (client, _) = makeSUT()
    XCTAssertNil(client.requestedURL)
  }
  
  func test_load_requestsDataFromURL() {
    let url = URL(string: "https://example.com")!
    let (client, sut) = makeSUT()
    sut.load()
    
    XCTAssertEqual(client.requestedURL, url)
  }
  
  func test_loadTwice_requestsDataFromURLTwice() {
    let url = URL(string: "https://example.com")!
    let (client, sut) = makeSUT()
    sut.load()
    sut.load()
    
    XCTAssertEqual(client.requestedURL, url)
    XCTAssertEqual(client.requestedURLs, [url, url])
  }
}

// MARK: Helpers

private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (client: HTTPClientSpy, loader: RemoteFeedLoader) {
  let client = HTTPClientSpy()
  let sut = RemoteFeedLoader(url: url, client: client)
  return (client, sut)
}

private class HTTPClientSpy: HTTPClient {
  var requestedURL: URL?
  var requestedURLs = [URL]()
  func get(from url: URL) {
    requestedURL = url
    requestedURLs.append(url)
  }
}


