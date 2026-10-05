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
# No dedup here: nothing in the payload can prove an agent session already posted
# the verdict (the payload is taken before the session's own hook runs), so this
# action is the ONE poster for formal verdicts in the repositories that call it.
ISSUE=$( { q .pull_request.title; q .pull_request.head.ref; } | grep -oE '(CAN|BUG)-[0-9]+' | head -1 || true)
# No ticket: the verdict still goes out, only the link is omitted.
LINK=""; [ -n "$ISSUE" ] && LINK=" ($ISSUE: https://linear.app/cancore/issue/$ISSUE)"
URL=$(q .pull_request.html_url); [ -n "$URL" ] || URL="PR #$(q .pull_request.number)"
echo "$VERDICT ${REVIEWER:-ревьюер} — ${AUTHOR:-автор PR}, $URL$LINK"
