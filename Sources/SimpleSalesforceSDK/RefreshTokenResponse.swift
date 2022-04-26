import Foundation

struct RefreshTokenResponse : Decodable{
  let accessToken : String
  let sfdcCommunityUrl : String
  let sfdcCommunityId : String
  let signature : String
  let scope : String
  let instanceUrl : String
  let id : String
  let tokenType: String
  let issuedAt : String

  enum CodingKeys: String, CodingKey {
    case accessToken =  "access_token"
    case sfdcCommunityUrl = "sfdc_community_url"
    case sfdcCommunityId = "sfdc_community_id"
    case signature
    case scope
    case instanceUrl  = "instance_url"
    case id
    case tokenType = "token_type"
    case issuedAt = "issued_at"
  }

}
