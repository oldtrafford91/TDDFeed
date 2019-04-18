import Foundation

public final class RemoteFeedLoader {
  
  public enum Error: Swift.Error {
    case connectivity
    case invalidData
  }
  
  public enum Result: Equatable {
    case success([FeedItem])
    case failure(Error)
  }
  private let url: URL
  private let client: HTTPClient
  
  public init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }
  
  public func load(completion: @escaping (Result) -> Void) {
    client.get(from: url, completion: { result in
      switch result {
      case .success(let data, let response):
        do {
          let items = try FeedItemsMapper.map(data, response)
          completion(.success(items))
        } catch {
          completion(.failure(.invalidData))
        }
      case .failure:
        completion(.failure(.connectivity))
      }
    })
  }
}
