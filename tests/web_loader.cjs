const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { webcrypto, createHash } = require('node:crypto');
const hashOf = data => createHash('sha256').update(data).digest('hex');
const pack = Buffer.from('GDPCresource pack fixture');
const wasm = Buffer.from([0, 97, 115, 109, 1, 0, 0, 0]);
const config = { executable: 'index', fileSizes: { 'index.pck': pack.length, 'index.wasm': wasm.length }, args: [] };
const manifest = {
    pck: [{file: 'parts/pck-000.pck', size: pack.length, sha256: hashOf(pack)}],
    wasm: [{file: 'parts/wasm-000.wasm', size: wasm.length, sha256: hashOf(wasm)}]
};
const shell = fs.readFileSync('tools/web_shell.html', 'utf8');
const script = shell.match(/<script>\s*([\s\S]*?)<\/script>/)[1]
    .replace('$GODOT_CONFIG', JSON.stringify(config))
    .replace('$GODOT_THREADS_ENABLED', 'false')
    .replace('$SHIFT_PACK_SHA256', hashOf(pack))
    .replace('$SHIFT_WEB_PARTS', JSON.stringify(manifest));

async function run(payload, status = 200, failOnce = false) {
    const elements = new Map(), calls = [], attempts = new Map();
    const element = id => {
        if (!elements.has(id)) elements.set(id, { hidden: ['retry', 'fallback'].includes(id), focus() { calls.push('focus'); } });
        return elements.get(id);
    };
    const nativeFetch = async file => {
        const count = (attempts.get(file) || 0) + 1;
        attempts.set(file, count);
        if (failOnce && count === 1) throw new TypeError('network error');
        if (file === 'parts/wasm-000.wasm') return new Response(wasm);
        if (file === 'parts/pck-000.pck') return new Response(payload, { status });
        throw new Error('Unexpected large-file request: ' + file);
    };
    const window = { fetch: nativeFetch, location: { reload() {} } };
    class Engine {
        static getMissingFeatures() { return []; }
        async init() {
            const response = await window.fetch('index.wasm');
            assert.deepEqual(Buffer.from(await response.arrayBuffer()), wasm);
            calls.push('init');
        }
        async preloadFile(bytes, path) { calls.push({ path, bytes: Buffer.from(bytes) }); }
        async start(options) { calls.push(options); }
    }
    const context = vm.createContext({
        Engine, crypto: webcrypto, navigator: { language: 'en-US' },
        document: { getElementById: element, baseURI: 'https://example.test/game/index.html' }, window,
        fetch: nativeFetch, Response, URL, AbortController,
        console: { error() {} }, setInterval: () => 1, clearInterval() {},
        setTimeout: (fn, ms) => setTimeout(fn, ms < 2000 ? 0 : ms), clearTimeout,
        Uint8Array, DataView, Date
    });
    await vm.runInContext(script, context);
    assert.equal(window.fetch, nativeFetch, 'Restore normal fetch after engine initialization');
    return { calls, elements, attempts };
}

(async () => {
    for (const failOnce of [false, true]) {
        const good = await run(pack, 200, failOnce);
        const mounted = good.calls.find(call => call.path);
        assert.equal(mounted.path, '/index.pck');
        assert.deepEqual(mounted.bytes, pack);
        assert.deepEqual(Array.from(good.calls.find(call => call.args).args), ['--main-pack', '/index.pck']);
        assert.equal(good.elements.get('loading').hidden, true);
        assert.equal(good.attempts.get('parts/pck-000.pck'), failOnce ? 2 : 1);
    }
    for (const payload of [pack.subarray(0, -1), Buffer.from('GDPCresource pack fixtur!')]) {
        const bad = await run(payload);
        assert.equal(bad.calls.some(call => call.args), false, 'Never boot a truncated or corrupt pack');
        assert.equal(bad.elements.get('retry').hidden, false);
        assert.equal(bad.elements.get('loading').hidden, false);
        assert.equal(bad.attempts.get('parts/pck-000.pck'), 4);
    }
    const missing = await run('Missing', 404);
    assert.equal(missing.calls.some(call => call.args), false);
    assert.equal(missing.elements.get('retry').hidden, false);
    console.log('Web loader: verified chunks boot, interrupted downloads recover, corrupt or missing chunks never boot.');
})().catch(error => { console.error(error); process.exitCode = 1; });
