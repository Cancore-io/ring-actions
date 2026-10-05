#!/usr/bin/env bash
# Decide whether a pull_request_review payload is worth a Slack line.
# Prints the message text on stdout when it is, nothing when it is silent;
# the reason for silence goes to stderr. Never exits non-zero on bad input.
set -u
EVENT="${1:-${GITHUB_EVENT_PATH:-}}"
q() { jq -r "$1 // \"\"" "$EVENT" 2>/dev/null || true; }

[ "$(q .action)" = "submitted" ] || { echo "silent: action is not submitted" >&2; exit 0; }
STATE=$(q .review.state | tr '[:upper:]' '[:lower:]')
case "$STATE" in
  approved) VERDICT="✅ одобрил" ;;
  changes_requested) VERDICT="⛔ запросил изменения" ;;
  *) echo "silent: state=$STATE is not a standing verdict" >&2; exit 0 ;;
esac
REVIEWER=$(q .review.user.login)
AUTHOR=$(q .pull_request.user.login)
if [ -n "$REVIEWER" ] && [ "$REVIEWER" = "$AUTHOR" ]; then
  echo "silent: self-review" >&2; exit 0
fi
# A ring-session verdict (marker on its own unquoted line) was already posted by
# the review-verdict-log hook; a quoted marker is somebody else's words.
if q .review.body | grep -v '^[[:space:]]*>' \
  | grep -qE '^[[:space:]]*([-*][[:space:]]*)?\*\*(В|в)ердикт:\*\*[[:space:]]*одобрено[[:space:]]*$'; then
  echo "silent: ring verdict, already delivered by the session hook" >&2; exit 0
fi
ISSUE=$( { q .pull_request.title; q .pull_request.head.ref; } | grep -oE '(CAN|BUG)-[0-9]+' | head -1 || true)
[ -n "$ISSUE" ] || { echo "silent: no ring ticket in PR title/branch" >&2; exit 0; }
echo "$VERDICT ${REVIEWER:-ревьюер} — ${AUTHOR:-автор PR}, $(q .pull_request.html_url) ($ISSUE: https://linear.app/cancore/issue/$ISSUE)"
