import SwiftUI

private enum Palette {
    static let blue = Color(red: 0.25, green: 0.52, blue: 0.91)
    static let mint = Color(red: 0.28, green: 0.73, blue: 0.61)
    static let pink = Color(red: 0.80, green: 0.48, blue: 0.72)
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
    @State private var session: QuizSession?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 230, ideal: 260, max: 320)
        } detail: {
            ZStack {
                ambientBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
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
                    .frame(maxWidth: 820)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 38)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar {
                ToolbarItemGroup {
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
        .onAppear(perform: resetSession)
        .onChange(of: library.selectedSetID) { _ in resetSession() }
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
                            mutateSession { $0.advance() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.blue)
                        .controlSize(.large)
                    } else {
                        Button("Check answer") { mutateSession { $0.submit() } }
                            .buttonStyle(.borderedProminent)
                            .tint(Palette.blue)
                            .controlSize(.large)
                            .disabled(session.selectedChoiceID == nil)
                    }
                }
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
        }
        .buttonStyle(.plain)
        .disabled(session.hasSubmitted)
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
        VStack(alignment: .leading, spacing: 20) {
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
                Button("Try again") { mutateSession { $0.restart() } }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.blue)
            }
            .padding(26)
            .glassCard()

            Text("REVIEW")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.7)
                .foregroundStyle(.secondary)

            ForEach(Array(session.quizSet.questions.enumerated()), id: \.element.id) { index, question in
                VStack(alignment: .leading, spacing: 12) {
                    let correct = session.answers[question.id] == question.correctAnswerId
                    HStack {
                        Label("Question \(index + 1)", systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(correct ? Palette.mint : Palette.pink)
                        Spacer()
                        Text(correct ? "Correct" : "Review")
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    RichTextView(markdown: question.question, textSize: 17)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let answer = question.correctChoice {
                        HStack(alignment: .top, spacing: 8) {
                            Text("ANSWER")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                            RichTextView(markdown: answer.text, textSize: 13)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    RichTextView(markdown: question.explanation, textSize: 13)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(22)
                .glassCard(radius: 19)
            }
        }
    }

    private func resetSession() {
        session = library.selectedSet.map { QuizSession(quizSet: $0) }
    }

    private func mutateSession(_ mutation: (inout QuizSession) -> Void) {
        guard var updated = session else { return }
        mutation(&updated)
        session = updated
    }
}
