import SwiftUI

#if os(iOS)
import UIKit

/// UIHostingController wrapper that opts out of safe-area inset propagation so
/// SwiftUI content can paint edge-to-edge on tall iPhones (Dynamic Island, home indicator).
struct FullScreenHost<Content: View>: UIViewControllerRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIViewController(context: Context) -> FullScreenHostingController<Content> {
        FullScreenHostingController(rootView: content)
    }

    func updateUIViewController(_ controller: FullScreenHostingController<Content>, context: Context) {
        controller.rootView = content
    }
}

final class FullScreenHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.insetsLayoutMarginsFromSafeArea = false
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
    }
}
#endif
