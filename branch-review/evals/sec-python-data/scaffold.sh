#!/usr/bin/env bash
# Checklist bullets planted here: C04 C05 C06 C12 C41 (see the graders).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p app
cat > app/__init__.py <<'PY'
from flask import Flask
from pymongo import MongoClient

app = Flask(__name__)
db = MongoClient()["shop"]
PY
cat > app/health.py <<'PY'
from flask import jsonify
from app import app


@app.get("/health")
def health():
    return jsonify(ok=True)
PY
git add -A
git commit -qm "initial"
git checkout -qb feat/import-export
cat > app/imports.py <<'PY'
import csv
import io
import pickle

import yaml
from flask import request, render_template_string, Response, jsonify

from app import app, db


@app.post("/imports/cart")
def import_cart():
    cart = pickle.loads(request.get_data())
    db.carts.insert_one(cart)
    return jsonify(ok=True)


@app.post("/imports/catalog")
def import_catalog():
    catalog = yaml.load(request.get_data(), Loader=yaml.Loader)
    db.catalog.insert_many(catalog["items"])
    return jsonify(count=len(catalog["items"]))


@app.get("/greeting")
def greeting():
    return render_template_string("<p>Hello " + request.args.get("name", "") + "</p>")


@app.post("/staff/login")
def staff_login():
    body = request.get_json()
    staff = db.staff.find_one({"username": body["username"], "password": body["password"]})
    return jsonify(ok=staff is not None)


@app.get("/exports/reviews.csv")
def export_reviews():
    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(["product", "rating", "comment"])
    for r in db.reviews.find():
        writer.writerow([r["product"], r["rating"], r["comment"]])
    return Response(out.getvalue(), mimetype="text/csv")
PY
git add -A
git commit -qm "imports and exports"
