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
  if (tokens[index].info.trim().toLowerCase() === 'graph') {
    return window.LearperGraph.render(tokens[index].content);
  }
  return codeFence(tokens, index, options, env, renderer);
};

function reportHeight() {
  window.webkit?.messageHandlers.height.postMessage(Math.ceil(document.body.scrollHeight));
}

function render(source, size) {
  document.documentElement.style.fontSize = `${size}px`;
  const root = document.getElementById('content');
  root.innerHTML = markdown.render(source);
  window.renderMathInElement(root, {
    delimiters: [
      { left: '$$', right: '$$', display: true },
      { left: '$', right: '$', display: false }
    ],
    ignoredTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code', 'svg'],
    throwOnError: false,
    trust: false
  });
  requestAnimationFrame(reportHeight);
}

new ResizeObserver(reportHeight).observe(document.body);
window.addEventListener('load', reportHeight);
