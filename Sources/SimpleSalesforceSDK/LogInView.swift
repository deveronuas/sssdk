import SwiftUI

public struct LogInView: View {
  public let url : URL
  public init (url : URL){
    self.url = url
  }

  @available(macOS 10.15, *)
  public var body: some View {
     Text("t")
  }
}

public struct LogInView_Previews: PreviewProvider {
  @available(macOS 10.15, *)
  public static var previews: some View {
    LogInView(url: URL(string: "https://www.google.com")!)
  }
}


