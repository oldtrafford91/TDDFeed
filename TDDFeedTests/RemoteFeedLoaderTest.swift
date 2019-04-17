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
    
    expect(sut, completeWith: .failure(.connectivity), when: {
      let clientError = NSError(domain: "Test", code: 0)
      client.complete(with: clientError)
    })
  }
  
  func test_load_deliverErrorOnNon200HTTPResponse() {
    let (client, sut) = makeSUT()
    let sampleResponseCode = [199, 201, 300, 400, 500]
    
    sampleResponseCode.enumerated().forEach { index, code in
      expect(sut, completeWith: .failure(.invalidData), when: {
        let jsonData = makeItemsJSONData([])
        client.complete(withStatusCode: code, data: jsonData , at: index)
      })
    }
  }
  
  func test_load_deliverErrorOn200HTTPResponseWithInvalidData() {
    let (client, sut) = makeSUT()
    
    expect(sut, completeWith: .failure(.invalidData), when: {
      let invalidJSON = Data("invalid json".utf8)
      client.complete(withStatusCode: 200, data: invalidJSON)
    })
  }
  
  func test_load_deliverNoItemsOn200HTTPResponseWithEmptyJSON() {
    let (client, sut) = makeSUT()
    
    expect(sut, completeWith: .success([]), when: {
      let emptyListJSON = Data("{\"items\": []}".utf8)
      client.complete(withStatusCode: 200, data: emptyListJSON)
    })
  }
  
  func test_load_deliverItemsOn200HTTPResponse() {
    let (client, sut) = makeSUT()
    let item1 = makeItem(
      id: UUID(),
      imageURL: URL(string: "http://imageURL.com")!
    )
    let item2 = makeItem(
      id: UUID(),
      description: "a description",
      location: "a location",
      imageURL: URL(string: "http://anotherURL.com")!
    )
    let items = [item1.model, item2.model]
    
    expect(sut, completeWith: .success(items), when: {
      let jsonData = makeItemsJSONData([item1.json, item2.json])
      client.complete(withStatusCode: 200, data: jsonData)
    })
  }
}

// MARK: Helpers

private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (client: HTTPClientSpy, loader: RemoteFeedLoader) {
  let client = HTTPClientSpy()
  let sut = RemoteFeedLoader(url: url, client: client)
  return (client, sut)
}

private func expect(_ sut: RemoteFeedLoader, completeWith result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
  var capturedResults = [RemoteFeedLoader.Result]()
  sut.load {
    capturedResults.append($0)
  }
  action()
  XCTAssertEqual(capturedResults, [result], file: file, line: line)
}

private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
  let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
  let json = [
    "id": item.id.uuidString,
    "description": item.description,
    "location": item.location,
    "image": item.imageURL.absoluteString
    ].reduce(into: [String: Any]()) { (acc, e) in
      if let value = e.value {
        acc[e.key] = value
      }
  }
  return (item, json)
}

private func makeItemsJSONData(_ items: [[String: Any]]) -> Data {
  let json = ["items": items]
  return try! JSONSerialization.data(withJSONObject: json)
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
  
  func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
    let response = HTTPURLResponse(url: requestedURLs[index],
                                   statusCode: code,
                                   httpVersion: nil,
                                   headerFields: nil)!
    messages[index].completion(.success(data, response))
  }
}


