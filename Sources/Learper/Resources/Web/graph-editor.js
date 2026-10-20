'use strict';
const source = document.getElementById('source');
const preview = document.getElementById('preview');
const error = document.getElementById('error');
const copyButton = document.getElementById('copy');
const exportButton = document.getElementById('export');
const status = document.getElementById('status');
let currentSVG = '';
let pendingRender;
let generation = 0;
let renderSequence = Promise.resolve();

function send(action, text) {
  const handler = window.webkit?.messageHandlers?.graphAction;
  if (!handler) { status.textContent = 'Open Create Graph in Learper to copy or export.'; return false; }
  handler.postMessage({ action, text });
  return true;
}

function updateGraph(save = true) {
  const text = source.value.trim();
  const ticket = ++generation;
  clearTimeout(pendingRender);
  status.textContent = '';
  currentSVG = '';
  copyButton.disabled = exportButton.disabled = true;
  if (save) send('draft', source.value);
  if (!text) {
    preview.replaceChildren();
    error.textContent = 'Enter Mermaid diagram text.';
    error.hidden = false;
    return;
  }
  renderSequence = renderSequence.catch(() => {}).then(async () => {
    const renderID = `learper-editor-${ticket}`;
    try {
      const result = await LearperMermaid.render(renderID, text);
      if (ticket !== generation) return;
      currentSVG = result.svg;
      preview.innerHTML = currentSVG;
      error.hidden = true;
      copyButton.disabled = exportButton.disabled = false;
    } catch (failure) {
      // Mermaid 10 leaves its temporary error diagram attached to the body.
      document.getElementById(`d${renderID}`)?.remove();
      if (ticket !== generation) return;
      preview.replaceChildren();
      error.textContent = failure.message || 'Could not render this Mermaid diagram.';
      error.hidden = false;
    }
  });
}

function setGraphSource(text) {
  source.value = text;
  updateGraph(false);
}

source.addEventListener('input', () => {
  copyButton.disabled = exportButton.disabled = true;
  send('draft', source.value);
  clearTimeout(pendingRender);
  pendingRender = setTimeout(() => updateGraph(false), 180);
});

const examples = {
  flowchart: 'flowchart LR\n  A[Start] --> B{Ready?}\n  B -- Yes --> C[Continue]\n  B -- No --> A',
  sequence: 'sequenceDiagram\n  Student->>Tutor: Submit answer\n  Tutor-->>Student: Feedback',
  class: 'classDiagram\n  Quiz --> Question\n  Question : +String prompt\n  Question : +String answer'
};
document.querySelectorAll('[data-example]').forEach(button => button.addEventListener('click', () => {
  source.value = examples[button.dataset.example];
  updateGraph();
}));
copyButton.addEventListener('click', () => {
  if (send('copy', '```mermaid\n' + source.value.trim() + '\n```')) status.textContent = 'Mermaid block copied.';
});
exportButton.addEventListener('click', () => send('export', currentSVG));
updateGraph(false);
