import SwiftUI
import AppKit

/// Suppresses the blue keyboard focus ring on controls (macOS 14+ API, no-op below).
struct DisableFocusRing: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content.focusEffectDisabled()
        } else {
            content
        }
    }
}

@main
struct ZenTimeApp: App {
    @StateObject private var store = ExamStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .frame(width: 880, height: 520)
                .background(WindowConfigurator())
                .modifier(DisableFocusRing())
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

/// Styles the hosting NSWindow into a centered, transparent, rounded floating panel
/// so the SwiftUI card reads as a serene card over the desktop.
struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.titlebarSeparatorStyle = .none
            window.styleMask.insert(.fullSizeContentView)
            window.isOpaque = false
            window.backgroundColor = .clear
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
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
