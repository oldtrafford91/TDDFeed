import Foundation

public enum HTTPClientResult {
  case success(Data, HTTPURLResponse)
  case failure(Error)
}

public protocol HTTPClient {
  func get(from url: URL, completion: @escaping  (HTTPClientResult) -> Void)
}

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
        if response.statusCode == 200, let root = try? JSONDecoder().decode(Root.self, from: data) {
          completion(.success(root.items.map {
            $0.item
          }))
        } else {
          completion(.failure(.invalidData))
        }
      case .failure:
        completion(.failure(.connectivity))
      }
    })
  }
}

private struct Root: Decodable {
  let items: [Item]
}

private struct Item: Decodable {
  let id: UUID
  let description: String?
  let location: String?
  let image: URL
  
  var item: FeedItem {
    return FeedItem(id: id, description: description, location: location, imageURL: image)
  }
}
