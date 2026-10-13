# Learper question format (v1)

Give this file to an agent when asking it to generate a Learper quiz. The app imports one UTF-8 `.json` file containing a quiz set. The Markdown here is the agent-facing API contract; the transport format is JSON. No network API or credentials are needed.

## Prompt for an agent

> Generate a Learper v1 multiple-choice quiz about **[topic or supplied notes]** with **[number]** questions at **[difficulty]**. Follow the JSON shape and rules below. Return only one valid JSON object, without Markdown fences or commentary. Make distractors plausible, ensure exactly one correct choice per question, and give an explanation that teaches why it is correct. Use `null` for `image`. When relevant, use Markdown, fenced code, and LaTeX delimiters as documented below. Do not invent facts from supplied notes; if the material is insufficient, say so outside the JSON instead of making a quiz.

## Shape

```json
{
  "version": 1,
  "id": "unique-set-id",
  "title": "Quiz title",
  "description": "Optional short set description",
  "questions": [
    {
      "id": "unique-question-id",
      "question": "Question stem with optional $inline math$",
      "description": "Optional context, Markdown, or a fenced code block",
      "hints": ["Optional progressive hint", "Another hint"],
      "choices": [
        { "id": "a", "text": "First answer" },
        { "id": "b", "text": "Second answer" }
      ],
      "correctAnswerId": "b",
      "explanation": "Why b is correct, and why the tempting alternative fails.",
      "image": null
    }
  ]
}
```

## Rules

- `version` must be `1`. `id`, `title`, `question`, and `explanation` must be nonempty. Set and question IDs should be stable, short, and unique; importing a set with an existing set ID replaces it.
- `questions` needs at least one item. Each question needs 2 to 6 choices with unique, nonempty IDs and text. `correctAnswerId` must exactly equal one choice ID.
- Include `description` as a string or `null`, `hints` as an array of strings (use `[]` if none), and `image` as `null` by default. These keys are required in v1 JSON. The app accepts an `image` object with optional `url` and `alt` strings for future compatibility, but v1 deliberately does not fetch or display images.
- Rich text supports basic Markdown, inline code using backticks, fenced code using triple backticks with `c`, `cpp`, `python`, or `rust`, inline LaTeX with `$...$`, and display LaTeX with `$$...$$`. Other code languages render as plain code.
- JSON strings must escape backslashes in LaTeX: `"$\\frac{1}{2}$"`. Escape newlines inside strings as `\n`. Output strict JSON with no trailing commas or comments.
- Put the answer only in `correctAnswerId`; do not mark the correct choice in the question or choices. Hints should help without revealing the choice ID.

## Import

Save the agent output as `something.json`, then choose **Import JSON…** in Learper. **Paste JSON** can import the entire JSON object from the clipboard. The app validates the structure and shows an error if a required field is missing or an answer ID is wrong. Imported sets are saved locally in Application Support. No quiz content is sent to a server.

See [`../Sources/Learper/Resources/sample-quiz.json`](../Sources/Learper/Resources/sample-quiz.json) for a complete working example.
