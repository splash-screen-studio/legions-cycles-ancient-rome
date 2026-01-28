#!/bin/bash
# Check status of Claude Code workers
# Usage: ./check-status.sh [issue-number]

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
STATUS_DIR="$REPO_ROOT/.claude-workers/status"
LOGS_DIR="$REPO_ROOT/.claude-workers/logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

status_icon() {
    case $1 in
        "pending") echo -e "${YELLOW}○${NC}" ;;
        "in_progress") echo -e "${BLUE}◐${NC}" ;;
        "pr_opened") echo -e "${YELLOW}◑${NC}" ;;
        "review_passed") echo -e "${GREEN}●${NC}" ;;
        "review_failed") echo -e "${RED}◐${NC}" ;;
        "merged") echo -e "${GREEN}✓${NC}" ;;
        "failed") echo -e "${RED}✗${NC}" ;;
        *) echo "?" ;;
    esac
}

if [ -n "$1" ]; then
    # Show specific worker
    STATUS_FILE="$STATUS_DIR/$1.json"
    if [ ! -f "$STATUS_FILE" ]; then
        echo "No status file for issue #$1"
        exit 1
    fi

    echo "=== Worker Status: Issue #$1 ==="
    echo ""
    cat "$STATUS_FILE" | jq '.'
    echo ""

    LOG_FILE="$LOGS_DIR/$1.log"
    if [ -f "$LOG_FILE" ]; then
        echo "=== Last 20 lines of log ==="
        tail -20 "$LOG_FILE"
    fi

    # Check for PR
    BRANCH=$(jq -r '.branch' "$STATUS_FILE")
    PR_NUM=$(gh pr list --head "$BRANCH" --json number -q '.[0].number' 2>/dev/null)
    if [ -n "$PR_NUM" ]; then
        echo ""
        echo "=== PR #$PR_NUM Status ==="
        gh pr view "$PR_NUM" --json state,reviews,checksState,mergeable -q '{state: .state, reviews: .reviews | length, checks: .checksState, mergeable: .mergeable}'

        echo ""
        echo "=== PR Checks ==="
        gh pr checks "$PR_NUM" 2>/dev/null || echo "No checks yet"
    fi
else
    # Show all workers
    echo "=== Claude Code Worker Status ==="
    echo ""
    printf "%-6s %-12s %-50s %s\n" "Issue" "Status" "Title" "PR"
    printf "%-6s %-12s %-50s %s\n" "-----" "------" "-----" "--"

    for STATUS_FILE in "$STATUS_DIR"/*.json; do
        if [ -f "$STATUS_FILE" ]; then
            ISSUE=$(jq -r '.issue' "$STATUS_FILE")
            STATUS=$(jq -r '.status' "$STATUS_FILE")
            TITLE=$(jq -r '.title' "$STATUS_FILE" | cut -c1-48)
            PR_NUM=$(jq -r '.pr_number // "—"' "$STATUS_FILE")

            ICON=$(status_icon "$STATUS")
            printf "%s %-4s %-12s %-50s %s\n" "$ICON" "#$ISSUE" "$STATUS" "$TITLE" "$PR_NUM"
        fi
    done

    echo ""
    echo "Legend: ${YELLOW}○${NC}=pending ${BLUE}◐${NC}=working ${YELLOW}◑${NC}=pr_opened ${GREEN}●${NC}=passed ${RED}◐${NC}=failed ${GREEN}✓${NC}=merged ${RED}✗${NC}=error"
    echo ""

    # Summary counts
    TOTAL=$(ls -1 "$STATUS_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    IN_PROGRESS=$(grep -l '"status": "in_progress"' "$STATUS_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    PR_OPENED=$(grep -l '"status": "pr_opened"' "$STATUS_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    MERGED=$(grep -l '"status": "merged"' "$STATUS_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')

    echo "Summary: $TOTAL total | $IN_PROGRESS working | $PR_OPENED awaiting review | $MERGED merged"
fi
