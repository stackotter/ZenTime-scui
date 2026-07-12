import Foundation
import Combine

/// The screens ZenTime walks through, in order.
enum Stage {
    case setup       // enter total exam time
    case questions   // enter questions + marks
    case summary     // review totals, then start
    case running     // live timing
    case finished    // time is up (chime played), awaiting acknowledge
    case save        // offer to save a PDF report
    case done        // finished / reset
}

/// One exam question with its mark weight and accumulated time.
struct Question: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var marks: Double
    var elapsed: TimeInterval = 0   // total time spent on this question (across revisits)
}

/// Central state + timing engine. All mutation happens on the main actor.
@MainActor
final class ExamStore: ObservableObject {

    // MARK: Navigation
    @Published var stage: Stage = .setup

    // MARK: Setup inputs
    @Published var hours: Int = 1
    @Published var minutes: Int = 30
    @Published var seconds: Int = 0

    // MARK: Report metadata
    /// The exam's name, asked for on the save screen and printed on the PDF report.
    @Published var examName: String = ""

    // MARK: Questions
    @Published var questions: [Question] = [
        Question(name: "Question 1", marks: 10),
        Question(name: "Question 2", marks: 10),
    ]

    // MARK: Live timing state
    @Published var currentIndex: Int = 0
    @Published var remaining: TimeInterval = 0   // total time left
    @Published var isArmed: Bool = false          // false during the 1s navigation grace
    @Published var finishedEarly: Bool = false    // true if the student ended before time ran out

    // MARK: Derived values
    var totalSeconds: TimeInterval {
        TimeInterval(max(0, hours) * 3600 + max(0, minutes) * 60 + max(0, seconds))
    }
    var totalMarks: Double {
        questions.reduce(0) { $0 + max(0, $1.marks) }
    }
    var timePerMark: TimeInterval {
        totalMarks > 0 ? totalSeconds / totalMarks : 0
    }
    func expectedTime(for question: Question) -> TimeInterval {
        timePerMark * max(0, question.marks)
    }
    var currentQuestion: Question? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    /// Whether the setup values form a runnable exam.
    var isConfigurationValid: Bool {
        totalSeconds > 0 &&
        !questions.isEmpty &&
        totalMarks > 0 &&
        questions.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    // MARK: Private timing internals
    private var ticker: Timer?
    private var lastTick: Double?   // monotonic uptime seconds; immune to wall-clock changes
    private var graceItem: DispatchWorkItem?

    private var now: Double { ProcessInfo.processInfo.systemUptime }

    /// Called when the countdown reaches zero.
    var onFinished: (() -> Void)?

    // MARK: Question editing
    @discardableResult
    func addQuestion() -> UUID {
        let q = Question(name: "Question \(questions.count + 1)", marks: 10)
        questions.append(q)
        return q.id
    }
    func removeQuestion(at index: Int) {
        guard questions.indices.contains(index) else { return }
        questions.remove(at: index)
    }
    /// Remove by identity — safe when a delete is deferred past an animation and
    /// the array may have shifted underneath the row's captured index.
    func removeQuestion(id: UUID) {
        guard questions.count > 1, let idx = questions.firstIndex(where: { $0.id == id }) else { return }
        questions.remove(at: idx)
    }

    // MARK: Exam lifecycle
    func startExam() {
        currentIndex = 0
        remaining = totalSeconds
        finishedEarly = false
        for i in questions.indices { questions[i].elapsed = 0 }
        stage = .running
        startTicker()
        armAfterGrace()
    }

    /// End the exam before time runs out (from the last question). Treated as a completion.
    func finishEarly() {
        finishedEarly = true
        finish()
    }

    func goNext() {
        guard currentIndex < questions.count - 1 else { return }
        currentIndex += 1
        armAfterGrace()
    }

    func goPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        armAfterGrace()
    }

    /// Pause the clocks, then re-arm after ~1s so the student can choose a question.
    private func armAfterGrace() {
        isArmed = false
        lastTick = nil
        graceItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.isArmed = true
            self.lastTick = self.now
        }
        graceItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: item)
    }

    private func startTicker() {
        ticker?.invalidate()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func tick() {
        guard stage == .running, isArmed, let last = lastTick else { return }
        let current = now
        let dt = max(0, current - last)   // clamp so a clock hiccup never rewinds time
        lastTick = current

        if questions.indices.contains(currentIndex) {
            questions[currentIndex].elapsed += dt
        }
        remaining -= dt

        if remaining <= 0 {
            remaining = 0
            finish()
        }
    }

    private func finish() {
        guard stage == .running else { return }   // ignore double-fire (fast click + timeout tick)
        stopTicker()
        isArmed = false
        stage = .finished
        onFinished?()
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
        graceItem?.cancel()
        graceItem = nil
        lastTick = nil
    }

    /// Advance from the finished screen to the save prompt.
    func acknowledge() {
        stage = .save
    }

    /// Return to the setup screen, keeping the prior time/questions for convenience.
    /// (`startExam()` re-zeroes each question's elapsed time, so a fresh run starts clean.)
    func reset() {
        stopTicker()
        currentIndex = 0
        remaining = 0
        isArmed = false
        stage = .setup
    }
}

// MARK: - Time formatting

extension TimeInterval {
    /// Formats a non-negative interval as HH:MM:SS.
    var hms: String {
        let total = Int(rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
