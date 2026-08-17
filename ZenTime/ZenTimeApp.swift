import SwiftCrossUI
import DefaultBackend
import AppKit

@main
struct ZenTimeApp: App {
    @State private var store = ExamStore()
    @State private var updatedWindow = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .frame(width: 880, height: 520)
                .inspectWindow { window in
                    guard !updatedWindow else { return }
                    updatedWindow = true

                    #if canImport(AppKitBackend)
                        window.titleVisibility = .hidden
                        window.titlebarAppearsTransparent = true
                        window.titlebarSeparatorStyle = .none
                        window.styleMask.insert(.fullSizeContentView)
                        // window.isOpaque = false
                        // window.backgroundColor = .clear
                        window.hasShadow = true
                        window.isMovableByWindowBackground = true

                        // Round the window via its content layer (not a SwiftUI clip) so the
                        // standard traffic-light buttons stay fully visible in the top-left.
                        if let content = window.contentView {
                            content.wantsLayer = true
                            content.layer?.cornerRadius = 16
                            content.layer?.masksToBounds = true
                            content.layer?.cornerCurve = .continuous
                            content.layer?.borderWidth = 0
                        }

                        // Keep all three traffic-light buttons present and usable.
                        window.standardWindowButton(.closeButton)?.isHidden = false
                        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
                        window.standardWindowButton(.zoomButton)?.isHidden = false
                        window.center()
                    #endif
                }
        }
        // .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
