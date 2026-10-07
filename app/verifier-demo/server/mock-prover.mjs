// Demo backend:
//  - mock prover: stands in for the phone app (NFC read + on-device proving). It issues a dummy JPKI
//    certificate for a chosen persona and proves with circuits/build artifacts.
//  - relay: hands a request to the real iPhone app (QR -> pipon://) and the proof back to the page.
//   node server/mock-prover.mjs   (port 8787; Vite proxies /api)
import { createServer } from "node:http";
import { randomBytes } from "node:crypto";
import { execFile } from "node:child_process";
import { readFile, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const circuits = path.resolve(here, "../../../circuits");
const PORT = Number(process.env.PORT || 8787);

// Dummy people only. DOB = EYYYYMMDD (era digit + Gregorian date).
const PERSONAS = {
  tokyo20: { label: "Tokyo · born 1999", ADDR: "東京都千代田区霞が関一丁目１番１号", DOB: "419990401", PREFECTURE_CODE: "13" },
  osaka40: { label: "Osaka · born 1985", ADDR: "大阪府大阪市北区中之島一丁目３番２０号", DOB: "319850715", PREFECTURE_CODE: "27" },
  tokyo17: { label: "Tokyo · born 2009", ADDR: "東京都新宿区西新宿二丁目８番１号", DOB: "420090401", PREFECTURE_CODE: "13" },
};

// make-claim.sh shares build/claim-tmp, so run one proof at a time.
let queue = Promise.resolve();
const serial = (fn) => (queue = queue.then(fn, fn));

function prove(binding, persona) {
  return serial(async () => {
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
      return json(res, 200, Object.fromEntries(Object.entries(PERSONAS).map(([k, v]) => [k, v.label])));
    }
    if (req.method === "GET" && req.url === "/api/vkey") {
      return json(res, 200, JSON.parse(await readFile(path.join(circuits, "build/vkey.json"), "utf8")));
    }
    if (req.method === "POST" && req.url === "/api/session") {
      // The page opens a session; the QR carries only its URL.
      const { binding, scope, service, statement } = await readBody(req);
      for (const [k, v] of sessions) if (v.expires < Date.now()) sessions.delete(k);
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
    if (req.method === "POST" && req.url === "/api/prove") {
      const { binding, persona, scope } = await readBody(req);
      const p = PERSONAS[persona];
      if (!p || typeof binding !== "string" || !/^([1-9A-HJ-NP-Za-km-z]{32,44}|[0-9a-f]{64})$/.test(binding)
        || !Number.isSafeInteger(scope) || scope < 1) {
        return json(res, 400, { error: "bad request" });
      }
      // One stable dummy card per persona, so its nullifier is the same on every proof.
      const { label: _label, ...fields } = p;
      const env = {
        ...fields,
        USER_KEY: path.join(circuits, `build/persona-${persona}.pem`),
        SERIAL: String(1000 + Object.keys(PERSONAS).indexOf(persona)),
        SCOPE: String(scope),
      };
      try {
        return json(res, 200, await prove(binding, env));
      } catch (e) {
        // A failed constraint means the card does not satisfy the statement (e.g. under 20): no proof exists.
        const unsatisfied = /Assert Failed|Error in template/.test(e.message);
        return json(res, unsatisfied ? 422 : 500, { error: unsatisfied ? "unsatisfiable" : "prover error" });
      }
    }
    json(res, 404, { error: "not found" });
  } catch (e) {
    json(res, 500, { error: String(e) });
  }
}).listen(PORT, "127.0.0.1", () => console.log(`mock prover on http://127.0.0.1:${PORT}`));
