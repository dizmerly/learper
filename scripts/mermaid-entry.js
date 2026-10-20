import mermaid from 'mermaid';

mermaid.initialize({
  startOnLoad: false,
  securityLevel: 'strict',
  maxTextSize: 12000,
  maxEdges: 200,
  theme: 'base',
  themeVariables: {
    background: '#171220',
    primaryColor: '#3d2b54',
    primaryBorderColor: '#bb91ed',
    primaryTextColor: '#f3eafa',
    lineColor: '#c49cf1',
    secondaryColor: '#2d2340',
    tertiaryColor: '#211a2e'
  },
  flowchart: { htmlLabels: false }
});

window.LearperMermaid = mermaid;
