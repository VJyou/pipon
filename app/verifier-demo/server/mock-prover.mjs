// Demo backend:
//  - mock prover: stands in for the phone app (NFC read + on-device proving). It issues a dummy JPKI
//    certificate for a chosen persona and proves with circuits/build artifacts.
//  - relay: hands a request to the real iPhone app (QR -> pipon://) and the proof back to the page.
//   node server/mock-prover.mjs   (port 8787; Vite proxies /api)
//   PUBLIC=1 node server/mock-prover.mjs   (public demo: also serves dist/, rate limits)
import { createServer } from "node:http";
import { randomBytes } from "node:crypto";
import { execFile } from "node:child_process";
import { readFile, mkdtemp, rm, mkdir, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const circuits = path.resolve(here, "../../../circuits");
const PORT = Number(process.env.PORT || 8787);
const PUBLIC = process.env.PUBLIC === "1";
const dist = path.resolve(here, "../dist");
// Same choice as circuits/scripts/make-claim.sh: gen_dummy_jpki.py needs Python >= 3.10 with `cryptography`.
const venvPython = path.join(process.env.HOME ?? "", ".venvs/zkcred/bin/python3");
const PYTHON = process.env.PYTHON || (existsSync(venvPython) ? venvPython : "python3");

// Dummy people only. DOB = EYYYYMMDD (era digit + Gregorian date).
const PERSONAS = {
  tokyo20: { label: "Tokyo · born 1999", ADDR: "東京都千代田区霞が関一丁目１番１号", DOB: "419990401", PREFECTURE_CODE: "13" },
  osaka40: { label: "Osaka · born 1985", ADDR: "大阪府大阪市北区中之島一丁目３番２０号", DOB: "319850715", PREFECTURE_CODE: "27" },
  tokyo17: { label: "Tokyo · born 2009", ADDR: "東京都新宿区西新宿二丁目８番１号", DOB: "420090401", PREFECTURE_CODE: "13" },
};
// "guest": a dummy card of its own for each browser (key made on first use), so every visitor can mint once and
// then see their second claim rejected. Same dummy person as tokyo20 otherwise.
const GUEST = { label: "Your own dummy card · Tokyo · born 1999", ADDR: "東京都千代田区霞が関一丁目１番１号", DOB: "419990401", PREFECTURE_CODE: "13" };
const guestDir = path.join(circuits, "build/guest-cards");
const MAX_GUESTS = 5000;

// Public demo limits: proofs per IP per hour, and how many proofs may wait in the queue.
const PROOFS_PER_IP_HOUR = 20;
const MAX_WAITING = 6;
const proofLog = new Map(); // ip -> timestamps
let waiting = 0;
// The proxy in front sets the client address in a header; trust only the one named by IP_HEADER.
const IP_HEADER = process.env.IP_HEADER; // "x-real-ip" on Railway
const clientIp = (req) => String((IP_HEADER && req.headers[IP_HEADER]) || req.socket.remoteAddress || "");
function allowProof(ip) {
  const now = Date.now();
  const recent = (proofLog.get(ip) ?? []).filter((t) => now - t < 3_600_000);
  if (recent.length >= PROOFS_PER_IP_HOUR) return false;
  recent.push(now);
  proofLog.set(ip, recent);
  return true;
}

// Retention promised in public/privacy.html: IPs at most an hour, relay sessions at most their 10 minutes.
setInterval(() => {
  const now = Date.now();
  for (const [ip, ts] of proofLog) if (ts.every((t) => now - t >= 3_600_000)) proofLog.delete(ip);
  for (const [id, s] of sessions) if (s.expires < now) sessions.delete(id);
}, 60_000).unref();

// make-claim.sh shares build/claim-tmp, so run one proof at a time.
let queue = Promise.resolve();
const serial = (fn) => (queue = queue.then(fn, fn));

function prove(binding, persona) {
  waiting++;
  return serial(async () => {
    waiting--;
    const dir = await mkdtemp(path.join(tmpdir(), "zkcred-"));
    const out = path.join(dir, "claim.json");
    const started = Date.now();
    try {
      await new Promise((resolve, reject) =>
        execFile(path.join(circuits, "scripts/make-claim.sh"), [binding, out],
          { env: { ...process.env, ...persona }, maxBuffer: 1 << 24 },
          (err, _stdout, stderr) => (err ? reject(new Error(stderr || err.message)) : resolve())),
      );
      const tmp = path.join(circuits, "build/claim-tmp");
      const [claim, proof, publicSignals] = await Promise.all(
        [out, path.join(tmp, "proof.json"), path.join(tmp, "public.json")].map(async (f) => JSON.parse(await readFile(f, "utf8"))),
      );
      return { claim, proof, publicSignals, ms: Date.now() - started };
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });
}

// Relay sessions: id -> { request, result?, expires }. In memory; demo only.
const sessions = new Map();
const SESSION_TTL_MS = 10 * 60_000;
const sessionRoute = /^\/api\/session\/([0-9a-f]{32})(\/result)?$/;

async function readBody(req, limit = 64 * 1024) {
  let body = "";
  for await (const chunk of req) {
    body += chunk;
    if (body.length > limit) throw new Error("body too large");
  }
  return JSON.parse(body);
}

const json = (res, code, body) => {
  res.writeHead(code, { "content-type": "application/json" });
  res.end(JSON.stringify(body));
};

createServer(async (req, res) => {
  try {
    if (req.method === "GET" && req.url === "/api/personas") {
      return json(res, 200, { guest: GUEST.label, ...Object.fromEntries(Object.entries(PERSONAS).map(([k, v]) => [k, v.label])) });
    }
    if (req.method === "GET" && req.url === "/api/vkey") {
      return json(res, 200, JSON.parse(await readFile(path.join(circuits, "build/vkey.json"), "utf8")));
    }
    if (req.method === "POST" && req.url === "/api/session") {
      // The page opens a session; the QR carries only its URL.
      const { binding, scope, service, statement } = await readBody(req);
      for (const [k, v] of sessions) if (v.expires < Date.now()) sessions.delete(k);
      if (sessions.size >= 2000) return json(res, 503, { error: "busy" });
      const id = randomBytes(16).toString("hex");
      sessions.set(id, { request: { binding, scope, service, statement }, expires: Date.now() + SESSION_TTL_MS });
      return json(res, 200, { id });
    }
    const m = sessionRoute.exec(req.url ?? "");
    if (m) {
      const s = sessions.get(m[1]);
      if (!s || s.expires < Date.now()) return json(res, 404, { error: "no such session" });
      if (req.method === "GET" && !m[2]) {
        // phone: fetch the request / page: poll for the result
        return json(res, 200, { request: s.request, result: s.result ?? null });
      }
      if (req.method === "POST" && m[2]) {
        // phone: deliver { proof, publicSignals, nonce } (snarkjs JSON format)
        const { proof, publicSignals, nonce } = await readBody(req);
        if (!proof || !Array.isArray(publicSignals) || publicSignals.length !== 8 || !/^[0-9]+$/.test(String(nonce))) {
          return json(res, 400, { error: "bad result" });
        }
        s.result = { proof, publicSignals, nonce: String(nonce) };
        return json(res, 200, { ok: true });
      }
    }
    if (req.method === "POST" && req.url === "/api/demo-card") {
      // The iPhone app's "demo card" for people without a My Number Card (hackathon judges): the same dummy person as
      // the web guest card, with a key of its own per install. Returns the dummy certificate, its TEST key and the
      // dummy CA certificate. The phone then signs and proves exactly as with a real card.
      const { cardId } = await readBody(req);
      if (typeof cardId !== "string" || !/^[0-9a-f]{32}$/.test(cardId)) return json(res, 400, { error: "bad request" });
      if (PUBLIC && !allowProof(clientIp(req))) return json(res, 429, { error: "too many requests from this address; try again later" });
      await mkdir(guestDir, { recursive: true });
      const userKey = path.join(guestDir, `${cardId}.pem`);
      const guests = await readdir(guestDir);
      if (guests.length >= MAX_GUESTS && !guests.includes(`${cardId}.pem`)) {
        return json(res, 503, { error: "the demo has run out of guest cards" });
      }
      const { label, ...fields } = GUEST;
      const dir = await mkdtemp(path.join(tmpdir(), "zkcred-card-"));
      try {
        await new Promise((resolve, reject) =>
          execFile(PYTHON, [path.join(circuits, "scripts/gen_dummy_jpki.py")], {
            env: {
              ...process.env, ...fields, OUT_DIR: dir, CA_KEY: path.join(circuits, "build/dummy-ca.pem"),
              USER_KEY: userKey, SERIAL: String(100000 + parseInt(cardId.slice(0, 7), 16)),
            },
          }, (err, _stdout, stderr) => (err ? reject(new Error(stderr || err.message)) : resolve())),
        );
        const [certificate, ca, key] = await Promise.all([
          readFile(path.join(dir, "user.der")), readFile(path.join(dir, "ca.der")), readFile(userKey, "utf8"),
        ]);
        return json(res, 200, {
          label, certificate: certificate.toString("base64"), caCertificate: ca.toString("base64"), privateKeyPEM: key,
        });
      } finally {
        await rm(dir, { recursive: true, force: true });
      }
    }
    if (req.method === "POST" && req.url === "/api/prove") {
      const { binding, persona, scope, guestId } = await readBody(req);
      const isGuest = persona === "guest" && typeof guestId === "string" && /^[0-9a-f]{32}$/.test(guestId);
      const p = isGuest ? GUEST : PERSONAS[persona];
      if (!p || typeof binding !== "string" || !/^([1-9A-HJ-NP-Za-km-z]{32,44}|[0-9a-f]{64})$/.test(binding)
        || !Number.isSafeInteger(scope) || scope < 1) {
        return json(res, 400, { error: "bad request" });
      }
      if (PUBLIC && !allowProof(clientIp(req))) return json(res, 429, { error: "too many proofs from this address; try again later" });
      if (waiting >= MAX_WAITING) return json(res, 503, { error: "the demo prover is busy; try again in a minute" });
      // One stable dummy card per persona (or per guest), so its nullifier is the same on every proof.
      const { label: _label, ...fields } = p;
      let userKey = path.join(circuits, `build/persona-${persona}.pem`);
      let serialNo = 1000 + Object.keys(PERSONAS).indexOf(persona);
      if (isGuest) {
        await mkdir(guestDir, { recursive: true });
        userKey = path.join(guestDir, `${guestId}.pem`);
        if ((await readdir(guestDir)).length >= MAX_GUESTS && !(await readdir(guestDir)).includes(`${guestId}.pem`)) {
          return json(res, 503, { error: "the demo has run out of guest cards" });
        }
        serialNo = 100000 + parseInt(guestId.slice(0, 7), 16);
      }
      const env = { ...fields, USER_KEY: userKey, SERIAL: String(serialNo), SCOPE: String(scope) };
      try {
        return json(res, 200, await prove(binding, env));
      } catch (e) {
        // A failed constraint means the card does not satisfy the statement (e.g. under 20): no proof exists.
        const unsatisfied = /Assert Failed|Error in template/.test(e.message);
        return json(res, unsatisfied ? 422 : 500, { error: unsatisfied ? "unsatisfiable" : "prover error" });
      }
    }
    if (PUBLIC && req.method === "GET" && !req.url.startsWith("/api/")) return serveStatic(req, res);
    json(res, 404, { error: "not found" });
  } catch (e) {
    json(res, 500, { error: String(e) });
  }
}).listen(PORT, process.env.HOST || "127.0.0.1", () => console.log(`mock prover on http://${process.env.HOST || "127.0.0.1"}:${PORT}${PUBLIC ? " (public: dist/, limits)" : ""}`));

// Built page (npm run build) for the public demo; unknown paths fall back to index.html.
const TYPES = { ".html": "text/html; charset=utf-8", ".js": "text/javascript", ".css": "text/css", ".png": "image/png",
  ".svg": "image/svg+xml", ".wasm": "application/wasm", ".json": "application/json", ".ico": "image/x-icon" };
async function serveStatic(req, res) {
  const rel = decodeURIComponent(new URL(req.url, "http://x").pathname).replace(/^\/+/, "");
  let file = path.resolve(dist, rel || "index.html");
  if (!file.startsWith(dist + path.sep) && file !== dist) return json(res, 404, { error: "not found" });
  let body;
  try { body = await readFile(file); } catch { file = path.join(dist, "index.html"); body = await readFile(file); }
  res.writeHead(200, { "content-type": TYPES[path.extname(file)] ?? "application/octet-stream",
    "cache-control": file.includes(`${path.sep}assets${path.sep}`) ? "public, max-age=31536000, immutable" : "no-cache" });
  res.end(body);
}
