import Foundation

enum QuizType: String, Codable, CaseIterable, Identifiable {
    case mcq
    case saq

    var id: Self { self }
    var title: String { self == .mcq ? "Multiple choice" : "Short answer" }
}

struct QuizSet: Codable, Identifiable, Equatable {
    let version: Int
    let id: String
    let title: String
    let description: String?
    let questions: [QuizQuestion]
    let type: QuizType

    init(version: Int, id: String, title: String, description: String?, questions: [QuizQuestion], type: QuizType = .mcq) {
        self.version = version
        self.id = id
        self.title = title
        self.description = description
        self.questions = questions
        self.type = type
    }

    private enum CodingKeys: String, CodingKey { case version, id, title, description, questions, type }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            version: try values.decode(Int.self, forKey: .version),
            id: try values.decode(String.self, forKey: .id),
            title: try values.decode(String.self, forKey: .title),
            description: try values.decodeIfPresent(String.self, forKey: .description),
            questions: try values.decode([QuizQuestion].self, forKey: .questions),
            type: try values.decodeIfPresent(QuizType.self, forKey: .type) ?? .mcq
        )
    }

    var questionCount: Int { questions.count }

    func validate() throws {
        guard version == 1 else {
            throw QuizError.invalid("Unsupported format version \(version). Expected version 1.")
        }
        guard !id.trimmed.isEmpty, !title.trimmed.isEmpty else {
            throw QuizError.invalid("The set needs a nonempty id and title.")
        }
        guard !questions.isEmpty else {
            throw QuizError.invalid("Add at least one question.")
        }

        var questionIDs = Set<String>()
        for (index, question) in questions.enumerated() {
            let label = "Question \(index + 1)"
            guard !question.id.trimmed.isEmpty, !question.question.trimmed.isEmpty,
                  type == .saq || !question.explanation.trimmed.isEmpty else {
                throw QuizError.invalid("\(label) needs an id, question, and explanation.")
            }
            guard questionIDs.insert(question.id).inserted else {
                throw QuizError.invalid("Question id '\(question.id)' appears more than once.")
            }
            if type == .saq {
                guard question.choices.isEmpty, question.correctAnswerId.isEmpty else {
                    throw QuizError.invalid("\(label) is short answer and cannot contain choices or correctAnswerId.")
                }
                continue
            }
            guard (2...6).contains(question.choices.count) else {
                throw QuizError.invalid("\(label) needs between 2 and 6 choices.")
            }

            var choiceIDs = Set<String>()
            for choice in question.choices {
                guard !choice.id.trimmed.isEmpty, !choice.text.trimmed.isEmpty else {
                    throw QuizError.invalid("\(label) has an empty choice id or text.")
                }
                guard choiceIDs.insert(choice.id).inserted else {
                    throw QuizError.invalid("\(label) repeats choice id '\(choice.id)'.")
                }
            }
            guard choiceIDs.contains(question.correctAnswerId) else {
                throw QuizError.invalid("\(label)'s correctAnswerId does not match a choice.")
            }
        }
    }
}

struct QuizQuestion: Codable, Identifiable, Equatable {
    let id: String
    let question: String
    let description: String?
    let hints: [String]
    let choices: [AnswerChoice]
    let correctAnswerId: String
    let explanation: String
    let image: QuestionImage?

    init(id: String, question: String, description: String? = nil, hints: [String], choices: [AnswerChoice] = [], correctAnswerId: String = "", explanation: String = "", image: QuestionImage? = nil) {
        self.id = id
        self.question = question
        self.description = description
        self.hints = hints
        self.choices = choices
        self.correctAnswerId = correctAnswerId
        self.explanation = explanation
        self.image = image
    }

    private enum CodingKeys: String, CodingKey { case id, question, description, hints, choices, correctAnswerId, explanation, image }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try values.decode(String.self, forKey: .id),
            question: try values.decode(String.self, forKey: .question),
            description: try values.decodeIfPresent(String.self, forKey: .description),
            hints: try values.decode([String].self, forKey: .hints),
            choices: try values.decodeIfPresent([AnswerChoice].self, forKey: .choices) ?? [],
            correctAnswerId: try values.decodeIfPresent(String.self, forKey: .correctAnswerId) ?? "",
            explanation: try values.decodeIfPresent(String.self, forKey: .explanation) ?? "",
            image: try values.decodeIfPresent(QuestionImage.self, forKey: .image)
        )
    }

    var correctChoice: AnswerChoice? {
        choices.first { $0.id == correctAnswerId }
    }
}

struct AnswerChoice: Codable, Identifiable, Equatable {
    let id: String
    let text: String
}

// Reserved for a later image renderer. v1 accepts metadata but never fetches or displays it.
struct QuestionImage: Codable, Equatable {
    let url: String?
    let alt: String?
}

enum QuizError: LocalizedError {
    case invalid(String)

    var errorDescription: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

enum QuizCodec {
    static func decode(_ data: Data) throws -> QuizSet {
        let decoder = JSONDecoder()
        let set = try decoder.decode(QuizSet.self, from: data)
        try set.validate()
        return set
    }

    static func encode(_ set: QuizSet) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(set)
    }
}
