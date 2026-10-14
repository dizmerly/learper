import AppKit
import SwiftUI

private enum Palette {
    static let blue = Color(red: 0.25, green: 0.52, blue: 0.91)
    static let mint = Color(red: 0.28, green: 0.73, blue: 0.61)
    static let pink = Color(red: 0.80, green: 0.48, blue: 0.72)
}

private enum ResultsTab: String, CaseIterable {
    case statistics = "Statistics"
    case review = "All questions"
}

private enum SidebarDestination {
    case quiz
    case createQuiz
}

private struct GlassCard: ViewModifier {
    var radius: CGFloat = 24

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius))
        } else {
            fallback(content)
        }
        #else
        fallback(content)
        #endif
    }

    private func fallback(_ content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(.white.opacity(0.24), lineWidth: 1)
            }
    }
}

private extension View {
    func glassCard(radius: CGFloat = 24) -> some View {
        modifier(GlassCard(radius: radius))
    }
}

struct ContentView: View {
    @EnvironmentObject private var library: QuizLibrary
    @ViewState private var session: QuizSession?
    @ViewState private var showingDeleteConfirmation = false
    @ViewState private var resultsTab: ResultsTab = .statistics
    @ViewState private var showingGraphEditor = false
    @ViewState private var destination: SidebarDestination = .quiz
    @ViewState private var promptTopic = ""
    @ViewState private var promptQuestionCount = 10
    @ViewState private var promptDifficulty: QuizDifficulty = .intermediate
    @ViewState private var promptCopied = false

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 230, ideal: 260, max: 320)
        } detail: {
            ZStack {
                ambientBackground
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 28) {
                        if destination == .createQuiz {
                            promptHeader
                            promptPage
                        } else {
                            header
                            if let session {
                                if session.showingResults {
                                    results(for: session)
                                } else {
                                    practice(for: session)
                                }
                            } else {
                                emptyState
                            }
                        }
                    }
                    .frame(maxWidth: 820)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 38)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar {
                ToolbarItemGroup {
                    Button { showingGraphEditor = true } label: {
                        Label("Create Graph", systemImage: "point.3.connected.trianglepath.dotted")
                    }
                    .help("Draw a graph from text")

                    Button { library.importFile() } label: {
                        Label("Import JSON", systemImage: "square.and.arrow.down")
                    }
                    .help("Import a quiz JSON file")

                    Button { library.importClipboard() } label: {
                        Label("Paste JSON", systemImage: "doc.on.clipboard")
                    }
                    .help("Import quiz JSON from the clipboard")
                }
            }
        }
        .background {
            QuizKeyboardView(onKey: handleQuizKey)
                .allowsHitTesting(false)
        }
        .onAppear(perform: resetSession)
        .onChange(of: library.selectedSetID) { _ in
            resetSession()
            destination = .quiz
        }
        .onChange(of: library.sets) { _ in
            resetSession()
            destination = .quiz
        }
        .onChange(of: promptTopic) { _ in promptCopied = false }
        .onChange(of: promptQuestionCount) { _ in promptCopied = false }
        .onChange(of: promptDifficulty) { _ in promptCopied = false }
        .sheet(isPresented: $showingGraphEditor) {
            GraphEditorView()
        }
        .alert("Could not load quiz", isPresented: Binding(
            get: { library.errorMessage != nil },
            set: { if !$0 { library.errorMessage = nil } }
        )) {
            Button("OK") { library.errorMessage = nil }
        } message: {
            Text(library.errorMessage ?? "Unknown error")
        }
        .confirmationDialog(
            "Remove this quiz from Learper?",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Remove Quiz", role: .destructive) {
                library.removeSelectedSet()
                resetSession()
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Palette.blue)
                Text("Learper")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)

            Text("YOUR QUIZZES")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 22)

            ScrollView {
                LazyVStack(spacing: 7) {
                    ForEach(library.sets) { set in
                        Button {
                            library.selectedSetID = set.id
                            destination = .quiz
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.stack.fill")
                                    .foregroundStyle(set.id == library.selectedSetID ? Palette.blue : .secondary)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(set.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .lineLimit(2)
                                    Text("\(set.questionCount) questions")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 13)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                set.id == library.selectedSetID ? Palette.blue.opacity(0.14) : .clear,
                                in: RoundedRectangle(cornerRadius: 13)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
            }

            Divider().padding(.horizontal, 18)
            Button {
                destination = .createQuiz
            } label: {
                Label("Create with AI", systemImage: "sparkles.rectangle.stack")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 12)
                    .background(
                        destination == .createQuiz ? Palette.blue.opacity(0.14) : .clear,
                        in: RoundedRectangle(cornerRadius: 13)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)

            Button { library.importFile() } label: {
                Label("Import quiz", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
        }
        .background(.regularMaterial)
    }

    private var ambientBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                Circle()
                    .fill(Palette.blue.opacity(0.15))
                    .frame(width: 470, height: 470)
                    .blur(radius: 95)
                    .offset(x: geometry.size.width * 0.35, y: -geometry.size.height * 0.43)
                Circle()
                    .fill(Palette.mint.opacity(0.13))
                    .frame(width: 440, height: 440)
                    .blur(radius: 105)
                    .offset(x: -geometry.size.width * 0.38, y: geometry.size.height * 0.42)
            }
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("STUDY SPACE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Palette.blue)
                Text(library.selectedSet?.title ?? "Ready to learn?")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tracking(-0.8)
                if let description = library.selectedSet?.description, !description.isEmpty {
                    Text(description)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 14))
                }
            }
            Spacer(minLength: 12)
            if session != nil {
                Menu {
                    Button("Restart quiz") { mutateSession { $0.restart() } }
                    Button("Remove quiz", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .glassCard(radius: 12)
                }
                .menuStyle(.borderlessButton)
                .help("Quiz actions")
            }
        }
    }

    private var promptHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CREATE A QUIZ")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(Palette.blue)
            Text("Ask any chatbot")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-0.8)
            Text("Set your topic, copy the full prompt, then import the JSON file your chatbot makes.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
    }

    private var promptPage: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 17) {
                Text("WHAT SHOULD THE QUIZ COVER?")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Palette.blue)

                Text("Enter a topic, paste notes, or describe what you want to practice.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                TextEditor(text: $promptTopic)
                    .font(.system(size: 14))
                    .frame(height: 90)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                    }
                    .accessibilityLabel("Topic, notes, or source material")

                HStack(spacing: 22) {
                    Stepper("Questions: \(promptQuestionCount)", value: $promptQuestionCount, in: 1...100)
                        .frame(maxWidth: 210)
                    Picker("Difficulty", selection: $promptDifficulty) {
                        ForEach(QuizDifficulty.allCases) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty)
                        }
                    }
                    .frame(maxWidth: 260)
                }

                HStack(spacing: 12) {
                    Button {
                        guard let prompt = generatedPrompt else { return }
                        NSPasteboard.general.clearContents()
                        promptCopied = NSPasteboard.general.setString(prompt, forType: .string)
                    } label: {
                        Label("Copy full prompt", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.blue)
                    .disabled(promptTopic.trimmed.isEmpty || generatedPrompt == nil)

                    if promptCopied {
                        Label("Copied", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.mint)
                    }
                }
            }
            .padding(26)
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("HOW IT WORKS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Palette.blue)
                Text("1. Paste the copied prompt into any chatbot.\n2. Download its learper-quiz.json file.\n3. Import that file here, or use Paste JSON if it returned text.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(6)
                HStack(spacing: 12) {
                    Button("Import JSON…") { library.importFile() }
                    Button("Paste JSON") { library.importClipboard() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(26)
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("PROMPT PREVIEW")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Palette.blue)
                if let prompt = generatedPrompt {
                    ScrollView {
                        Text(verbatim: prompt)
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 300)
                } else {
                    Text("The bundled quiz format could not be loaded.")
                        .foregroundStyle(Palette.pink)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(26)
            .glassCard()
        }
    }

    private var generatedPrompt: String? {
        guard let format = QuizPrompt.formatDocument else { return nil }
        return QuizPrompt.make(
            topic: promptTopic.trimmed.isEmpty ? "[topic or supplied notes]" : promptTopic,
            questionCount: promptQuestionCount,
            difficulty: promptDifficulty,
            format: format
        )
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(Palette.blue)
            Text("Your next quiz starts here")
                .font(.system(size: 23, weight: .semibold, design: .rounded))
            Text("Import a JSON quiz made with the agent format, or paste one from your clipboard.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 390)
            Button("Import JSON…") { library.importFile() }
                .buttonStyle(.borderedProminent)
                .tint(Palette.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(65)
        .glassCard()
    }

    private func practice(for session: QuizSession) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Label("Question \(session.questionIndex + 1) of \(session.quizSet.questionCount)", systemImage: "circle.grid.2x2.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(session.correctCount) correct so far")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(session.questionIndex + 1), total: Double(session.quizSet.questionCount))
                .tint(Palette.blue)

            VStack(alignment: .leading, spacing: 18) {
                Text("CHOOSE THE BEST ANSWER")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Palette.blue)
                RichTextView(markdown: session.question.question, textSize: 22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let description = session.question.description, !description.isEmpty {
                    RichTextView(markdown: description, textSize: 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Divider()
                VStack(spacing: 10) {
                    ForEach(Array(session.question.choices.enumerated()), id: \.element.id) { index, choice in
                        choiceRow(choice, index: index, session: session)
                    }
                }

                if !session.hasSubmitted, !session.question.hints.isEmpty {
                    hintSection(for: session)
                }
                if session.hasSubmitted {
                    feedback(for: session)
                }

                HStack {
                    Spacer()
                    if session.hasSubmitted {
                        Button(session.isLastQuestion ? "See results" : "Next question") {
                            mutateSession { $0.primaryAction() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.blue)
                        .controlSize(.large)
                    } else {
                        Button("Check answer") { mutateSession { $0.primaryAction() } }
                            .buttonStyle(.borderedProminent)
                            .tint(Palette.blue)
                            .controlSize(.large)
                            .disabled(session.selectedChoiceID == nil)
                    }
                }
                Text("Press 1–4 to choose an answer. Press Space to check, then Space again to continue.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(28)
            .glassCard()
        }
    }

    private func choiceRow(_ choice: AnswerChoice, index: Int, session: QuizSession) -> some View {
        let selected = session.selectedChoiceID == choice.id
        let correct = session.hasSubmitted && choice.id == session.question.correctAnswerId
        let incorrect = session.hasSubmitted && selected && !correct
        let tint = correct ? Palette.mint : (incorrect ? Palette.pink : Palette.blue)

        return Button {
            mutateSession { $0.select(choice.id) }
        } label: {
            HStack(alignment: .center, spacing: 13) {
                Text(String(UnicodeScalar(65 + index)!))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(selected || correct ? .white : .secondary)
                    .frame(width: 29, height: 29)
                    .background(selected || correct ? tint : Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 9))
                RichTextView(markdown: choice.text, textSize: 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .allowsHitTesting(false)
                if selected || correct {
                    Image(systemName: correct ? "checkmark.circle.fill" : (incorrect ? "xmark.circle.fill" : "circle.inset.filled"))
                        .foregroundStyle(tint)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                selected || correct ? tint.opacity(0.12) : Color.primary.opacity(0.035),
                in: RoundedRectangle(cornerRadius: 15)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(selected || correct ? tint.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
        .disabled(session.hasSubmitted)
        .accessibilityLabel("Choice \(index + 1): \(choice.text)")
    }

    private func hintSection(for session: QuizSession) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(0..<session.revealedHintCount, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.orange)
                    RichTextView(markdown: session.question.hints[index], textSize: 13)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if session.revealedHintCount < session.question.hints.count {
                Button(session.revealedHintCount == 0 ? "Show a hint" : "Show another hint") {
                    mutateSession { $0.revealHint() }
                }
                .font(.system(size: 12, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundStyle(Palette.blue)
            }
        }
        .padding(.top, 5)
    }

    private func feedback(for session: QuizSession) -> some View {
        let correct = session.selectedChoiceID == session.question.correctAnswerId
        return VStack(alignment: .leading, spacing: 9) {
            Label(correct ? "Nice work" : "Keep going", systemImage: correct ? "checkmark.seal.fill" : "arrow.uturn.backward.circle.fill")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(correct ? Palette.mint : Palette.pink)
            if !correct, let answer = session.question.correctChoice {
                Text("Correct answer: \(answer.id.uppercased())")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            RichTextView(markdown: session.question.explanation, textSize: 14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((correct ? Palette.mint : Palette.pink).opacity(0.10), in: RoundedRectangle(cornerRadius: 15))
    }

    private func results(for session: QuizSession) -> some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 22) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Palette.blue)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Quiz complete")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("You got \(session.correctCount) of \(session.quizSet.questionCount) right.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Try again") {
                    resultsTab = .statistics
                    mutateSession { $0.restart() }
                }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.blue)
            }
            .padding(26)
            .glassCard()

            Picker("Results", selection: $resultsTab) {
                ForEach(ResultsTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 320)

            if resultsTab == .statistics {
                statistics(for: session)
            } else {
                sectionHeading("ALL QUESTIONS")
                ForEach(session.outcomes) { outcome in
                    outcomeCard(outcome)
                }
            }
        }
    }

    private func statistics(for session: QuizSession) -> some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                statisticCard("\(session.correctCount)", label: "Correct", color: Palette.mint)
                statisticCard("\(session.missedOutcomes.count)", label: "Missed", color: Palette.pink)
                statisticCard("\(session.accuracyPercent)%", label: "Accuracy", color: Palette.blue)
            }

            sectionHeading("MISSED QUESTIONS")
            if session.missedOutcomes.isEmpty {
                Label("You got every question right.", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.mint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(25)
                    .glassCard(radius: 19)
            } else {
                ForEach(session.missedOutcomes) { outcome in
                    outcomeCard(outcome)
                }
            }
        }
    }

    private func statisticCard(_ value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(radius: 19)
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .tracking(1.7)
            .foregroundStyle(.secondary)
    }

    private func outcomeCard(_ outcome: QuestionOutcome) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    "Question \(outcome.number)",
                    systemImage: outcome.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .foregroundStyle(outcome.isCorrect ? Palette.mint : Palette.pink)
                Spacer()
                Text(outcome.isCorrect ? "Correct" : "Missed")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 12, weight: .semibold))

            RichTextView(markdown: outcome.question.question, textSize: 17)
                .frame(maxWidth: .infinity, alignment: .leading)
            answerLine("YOUR ANSWER", text: outcome.selectedChoice.text)
            if !outcome.isCorrect, let correctChoice = outcome.correctChoice {
                answerLine("CORRECT ANSWER", text: correctChoice.text)
            }
            Divider()
            RichTextView(markdown: outcome.question.explanation, textSize: 13)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .glassCard(radius: 19)
    }

    private func answerLine(_ label: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            RichTextView(markdown: text, textSize: 13)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func resetSession() {
        session = library.selectedSet.map { QuizSession(quizSet: $0) }
        resultsTab = .statistics
    }

    private func handleQuizKey(_ key: QuizKey) -> Bool {
        guard destination == .quiz, !showingGraphEditor,
              let session, !session.showingResults else { return false }
        switch key {
        case .choice(let number):
            guard !session.hasSubmitted, number <= session.question.choices.count else { return false }
            mutateSession { $0.selectChoice(number: number) }
        case .primaryAction:
            mutateSession { $0.primaryAction() }
        }
        return true
    }

    private func mutateSession(_ mutation: (inout QuizSession) -> Void) {
        guard var updated = session else { return }
        mutation(&updated)
        session = updated
    }
}
