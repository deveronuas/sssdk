import Foundation

struct IntrospectResponse : Decodable{
  let active: Bool
  let scope: String
  let clientId: String
  let username: String
  let sub: String
  let tokenType: String
  let accessTokenExpiryDate: Int
  let iat: Int
  let nbf: Int

  enum CodingKeys: String, CodingKey {
    case active
    case scope
    case clientId  = "client_id"
    case username
    case sub
    case tokenType = "token_type"
    case accessTokenExpiryDate = "exp"
    case iat
    case nbf
  }
}
