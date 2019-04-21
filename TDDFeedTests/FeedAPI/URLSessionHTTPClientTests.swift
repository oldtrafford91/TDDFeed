import XCTest
import TDDFeed

class URLSessionHTTPClient {
  private let session: URLSession
  
  init(session: URLSession = .shared) {
    self.session = session
  }
  
  struct UnexpectedValuesRepresentation: Error {}
  
  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url, completionHandler: {data, response, error in
      if let error = error {
        completion(.failure(error))
      } else if let data = data, data.count > 0, let response = response as? HTTPURLResponse {
        completion(.success(data, response))
      } else {
        completion(.failure(UnexpectedValuesRepresentation()))
      }
    }).resume()
  }
}

class URLSessionHTTPClientTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    URLProtocolStub.startInterceptingRequest()
  }
  
  override func tearDown() {
    super.tearDown()
    URLProtocolStub.stopInterceptingRequest()
  }
  
  func test_getFromURL_performGETRequestWithURL() {
    let url = anyURL()
    let exp = expectation(description: "Wait for request")
    URLProtocolStub.observeRequests { request in
      XCTAssertEqual(request.url, url)
      XCTAssertEqual(request.httpMethod, "GET")
      exp.fulfill()
    }
    
    makeSUT().get(from: url) { _ in }
    wait(for: [exp], timeout: 1.0)
  }
  
  func test_getFromURL_failOnRequestError() {
    let error = anyNSError()
    let expectedError = resultErrorFor(nil, respsonse: nil, error: error) as NSError?
    XCTAssertEqual(expectedError, error)
  }

  func test_getFromURL_failOnAllInvalidRepresentationCases() {
    XCTAssertNotNil(resultErrorFor(nil, respsonse: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(nil, respsonse: nonHTTPResponse(), error: nil))
    XCTAssertNotNil(resultErrorFor(nil, respsonse: anyHTTPURLResponse(), error: nil))
    XCTAssertNotNil(resultErrorFor(anyData(), respsonse: nil, error: nil))
    XCTAssertNotNil(resultErrorFor(anyData(), respsonse: nil, error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(nil, respsonse: nonHTTPResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(nil, respsonse: anyHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(anyData(), respsonse: nonHTTPResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(anyData(), respsonse: anyHTTPURLResponse(), error: anyNSError()))
    XCTAssertNotNil(resultErrorFor(anyData(), respsonse: nonHTTPResponse(), error: nil))
  }
  
  func test_getFromURL_successOnHTTPResponseWithData() {
    let data = anyData()
    let response = anyHTTPURLResponse()
    URLProtocolStub.stub(data: data, response: response, error: nil)
    
    let exp = expectation(description: "Wait for completion")
    
    makeSUT().get(from: anyURL()) { (result) in
      switch result {
      case let .success(receivedData, receivedResponse):
        XCTAssertEqual(receivedData, data)
        XCTAssertEqual(receivedResponse.url, response?.url)
        XCTAssertEqual(receivedResponse.statusCode, response?.statusCode)
        
      default:
        XCTFail("Expected success, got \(result) instead")
      }
      
      exp.fulfill()
    }
    
    wait(for: [exp], timeout: 1.0)
  }
  
  
  // MARK: Helpers
  
  private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
    let sut = URLSessionHTTPClient()
    trackMemoryLeaks(sut)
    return sut
  }
  
  private func anyURL() -> URL {
    return URL(string: "http://example.com")!
  }
  
  private func anyData() -> Data {
    return Data("data".utf8)
  }
  
  private func anyNSError() -> NSError {
    return NSError(domain: "any Error", code: 0)
  }
  
  private func anyHTTPURLResponse() -> HTTPURLResponse? {
    return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
  }
  
  private func nonHTTPResponse() -> URLResponse {
    return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
  }
  
  func resultErrorFor(_ data: Data?, respsonse: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
    URLProtocolStub.stub(data: data, response: respsonse, error: error)
    let sut = makeSUT(file: file, line: line)
    let exp = expectation(description: "Wait for completion block")
    var receivedError: Error?
    sut.get(from: anyURL()) { result in
      switch result {
      case .failure(let error):
        receivedError = error
      default:
        XCTFail("Expected failure, but got \(result) instead", file: file, line: line)
      }
      exp.fulfill()
    }
    
    wait(for: [exp], timeout: 1.0)
    return receivedError
  }
  
  private class URLProtocolStub: URLProtocol {
    private struct Stub {
      let data: Data?
      let response: URLResponse?
      let error: Error?
    }
    private static var stub: Stub?
    private static var requestObserver: ((URLRequest) -> Void)?
    
    static func startInterceptingRequest() {
      URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequest() {
      URLProtocol.unregisterClass(URLProtocolStub.self)
      stub = nil
      requestObserver = nil
    }
    
    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
      requestObserver = observer
    }
    
    static func stub(data: Data?, response: URLResponse?, error: Error?) {
      stub = Stub(data: data, response: response, error: error)
    }
    
    // MARK: - Override
    
    override class func canInit(with request: URLRequest) -> Bool {
      requestObserver?(request)
      return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }
    
    override func startLoading() {
      if let data = URLProtocolStub.stub?.data {
        client?.urlProtocol(self, didLoad: data)
      }
      if let response = URLProtocolStub.stub?.response {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      }
      if let error = URLProtocolStub.stub?.error {
        client?.urlProtocol(self, didFailWithError: error)
      }
      client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
      
    }
  }
}


