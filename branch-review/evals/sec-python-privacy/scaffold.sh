#!/usr/bin/env bash
# Checklist bullets planted here: C21 C25 C26 C27 C28 (see the graders).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p app
cat > app/db.py <<'PY'
import sqlite3

conn = sqlite3.connect("app.db")
PY
cat > app/accounts.py <<'PY'
import logging

from app.db import conn

log = logging.getLogger(__name__)


def delete_account(user_id):
    """Right-to-erasure: remove everything we hold about a user."""
    conn.execute("DELETE FROM orders WHERE user_id = ?", (user_id,))
    conn.execute("DELETE FROM addresses WHERE user_id = ?", (user_id,))
    conn.execute("DELETE FROM users WHERE id = ?", (user_id,))
    log.info("deleted account %s", user_id)
PY
git add -A
git commit -qm "initial"
git checkout -qb feat/support-and-signup
cat > app/signup.py <<'PY'
import hashlib
import logging
import os

import requests

from app.db import conn

log = logging.getLogger(__name__)
SMS_API_KEY = os.environ["SMS_API_KEY"]


def create_user(email, password, ssn, date_of_birth):
    pw_hash = hashlib.sha256(password.encode()).hexdigest()
    conn.execute(
        "INSERT INTO users (email, pw_hash, ssn, dob) VALUES (?, ?, ?, ?)",
        (email, pw_hash, ssn, date_of_birth),
    )
    log.info("new signup email=%s ssn=%s dob=%s", email, ssn, date_of_birth)


def send_verification_sms(phone):
    log.debug("sending SMS via provider with key %s to %s", SMS_API_KEY, phone)
    requests.post(
        "https://sms.provider.example/send",
        json={"to": phone, "body": "Your code is ready"},
        headers={"Authorization": f"Bearer {SMS_API_KEY}"},
        timeout=5,
    )
PY
cat > app/support.py <<'PY'
import hashlib
import hmac
import os

from flask import request, abort

from app import app
from app.db import conn

WEBHOOK_SECRET = os.environ["SUPPORT_WEBHOOK_SECRET"]


@app.post("/support/tickets/<int:user_id>/attachments")
def add_attachment(user_id):
    f = request.files["file"]
    conn.execute(
        "INSERT INTO support_attachments (user_id, name, body) VALUES (?, ?, ?)",
        (user_id, f.filename, f.read()),
    )
    return "", 201


@app.post("/support/webhook")
def support_webhook():
    expected = hashlib.md5((WEBHOOK_SECRET + request.get_data(as_text=True)).encode()).hexdigest()
    if not hmac.compare_digest(expected, request.headers.get("X-Signature", "")):
        abort(401)
    return "", 204
PY
git add -A
git commit -qm "support attachments and signup"
