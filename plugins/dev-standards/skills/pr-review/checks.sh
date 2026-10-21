#!/usr/bin/env bash
# Deterministic PR checks. Prints BLOCKING:, NIT:, INFO:, or OK: lines.
# Usage: checks.sh <pr-number-or-url>

set -uo pipefail

pr="${1:-}"
if [ -z "$pr" ]; then
  echo "Usage: checks.sh <pr-number-or-url>" >&2
  exit 2
fi

# Path patterns that count as UI changes. Adjust per repo.
ui_pattern='\.(tsx|jsx|vue|svelte|css|scss|sass|less|html)$|/(components|ui|styles|pages|views|assets|public)/|\.(svg|png|jpg|jpeg|gif|webp)$'

# Merge conflicts
mergeable=$(gh pr view "$pr" --json mergeable --jq '.mergeable')
if [ "$mergeable" = "CONFLICTING" ]; then
  echo "BLOCKING: Merge conflicts with the base branch. Rebase or merge the base branch and resolve them."
elif [ "$mergeable" = "UNKNOWN" ]; then
  echo "INFO: GitHub has not computed mergeability yet. Re-run this check before submitting."
else
  echo "OK: No merge conflicts."
fi

# Branch up to date with the base branch
read -r base head_sha pr_url <<< "$(gh pr view "$pr" --json baseRefName,headRefOid,url --jq '"\(.baseRefName) \(.headRefOid) \(.url)"')"
repo=$(echo "$pr_url" | sed -E 's#https://[^/]+/([^/]+/[^/]+)/pull/.*#\1#')
behind=$(gh api "repos/$repo/compare/$base...$head_sha" --jq '.behind_by' 2>/dev/null || true)
if [ -z "$behind" ]; then
  echo "INFO: Could not determine whether the branch is behind $base."
elif [ "$behind" -gt 0 ]; then
  echo "NIT: Branch is $behind commit(s) behind $base. Update it with the base branch."
else
  echo "OK: Branch is up to date with $base."
fi

# Linked issue
issues=$(gh pr view "$pr" --json closingIssuesReferences --jq '[.closingIssuesReferences[].number] | join(" ")')
if [ -z "$issues" ]; then
  echo "NIT: No linked issue. Link one with a closing keyword in the PR body (for example: Closes #123)."
else
  echo "OK: Linked issue(s): $issues"
fi

# CI status
failing=$(gh pr view "$pr" --json statusCheckRollup --jq '[.statusCheckRollup[] | select(.conclusion == "FAILURE" or .conclusion == "CANCELLED" or .conclusion == "TIMED_OUT" or .state == "FAILURE" or .state == "ERROR") | (.name // .context)] | join(", ")')
pending=$(gh pr view "$pr" --json statusCheckRollup --jq '[.statusCheckRollup[] | select(.status == "IN_PROGRESS" or .status == "QUEUED" or .state == "PENDING") | (.name // .context)] | join(", ")')
if [ -n "$failing" ]; then
  echo "BLOCKING: CI checks failing: $failing"
else
  echo "OK: No failing CI checks."
fi
if [ -n "$pending" ]; then
  echo "INFO: CI checks still running: $pending"
fi

# UI changes without screenshots
files=$(gh pr view "$pr" --json files --jq '.files[].path')
ui_files=$(echo "$files" | grep -E "$ui_pattern" || true)
if [ -n "$ui_files" ]; then
  body=$(gh pr view "$pr" --json body --jq '.body')
  has_image=$(echo "$body" | grep -Ei '!\[|<img|user-attachments|\.(png|jpe?g|gif|webp)' || true)
  if [ -z "$has_image" ]; then
    echo "BLOCKING: UI files changed with no screenshots in the PR body. Add before and after screenshots. Files:"
    echo "$ui_files" | sed 's/^/  - /'
  else
    echo "OK: UI files changed and the PR body includes images."
  fi
fi

# Size, as a signal for the scope check
stats=$(gh pr view "$pr" --json additions,deletions,changedFiles --jq '"\(.additions) \(.deletions) \(.changedFiles)"')
read -r additions deletions changed <<< "$stats"
echo "INFO: Size: +$additions -$deletions across $changed files."
if [ $((additions + deletions)) -gt 800 ]; then
  echo "INFO: Over 800 changed lines. Evaluate whether it must be split."
fi
