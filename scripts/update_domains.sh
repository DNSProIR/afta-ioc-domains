#!/usr/bin/env bash
# Fetch the latest AFTA domain IOC list and write data/ + metadata.json
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${ROOT_DIR}/data"
# Iran-hosted proxy (afta.gov.ir is not reachable from GitHub-hosted runners)
SOURCE_URL="https://serverapi.ir/aftadomain.php"
UPSTREAM_URL="https://afta.gov.ir/uploads/DOMAIN/AFTA_IOC_DOMAINs.txt"
OUT_FILE="${DATA_DIR}/AFTA_IOC_DOMAINs.txt"
META_FILE="${DATA_DIR}/metadata.json"
TMP_BODY="$(mktemp)"
TMP_HEADERS="$(mktemp)"

cleanup() {
  rm -f "${TMP_BODY}" "${TMP_HEADERS}"
}
trap cleanup EXIT

mkdir -p "${DATA_DIR}"

echo "Fetching ${SOURCE_URL} ..."
HTTP_CODE="$(
  curl -sS -L \
    --retry 5 \
    --retry-delay 5 \
    --retry-all-errors \
    --connect-timeout 30 \
    --max-time 180 \
    -A "afta-ioc-domains-mirror/1.0 (+https://github.com; GitHub Actions)" \
    -D "${TMP_HEADERS}" \
    -o "${TMP_BODY}" \
    -w "%{http_code}" \
    "${SOURCE_URL}"
)"

if [[ "${HTTP_CODE}" != "200" ]]; then
  echo "ERROR: HTTP ${HTTP_CODE} from source" >&2
  head -c 500 "${TMP_BODY}" >&2 || true
  exit 1
fi

if [[ ! -s "${TMP_BODY}" ]]; then
  echo "ERROR: empty response body" >&2
  exit 1
fi

# Reject HTML error / portal pages
if grep -qiE '<html|<!DOCTYPE' "${TMP_BODY}"; then
  echo "ERROR: response looks like HTML, not a domain list" >&2
  head -c 500 "${TMP_BODY}" >&2 || true
  exit 1
fi

# Normalize trailing whitespace; ensure final newline; preserve line order
python3 - "${TMP_BODY}" "${OUT_FILE}" <<'PY'
import pathlib
import sys

src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
text = src.read_text(encoding="utf-8", errors="replace")
lines = [ln.rstrip() for ln in text.splitlines()]
while lines and lines[-1] == "":
    lines.pop()
if not lines:
    raise SystemExit("ERROR: no domain lines after normalization")
dst.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

LAST_MODIFIED="$(
  awk 'BEGIN{IGNORECASE=1} tolower($0) ~ /^last-modified:/ {
    sub(/^[^:]*:[[:space:]]*/, "", $0)
    sub(/\r$/, "", $0)
    print
    exit
  }' "${TMP_HEADERS}" || true
)"

FETCHED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
LIST_DATE="$(date -u +"%Y-%m-%d")"

if [[ -n "${LAST_MODIFIED}" ]]; then
  PARSED="$(
    python3 -c 'from email.utils import parsedate_to_datetime; import sys
try:
    print(parsedate_to_datetime(sys.argv[1]).strftime("%Y-%m-%d"))
except Exception:
    pass' "${LAST_MODIFIED}" 2>/dev/null || true
  )"
  if [[ -n "${PARSED}" ]]; then
    LIST_DATE="${PARSED}"
  fi
fi

DOMAIN_COUNT="$(grep -cE '^[A-Za-z0-9._*-]+$' "${OUT_FILE}" || true)"

python3 - "${META_FILE}" "${SOURCE_URL}" "${UPSTREAM_URL}" "${FETCHED_AT}" "${LIST_DATE}" "${LAST_MODIFIED}" "${DOMAIN_COUNT}" <<'PY'
import json
import sys

meta_path, source, upstream, fetched_at, list_date, last_modified, domain_count = sys.argv[1:8]
payload = {
    "source": source,
    "upstream": upstream,
    "fetched_at": fetched_at,
    "list_date": list_date,
    "last_modified": last_modified or None,
    "domain_count": int(domain_count),
}
with open(meta_path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
PY

echo "Wrote ${OUT_FILE} (${DOMAIN_COUNT} domains)"
echo "list_date=${LIST_DATE} fetched_at=${FETCHED_AT}"
cat "${META_FILE}"
