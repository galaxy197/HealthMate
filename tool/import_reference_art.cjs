// Export only the small illustrations from the user's editable UI kit.
// Usage: node tool/import_reference_art.cjs <design.json> <sharp module path>
const fs = require('node:fs');
const path = require('node:path');
const sharp = require(process.argv[3]);
const design = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const found = new Map();
function walk(nodes) {
  for (const node of nodes) {
    if (node.name?.startsWith('Illustration / ')) {
      const original = node.name.slice('Illustration / '.length);
      const name = original === 'Blue flame' ? 'flame' : original;
      if (!found.has(name)) found.set(name, node);
    }
    walk(node.children || []);
  }
}
design.screens.forEach(s => walk(s.children));
const fill = value => !value ? 'none' : design.gradients[value] ? `url(#${value})` : value;
const gradients = Object.entries(design.gradients).map(([name, colors]) =>
  `<linearGradient id="${name}" x2="0" y2="1"><stop stop-color="${colors[0]}"/><stop offset="1" stop-color="${colors[1]}"/></linearGradient>`).join('');
const destination = path.join('assets', 'design');
fs.mkdirSync(destination, {recursive: true});
(async () => {
  for (const [name, node] of found) {
    if (!/^[a-z_-]+$/.test(name)) continue;
    if (node.children.some(n => !['path', 'rect'].includes(n.type))) continue;
    const flame = name === 'flame';
    const paths = node.children.map(n => n.type === 'rect'
      ? `<rect x="${n.x}" y="${n.y}" width="${n.w}" height="${n.h}" rx="${n.r}" fill="${fill(n.fill)}"/>`
      : `${flame ? `<g transform="translate(${n.x} ${n.y}) scale(${n.w / n.vb[0]} ${n.h / n.vb[1]})">` : ''}<path d="${n.d}" fill="${fill(n.fill)}" stroke="${fill(n.color)}" stroke-width="${n.sw}" stroke-linecap="round" stroke-linejoin="round"/>${flame ? '</g>' : ''}`).join('');
    const vb = flame ? [node.w, node.h] : node.children[0]?.vb || [48, 48];
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${vb[0]} ${vb[1]}" width="192" height="192"><defs>${gradients}</defs>${paths}</svg>`;
    await sharp(Buffer.from(svg)).png().toFile(path.join(destination, `${name}.png`));
    console.log(name);
  }
})();
