import Prch
import PrchNIO
import Vapor

public struct SessionClient: EventLoopSession {
  public typealias RequestType = ClientRequest

  let client: Vapor.Client

  public init(client: Vapor.Client) {
    self.client = client
  }

  public func nextEventLoop() -> EventLoop {
    client.eventLoop
  }

  public func beginRequest(
    _ request: RequestType
  ) -> EventLoopFuture<ResponseComponents> {
    client.send(request).map { $0 as ResponseComponents }
  }

  public func createRequest<RequestType>(
    _ request: RequestType,
    withBaseURL baseURL: URL,
    andHeaders headers: [String: String],
    usingEncoder encoder: RequestEncoder
  ) throws -> ClientRequest where RequestType: Prch.Request {
    guard var components = URLComponents(
      url: baseURL.appendingPathComponent(request.path),
      resolvingAgainstBaseURL: false
    ) else {
      throw ClientError.badURL(baseURL, request.path)
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
    urlRequest.method = HTTPMethod(rawValue: request.method)

    let headerDict = request.headers.merging(
      headers, uniquingKeysWith: { requestHeaderKey, _ in
        requestHeaderKey
      }
    )
    urlRequest.headers = HTTPHeaders(Array(headerDict))

    if let encodeBody = request.encodeBody {
      urlRequest.body = try ByteBuffer(data: encodeBody(encoder))
    }
    return urlRequest
  }
}
