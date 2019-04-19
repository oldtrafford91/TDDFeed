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
  
  func test_getFromURL_failOnRequestError() {
    URLProtocolStub.startInterceptingRequest()
    let url = URL(string: "http://example2.com")!
    let error = NSError(domain: "any erro", code: 1)
    URLProtocolStub.stub(url: url, data: nil, response: nil, error: error)
    let sut = URLSessionHTTPClient()
    
    let exp = expectation(description: "Wait for completion block")
    
    sut.get(from: url) { result in
      switch result {
      case .failure(let receivedErrror as NSError):
        XCTAssertEqual(receivedErrror, error)
      default:
        XCTFail("Expected failure with error \(error) but got \(result) instead")
      }
      exp.fulfill()
    }
    
    wait(for: [exp], timeout: 1.0)
    URLProtocolStub.stopInterceptingRequest()
  }
  
  // MARK: Helpers
  private class URLProtocolStub: URLProtocol {
    private struct Stub {
      let data: Data?
      let response: URLResponse?
      let error: Error?
    }
    private static var stubs = [URL: Stub]()
    
    static func startInterceptingRequest() {
      URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequest() {
      URLProtocol.unregisterClass(URLProtocolStub.self)
      stubs = [:]
    }
    
    static func stub(url: URL, data: Data?, response: URLResponse?, error: Error?) {
      let stub = Stub(data: data, response: response, error: error)
      URLProtocolStub.stubs[url] = stub
    }
    
    // MARK: - Override
    
    override class func canInit(with request: URLRequest) -> Bool {
      guard let url = request.url else {
        return false
      }
      return URLProtocolStub.stubs[url] != nil
      
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }
    
    override func startLoading() {
      guard let url = request.url, let stub = URLProtocolStub.stubs[url] else {
        return
      }
      if let data = stub.data {
        client?.urlProtocol(self, didLoad: data)
      }
      if let response = stub.response {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      }
      if let error = stub.error {
        client?.urlProtocol(self, didFailWithError: error)
      }
      client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
  }
}


