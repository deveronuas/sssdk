import SwiftUI

public struct LoginView: View {
  public let url: URL
  public init (url: URL){
    self.url = url
  }

  public var body: some View {
     SafariView(url: url)
  }
}

public struct LoginView_Previews: PreviewProvider {
  public static var previews: some View {
    LoginView(url: URL(string: "https://www.google.com")!)
  }
}
