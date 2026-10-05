# ring-actions

Public shared GitHub Actions for the Cancore ring, consumable from both public
and private repositories (a public repository cannot use an action from a
private one).

| Action | What it does |
|---|---|
| `actions/review-verdict-notify` | Posts an approved / changes_requested review verdict to Slack. Reads the event payload only: no checkout, no PR-head code runs. |

Pin by full commit sha:

```yaml
- uses: Cancore-io/ring-actions/actions/review-verdict-notify@<sha>
  with:
    slack-bot-token: ${{ secrets.SLACK_BOT_TOKEN }}
```

Without a token the action logs a warning and exits green.
