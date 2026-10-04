#!/usr/bin/env python3
"""Generate a JPKI-like dummy signing certificate and circuit input.

Everything here is synthetic: a dummy CA, a dummy person, and a challenge signed by the
dummy "card" key. The SAN layout mimics the JPKI signing certificate
(otherName 1.2.392.200149.8.5.5.{1,3,4,5}), but no real certificate is used.

Output: circuits/fixtures/dummy/{ca.der,user.der,input.json}
"""
import datetime
import hashlib
import json
import os
import sys

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.x509.oid import NameOID

N, K = 121, 17
MAX_TBS = int(os.environ.get("MAX_TBS", "2048"))
OUT = os.environ.get("OUT_DIR", os.path.join(os.path.dirname(__file__), "..", "fixtures", "dummy"))

OID_NAME = "1.2.392.200149.8.5.5.1"
OID_SEX = "1.2.392.200149.8.5.5.3"
OID_DOB = "1.2.392.200149.8.5.5.4"
OID_ADDR = "1.2.392.200149.8.5.5.5"

# Dummy person. EYYYYMMDD: era 4 (Heisei), Gregorian year assumed (TODO: confirm with profile spec).
PERSON = {
    "name": "試験　太郎",
    "sex": "1",
    "dob": "419990401",
    "addr": os.environ.get("ADDR", "東京都千代田区霞が関一丁目１番１号"),
}
PREFECTURE_CODE = 13  # 東京都 (JIS X 0401)
CURRENT_DATE = 20261004
AGE_THRESHOLD = 20
SCOPE = 1  # service identifier, public


def utf8_der(s: str) -> bytes:
    b = s.encode()
    if len(b) < 128:
        return bytes([0x0C, len(b)]) + b
    if len(b) < 256:
        return bytes([0x0C, 0x81, len(b)]) + b
    return bytes([0x0C, 0x82, len(b) >> 8, len(b) & 0xFF]) + b


def oid_der(dotted: str) -> bytes:
    parts = [int(p) for p in dotted.split(".")]
    body = bytes([40 * parts[0] + parts[1]])
    for p in parts[2:]:
        enc = [p & 0x7F]
        p >>= 7
        while p:
            enc.append(0x80 | (p & 0x7F))
            p >>= 7
        body += bytes(reversed(enc))
    return bytes([0x06, len(body)]) + body


def chunks(x: int) -> list[str]:
    return [str((x >> (N * i)) & ((1 << N) - 1)) for i in range(K)]


def sha_pad(msg: bytes, max_len: int) -> tuple[list[int], int]:
    ml = len(msg) * 8
    p = msg + b"\x80"
    while (len(p) % 64) != 56:
        p += b"\x00"
    p += ml.to_bytes(8, "big")
    if len(p) > max_len:
        sys.exit(f"padded TBS {len(p)} > MAX_TBS {max_len}")
    return list(p) + [0] * (max_len - len(p)), len(p)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    now = datetime.datetime(2026, 10, 1, tzinfo=datetime.timezone.utc)

    ca_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    ca_name = x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, "JP"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "JPKI-DUMMY"),
        x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, "DUMMY for digital signature"),
    ])
    ca_cert = (
        x509.CertificateBuilder()
        .subject_name(ca_name).issuer_name(ca_name)
        .public_key(ca_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now).not_valid_after(now + datetime.timedelta(days=3650))
        .add_extension(x509.BasicConstraints(ca=True, path_length=None), critical=True)
        .sign(ca_key, hashes.SHA256())
    )

    user_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    san = x509.SubjectAlternativeName([
        x509.OtherName(x509.ObjectIdentifier(OID_NAME), utf8_der(PERSON["name"])),
        x509.OtherName(x509.ObjectIdentifier(OID_SEX), utf8_der(PERSON["sex"])),
        x509.OtherName(x509.ObjectIdentifier(OID_DOB), utf8_der(PERSON["dob"])),
        x509.OtherName(x509.ObjectIdentifier(OID_ADDR), utf8_der(PERSON["addr"])),
    ])
    user_cert = (
        x509.CertificateBuilder()
        .subject_name(x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "JP"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "Chiyoda-ku"),
            x509.NameAttribute(NameOID.COMMON_NAME, "DUMMY0000000000000000000000000"),
        ]))
        .issuer_name(ca_name)
        .public_key(user_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now).not_valid_after(now + datetime.timedelta(days=365 * 5))
        .add_extension(x509.KeyUsage(True, True, False, False, False, False, False, False, False), critical=True)
        .add_extension(san, critical=False)
        .sign(ca_key, hashes.SHA256())
    )

    tbs = user_cert.tbs_certificate_bytes
    ca_pub = ca_key.public_key().public_numbers()
    user_pub = user_key.public_key().public_numbers()

    # Field locations inside TBS (the circuit re-checks the bytes around them).
    mod_bytes = user_pub.n.to_bytes(256, "big")
    mod_off = tbs.index(b"\x30\x82\x01\x0a\x02\x82\x01\x01\x00" + mod_bytes) + 9
    dob_oid_off = tbs.index(oid_der(OID_DOB))
    addr_oid_off = tbs.index(oid_der(OID_ADDR))
    addr_hdr = tbs[addr_oid_off + 12: addr_oid_off + 18]
    addr_long = 1 if addr_hdr[1] == 0x81 else 0

    # Challenge: the card signs SHA-256(msg) with PKCS#1 v1.5. msg binds the wallet + nonce.
    wallet = bytes(range(32))  # dummy wallet pubkey
    nonce = (12345).to_bytes(8, "big")
    msg = hashlib.sha256(wallet + nonce).digest()
    chal_sig = user_key.sign(msg, padding.PKCS1v15(), hashes.SHA256())

    tbs_padded, tbs_len = sha_pad(tbs, MAX_TBS)
    inp = {
        "tbs": [str(b) for b in tbs_padded],
        "tbsPaddedLen": str(tbs_len),
        "caSig": chunks(int.from_bytes(user_cert.signature, "big")),
        "caModulus": chunks(ca_pub.n),
        "modOffset": str(mod_off),
        "dobOidOffset": str(dob_oid_off),
        "addrOidOffset": str(addr_oid_off),
        "addrLongForm": str(addr_long),
        "chalSig": chunks(int.from_bytes(chal_sig, "big")),
        "chalMsg": [str(int.from_bytes(msg[:16], "big")), str(int.from_bytes(msg[16:], "big"))],
        "currentDate": str(CURRENT_DATE),
        "ageThreshold": str(AGE_THRESHOLD),
        "prefectureCode": str(PREFECTURE_CODE),
        "scope": str(SCOPE),
    }

    with open(os.path.join(OUT, "ca.der"), "wb") as f:
        f.write(ca_cert.public_bytes(serialization.Encoding.DER))
    with open(os.path.join(OUT, "user.der"), "wb") as f:
        f.write(user_cert.public_bytes(serialization.Encoding.DER))
    with open(os.path.join(OUT, "input.json"), "w") as f:
        json.dump(inp, f)
    print(f"tbs={len(tbs)}B padded={tbs_len}B max={MAX_TBS} mod@{mod_off} dobOid@{dob_oid_off} "
          f"addrOid@{addr_oid_off} addrLong={addr_long} addrBytes={len(PERSON['addr'].encode())}")


if __name__ == "__main__":
    main()
