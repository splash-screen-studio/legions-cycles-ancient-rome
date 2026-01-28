#!/bin/bash
# Spawn a Claude Code worker for a specific GitHub issue
# Usage: ./spawn-worker.sh <issue-number> [--background]

set -e

ISSUE_NUM=$1
BACKGROUND=${2:-""}
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORKERS_DIR="$REPO_ROOT/.claude-workers"
WORKTREES_DIR="$REPO_ROOT/.claude-workers/worktrees"
STATUS_DIR="$WORKERS_DIR/status"
LOGS_DIR="$WORKERS_DIR/logs"

if [ -z "$ISSUE_NUM" ]; then
    echo "Usage: $0 <issue-number> [--background]"
    echo "Example: $0 22"
    echo "         $0 22 --background"
    exit 1
fi

# Fetch issue details
echo "Fetching issue #$ISSUE_NUM..."
ISSUE_TITLE=$(gh issue view "$ISSUE_NUM" --json title -q '.title' 2>/dev/null)
if [ -z "$ISSUE_TITLE" ]; then
    echo "Error: Could not fetch issue #$ISSUE_NUM"
    exit 1
fi

# Create branch name from issue
BRANCH_NAME="issue-${ISSUE_NUM}-$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | cut -c1-40)"
WORKTREE_PATH="$WORKTREES_DIR/issue-$ISSUE_NUM"

echo "Issue: #$ISSUE_NUM - $ISSUE_TITLE"
echo "Branch: $BRANCH_NAME"
echo "Worktree: $WORKTREE_PATH"

# Check if worktree already exists
if [ -d "$WORKTREE_PATH" ]; then
    echo "Warning: Worktree already exists at $WORKTREE_PATH"
    echo "Use 'git worktree remove $WORKTREE_PATH' to remove it first"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    # Create worktree with new branch
    echo "Creating git worktree..."
    cd "$REPO_ROOT"
    git fetch origin main
    git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" origin/main
fi

# Create status file
STATUS_FILE="$STATUS_DIR/${ISSUE_NUM}.json"
cat > "$STATUS_FILE" << EOF
{
  "issue": $ISSUE_NUM,
  "title": "$ISSUE_TITLE",
  "branch": "$BRANCH_NAME",
  "worktree": "$WORKTREE_PATH",
  "status": "in_progress",
  "started_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "pr_number": null,
  "pr_url": null,
  "review_status": null,
  "attempts": 1,
  "last_error": null
}
EOF

echo "Status file created: $STATUS_FILE"

# Prepare worker prompt
WORKER_PROMPT="# YOU ARE A WORKER

**READ CLAUDE_WORKER.md AND CLAUDE.md FIRST** - They define your role and the BRicey architecture.

You are a one-shot Worker implementing GitHub issue #$ISSUE_NUM.
You are NOT interactive. Complete your task and EXIT.

## CRITICAL: BRicey Module Architecture

This project uses the BRicey module pattern:
- Entry points (init.server.luau, init.client.luau) require and initialize modules
- Feature modules use .luau extension (NOT .server.luau or .client.luau)
- ModuleScripts return their table and do NOT auto-execute code

When creating a new feature:
1. Create src/server/MyFeature.luau or src/client/MyFeature.luau (note: .luau extension)
2. Update init.server.luau or init.client.luau to require and initialize it
3. ModuleScripts must return their table and NOT have auto-executing code at the bottom

## Workflow

1. Read CLAUDE.md and CLAUDE_WORKER.md
2. Read the issue: gh issue view $ISSUE_NUM
3. Create ModuleScript(s) with .luau extension
4. Update entry point (init.server.luau or init.client.luau) to require/initialize
5. Test with rojo serve
6. Commit and push
7. Open PR
8. EXIT

## Commit
git add <files>
git commit -m 'Implement #$ISSUE_NUM: $ISSUE_TITLE

Co-Authored-By: Claude <noreply@anthropic.com>'

## Open PR
git push -u origin $BRANCH_NAME

gh pr create --title 'Implement #$ISSUE_NUM: $ISSUE_TITLE' --body 'Closes #$ISSUE_NUM

## Summary
[What you implemented]

## Changes
- [Files created/modified]

## BRicey Pattern Checklist
- [ ] ModuleScripts use .luau extension
- [ ] Entry point updated to require/initialize module
- [ ] No auto-executing code in ModuleScripts
- [ ] ModuleScripts return their table'

## EXIT
Your work is complete. Do not continue. Exit now."

LOG_FILE="$LOGS_DIR/${ISSUE_NUM}.log"

echo "Starting worker..."
echo "Log file: $LOG_FILE"

if [ "$BACKGROUND" = "--background" ]; then
    # Run in background
    (
        cd "$WORKTREE_PATH"
        echo "=== Worker started at $(date) ===" >> "$LOG_FILE"
        echo "Issue: #$ISSUE_NUM - $ISSUE_TITLE" >> "$LOG_FILE"
        echo "Branch: $BRANCH_NAME" >> "$LOG_FILE"
        echo "========================================" >> "$LOG_FILE"

        claude --print --dangerously-skip-permissions "$WORKER_PROMPT" >> "$LOG_FILE" 2>&1

        # Update status based on result
        if gh pr list --head "$BRANCH_NAME" --json number -q '.[0].number' | grep -q .; then
            PR_NUM=$(gh pr list --head "$BRANCH_NAME" --json number -q '.[0].number')
            PR_URL=$(gh pr view "$PR_NUM" --json url -q '.url')
            # Update status file
            cat > "$STATUS_FILE" << EOFSTATUS
{
  "issue": $ISSUE_NUM,
  "title": "$ISSUE_TITLE",
  "branch": "$BRANCH_NAME",
  "worktree": "$WORKTREE_PATH",
  "status": "pr_opened",
  "started_at": "$(jq -r '.started_at' "$STATUS_FILE")",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "pr_number": $PR_NUM,
  "pr_url": "$PR_URL",
  "review_status": "pending",
  "attempts": 1,
  "last_error": null
}
EOFSTATUS
        fi

        echo "=== Worker completed at $(date) ===" >> "$LOG_FILE"
    ) &

    echo "Worker spawned in background (PID: $!)"
    echo "Monitor with: tail -f $LOG_FILE"
else
    # Run in foreground
    cd "$WORKTREE_PATH"
    echo "=== Worker started at $(date) ===" | tee -a "$LOG_FILE"
    echo "Issue: #$ISSUE_NUM - $ISSUE_TITLE" | tee -a "$LOG_FILE"
    echo "Branch: $BRANCH_NAME" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"

    claude --print --dangerously-skip-permissions "$WORKER_PROMPT" 2>&1 | tee -a "$LOG_FILE"

    echo "=== Worker completed at $(date) ===" | tee -a "$LOG_FILE"
fi
