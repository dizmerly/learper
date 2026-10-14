# Learper portable quiz file (v1)

This document is a standalone file format for **any chatbot**. Give the chatbot this document and a topic, notes, or source material. Its entire job is to create a downloadable UTF-8 `.json` quiz file. The chatbot does not need access to Learper, your computer, an API key, or a computer-use tool. You download the file and import it in Learper yourself.

## Request to paste into a chatbot

> Create a Learper v1 multiple-choice quiz about **[topic or supplied notes]** with **[number]** questions at **[difficulty]**. Follow the attached Learper format exactly. Create and attach a downloadable UTF-8 file named `learper-quiz.json`; its contents must be one valid JSON object, with no Markdown fences or commentary. Give me the file to download. You do not need to open Learper or use my computer. Make plausible distractors, exactly one correct choice per question, and a useful explanation. If the material is insufficient, tell me instead of inventing facts. If your chat interface cannot attach a file, say so and provide the complete JSON in one `json` code block that I can save as `learper-quiz.json`.

The request above is the only platform-specific step: use a chatbot's normal file attachment or artifact feature if it has one. A text-only chatbot can still produce the same JSON, but the user must save that text as a `.json` file. Do not claim that a file exists unless the user can actually download it.

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

- The file must contain exactly one top-level JSON object. `version` must be `1`. `id`, `title`, `question`, and `explanation` must be nonempty. Set and question IDs should be stable, short, and unique; importing a set with an existing set ID replaces it.
- `questions` needs at least one item. Each question needs 2 to 6 choices with unique, nonempty IDs and text. `correctAnswerId` must exactly equal one choice ID.
- Include `hints` as an array of strings (use `[]` if none). `description` and `image` are optional; omit them or use `null` when unused. The app accepts an `image` object with optional `url` and `alt` strings for future compatibility, but v1 deliberately does not fetch or display images. A chatbot should normally omit `image`.
- Rich text supports basic Markdown, inline code using backticks, fenced code using triple backticks with `c`, `cpp`, `python`, or `rust`, inline LaTeX with `$...$`, and display LaTeX with `$$...$$`. Other code languages render as plain code.
- For graph theory diagrams, use a fenced `graph` block with the text syntax below. It works in questions, descriptions, hints, choices, and explanations. Produce graph text instead of an image URL or an image-generation request. The format remains version `1`.
- JSON strings must escape backslashes in LaTeX: `"$\\frac{1}{2}$"`. Escape newlines inside strings as `\n`. The downloadable file must be strict JSON with no trailing commas, comments, or surrounding Markdown.
- Put the answer only in `correctAnswerId`; do not mark the correct choice in the question or choices. Hints should help without revealing the choice ID.

## Graphs

A graph block uses triple backticks with the exact language `graph`:

````markdown
```graph
a > b > c
b > d > e
```
````

Learper creates five vertices (`a`, `b`, `c`, `d`, `e`) and directed edges `a → b`, `b → c`, `b → d`, and `d → e`. This is a locally rendered SVG diagram. Labels identify vertices: the same label always means the same vertex.

| Syntax | Meaning |
| --- | --- |
| `a > b` or `a -> b` | Directed edge from `a` to `b` |
| `a > b > c` | Chain of directed edges |
| `a -- b -- c` | Chain of undirected edges |
| `a > b : 3` | Single edge with label/weight `3` |
| `a -- b : "cost 5"` | Undirected edge with a quoted label |
| `"Start here" > End` | Vertex label containing spaces |
| `z` | Isolated vertex |
| `a > a` | Self-loop |
| `a > b; b > a` | Reciprocal directed edges |
| `direction: TB` | Top-to-bottom layout; default is `LR` |
| `layout: circle` | Circular layout; default is `auto` |
| `# comment` | Comment until the end of the line |

Separate statements with a newline or semicolon. Bare labels may contain letters, numbers, underscores, and interior dots or single hyphens. For other labels use double quotes with JSON escaping (e.g. `"Say \"hi\""` in graph text). Quoted labels cannot contain newlines or control characters. A label after `:` applies to one edge, so write labeled edges on separate lines rather than labeling a chain. Duplicate identical edges are collapsed; different edge labels preserve parallel edges. Directed and undirected edges can appear in one graph. Cyclic graphs and graphs containing undirected edges automatically use a circular layout.

Keep graphs small enough to read. Hard limits per block: 80 vertices, 200 edges, 48 characters per vertex/edge label, and 12,000 source characters. Invalid graph syntax displays an inline error without preventing the rest of the question from rendering.

In a quiz JSON string, escape the fence's newlines as `\n` and any label quotes as `\"`. A complete question example:

```json
{
  "id": "graph-1",
  "question": "What is the out-degree of vertex b?",
  "description": "```graph\na > b > c\nb > d > e\n```",
  "hints": ["Count the arrows leaving b."],
  "choices": [
    { "id": "a", "text": "1" },
    { "id": "b", "text": "2" },
    { "id": "c", "text": "3" }
  ],
  "correctAnswerId": "b",
  "explanation": "Two edges leave b: b → c and b → d. The edge a → b enters b."
}
```

When asking a chatbot for a graph quiz, add: “Use fenced `graph` blocks for all diagrams and follow the Learper graph syntax. Generate the vertices and edges as text.” See the [complete graph quiz](../Sources/Learper/Resources/graph-theory-quiz.json) for more examples.

## Download and import

Download the chatbot's `.json` attachment, then choose **Import JSON…** in Learper and select that file. If the chatbot could only return text, save the JSON code block as a UTF-8 `.json` file, or copy its JSON content and choose **Paste JSON**. The app validates the structure and shows an error if a required field is missing or an answer ID is wrong. Imported sets are saved locally in Application Support. No quiz content is sent to a server.

See [`../Sources/Learper/Resources/sample-quiz.json`](../Sources/Learper/Resources/sample-quiz.json) for a complete working example.
