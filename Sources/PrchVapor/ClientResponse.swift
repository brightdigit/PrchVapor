import Prch
import Vapor

extension ClientResponse: ResponseComponents {
  public var data: Data? {
    body.map {
      Data(buffer: $0)
    }
  }

  public var statusCode: Int? {
    Int(status.code)
  }
}
