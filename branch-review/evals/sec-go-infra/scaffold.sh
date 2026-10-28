#!/usr/bin/env bash
# Checklist bullets planted here: C23 C43 C44 C45 (see the graders).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p cmd/sync migrations infra web
cat > migrations/001_init.sql <<'SQL'
CREATE ROLE app_readonly;
CREATE TABLE customers (id uuid PRIMARY KEY, email text NOT NULL);
GRANT SELECT ON customers TO app_readonly;
SQL
cat > infra/db.tf <<'TF'
resource "aws_security_group" "db" {
  name = "orders-db"
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
  }
}
TF
cat > web/package.json <<'JSON'
{
  "name": "orders-web",
  "dependencies": {
    "react": "18.3.1"
  }
}
JSON
git add -A
git commit -qm "initial"
git checkout -qb feat/reporting
cat > cmd/sync/main.go <<'GO'
package main

import (
	"crypto/tls"
	"io"
	"log"
	"net/http"
	"os"
)

func main() {
	client := &http.Client{Transport: &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}}
	resp, err := client.Get("https://ledger.internal.example/export?token=" + os.Getenv("LEDGER_TOKEN"))
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()
	io.Copy(os.Stdout, resp.Body)
}
GO
cat > migrations/002_reporting.sql <<'SQL'
-- Reporting needs to read the new tables.
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_readonly;
SQL
cat > infra/db.tf <<'TF'
resource "aws_security_group" "db" {
  name = "orders-db"
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
TF
cat > web/package.json <<'JSON'
{
  "name": "orders-web",
  "dependencies": {
    "react": "18.3.1",
    "chartjs-plugin-reporting": "latest",
    "lodahs": "^4.17.21"
  }
}
JSON
git add -A
git commit -qm "reporting"
