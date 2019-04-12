import XCTest

import TDDFeed

class RemoteFeedLoaderTest: XCTestCase {
  func test_doesNotRequestDataFromURL() {
    let (client, _) = makeSUT()
    XCTAssertTrue(client.requestedURLs.isEmpty)
  }
  
  func test_load_requestsDataFromURL() {
    let url = URL(string: "https://example.com")!
    let (client, sut) = makeSUT()
    sut.load()
    
    XCTAssertEqual(client.requestedURLs, [url])
  }
  
  func test_loadTwice_requestsDataFromURLTwice() {
    let url = URL(string: "https://example.com")!
    let (client, sut) = makeSUT()
    sut.load()
    sut.load()
    
    XCTAssertEqual(client.requestedURLs, [url, url])
  }
  
  func test_load_deliverErrorOnClientError() {
    let (client, sut) = makeSUT()
    client.error = NSError(domain: "Test", code: 0)
    var capturedError: RemoteFeedLoader.Error?
    sut.load { error in
      capturedError = error
    }
    
    XCTAssertEqual(capturedError, .connectivity)
    
    
  }
}

// MARK: Helpers

private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (client: HTTPClientSpy, loader: RemoteFeedLoader) {
  let client = HTTPClientSpy()
  let sut = RemoteFeedLoader(url: url, client: client)
  return (client, sut)
}

private class HTTPClientSpy: HTTPClient {
  var requestedURLs = [URL]()
  var error: Error?
  func get(from url: URL, completion: @escaping (Error) -> Void) {
    if let error = error {
      completion(error)
    }
    requestedURLs.append(url)
  }
}


