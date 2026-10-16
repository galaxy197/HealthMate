// Windows-only workaround for Flutter's CanvasKit web-test asset routing.
// Serve the unmodified cached SDK files only in the isolated test browser.
const {spawn} = require('node:child_process');
const {readFile} = require('node:fs/promises');
const path = require('node:path');
const args = process.argv.slice(2);
const port = args.find(arg => arg.startsWith('--remote-debugging-port='))?.split('=')[1];
const targetIndex = args.findIndex(arg => arg.startsWith('http://localhost:'));
const chrome = process.env.HEALTHMATE_TEST_CHROME;
const sdk = process.env.HEALTHMATE_TEST_FLUTTER_SDK;
if (!port || targetIndex < 0 || !chrome || !sdk) {
  throw Error('Run via tool/test_emulators.ps1 with a Flutter localhost test browser.');
}
const targetUrl = args[targetIndex];
args[targetIndex] = 'about:blank';
const child = spawn(chrome, args, {stdio: 'inherit', windowsHide: true});
child.on('exit', code => process.exit(code || 0));
child.on('error', error => {console.error(error.message); process.exit(1);});
process.on('SIGTERM', () => child.kill());
// A broken web bootstrap must fail rather than hang indefinitely.
setTimeout(() => {child.kill(); process.exit(2);}, 180000).unref();

(async () => {
  let pages;
  for (let attempt = 0; attempt < 100; attempt++) {
    try {
      pages = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
      if (pages.some(page => page.type === 'page')) break;
    } catch { /* Chrome is still starting. */ }
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  const ws = new WebSocket(pages.find(page => page.type === 'page').webSocketDebuggerUrl);
  let sequence = 0;
  const pending = new Map();
  const call = (method, params = {}) => new Promise((resolve, reject) => {
    const id = ++sequence;
    pending.set(id, {resolve, reject});
    ws.send(JSON.stringify({id, method, params}));
  });
  const base = path.resolve(sdk, 'bin/cache/flutter_web_sdk/canvaskit');
  ws.onmessage = async event => {
    const message = JSON.parse(event.data);
    if (pending.has(message.id)) {
      const entry = pending.get(message.id);
      pending.delete(message.id);
      if (message.error) entry.reject(message.error); else entry.resolve(message.result);
    }
    if (message.method !== 'Fetch.requestPaused') return;
    try {
      const relative = new URL(message.params.request.url).pathname.replace(/^\/canvaskit\//, '');
      const file = path.resolve(base, relative);
      if (!file.startsWith(base + path.sep) || !/\.(js|wasm)$/.test(file)) {
        throw Error('Invalid cached CanvasKit asset path.');
      }
      const bytes = await readFile(file);
      await call('Fetch.fulfillRequest', {
        requestId: message.params.requestId, responseCode: 200,
        responseHeaders: [{name: 'Content-Type', value: relative.endsWith('.wasm') ? 'application/wasm' : 'text/javascript'}],
        body: bytes.toString('base64'),
      });
    } catch (error) {console.error(error.message); child.kill(); process.exit(1);}
  };
  await new Promise(resolve => ws.onopen = resolve);
  const origin = new URL(targetUrl).origin;
  await call('Fetch.enable', {patterns: [{urlPattern: `${origin}/canvaskit/*`, requestStage: 'Request'}]});
  await call('Page.navigate', {url: targetUrl});
})().catch(error => {console.error(error.message); child.kill(); process.exit(1);});
