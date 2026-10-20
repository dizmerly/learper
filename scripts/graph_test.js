'use strict';
(function () {
  let checks = 0;
  function assert(condition, message) {
    if (!condition) throw new Error(message);
    checks++;
  }
  function rejects(source, message) {
    let failed = false;
    try { LearperGraph.parse(source); } catch (_) { failed = true; }
    assert(failed, message);
  }
  const graph = LearperGraph.parse('a>b>c\nb>d>e');
  assert(JSON.stringify(graph.nodes) === '["a","b","c","d","e"]', 'Branches must share b.');
  assert(JSON.stringify(graph.edges.map(e => [e.from, e.to])) === '[["a","b"],["b","c"],["b","d"],["d","e"]]', 'Chains must preserve directed edges.');
  assert(graph.edges.every(edge => edge.directed), 'The > operator must produce arrows.');
  const ranked = LearperGraph.layout(graph);
  assert(ranked.positions.get('a').x < ranked.positions.get('b').x, 'Directed DAG layout must follow ranks.');
  assert(ranked.positions.get('c').y !== ranked.positions.get('d').y, 'Branches must be separated.');
  const topDown = LearperGraph.layout(LearperGraph.parse('direction: TB\na -> b -> c'));
  assert(topDown.positions.get('a').y < topDown.positions.get('b').y, 'TB must put children below parents.');
  const cycle = LearperGraph.parse('a > b > c > a; b > b; isolated');
  const cyclicSVG = LearperGraph.svg(cycle);
  assert((cyclicSVG.match(/class="edge"/g) || []).length === 4, 'Cycles and loops must render every edge.');
  assert(!/NaN|Infinity/.test(cyclicSVG), 'Cycles must have finite positions.');
  const undirected = LearperGraph.parse('a--b--c; b--a; z');
  assert(undirected.edges.length === 2 && undirected.nodes.length === 4, 'Undirected duplicate edges must collapse, preserving isolated nodes.');
  assert(!LearperGraph.svg(undirected).includes('marker-end='), 'Undirected edges must have no arrowheads.');
  const labels = LearperGraph.parse('"Start here" -> "Say \\"hi\\"" : "cost 5"');
  assert(labels.nodes[1] === 'Say "hi"' && labels.edges[0].label === 'cost 5', 'Quoted labels must support JSON escapes.');
  assert(LearperGraph.parse('α > β # a comment\nβ > γ').nodes.length === 3, 'Unicode labels and comments must work.');
  assert(LearperGraph.parse('a > b; a -> b').edges.length === 1, 'Identical directed edges must collapse.');
  const parallel = LearperGraph.svg(LearperGraph.parse('a > b : 1; a > b : 2; b > a'));
  const paths = [...parallel.matchAll(/class="edge" d="([^"]+)"/g)].map(match => match[1]);
  assert(new Set(paths).size === 3, 'Parallel and reciprocal edges must use separate paths.');
  const skip = LearperGraph.svg(LearperGraph.parse('a > b > c; a > c'));
  const skipPath = [...skip.matchAll(/class="edge" d="([^"]+)"/g)][2][1];
  const controlY = Number(skipPath.match(/Q [\d.-]+ ([\d.-]+)/)[1]);
  assert(controlY !== LearperGraph.layout(LearperGraph.parse('a > b > c; a > c')).positions.get('b').y, 'A skip edge must curve around the intervening vertex.');
  const loops = LearperGraph.svg(LearperGraph.parse(Array.from({ length: 20 }, (_, i) => `a > a : ${i}`).join(';')));
  assert(Number(loops.match(/viewBox="[\d.-]+ ([\d.-]+)/)[1]) < 0, 'The viewBox must include tall loops without clipping.');
  const safe = LearperGraph.svg(LearperGraph.parse('"<script>alert(1)</script>" > "A&B"'));
  assert(!safe.includes('<script>') && safe.includes('&lt;script&gt;') && safe.includes('A&amp;B'), 'SVG labels must escape markup.');
  const bad = LearperGraph.render('a > <img src=x onerror=alert(1)>');
  assert(!bad.includes('<img') && bad.includes('graph-error'), 'Invalid input must be displayed as escaped text.');
  const first = LearperGraph.svg(graph), second = LearperGraph.svg(graph);
  assert(first.match(/marker id="([^"]+)"/)[1] !== second.match(/marker id="([^"]+)"/)[1], 'Multiple diagrams must have independent marker IDs.');
  assert(first.includes('<desc') && first.includes('a to b'), 'Diagrams must expose vertices and edges to accessibility tools.');
  ['a >', '> a', 'a b', 'a > > b', 'a > b :', 'a > b > c : 2', 'direction: sideways', 'layout: force', '"unterminated', '""', '"a\\nb"', '', '# nothing', '"' + 'x'.repeat(49) + '"', 'x'.repeat(12001)].forEach(source => rejects(source, `Invalid source was accepted: ${source.slice(0, 50)}`));
  rejects(Array.from({ length: 81 }, (_, i) => `n${i}`).join(';'), 'The node limit must be enforced.');
  rejects(Array.from({ length: 201 }, (_, i) => `a > b : ${i}`).join(';'), 'The edge limit must be enforced.');
  const maximum = LearperGraph.layout(LearperGraph.parse(Array.from({ length: 80 }, (_, i) => `n${i}`).join('>')));
  assert(maximum.positions.size === 80 && Number.isFinite(maximum.width), 'The node limit boundary must remain renderable.');
  const isolated = LearperGraph.layout(LearperGraph.parse('alone'));
  assert(isolated.positions.size === 1 && Number.isFinite(isolated.height), 'A single vertex must render.');
  const quiz = JSON.parse(graphQuizSource);
  for (const question of quiz.questions) {
    const source = question.description.match(/```mermaid\n([\s\S]*?)\n```/)?.[1];
    assert(source && source.startsWith('flowchart LR'), `The sample question ${question.id} must contain Mermaid flowchart text.`);
  }
  globalThis.graphTestCount = checks;
})();
