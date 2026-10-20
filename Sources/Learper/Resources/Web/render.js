const markdown = window.markdownit({
  html: false,
  linkify: false,
  breaks: true,
  highlight(code, language) {
    const supported = { c: 'c', cpp: 'cpp', 'c++': 'cpp', python: 'python', py: 'python', rust: 'rust', rs: 'rust' };
    const grammar = supported[(language || '').toLowerCase()];
    const escaped = markdown.utils.escapeHtml(code);
    const highlighted = grammar && window.hljs.getLanguage(grammar)
      ? window.hljs.highlight(code, { language: grammar, ignoreIllegals: true }).value
      : escaped;
    const label = grammar ? `<span class="code-label">${grammar}</span>` : '';
    return `<pre class="code-block">${label}<code class="hljs">${highlighted}</code></pre>`;
  }
});

markdown.disable('image');

const codeFence = markdown.renderer.rules.fence;
markdown.renderer.rules.fence = function (tokens, index, options, env, renderer) {
  const language = tokens[index].info.trim().toLowerCase();
  if (language === 'mermaid') {
    const number = env.mermaidSources.push(tokens[index].content) - 1;
    return `<figure class="mermaid-diagram" data-mermaid-index="${number}"><div class="mermaid-scroll">Rendering diagram…</div></figure>`;
  }
  if (language === 'graph') {
    return window.LearperGraph.render(tokens[index].content);
  }
  return codeFence(tokens, index, options, env, renderer);
};

let heightFrame = null;
let lastHeight = -1;
let lastSource = null;
let lastSize = null;
let renderGeneration = 0;
let mermaidSequence = Promise.resolve();
let mermaidLoad;

function loadMermaid() {
  if (window.LearperMermaid) return Promise.resolve();
  if (!mermaidLoad) {
    mermaidLoad = new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'vendor/mermaid/mermaid.min.js';
      script.onload = resolve;
      script.onerror = () => reject(new Error('The bundled Mermaid renderer could not be loaded.'));
      document.head.appendChild(script);
    });
  }
  return mermaidLoad;
}

function renderMermaid(root, sources, generation) {
  sources.forEach((source, index) => {
    const container = root.querySelector(`[data-mermaid-index="${index}"] .mermaid-scroll`);
    mermaidSequence = mermaidSequence.catch(() => {}).then(async () => {
      const renderID = `learper-rich-${generation}-${index}`;
      try {
        await loadMermaid();
        const result = await window.LearperMermaid.render(renderID, source);
        if (generation !== renderGeneration || !container.isConnected) return;
        container.innerHTML = result.svg;
      } catch (failure) {
        document.getElementById(`d${renderID}`)?.remove();
        if (generation !== renderGeneration || !container.isConnected) return;
        container.replaceChildren();
        const message = document.createElement('p');
        message.className = 'mermaid-error';
        message.textContent = `Diagram error: ${failure.message || 'Invalid Mermaid syntax'}`;
        container.appendChild(message);
      }
      reportHeight();
    });
  });
}

function contentHeight() {
  // Measure content, not the viewport: scrollHeight cannot reliably shrink after
  // a tall question is replaced by a short one.
  return Math.ceil(document.getElementById('content').getBoundingClientRect().height + 8);
}

function reportHeight() {
  if (heightFrame !== null) return;
  heightFrame = requestAnimationFrame(() => {
    heightFrame = null;
    const height = contentHeight();
    if (height === lastHeight) return;
    lastHeight = height;
    window.webkit?.messageHandlers?.height?.postMessage(height);
  });
}

function render(source, size) {
  if (source === lastSource && size === lastSize) return;
  document.documentElement.style.fontSize = `${size}px`;
  lastSize = size;
  if (source === lastSource) {
    reportHeight();
    return;
  }
  lastSource = source;
  const root = document.getElementById('content');
  const environment = { mermaidSources: [] };
  root.innerHTML = markdown.render(source, environment);
  window.renderMathInElement(root, {
    delimiters: [
      { left: '$$', right: '$$', display: true },
      { left: '$', right: '$', display: false }
    ],
    ignoredTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code', 'svg'],
    throwOnError: false,
    trust: false
  });
  renderMermaid(root, environment.mermaidSources, ++renderGeneration);
  reportHeight();
}

new ResizeObserver(reportHeight).observe(document.getElementById('content'));
window.addEventListener('load', reportHeight);
