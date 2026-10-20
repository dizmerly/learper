# Learper portable quiz file (v1)

Give this document to any chatbot. Learper imports its JSON output locally; no account or API key is needed.

## Request to paste into a chatbot

> Create a Learper v1 [quiz type] quiz about **[topic or supplied notes]** with **[number]** questions at **[difficulty]** difficulty. [selection instruction] Use `"type": "[quiz type id]"` and follow only the matching question shape below. Set `"weight": 1` on every new question; when revising an existing quiz, preserve each supplied question weight unless changing it is explicitly requested. Create and attach a downloadable UTF-8 file named `learper-quiz.json` containing one JSON object, with no Markdown fences or commentary. If you cannot attach a file, provide the complete JSON in one `json` code block. If the source material is insufficient, say so instead of inventing facts. Use fenced `mermaid` blocks for diagrams when helpful; do not use image URLs.

## Common fields

The top-level object has `version` (always `1`), a unique `id`, a nonempty `title`, optional `description`, `type` (`"mcq"` or `"saq"`), and a nonempty `questions` array. Question IDs must be unique within a set. Each question has a nonempty `question`, optional `description`, a `hints` array (use `[]` when there are no hints), and `weight` (start at `1`). Importing the same set ID replaces the earlier set. Old files without `type` still import as MCQ; old questions without `weight` start at `1`.

## Multiple choice (`"type": "mcq"`)

```json
{
  "version": 1,
  "id": "example-mcq",
  "title": "Example MCQ",
  "type": "mcq",
  "questions": [
    {
      "id": "q1",
      "question": "What is 2 + 2?",
      "weight": 1,
      "hints": ["Add two to two."],
      "choices": [
        { "id": "a", "text": "3" },
        { "id": "b", "text": "4" }
      ],
      "correctAnswerId": "b",
      "explanation": "Two plus two is four."
    },
    {
      "id": "q2",
      "question": "Which numbers are even? Select all that apply.",
      "weight": 1,
      "hints": [],
      "choices": [
        { "id": "a", "text": "2" },
        { "id": "b", "text": "3" },
        { "id": "c", "text": "4" }
      ],
      "correctAnswerIds": ["a", "c"],
      "explanation": "Two and four are divisible by two."
    }
  ]
}
```

Each MCQ needs 2–6 choices with unique IDs and nonempty text, plus a nonempty `explanation`. For a single-answer question use one matching `correctAnswerId`. For a select-all-that-apply question, omit `correctAnswerId` and use `correctAnswerIds` with at least two distinct IDs from the choices. Never use both fields on one question. Learper lets the student toggle multiple choices and marks the answer correct only when the selected set matches every correct ID and contains no extra choices. Make distractors plausible. Keep the answer out of the question and choices. Learper grades each answer immediately.

## Short answer (`"type": "saq"`)

```json
{
  "version": 1,
  "id": "example-saq",
  "title": "Example SAQ",
  "type": "saq",
  "questions": [
    {
      "id": "q1",
      "question": "Explain why 2 + 2 equals 4.",
      "weight": 1,
      "hints": ["Think of two pairs."],
      "explanation": "A complete answer explains that two objects combined with two more form a set of four."
    }
  ]
}
```

SAQ questions have no `choices`, `correctAnswerId`, or `correctAnswerIds`. The optional `explanation` is reference answer or grading guidance; it is hidden while the student answers and included in the final text copied for chatbot grading. Make questions clear enough to assess from the student's written answer. Learper does not assign scores to SAQs.

## Practice weights

Learper stores a weight on each question in the quiz JSON. The default is `1`; accepted values are `0.25` through `5`. After answering, the student rates how hard the question felt: **Easy** multiplies weight by `0.6`, **Moderate** by `0.85`, **Hard** by `1.5`, and **Impossible** by `2`. The result is rounded to two decimals and kept within the accepted range.

Students can place quizzes in folders and practice every quiz in a folder together. New questions (all weight `1`) appear once in a random order. In later folder sessions, every question still appears once, while higher weights add more repeat draws and make a question more likely to be drawn. This is a weighted review loop using Anki-style self-ratings, rather than Anki's date-based FSRS scheduler.

After practice, **Copy results for chatbot** includes the answers, ratings, updated weights, and an explanation of what the weights mean. **Export Updated JSON…** writes the current quiz, including its weights, to a new file. Learper also saves those weights in its local library JSON. The original downloaded import file is not edited automatically.

## Rich text and diagrams

Question, description, hint, choice, and explanation text support Markdown, inline `$...$` and display `$$...$$` LaTeX, plus fenced code blocks. C, C++, Python, and Rust code is highlighted. JSON strings must escape newlines as `\n` and LaTeX backslashes as `\\`.

Use a fenced `mermaid` block for a diagram. Mermaid flowcharts, sequence diagrams, class diagrams, and other supported Mermaid syntax are rendered locally:

````markdown
```mermaid
flowchart LR
  A[Start] --> B{Ready?}
  B -- Yes --> C[Continue]
  B -- No --> A
```
````

The same block in a JSON string begins `"```mermaid\nflowchart LR\n` and ends `\n```"`. Keep each diagram under 12,000 characters and 200 edges. Invalid syntax displays an inline error, leaving the rest of the question visible. Mermaid diagrams are rendered offline and cannot run links or scripts.

The optional `image` object with `url` and `alt` strings remains accepted for compatibility, but Learper does not fetch or display images. Prefer Mermaid for diagrams.

## Download and import

Download `learper-quiz.json` and choose **Import JSON…** in Learper. If the chatbot supplied JSON text, save it as a UTF-8 `.json` file or copy it and choose **Paste JSON**. The app validates the file before saving it locally.
