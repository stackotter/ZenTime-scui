import SwiftCrossUI

/// Step 4: the live exam screen — big total countdown, small per-question stopwatch, nav.
struct TimerView: View {
    @Environment(ExamStore.self) var store

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Total time remaining, with a soft rolling-digit transition each second.
            Text(store.remaining.hms)
                .font(.system(size: 76, weight: .bold, design: .default))
                .foregroundColor(.zenText)
                // .monospacedDigit()
                // .contentTransition(.numericText(countsDown: true))
                // .animation(.easeInOut(duration: 0.35), value: store.remaining.hms)

            // Per-question label + stopwatch. Keyed on the index so switching questions
            // fades/drifts the whole block in for a calm transition.
            HStack(spacing: 12) {
                Text(store.currentQuestion?.name ?? "—")
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .foregroundColor(.zenSubtle)
                    .lineLimit(1)

                Text((store.currentQuestion?.elapsed ?? 0).hms)
                    .font(.system(size: 22, weight: .regular, design: .default))
                    .foregroundColor(.zenSubtle)
                    // .monospacedDigit()
                    // .contentTransition(.numericText())
                    // .animation(.easeInOut(duration: 0.35), value: (store.currentQuestion?.elapsed ?? 0).hms)
            }
            .padding(.top, 10)
            // .id(store.currentIndex)
            // .transition(.asymmetric(
            //     insertion: .opacity.combined(with: .offset(y: 8)),
            //     removal: .opacity.combined(with: .offset(y: -8))
            // ))
            // .animation(.spring(response: 0.45, dampingFraction: 0.85), value: store.currentIndex)

            // Grace / status line — fades in during the ~1s "choose a question" window.
            // Text("Get ready…")
            //     .font(.system(size: 13, weight: .medium, design: .default))
            //     .foregroundColor(.zenAccent)
            //     .padding(.top, 8)
                // .opacity(store.isArmed ? 0 : 1)
                // .animation(.easeInOut(duration: 0.4), value: store.isArmed)

            Spacer()

            // Navigation. Both side buttons share a fixed min width so the centered
            // "Question X of Y" label never shifts when Next becomes "Finish early".
            HStack {
                Button("Previous") {
                    store.goPrevious()
                } /* label: {
                    Label("Previous", systemImage: "chevron.left").frame(minWidth: 112)
                } */
                // .buttonStyle(PillButtonStyle())
                .disabled(store.currentIndex <= 0)

                Spacer()

                Text("Question \(store.currentIndex + 1) of \(store.questions.count)")
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundColor(.zenSubtle)
                    // .contentTransition(.numericText())
                    // .animation(.easeInOut(duration: 0.3), value: store.currentIndex)

                Spacer()

                // On the last question, Next becomes "Finish early".
                Group {
                    if store.currentIndex >= store.questions.count - 1 {
                        Button("Finish early") {
                            store.finishEarly()
                        } /* label: {
                            Label("Finish early", systemImage: "flag.checkered").frame(minWidth: 112)
                        } */
                        // .buttonStyle(PillButtonStyle(prominent: true))
                        // .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    } else {
                        Button("Next") {
                            store.goNext()
                        } /* label: {
                            Label("Next", systemImage: "chevron.right").frame(minWidth: 112)
                        } */
                        // .buttonStyle(PillButtonStyle())
                        // .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                // .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.currentIndex)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Step 5: time is up — the chime has played, await acknowledgement.
struct FinishedView: View {
    @Environment(ExamStore.self) var store
    @State private var appeared = false

    var buttonLabel: String {
        #if os(macOS)
            "Acknowledge"
        #else
            "Finish"
        #endif
    }

    var body: some View {
        VStack(spacing: 22) {
            // Image(systemName: "checkmark.seal.fill")
                // .font(.system(size: 54))
                // .scaleEffect(appeared ? 1 : 0.6)
                // .animation(.spring(response: 0.55, dampingFraction: 0.6), value: appeared)
            Circle().fill(Color.zenAccent)
                .frame(width: 54, height: 54)
                // .opacity(appeared ? 1 : 0)
                .onAppear { appeared = true }

            Text(store.finishedEarly ? "All done" : "Time's up").zenTitle(34)

            Text(store.finishedEarly
                 ? "You finished early. Your times are saved for this session."
                 : "Take a breath. Your times are saved for this session.")
                .font(.system(size: 15, design: .default))
                .foregroundColor(.zenSubtle)
                .multilineTextAlignment(.center)

            Button(buttonLabel) {
                #if os(macOS)
                    ChimePlayer.shared.stop()
                    store.acknowledge()
                #else
                    store.reset()
                #endif
            }
            // .buttonStyle(PillButtonStyle(prominent: true))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
