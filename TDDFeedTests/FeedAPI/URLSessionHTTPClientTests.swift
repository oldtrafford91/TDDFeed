import XCTest
import TDDFeed

class URLSessionHTTPClient {
  private let session: URLSession
  
  init(session: URLSession) {
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
  
  func test_getFromURL_resumeDataTaskWithURL() {
    let url = URL(string: "http://example2.com")!
    let session = URLSessionSpy()
    let task = URLSessionDataTaskSpy()
    session.stub(url: url, task: task)
    let sut = URLSessionHTTPClient(session: session)
    sut.get(from: url) {_ in}
    
    XCTAssertEqual(task.resumeCallCount, 1)
  }
  
  func test_getFromURL_failOnRequestError() {
    let url = URL(string: "http://example2.com")!
    let session = URLSessionSpy()
    let error = NSError(domain: "any erro", code: 1)
    session.stub(url: url, error: error)
    let sut = URLSessionHTTPClient(session: session)
    
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
  }
  
  // MARK: Helpers
  private class URLSessionSpy: URLSession {
    struct Stub {
      let task: URLSessionDataTask
      let error: Error?
    }
    var stubs = [URL: Stub]()
    
    func stub(url: URL, task: URLSessionDataTask = FakeURLSessionDataTask(), error: Error? = nil) {
      let stub = Stub(task: task, error: error)
      stubs[url] = stub
    }
    
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
      guard let stub = stubs[url] else {
        fatalError("")
      }
      completionHandler(nil, nil, stub.error)
      return stub.task
    }
  }
  
  private class FakeURLSessionDataTask: URLSessionDataTask {
    override func resume() {}
  }
  private class URLSessionDataTaskSpy: URLSessionDataTask {
    var resumeCallCount = 0
    override func resume() {
      resumeCallCount += 1
    }
  }

}


