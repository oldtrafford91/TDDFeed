import Foundation

public final class RemoteFeedLoader: FeedLoader {
  
  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }
  public typealias Result = LoadFeedResult<Error>

  private let url: URL
  private let client: HTTPClient
  
  public init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }
  
  public func load(completion: @escaping (Result) -> Void) {
    client.get(from: url, completion: { [weak self] result in
      guard self != nil else { return }
      switch result {
      case .success(let data, let response):
        completion(FeedItemsMapper.map(data, from: response))
      case .failure:
        completion(.failure(.connectivity))
      }
    })
  }
  
  
}
