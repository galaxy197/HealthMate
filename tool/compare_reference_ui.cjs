// Usage: node compare_reference_ui.cjs <UI-kit directory> <sharp module path>
// Run reference_ui_test.dart first. Its populated values exist only in tests.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require(process.argv[3] || 'sharp');
const kit = process.argv[2];
if (!kit) throw new Error('Pass the directory containing previews/T01.png.');
const output = path.resolve('docs/ux/reference-v2');
const screens = path.resolve('build/figma-v2/screens');
const frames = [
  ['T01', 'today', 'Home'], ['J01', 'journal', 'Journal'],
  ['W01', 'habits', 'Habits'], ['P01', 'profile', 'Profile'],
  ['R01', 'reports', 'Progress'],
];
const header = (title, width) => Buffer.from(`<svg width="${width}" height="62" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="#f8f9fc"/><text x="16" y="24" font-family="Arial,sans-serif" font-size="16" fill="#171818">${title}</text><text x="16" y="47" font-family="Arial,sans-serif" font-size="12" fill="#5f6269">Same 390px width; native system bars cropped. Flutter uses test fixtures.</text></svg>`);
async function normalized(file) {
  return sharp(file).resize(390, 844).extract({left: 0, top: 44, width: 390, height: 777}).png().toBuffer();
}
(async () => {
  fs.mkdirSync(output, {recursive: true});
  const thumbnails = [];
  const actual = [];
  for (const [frame, name, title] of frames) {
    const reference = await normalized(path.join(kit, 'previews', `${frame}.png`));
    const screenshot = await normalized(path.join(screens, `${name}-populated.png`));
    const pair = await sharp({create: {width: 810, height: 855, channels: 4, background: '#f8f9fc'}})
      .composite([{input: header(`${title} — Figma ${frame} (left) / Flutter (right)`, 810), top: 0, left: 0},
        {input: reference, top: 62, left: 10}, {input: screenshot, top: 62, left: 410}])
      .png().toBuffer();
    fs.writeFileSync(path.join(output, `comparison-${name}.png`), pair);
    thumbnails.push({input: await sharp(pair).resize(540, 570).toBuffer(), left: (thumbnails.length % 3) * 550, top: Math.floor(thumbnails.length / 3) * 580});
    actual.push({input: await sharp(path.join(screens, `${name}-populated.png`)).resize(390, 844).toBuffer(), left: actual.length * 400 + 10, top: 62});
  }
  await sharp({create: {width: 1650, height: 1160, channels: 4, background: '#f8f9fc'}}).composite(thumbnails).png().toFile(path.join(output, 'comparison-board.png'));
  await sharp({create: {width: 2010, height: 922, channels: 4, background: '#f8f9fc'}})
    .composite([{input: header('HealthMate — Flutter UI review / test fixtures only', 2010), left: 0, top: 0}, ...actual])
    .png().toFile(path.join(output, 'flutter-overview.png'));
  for (const file of fs.readdirSync(screens).filter(f => f.endsWith('.png'))) {
    fs.copyFileSync(path.join(screens, file), path.join(output, file));
  }
  process.stdout.write(`Saved five comparison pairs, overview, board, and UI captures to ${output}\n`);
})();
