import Foundation

public struct MockData {
  public let introspectApiResponseData =
"""
   {
    \"active\":true,
    \"scope\":\"api web refresh_token\",
    \"client_id\":\"3XATVHBJBJBSBJNJH!nbjd\",
    \"username\":\"demo.c@deveronuas.com\",
    \"sub\":\"https://login.salesforce.com/id/00123456789U\",
    \"token_type\":\"access_token\",
    \"exp\":1651259020,
    \"iat\":1651172620,
    \"nbf\":1651172620
   }
"""

  public let refreshTokenResponseData =
"""
   {
    \"access_token\":\"NEWACCESSTOKEN\",
    \"sfdc_community_url\":\"https://sales.force.com\",
    \"sfdc_community_id\":\"0WUNNJND\",
    \"signature\":\"9c/dKHiI8RX1dknn7/YHSBH0o=\",
    \"scope\":\"refresh_token web api\",
    \"instance_url\":\"https://host.my.salesforce.com\",
    \"id\":\"https://login.salesforce.com/id/00DSYHh\",
    \"token_type\":\"Bearer\",
    \"issued_at\":\"1651173169359\"
   }
"""

  public let mockReceivedUrl = "https://www.customercontactinfo.com/user_callback.jsp#" +
  "access_token=00Dx000000BV7z%21AR8QBM8J_xr9kLqmZIRyQxZgLcMd" +
  "TGGGSoVim8FfJkZEqxbjaFbberKGk8v8AnYrvChG4qJbQo8" +
  "&refresh_token=5Aep4iLM.DOh_B454_pZfVti1dPEk8aXVSIQ%3D%3D" +
  "&instance_url=https://yourInstance.salesforce.com" +
  "&id=https://login.salesforce.com%2Fid%2F0Dx0007z%2F005x00P" +
  "&issued_at=1278448101416" +
  "&signature=miQQ1J4sdMPiduBsvyRYPCDozqhe43KRc1i9LmZHR70%3D" +
  "&scope=id+api+refresh_token" +
  "&token_type=Bearer" +
  "&state=mystate"

}

