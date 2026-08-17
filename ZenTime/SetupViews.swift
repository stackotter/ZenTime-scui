import Foundation
import SwiftCrossUI

#if canImport(AppKitBackend)
    import AppKitBackend
    import AppKit
#endif

// MARK: - Step 1: total time

struct SetupView: View {
    @Environment(ExamStore.self) var store

    var body: some View {
        VStack(spacing: 26) {
            VStack(spacing: 6) {
                Text("ZenTime").zenTitle(40)
                Text("How long is your exam?")
                    .font(.system(size: 16, design: .default))
                    .foregroundColor(.zenSubtle)
            }

            HStack(alignment: .center, spacing: 14) {
                TimeField(label: "Hours", value: store.$hours, range: 0...23)
                colon
                TimeField(label: "Minutes", value: store.$minutes, range: 0...59)
                colon
                TimeField(label: "Seconds", value: store.$seconds, range: 0...59)
            }

            Button("Proceed") { store.stage = .questions }
                // .buttonStyle(PillButtonStyle(prominent: true, enabled: store.totalSeconds > 0))
                .disabled(store.totalSeconds <= 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var colon: some View {
        Text(":").zenTitle(34).foregroundColor(.zenSubtle).padding(.bottom, 18)
    }
}

/// A labelled numeric field with steppers, clamped to a range.
/// When not being typed into, the value renders as animated rolling digits so
/// pressing the steppers smoothly counts up/down instead of popping.
private struct TimeField: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    /* @FocusState */ @State private var focused: Bool = false
    @State private var scrollAccum: CGFloat = 0

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    if focused {
                        TextField("", value: $value)
                            // .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            // .focused($focused)
                            .onChange(of: value) {
                                self.value = min(max(value, range.lowerBound), range.upperBound)
                            }
                    } else {
                        Text("\(value)")
                            // .monospacedDigit()
                            // .contentTransition(.numericText())
                            // .contentShape(Rectangle())
                            .onTapGesture { focused = true }
                    }
                }
                .font(.system(size: 34, weight: .semibold, design: .default))
                .foregroundColor(.zenText)
                .frame(width: 78)
                // .animation(.spring(response: 0.35, dampingFraction: 0.72), value: value)
                // Scroll (two-finger swipe) over the number to nudge it up/down.
                #if canImport(AppKitBackend)
                    .overlay {
                        ScrollWheelReader { _, deltaY in
                            scrollAccum += deltaY
                            let stepPts: CGFloat = 34   // higher = less sensitive
                            while scrollAccum >= stepPts {
                                value = min(value + 1, range.upperBound); scrollAccum -= stepPts
                            }
                            while scrollAccum <= -stepPts {
                                value = max(value - 1, range.lowerBound); scrollAccum += stepPts
                            }
                            return true   // consume vertical scroll over the number
                        }
                    }
                #endif

                // Custom up/down buttons (no native NSStepper focus ring).
                VStack(spacing: 3) {
                    stepButton(/* "chevron.up" */ "+") {
                        value = min(value + 1, range.upperBound)
                    }
                    stepButton(/* "chevron.down" */ "-") {
                        value = max(value - 1, range.lowerBound)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.10)))

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.zenSubtle)
        }
    }

    private func stepButton(_ symbol: String, action: @escaping @MainActor @Sendable () -> Void) -> some View {
        Button(symbol, action: action)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.zenText)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.14)))
            // .focusable(false)
            // .buttonStyle(.plain)
    }
}

// MARK: - Step 2: questions table

