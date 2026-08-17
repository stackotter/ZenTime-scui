import Foundation
import SwiftCrossUI

/// Step 6: offer to save a styled PDF of the recorded times.
struct SaveView: View {
    @Environment(ExamStore.self) var store
    @State private var savedURL: URL?
    @State private var didAttempt = false
    @Environment(\.revealFile) var revealFile
    /* @FocusState */ @State private var nameFocused: Bool = false

    private var isSaved: Bool { savedURL != nil }
    private var trimmedName: String {
        store.examName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    #if os(macOS)
        private func attemptSave() {
            guard !trimmedName.isEmpty else {
                nameFocused = true
                return
            }
            store.examName = trimmedName
            // Run the (modal) save panel, then animate into the "Saved" state.
            let url = PDFExporter.savePDF(store: store)
            didAttempt = true
            // withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                savedURL = url
            // }
        }

        var body: some View {
            VStack(spacing: 22) {
                Circle().fill(Color.zenAccent)
                    .frame(width: 48, height: 48)
                // Image(systemName: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                //     .font(.system(size: 48))
                //     .foregroundColor(.zenAccent)
                    // .id(isSaved)
                    // .transition(.scale(scale: 0.5).combined(with: .opacity))

                Text(isSaved ? "Saved" : "Save your times?").zenTitle(30)
                    // .id(isSaved)
                    // .transition(.opacity.combined(with: .offset(y: 8)))

                Text(message)
                    .font(.system(size: 14, design: .default))
                    .foregroundColor(.zenSubtle)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
                    // .id(isSaved)
                    // .transition(.opacity)

                // Ask for the exam's name before saving — it titles the PDF report.
                if savedURL == nil {
                    VStack(spacing: 6) {
                        Text("Exam name")
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(.zenSubtle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("e.g. Physics Paper 1", text: store.$examName)
                            // .textFieldStyle(.plain)
                            .font(.system(size: 16, design: .default))
                            .foregroundColor(.zenText)
                            // .focused($nameFocused)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(/* Color.white.opacity(0.10) */ Color.gray))
                            // .overlay {
                            //     RoundedRectangle(cornerRadius: 12)
                            //     // .strokeBorder(Color.white.opacity(nameFocused ? 0.25 : 0.10), lineWidth: 1)
                            // }
                            .onSubmit { attemptSave() }
                    }
                    .frame(maxWidth: 360)
                    // .transition(.opacity)
                }

                HStack(spacing: 12) {
                    if savedURL == nil {
                        Button("Not now") { store.reset() }
                            // .buttonStyle(PillButtonStyle())
                        Button("Save PDF") { attemptSave() }
                            // .buttonStyle(PillButtonStyle(prominent: true, enabled: !trimmedName.isEmpty))
                            .disabled(trimmedName.isEmpty)
                    } else {
                        Button("Reveal in Finder") {
                            if let url = savedURL {
                                // NSWorkspace.shared.activateFileViewerSelecting([url])
                                revealFile?(url)
                            }
                        }
                        // .buttonStyle(PillButtonStyle())
                        Button("Done") { store.reset() }
                            // .buttonStyle(PillButtonStyle(prominent: true))
                    }
                }
                // .id(isSaved)
                // .transition(.opacity.combined(with: .offset(y: 10)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isSaved)
        }
    #else
        var body: some View {
            VStack(spacing: 22) {
                Text("Exporting PDF reports is not supported outside of macOS")
                Button("Done") { store.reset() }
                    // .buttonStyle(PillButtonStyle(prominent: true))
            }
        }
    #endif

    private var message: String {
        if let url = savedURL {
            return "Your report is saved at \(url.path)."
        }
        if didAttempt {
            return "Save was cancelled. You can try again or finish up."
        }
        return "Name your exam, then export a styled PDF of the time spent on each question — over-budget questions are highlighted."
    }
}
