/* Offline text-to-SVG graphs. No evaluation of source, HTML, or remote assets. */
(function (root) {
  'use strict';
  const limits = { characters: 12000, nodes: 80, edges: 200, label: 48 };
  let diagramID = 0;
  const escape = value => String(value).replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  })[c]);

  function parse(source) {
    if (typeof source !== 'string' || source.length > limits.characters) {
      throw new Error(`Graph text must be at most ${limits.characters} characters.`);
    }
    const tokens = [];
    let index = 0, line = 1;
    function fail(message, at = line) { throw new Error(`Line ${at}: ${message}`); }
    while (index < source.length) {
      const char = source[index];
      if (char === '\n' || char === ';') {
        tokens.push({ type: 'break', line });
        if (char === '\n') line++;
        index++;
      } else if (/\s/.test(char)) {
        index++;
      } else if (char === '#') {
        while (index < source.length && source[index] !== '\n') index++;
      } else if (char === '"') {
        const start = index++, startLine = line;
        let closed = false;
        while (index < source.length) {
          if (source[index] === '\n') fail('Quoted labels must stay on one line.', startLine);
          if (source[index] === '\\') { index += 2; continue; }
          if (source[index++] === '"') { closed = true; break; }
        }
        if (!closed) fail('Close the quoted label with a double quote.', startLine);
        let value;
        try { value = JSON.parse(source.slice(start, index)); }
        catch (_) { fail('Use JSON escaping inside quoted labels.', startLine); }
        tokens.push({ type: 'node', value, quoted: true, line: startLine });
      } else if (source.startsWith('->', index) || source.startsWith('--', index) || char === '>') {
        const value = char === '>' ? '>' : source.slice(index, index + 2);
        tokens.push({ type: 'edge', value, line });
        index += value.length;
      } else if (char === ':') {
        tokens.push({ type: 'colon', line });
        index++;
      } else {
        const match = source.slice(index).match(/^[\p{L}\p{N}_]+(?:[.-][\p{L}\p{N}_]+)*/u);
        if (!match) fail(`Unexpected character ${JSON.stringify(char)}. Quote labels with spaces or punctuation.`);
        tokens.push({ type: 'node', value: match[0], quoted: false, line });
        index += match[0].length;
      }
    }

    const graph = { nodes: [], edges: [], direction: 'LR', layout: 'auto' };
    const names = new Set(), edgeKeys = new Set();
    function label(token) {
      if (!token.value.trim() || token.value.length > limits.label || /[\u0000-\u001f\u007f]/.test(token.value)) {
        fail(`Labels must contain 1–${limits.label} characters without control characters.`, token.line);
      }
      return token.value;
    }
    function node(token) {
      const name = label(token);
      if (!names.has(name)) { names.add(name); graph.nodes.push(name); }
      if (names.size > limits.nodes) fail(`Use at most ${limits.nodes} vertices.`, token.line);
      return name;
    }
    function statement(parts) {
      if (!parts.length) return;
      const first = parts[0];
      if (first.type !== 'node') fail('Start with a vertex label.', first.line);
      if (!first.quoted && ['direction', 'layout'].includes(first.value) && parts[1]?.type === 'colon') {
        const allowed = first.value === 'direction' ? ['LR', 'TB'] : ['auto', 'circle'];
        if (parts.length !== 3 || parts[2].type !== 'node' || !allowed.includes(parts[2].value)) {
          fail(`Use ${first.value}: ${allowed.join(' or ')}.`, first.line);
        }
        graph[first.value] = parts[2].value;
        return;
      }
      const colon = parts.findIndex(part => part.type === 'colon');
      let edgeLabel = '';
      if (colon !== -1) {
        if (colon !== 3 || parts.length !== 5 || parts[4].type !== 'node') {
          fail('An edge label needs one edge, for example a > b : 3.', first.line);
        }
        edgeLabel = label(parts[4]);
        parts = parts.slice(0, colon);
      }
      let from = node(first);
      for (let i = 1; i < parts.length; i += 2) {
        const operator = parts[i], next = parts[i + 1];
        if (operator.type !== 'edge' || !next || next.type !== 'node') {
          fail('Expected an edge and vertex, for example a > b > c.', operator.line);
        }
        const to = node(next), directed = operator.value !== '--';
        const endpoints = directed ? [from, to] : [from, to].sort();
        const key = JSON.stringify([endpoints, directed, edgeLabel]);
        if (!edgeKeys.has(key)) {
          edgeKeys.add(key);
          graph.edges.push({ from, to, directed, label: edgeLabel });
        }
        if (graph.edges.length > limits.edges) fail(`Use at most ${limits.edges} edges.`, operator.line);
        from = to;
      }
    }
    let parts = [];
    for (const token of tokens) {
      if (token.type === 'break') { statement(parts); parts = []; }
      else parts.push(token);
    }
    statement(parts);
    if (!graph.nodes.length) throw new Error('Add a vertex or an edge, for example a > b > c.');
    return graph;
  }

  function layout(graph) {
    const positions = new Map();
    const nodeWidth = Math.max(56, ...graph.nodes.map(name => name.length * 8 + 26));
    const nodeHeight = 44, padding = 76;
    const incoming = new Map(graph.nodes.map(name => [name, 0]));
    const children = new Map(graph.nodes.map(name => [name, []]));
    const ranks = new Map(graph.nodes.map(name => [name, 0]));
    for (const edge of graph.edges) {
      if (!edge.directed) continue;
      incoming.set(edge.to, incoming.get(edge.to) + 1);
      children.get(edge.from).push(edge.to);
    }
    const queue = graph.nodes.filter(name => incoming.get(name) === 0);
    for (let i = 0; i < queue.length; i++) {
      const name = queue[i];
      for (const child of children.get(name)) {
        ranks.set(child, Math.max(ranks.get(child), ranks.get(name) + 1));
        incoming.set(child, incoming.get(child) - 1);
        if (incoming.get(child) === 0) queue.push(child);
      }
    }
    const circular = graph.layout === 'circle' || queue.length !== graph.nodes.length || graph.edges.some(edge => !edge.directed);
    let width, height;
    if (circular && graph.nodes.length > 1) {
      const radius = Math.max(100, graph.nodes.length * (nodeWidth + 38) / (2 * Math.PI));
      width = height = radius * 2 + padding * 2 + nodeWidth;
      graph.nodes.forEach((name, i) => {
        const angle = -Math.PI / 2 + i * 2 * Math.PI / graph.nodes.length;
        positions.set(name, { x: width / 2 + radius * Math.cos(angle), y: height / 2 + radius * Math.sin(angle) });
      });
    } else {
      const tiers = Array.from({ length: Math.max(...ranks.values()) + 1 }, () => []);
      graph.nodes.forEach(name => tiers[ranks.get(name)].push(name));
      const count = Math.max(...tiers.map(tier => tier.length));
      const horizontal = graph.direction === 'LR';
      const step = horizontal ? nodeWidth + 100 : nodeHeight + 100;
      const crossStep = horizontal ? nodeHeight + 65 : nodeWidth + 65;
      const along = (tiers.length - 1) * step + (horizontal ? nodeWidth : nodeHeight) + padding * 2;
      const across = (count - 1) * crossStep + (horizontal ? nodeHeight : nodeWidth) + padding * 2;
      width = horizontal ? along : across;
      height = horizontal ? across : along;
      tiers.forEach((tier, rank) => tier.forEach((name, i) => {
        const a = padding + (horizontal ? nodeWidth : nodeHeight) / 2 + rank * step;
        const b = across / 2 + (i - (tier.length - 1) / 2) * crossStep;
        positions.set(name, horizontal ? { x: a, y: b } : { x: b, y: a });
      }));
    }
    return { positions, width, height, nodeWidth, nodeHeight };
  }

  function svg(graph) {
    const { positions, width, height, nodeWidth, nodeHeight } = layout(graph);
    const prefix = `learper-graph-${++diagramID}`;
    const n = value => Math.round(value * 100) / 100;
    const point = p => `${n(p.x)} ${n(p.y)}`;
    let minX = 0, minY = 0, maxX = width, maxY = height;
    function include(p, margin = 24) {
      minX = Math.min(minX, p.x - margin); minY = Math.min(minY, p.y - margin);
      maxX = Math.max(maxX, p.x + margin); maxY = Math.max(maxY, p.y + margin);
    }
    function boundary(center, toward, extra = 0) {
      const dx = toward.x - center.x, dy = toward.y - center.y;
      const scale = 1 / Math.max(Math.abs(dx) / (nodeWidth / 2 + extra), Math.abs(dy) / (nodeHeight / 2 + extra));
      return { x: center.x + dx * scale, y: center.y + dy * scale };
    }
    const paths = graph.edges.map((edge, edgeIndex) => {
      const a = positions.get(edge.from), b = positions.get(edge.to);
      let path, labelAt;
      if (edge.from === edge.to) {
        const offset = graph.edges.slice(0, edgeIndex).filter(other => other.from === edge.from && other.to === edge.to).length * 16;
        const loop = nodeHeight / 2 + 55 + offset;
        path = `M ${n(a.x - 15)} ${n(a.y - nodeHeight / 2)} C ${n(a.x - nodeWidth / 2 - 40)} ${n(a.y - loop)}, ${n(a.x + nodeWidth / 2 + 40)} ${n(a.y - loop)}, ${n(a.x + 15)} ${n(a.y - nodeHeight / 2 - 5)}`;
        labelAt = { x: a.x, y: a.y - loop + 8 };
        include({ x: a.x - nodeWidth / 2 - 40, y: a.y - loop });
        include({ x: a.x + nodeWidth / 2 + 40, y: a.y - loop });
      } else {
        // Offset reciprocal and parallel edges so both arrowheads remain visible.
        const peers = graph.edges.filter(other => (other.from === edge.from && other.to === edge.to) || (other.from === edge.to && other.to === edge.from));
        const peerIndex = peers.indexOf(edge);
        const dx = b.x - a.x, dy = b.y - a.y, distance = Math.hypot(dx, dy);
        const orientation = edge.from < edge.to ? 1 : -1;
        let offset = peers.length > 1 ? (peerIndex - (peers.length - 1) / 2) * 42 * orientation : 0;
        let mid, start, end;
        function route() {
          mid = { x: (a.x + b.x) / 2 - dy / distance * offset, y: (a.y + b.y) / 2 + dx / distance * offset };
          start = boundary(a, mid, 2); end = boundary(b, mid, edge.directed ? 9 : 2);
        }
        function hitsVertex() {
          for (const [name, center] of positions) {
            if (name === edge.from || name === edge.to) continue;
            for (let sample = 1; sample < 40; sample++) {
              const t = sample / 40, u = 1 - t;
              const x = u * u * start.x + 2 * u * t * mid.x + t * t * end.x;
              const y = u * u * start.y + 2 * u * t * mid.y + t * t * end.y;
              if (Math.abs(x - center.x) < nodeWidth / 2 + 10 && Math.abs(y - center.y) < nodeHeight / 2 + 10) return true;
            }
          }
          return false;
        }
        route();
        // Route skip edges around intermediate vertices instead of through them.
        const side = Math.sign(offset) || (edgeIndex % 2 ? 1 : -1);
        for (let attempt = 1; attempt <= 12 && hitsVertex(); attempt++) {
          offset = side * (80 * attempt + peerIndex * 42);
          route();
        }
        include(mid);
        path = `M ${point(start)} Q ${point(mid)} ${point(end)}`;
        labelAt = { x: (start.x + 2 * mid.x + end.x) / 4, y: (start.y + 2 * mid.y + end.y) / 4 - 8 };
      }
      if (edge.label) {
        include({ x: labelAt.x - edge.label.length * 4, y: labelAt.y });
        include({ x: labelAt.x + edge.label.length * 4, y: labelAt.y });
      }
      return `<path class="edge" d="${path}"${edge.directed ? ` marker-end="url(#${prefix}-arrow)"` : ''}/>` +
        (edge.label ? `<text class="edge-label" x="${n(labelAt.x)}" y="${n(labelAt.y)}">${escape(edge.label)}</text>` : '');
    }).join('');
    const nodes = graph.nodes.map(name => {
      const p = positions.get(name);
      return `<g class="vertex"><rect x="${n(p.x - nodeWidth / 2)}" y="${n(p.y - nodeHeight / 2)}" width="${nodeWidth}" height="${nodeHeight}" rx="16"/><text x="${n(p.x)}" y="${n(p.y)}" dy="0.35em">${escape(name)}</text></g>`;
    }).join('');
    const description = `${graph.nodes.length} vertices: ${graph.nodes.join(', ')}. ${graph.edges.length} edges. ` +
      graph.edges.map(edge => `${edge.from} ${edge.directed ? 'to' : 'connected to'} ${edge.to}${edge.label ? ` (${edge.label})` : ''}`).join('; ');
    return `<svg xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="${prefix}-title ${prefix}-desc" viewBox="${n(minX)} ${n(minY)} ${n(maxX - minX)} ${n(maxY - minY)}" width="${n(maxX - minX)}" height="${n(maxY - minY)}">` +
      `<title id="${prefix}-title">Graph</title><desc id="${prefix}-desc">${escape(description)}</desc>` +
      `<style>.edge{fill:none;stroke:#577baf;stroke-width:2}.arrow{fill:#577baf}.vertex rect{fill:#edf3fc;stroke:#577baf;stroke-width:1.5}.vertex text,.edge-label{fill:#233141;font:15px -apple-system,BlinkMacSystemFont,sans-serif;text-anchor:middle}.edge-label{font-size:13px;paint-order:stroke;stroke:#fff;stroke-width:4;stroke-linejoin:round}@media(prefers-color-scheme:dark){.edge{stroke:#91b8ef}.arrow{fill:#91b8ef}.vertex rect{fill:#202e43;stroke:#91b8ef}.vertex text,.edge-label{fill:#e7eef7}.edge-label{stroke:#172336}}</style>` +
      `<defs><marker id="${prefix}-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path class="arrow" d="M 0 0 L 10 5 L 0 10 z"/></marker></defs>${paths}${nodes}</svg>`;
  }

  function render(source) {
    try {
      const graph = parse(source);
      return `<figure class="graph-diagram"><div class="graph-scroll">${svg(graph)}</div><figcaption>${graph.nodes.length} vertices · ${graph.edges.length} edges</figcaption></figure>`;
    } catch (error) {
      return `<div class="graph-error" role="alert"><strong>Could not draw graph</strong><p>${escape(error.message)}</p><pre>${escape(source)}</pre></div>`;
    }
  }
  root.LearperGraph = { parse, layout, svg, render, limits };
  if (typeof module !== 'undefined' && module.exports) module.exports = root.LearperGraph;
})(typeof window !== 'undefined' ? window : globalThis);
