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
    sut.load { _ in}
    
    XCTAssertEqual(client.requestedURLs, [url])
  }
  
  func test_loadTwice_requestsDataFromURLTwice() {
    let url = URL(string: "https://example.com")!
    let (client, sut) = makeSUT()
    sut.load { _ in}
    sut.load { _ in}
    
    XCTAssertEqual(client.requestedURLs, [url, url])
  }
  
  func test_load_deliverErrorOnClientError() {
    let (client, sut) = makeSUT()
    
    expect(sut, completeWithError: .connectivity, when: {
      let clientError = NSError(domain: "Test", code: 0)
      client.complete(with: clientError)
    })
  }
  
  func test_load_deliverErrorOnNon200HTTPResponse() {
    let (client, sut) = makeSUT()
    let sampleResponseCode = [199, 201, 300, 400, 500]
    
    sampleResponseCode.enumerated().forEach { index, code in
      expect(sut, completeWithError: .invalidData, when: {
        client.complete(withStatusCode: code, at: index)
      })
    }
  }
  
  func test_load_deliverErrorOn200HTTPResponseWithInvalidData() {
    let (client, sut) = makeSUT()
    
    expect(sut, completeWithError: .invalidData, when: {
      let invalidJSON = Data("invalid json".utf8)
      client.complete(withStatusCode: 200, data: invalidJSON)
    })
  }
  
}

// MARK: Helpers

private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (client: HTTPClientSpy, loader: RemoteFeedLoader) {
  let client = HTTPClientSpy()
  let sut = RemoteFeedLoader(url: url, client: client)
  return (client, sut)
}

private func expect(_ sut: RemoteFeedLoader, completeWithError error: RemoteFeedLoader.Error, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
  var capturedErrors = [RemoteFeedLoader.Result]()
  sut.load {
    capturedErrors.append($0)
  }
  action()
  XCTAssertEqual(capturedErrors, [.failure(error)], file: file, line: line)
}

private class HTTPClientSpy: HTTPClient {
  var requestedURLs: [URL] {
    return messages.map { $0.url }
  }
  private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
  
  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    messages.append((url, completion))
  }
  
  func complete(with error: Error, at index: Int = 0) {
    messages[index].completion(.failure(error))
  }
  
  func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
    let response = HTTPURLResponse(url: requestedURLs[index],
                                   statusCode: code,
                                   httpVersion: nil,
                                   headerFields: nil)!
    messages[index].completion(.success(data, response))
  }
}


