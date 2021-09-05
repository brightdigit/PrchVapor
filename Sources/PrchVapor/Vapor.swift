import Prch
import PrchNIO
import Vapor

extension ClientResponse: Prch.Response {
  public var data: Data? {
    body.map {
      Data(buffer: $0)
    }
  }

  public var statusCode: Int? {
    Int(status.code)
  }
}

extension URI {
  init(components: URLComponents) {
    self.init(
      scheme: .init(components.scheme),
      host: components.host,
      port: components.port,
      path: components.path,
      query: components.query,
      fragment: components.fragment
    )
  }
}

public struct SessionClient: EventLoopSession {
  public init(client: Client) {
    self.client = client
  }

  public func nextEventLoop() -> EventLoop {
    client.eventLoop
  }

  let client: Client
  public func beginRequest(_ request: ClientRequest) -> EventLoopFuture<Prch.Response> {
    client.send(request).map { $0 as Prch.Response }
  }

  public func createRequest<ResponseType>(
    _ request: APIRequest<ResponseType>,
    withBaseURL baseURL: URL,
    andHeaders headers: [String: String]
  ) throws -> ClientRequest where ResponseType: APIResponseValue {
    guard var components = URLComponents(
      url: baseURL.appendingPathComponent(request.path),
      resolvingAgainstBaseURL: false
    ) else {
      throw APIClientError.badURL(baseURL, request.path)
    }

    var queryItems = [URLQueryItem]()
    for (key, value) in request.queryParameters {
      if !String(describing: value).isEmpty {
        queryItems.append(URLQueryItem(name: key, value: String(describing: value)))
      }
    }
    components.queryItems = queryItems

    var urlRequest = ClientRequest()
    urlRequest.url = URI(components: components)
    urlRequest.method = HTTPMethod(rawValue: request.service.method)
    
    let headerDict = request.headers.merging(
      headers, uniquingKeysWith: { requestHeaderKey, _ in
        requestHeaderKey
      }
    )
    urlRequest.headers = HTTPHeaders(Array(headerDict))

    if let encodeBody = request.encodeBody {
      urlRequest.body = try ByteBuffer(data: encodeBody(JSONEncoder()))
    }
    return urlRequest
  }
}
