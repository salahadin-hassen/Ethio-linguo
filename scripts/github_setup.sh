#!/usr/bin/env bash
# One-time GitHub setup: labels, workstream issues, foundation PR, protection for main.
# Needs the GitHub CLI, signed in as a repo admin:  gh auth login
# Safe to re-run: existing labels are updated, and issues/PRs are only created if missing.
set -euo pipefail
REPO="${REPO:-salahadin-hassen/Ethio-linguo}"
cd "$(git rev-parse --show-toplevel)"

label() { gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force; }
label frontend      1d76db "Engineer 1: Flutter UI"
label media         0e8a16 "Engineer 2: media learning"
label voice-ai      5319e7 "Engineer 3: AI tutor"
label integration   fbca04 "Shared contracts / integration branch"
label bug           d73a4a "Something is broken"
label blocker       b60205 "Blocks a workstream - escalate now"
label demo-critical e99695 "On the demo path"

issue() { # $1=file $2=labels
  local title; title="$(head -1 "$1" | sed 's/^# //')"
  if gh issue list --repo "$REPO" --state all --search "\"$title\" in:title" --json number -q '.[0].number' | grep -q .; then
    echo "exists: $title"; return
  fi
  tail -n +2 "$1" | gh issue create --repo "$REPO" --title "$title" --label "$2" --body-file -
}
issue .github/workstreams/E1-mobile-ui.md      frontend,demo-critical
issue .github/workstreams/E2-media-learning.md media,demo-critical
issue .github/workstreams/E3-ai-tutor.md       voice-ai,demo-critical

if ! gh pr list --repo "$REPO" --head chore/hackathon-foundation --state all --json number -q '.[0].number' | grep -q .; then
  gh pr create --repo "$REPO" --base main --head chore/hackathon-foundation \
    --title "Hackathon foundation: architecture, contracts, docs and workflow" \
    --label integration --body-file .github/FOUNDATION_PR.md
fi

# Protect main: PRs only, no force-push, no deletion. Free plans allow this on public repos only.
gh api -X PUT "repos/$REPO/branches/main/protection" --input - <<'JSON' || echo "WARN: branch protection not applied (permissions/plan)."
{ "required_status_checks": null, "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null, "allow_force_pushes": false, "allow_deletions": false }
JSON
echo "Done."
