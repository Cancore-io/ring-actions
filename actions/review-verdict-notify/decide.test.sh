#!/usr/bin/env bash
# Fixture run of decide.sh — `bash decide.test.sh`, exits 1 on any mismatch.
set -u
cd "$(dirname "$0")"
fail=0
tmp=$(mktemp)
check() { # name, expect(notify|silent), json
  printf '%s' "$3" > "$tmp"
  out=$(bash decide.sh "$tmp" 2>/dev/null)
  got=silent; [ -n "$out" ] && got=notify
  if [ "$got" = "$2" ]; then echo "ok   $1"; else echo "FAIL $1: expected $2, got $got ($out)"; fail=1; fi
}
pr='"pull_request":{"title":"fix: x (BUG-1)","html_url":"https://github.com/o/r/pull/1","user":{"login":"author"},"head":{"ref":"agent/BUG-1"}}'
check "approved notifies" notify "{\"action\":\"submitted\",\"review\":{\"state\":\"APPROVED\",\"user\":{\"login\":\"rev\"},\"body\":\"\"},$pr}"
check "changes_requested notifies" notify "{\"action\":\"submitted\",\"review\":{\"state\":\"changes_requested\",\"user\":{\"login\":\"rev\"}},$pr}"
check "commented is silent" silent "{\"action\":\"submitted\",\"review\":{\"state\":\"commented\",\"user\":{\"login\":\"rev\"}},$pr}"
check "dismissed is silent" silent "{\"action\":\"dismissed\",\"review\":{\"state\":\"dismissed\",\"user\":{\"login\":\"rev\"}},$pr}"
check "self-review is silent" silent "{\"action\":\"submitted\",\"review\":{\"state\":\"approved\",\"user\":{\"login\":\"author\"}},$pr}"
check "ring marker is silent" silent "{\"action\":\"submitted\",\"review\":{\"state\":\"approved\",\"user\":{\"login\":\"rev\"},\"body\":\"## Ревью\\n- **Вердикт:** одобрено\\nhead abc\"},$pr}"
check "quoted marker notifies" notify "{\"action\":\"submitted\",\"review\":{\"state\":\"changes_requested\",\"user\":{\"login\":\"rev\"},\"body\":\"> - **Вердикт:** одобрено\\nнет\"},$pr}"
check "no ticket is silent" silent '{"action":"submitted","review":{"state":"approved","user":{"login":"rev"}},"pull_request":{"title":"x","head":{"ref":"feat"},"user":{"login":"a"}}}'
check "garbage payload is silent" silent 'not json'
rm -f "$tmp"
exit $fail
