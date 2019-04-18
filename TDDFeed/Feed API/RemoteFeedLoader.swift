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

private class FeedItemsMapper {
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
  
  static var OK_200: Int { return 200 }
  
  static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
    guard response.statusCode == OK_200 else {
      throw RemoteFeedLoader.Error.invalidData
    }
    let root = try JSONDecoder().decode(Root.self, from: data)
    return root.items.map { $0.item }
  }
}


