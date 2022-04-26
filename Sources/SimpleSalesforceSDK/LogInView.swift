import SwiftUI

public struct LoginView: View {
  public let url : URL
  public init (url : URL){
    self.url = url
  }

  @available(macOS 10.15, *)
  public var body: some View {
     SafariView(url: url)
  }
}

public struct LoginView_Previews: PreviewProvider {
  @available(macOS 10.15, *)
  public static var previews: some View {
    LoginView(url: URL(string: "https://www.google.com")!)
  }
}


