// Witness-level tests: valid input passes, each tampering is rejected by a constraint.
// Run: node test/witness.test.cjs   (needs build/ from scripts/build.sh and fixtures/dummy/input.json)
const fs = require("fs");
const path = require("path");
const wc = require("../build/jpki_age_region_js/witness_calculator.js");

const root = path.join(__dirname, "..");
const wasm = fs.readFileSync(path.join(root, "build/jpki_age_region_js/jpki_age_region.wasm"));
const base = JSON.parse(fs.readFileSync(path.join(root, "fixtures/dummy/input.json")));

const clone = () => JSON.parse(JSON.stringify(base));
const cases = [
  ["valid", (i) => i, true],
  ["wrong prefecture (大阪府=27)", (i) => { i.prefectureCode = "27"; }, false],
  ["prefecture out of range (0)", (i) => { i.prefectureCode = "0"; }, false],
  ["under age (threshold 30)", (i) => { i.ageThreshold = "30"; }, false],
  ["date before 20th birthday", (i) => { i.currentDate = "20190331"; }, false],
  ["tampered TBS byte (DOB digit)", (i) => { const o = +i.dobOidOffset + 20; i.tbs[o] = String(+i.tbs[o] ^ 1); }, false],
  ["challenge for another wallet", (i) => { i.chalMsg[0] = String(BigInt(i.chalMsg[0]) + 1n); }, false],
  ["DOB offset pointed elsewhere", (i) => { i.dobOidOffset = i.addrOidOffset; }, false],
  ["modulus offset shifted", (i) => { i.modOffset = String(+i.modOffset + 1); }, false],
  ["field beyond hashed data", (i) => { i.tbsPaddedLen = String(+i.dobOidOffset + 16 - ((+i.dobOidOffset + 16) % 64)); }, false],
];

(async () => {
  const calc = await wc(wasm);
  let fail = 0;
  for (const [name, mut, ok] of cases) {
    const input = clone();
    mut(input);
    let passed;
    try {
      await calc.calculateWTNSBin(input, 0);
      passed = true;
    } catch (e) {
      passed = false;
    }
    const good = passed === ok;
    if (!good) fail++;
    console.log(`${good ? "PASS" : "FAIL"}  ${name}  (expected ${ok ? "accept" : "reject"})`);
  }
  process.exit(fail ? 1 : 0);
})();
