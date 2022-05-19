import Foundation
import SwiftUI
import SafariServices

public struct SafariView: UIViewControllerRepresentable {
  public let url: URL

  public  func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
    return SFSafariViewController(url: url)
  }

  public func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}
}
