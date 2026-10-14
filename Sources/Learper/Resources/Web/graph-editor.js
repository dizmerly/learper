'use strict';
const source = document.getElementById('source');
const preview = document.getElementById('preview');
const error = document.getElementById('error');
const copyButton = document.getElementById('copy');
const exportButton = document.getElementById('export');
const status = document.getElementById('status');
let currentSVG = '';
let pendingRender;

function send(action, text) {
  const handler = window.webkit?.messageHandlers?.graphAction;
  if (!handler) { status.textContent = 'Open Create Graph in Learper to copy or export.'; return false; }
  handler.postMessage({ action, text });
  return true;
}

function updateGraph(save = true) {
  clearTimeout(pendingRender);
  status.textContent = '';
  try {
    const graph = LearperGraph.parse(source.value);
    currentSVG = LearperGraph.svg(graph);
    preview.innerHTML = currentSVG;
    document.getElementById('counts').textContent = `${graph.nodes.length} vertices · ${graph.edges.length} edges`;
    error.hidden = true;
    copyButton.disabled = exportButton.disabled = false;
  } catch (failure) {
    currentSVG = '';
    preview.replaceChildren();
    document.getElementById('counts').textContent = '';
    error.textContent = failure.message;
    error.hidden = false;
    copyButton.disabled = exportButton.disabled = true;
  }
  if (save) send('draft', source.value);
}

function setGraphSource(text) {
  source.value = text;
  updateGraph(false);
}

source.addEventListener('input', () => {
  // Invalidate export immediately while the preview catches up with typing.
  copyButton.disabled = exportButton.disabled = true;
  send('draft', source.value);
  clearTimeout(pendingRender);
  pendingRender = setTimeout(() => updateGraph(false), 120);
});
const examples = {
  branch: 'a > b > c\nb > d > e',
  cycle: 'a > b > c > a\nb > b',
  undirected: 'a -- b -- c -- a\nb -- d\nz'
};
document.querySelectorAll('[data-example]').forEach(button => button.addEventListener('click', () => {
  source.value = examples[button.dataset.example];
  updateGraph();
}));
copyButton.addEventListener('click', () => {
  if (send('copy', '```graph\n' + source.value.trim() + '\n```')) status.textContent = 'Graph block copied.';
});
exportButton.addEventListener('click', () => send('export', currentSVG));
updateGraph(false);
