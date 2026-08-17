import SwiftCrossUI

/// Routes between stages inside the floating rounded card.
struct RootView: View {
    @Environment(ExamStore.self) var store

    var body: some View {
        ZStack {
            AnimatedBackground()

            Group {
                switch store.stage {
                case .setup:     SetupView()
                case .questions: QuestionsView()
                case .summary:   SummaryView()
                case .running:   TimerView()
                case .finished:  FinishedView()
                case .save, .done: SaveView()
                }
            }
            .padding(36)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Each screen fades + drifts + subtly scales in for a calm transition.
            // .transition(.asymmetric(
            //     insertion: .opacity.combined(with: .scale(scale: 0.97)).combined(with: .offset(y: 8)),
            //     removal: .opacity.combined(with: .scale(scale: 1.02))
            // ))
            // .id(store.stage)
        }
        .frame(width: 880, height: 520)
        // Rounding + border are applied to the NSWindow's content layer so the
        // traffic-light buttons remain visible (see WindowConfigurator).
        // .animation(.spring(response: 0.5, dampingFraction: 0.82), value: store.stage)
        .onAppear {
            store.onFinished = { ChimePlayer.shared.play() }
        }
    }
}

// MARK: - Shared styling

extension Color {
    static let zenText = Color(red: 0.95, green: 0.96, blue: 0.90)
    static let zenSubtle = Color.white.opacity(0.55)
    static let zenAccent = Color(red: 0.78, green: 0.82, blue: 0.42)
}

/// Rounded serene title font helper.
extension View {
    func zenTitle(_ size: Double) -> some View {
        self.font(.system(size: size, weight: .semibold, design: .default))
            .foregroundColor(.zenText)
    }
}

/// A translucent pill button used throughout the flow, with a smooth hover lift.
// struct PillButtonStyle: ButtonStyle {
//     var prominent: Bool = false
//     var enabled: Bool = true

//     func makeBody(configuration: Configuration) -> some View {
//         PillBody(configuration: configuration, prominent: prominent, enabled: enabled)
//     }

//     private struct PillBody: View {
//         let configuration: Configuration
//         let prominent: Bool
//         let enabled: Bool
//         @State private var hovering = false

//         var body: some View {
//             configuration.label
//                 .font(.system(size: 15, weight: .medium, design: .rounded))
//                 .foregroundColor(prominent ? Color(red: 0.10, green: 0.13, blue: 0.06) : .zenText)
//                 .padding(.horizontal, 22)
//                 .padding(.vertical, 11)
//                 .background(
//                     Capsule()
//                         .fill(prominent
//                               ? Color.zenAccent.opacity(enabled ? (hovering ? 1 : 0.92) : 0.4)
//                               : Color.white.opacity(enabled ? (hovering ? 0.2 : 0.14) : 0.06))
//                 )
//                 .overlay(
//                     Capsule()
//                         // .strokeBorder(Color.white.opacity(prominent ? 0 : 0.12), lineWidth: 1)
//                 )
//                 .opacity(configuration.isPressed ? 0.7 : 1)
//                 // .scaleEffect(configuration.isPressed ? 0.97 : (hovering && enabled ? 1.04 : 1))
//                 // .animation(.spring(response: 0.28, dampingFraction: 0.7), value: hovering)
//                 // .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
//                 .onHover { if enabled { hovering = $0 } }
//         }
//     }
// }
