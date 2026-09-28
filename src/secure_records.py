#!/usr/bin/env python3
"""Encrypt/decrypt student records and check file integrity (SHA-256)."""
import argparse
import hashlib
import json
import os
import sys
from pathlib import Path

from cryptography.fernet import Fernet, InvalidToken

# The key is stored OUTSIDE the repository (in the home folder).
KEY_FILE = Path(os.environ.get("EXAM_KEY_FILE", Path.home() / ".exam_keys" / "records.key"))
# Only hashes are stored here, never keys.
HASH_DB = Path("tests/hashes.json")


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def require_file(path):
    p = Path(path)
    if not p.is_file():
        raise FileNotFoundError(f"File not found: {p}")
    if p.stat().st_size == 0:
        raise ValueError(f"File is empty: {p}")
    return p


def load_db():
    try:
        return json.loads(HASH_DB.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_db(db):
    HASH_DB.parent.mkdir(exist_ok=True)
    HASH_DB.write_text(json.dumps(db, indent=2))


def load_key():
    if not KEY_FILE.is_file():
        raise FileNotFoundError(f"Key not found at {KEY_FILE}. Run 'keygen' first.")
    return KEY_FILE.read_bytes().strip()


def cmd_keygen(_):
    if Path.cwd() in KEY_FILE.resolve().parents:
        raise ValueError("Key path is inside the repository. Choose a path outside it.")
    if KEY_FILE.exists():
        raise FileExistsError(f"Key already exists: {KEY_FILE}")
    KEY_FILE.parent.mkdir(parents=True, exist_ok=True)
    KEY_FILE.write_bytes(Fernet.generate_key())
    os.chmod(KEY_FILE, 0o600)
    print(f"Key created at {KEY_FILE} (keep it OUT of git)")


def cmd_encrypt(a):
    src = require_file(a.input)
    db = load_db()
    db[str(src)] = sha256_file(src)  # baseline hash of the original
    save_db(db)
    Path(a.output).write_bytes(Fernet(load_key()).encrypt(src.read_bytes()))
    print(f"Encrypted {src} -> {a.output}")
    print(f"SHA-256 (original): {db[str(src)]}")


def cmd_decrypt(a):
    enc = require_file(a.input)
    try:
        plain = Fernet(load_key()).decrypt(enc.read_bytes())
    except InvalidToken:
        raise ValueError("Decryption failed: wrong key, or not an encrypted file, or file was changed.")
    Path(a.output).write_bytes(plain)
    if a.original:
        ok = hashlib.sha256(plain).hexdigest() == sha256_file(require_file(a.original))
        print("VERIFY:", "MATCH - decrypted file equals original" if ok else "MISMATCH")
        if not ok:
            sys.exit(2)
    else:
        print(f"Decrypted -> {a.output} (use --original to verify)")


def cmd_hash(a):
    p = require_file(a.input)
    db = load_db()
    db[str(p)] = sha256_file(p)
    save_db(db)
    print(f"Baseline stored. SHA-256: {db[str(p)]}")


def cmd_check(a):
    p = require_file(a.input)
    db = load_db()
    if str(p) not in db:
        raise ValueError(f"No baseline hash for {p}. Run 'hash' first.")
    now = sha256_file(p)
    if now == db[str(p)]:
        print("INTEGRITY OK: file unchanged")
    else:
        print("INTEGRITY FAIL: file was modified")
        print(f"  expected {db[str(p)]}")
        print(f"  actual   {now}")
        sys.exit(2)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("keygen", help="create the secret key").set_defaults(fn=cmd_keygen)

    for name, fn in (("encrypt", cmd_encrypt), ("decrypt", cmd_decrypt)):
        s = sub.add_parser(name, help=f"{name} a file")
        s.add_argument("input")
        s.add_argument("output")
        if name == "decrypt":
            s.add_argument("--original", help="original file to compare against")
        s.set_defaults(fn=fn)

    for name, fn in (("hash", cmd_hash), ("check", cmd_check)):
        s = sub.add_parser(name, help=f"{name} a file")
        s.add_argument("input")
        s.set_defaults(fn=fn)

    a = ap.parse_args()
    try:
        a.fn(a)
    except (FileNotFoundError, FileExistsError, ValueError, PermissionError, OSError) as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