struct QuestionsView: View {
    @Environment(ExamStore.self) var store

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text("Questions & Marks").zenTitle(28)
                Text("List each question and how many marks it's worth. Swipe a row left to delete it.")
                    .font(.system(size: 15, design: .default))
                    .foregroundColor(.zenSubtle)
            }

            // Compact column-label row, aligned to the cells below.
            // NOTE: the trailing spacer must have a definite HEIGHT — a width-only
            // Color.clear is height-greedy and would inflate this whole row.
            HStack(spacing: 10) {
                Text("#").frame(width: 28, alignment: .leading)
                Text("QUESTION").frame(maxWidth: .infinity, alignment: .leading)
                Text("MARKS").frame(width: 90, alignment: .leading)
                Color.clear.frame(width: 28, height: 1)
            }
            .font(.system(size: 11, weight: .semibold, design: .default))
            // .tracking(0.5)
            .foregroundColor(.zenSubtle.opacity(0.7))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.bottom, 2)

            // ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(store.questions.enumerated()), id: \.element.id) { index, _ in
                            QuestionRow(index: index)
                        }
                    }
                    .padding(.vertical, 1)
                }
            //     .overlay(scrollReactor(proxy: proxy), alignment: .bottom)
            // }
            // The list fills the FIXED region between the header and the buttons and
            // scrolls internally. This keeps the buttons pinned in place no matter how
            // many questions are added (adding a row scrolls, it doesn't push layout).
            // ScrollView content stays top-aligned, so rows sit right under the header.
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.bottom, 4)

            HStack {
                Button("Add question") {
                    scrollTarget = store.addQuestion()
                } /* label: {
                    Label("Add question", systemImage: "plus")
                } */
                // .buttonStyle(PillButtonStyle())

                Spacer()

                Button("Back") { store.stage = .setup }
                    // .buttonStyle(PillButtonStyle())
                Button("Proceed") { store.stage = .summary }
                    // .buttonStyle(PillButtonStyle(prominent: true, enabled: canProceed))
                    .disabled(!canProceed)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @State private var scrollTarget: UUID?

    /// Empty overlay used only to react to `scrollTarget` changes with the proxy in scope.
    // private func scrollReactor(proxy: ScrollViewProxy) -> some View {
    //     Color.clear
    //         .frame(height: 0)
    //         .onChange(of: scrollTarget) { id in
    //             guard let id else { return }
    //             // withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
    //                 proxy.scrollTo(id, anchor: .bottom)
    //             // }
    //         }
    // }

    private var canProceed: Bool {
        !store.questions.isEmpty &&
        store.totalMarks > 0 &&
        store.questions.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

private struct QuestionRow: View {
    @Environment(ExamStore.self) var store
    let index: Int
    @State private var appeared = false
    @State private var drag: CGFloat = 0
    @State private var swipeAccum: CGFloat = 0
    @State private var swipeReset: DispatchWorkItem?

    private var canDelete: Bool { store.questions.count > 1 }
    private var questionID: UUID? {
        store.questions.indices.contains(index) ? store.questions[index].id : nil
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Red "delete" backdrop revealed as the row is swiped left.
            // RoundedRectangle(cornerRadius: 12)
            //     .fill(Color(red: 0.78, green: 0.20, blue: 0.20))
            //     .overlay(alignment: .trailing) {
            //         // Image(systemName: "trash.fill")
            //         //     .foregroundColor(.white)
            //         //     .font(.system(size: 15, weight: .semibold))
            //         Color.red.frame(width: 15, height: 15)
            //             .padding(.trailing, 22)
            //     }
                // .opacity(drag < -4 ? 1 : 0)

            rowContent
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                // .offset(x: drag)
                // .gesture(swipeGesture)
                // Two-finger trackpad swipe-left to delete (scroll-wheel deltas).
                #if canImport(AppKitBackend)
                    .overlay {
                        ScrollWheelReader { dx, dy in
                            handleSwipe(deltaX: dx, deltaY: dy)
                        }
                    }
                #endif
        }
        .font(.system(size: 15, design: .default))
        // Staggered entrance: rows fade/slide in one after another, quickly.
        // .opacity(appeared ? 1 : 0)
        // .offset(y: appeared ? 0 : 10)
        .onAppear {
            // withAnimation(.spring(response: 0.4, dampingFraction: 0.85)
                // .delay(Double(index) * 0.06)) {
                appeared = true
            // }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(.zenSubtle)
                .frame(width: 28, alignment: .leading)

            TextField("Question name", text: bindingName)
                // .textFieldStyle(.plain)
                .foregroundColor(.zenText)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("0", value: bindingMarks)
                // .textFieldStyle(.plain)
                .foregroundColor(.zenText)
                .frame(width: 90, alignment: .leading)

            Button("Delete") {
                deleteSelf()
            } /* label: {
                Image(systemName: "trash")
                    .foregroundColor(.zenSubtle)
            } */
            // .buttonStyle(.plain)
            // .frame(width: 28)
            .disabled(!canDelete)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
    }

    /// Trackpad swipe-left to delete: drag the row left, and past a threshold it
    /// slides off and is removed. A short swipe springs back.
    // private var swipeGesture: some Gesture {
    //     DragGesture(minimumDistance: 12)
    //         .onChanged { v in
    //             guard canDelete else { return }
    //             // Only track leftward drags; ignore mostly-vertical gestures.
    //             if v.translation.width < 0 && abs(v.translation.width) > abs(v.translation.height) {
    //                 drag = max(v.translation.width, -160)
    //             }
    //         }
    //         .onEnded { v in
    //             if canDelete && v.translation.width < -80 {
    //                 /* withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { */ drag = -520 /* } */
    //                 scheduleDelete()
    //             } else {
    //                 /* withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { */ drag = 0 /* } */
    //             }
    //         }
    // }

    #if canImport(AppKitBackend)
        /// Handle a two-finger trackpad swipe. Returns true when the horizontal swipe
        /// is consumed; vertical scrolls are passed back so the list still scrolls.
        private func handleSwipe(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
            guard canDelete, abs(deltaX) > abs(deltaY) else { return false }

            // Natural scrolling: a leftward swipe yields negative deltaX.
            swipeAccum = max(min(swipeAccum + deltaX, 0), -170)
            // withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.85)) {
                drag = swipeAccum
            // }

            if swipeAccum <= -90 {
                swipeReset?.cancel()
                swipeAccum = 0
                /* withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { */ drag = -520 /* } */
                scheduleDelete()
                return true
            }

            // Spring back if the swipe stalls short of the threshold.
            swipeReset?.cancel()
            let item = DispatchWorkItem {
                swipeAccum = 0
                /* withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { */ drag = 0 /* } */
            }
            swipeReset = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
            return true
        }
    #endif

    /// Immediate delete (trash button) — resolved by identity.
    private func deleteSelf() {
        guard canDelete, let id = questionID else { return }
        // withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            store.removeQuestion(id: id)
        // }
    }

    /// Deferred delete (after the row slides off) — captures the id NOW so a
    /// concurrent delete shifting the array can't retarget the wrong row.
    private func scheduleDelete() {
        guard canDelete, let id = questionID else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            // withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                store.removeQuestion(id: id)
            // }
        }
    }

    // Index-safe bindings (rows can be removed underneath us).
    private var bindingName: Binding<String> {
        Binding(
            get: { store.questions.indices.contains(index) ? store.questions[index].name : "" },
            set: { if store.questions.indices.contains(index) { store.questions[index].name = $0 } }
        )
    }
    private var bindingMarks: Binding<Double> {
        Binding(
            get: { store.questions.indices.contains(index) ? store.questions[index].marks : 0 },
            set: { if store.questions.indices.contains(index) { store.questions[index].marks = max(0, $0) } }
        )
    }
}

// MARK: - Step 3: summary

struct SummaryView: View {
    @Environment(ExamStore.self) var store

    var body: some View {
        VStack(spacing: 24) {
            Text("Ready when you are").zenTitle(28)

            HStack(spacing: 16) {
                SummaryTile(value: store.totalSeconds.hms, label: "Total time")
                SummaryTile(value: numberString(store.totalMarks), label: "Total marks")
                SummaryTile(value: "\(store.questions.count)", label: "Questions")
            }

            Text("That's about \(perMarkString) per mark.")
                .font(.system(size: 14, design: .default))
                .foregroundColor(.zenSubtle)

            HStack {
                Button("Back") { store.stage = .questions }
                    // .buttonStyle(PillButtonStyle())
                Button("Let's Go") { store.startExam() }
                    // .buttonStyle(PillButtonStyle(prominent: true, enabled: store.isConfigurationValid))
                    .disabled(!store.isConfigurationValid)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var perMarkString: String {
        let t = store.timePerMark
        if t >= 60 {
            let m = Int(t) / 60, s = Int(t) % 60
            return "\(m)m \(s)s"
        }
        return String(format: "%.1fs", t)
    }

    private func numberString(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

private struct SummaryTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .default))
                .foregroundColor(.zenText)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.zenSubtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.10)))
    }
}

