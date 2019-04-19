import XCTest
import TDDFeed

class URLSessionHTTPClient {
  private let session: URLSession
  
  init(session: URLSession = .shared) {
    self.session = session
  }
  
  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
    session.dataTask(with: url, completionHandler: {_, _, error in
      if let error = error {
        completion(.failure(error))
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
    let url = URL(string: "http://example.com")!
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
    let error = NSError(domain: "any erro", code: 1)
    let url = URL(string: "http://example.com")!
    URLProtocolStub.stub(data: nil, response: nil, error: error)
    
    let exp = expectation(description: "Wait for completion block")
    
    makeSUT().get(from: url) { result in
      switch result {
      case .failure(let receivedErrror as NSError):
        XCTAssertEqual(receivedErrror, error)
      default:
        XCTFail("Expected failure with error \(error) but got \(result) instead")
      }
      exp.fulfill()
    }
    
    wait(for: [exp], timeout: 1.0)
  }
  
  // MARK: Helpers
  
  private func makeSUT() -> URLSessionHTTPClient {
    let sut = URLSessionHTTPClient()
    trackMemoryLeaks(sut)
    return sut
  }
  
  private func trackMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line ) {
    addTeardownBlock { [weak instance] in
      XCTAssertNil(instance, "Instance of sut should be deallocated. Potential memory leak.", file: file, line: line)
    }
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