// MARK: - Scroll-wheel input

#if canImport(AppKitBackend)
    /// Reports trackpad / mouse scroll deltas over its area without swallowing clicks.
    /// Uses a local scroll-wheel monitor keyed to the view's bounds, and returns `nil`
    /// from `hitTest` so taps still reach the SwiftUI controls underneath.
    /// The handler returns `true` to consume the event (stop it propagating), or
    /// `false` to let it pass through (e.g. vertical scrolls a row shouldn't eat).
    struct ScrollWheelReader: NSViewRepresentable {
        let onScroll: (_ deltaX: CGFloat, _ deltaY: CGFloat) -> Bool

        func makeNSView(context: Context) -> ScrollCatcherView {
            let v = ScrollCatcherView()
            v.onScroll = onScroll
            return v
        }

        func updateNSView(_ nsView: ScrollCatcherView, context: Context) {
            nsView.onScroll = onScroll
        }
    }

    final class ScrollCatcherView: NSView {
        var onScroll: ((CGFloat, CGFloat) -> Bool)?
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil, monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self, let window = self.window, event.window == window else { return event }
                let p = self.convert(event.locationInWindow, from: nil)
                if self.bounds.contains(p),
                   self.onScroll?(event.scrollingDeltaX, event.scrollingDeltaY) == true {
                    return nil   // consumed — nothing behind also scrolls
                }
                return event
            }
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }

        // Pass all mouse events through to the SwiftUI controls beneath.
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }
#endif
