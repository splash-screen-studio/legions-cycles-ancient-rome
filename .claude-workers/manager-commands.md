# Manager Commands Reference

This document contains all commands needed by the **Manager** role to monitor workers, handle reviews, and merge PRs.

## Quick Reference

```bash
# Spawn workers
./spawn-worker.sh 22              # Foreground (see output)
./spawn-worker.sh 22 --background # Background (check logs later)

# Monitor workers
./check-status.sh                 # All workers
./check-status.sh 22              # Specific worker
tail -f logs/22.log               # Live log

# PR management
gh pr list --state open
gh pr checks <pr-number>
gh pr view <pr-number> --comments
gh pr merge <pr-number> --squash --delete-branch

# CI status
gh run list --branch main --limit 5
gh run view <run-id>
```

---

## Workflow: Manager Session

### 1. Check Worker Status

```bash
cd .claude-workers
./check-status.sh
```

### 2. Review Open PRs

```bash
# List all open PRs
gh pr list --state open

# View specific PR details
gh pr view <pr-number>

# Check CI status
gh pr checks <pr-number>

# View Claude's review comments
gh pr view <pr-number> --comments
```

### 3. Handle Review Results

#### If Review PASSED

```bash
# Merge the PR
gh pr merge <pr-number> --squash --delete-branch

# Verify main branch CI is green
gh run list --branch main --limit 1

# Update status file
cat > status/<issue-number>.json << EOF
{
  "issue": <issue-number>,
  "status": "merged",
  ...
}
EOF

# Clean up worktree
git worktree remove worktrees/issue-<issue-number>
```

#### If Review FAILED

```bash
# Check what Claude requested
gh pr view <pr-number> --comments | grep -A 20 "@claude"

# Spawn worker to continue on same branch
./spawn-worker.sh <issue-number>  # Will use existing worktree/branch

# Or manually fix in worktree
cd worktrees/issue-<issue-number>
# Make fixes...
git add . && git commit -m "Address review feedback"
git push
```

#### If Review Has Minor Issues

```bash
# Create new issues for minor problems
gh issue create --title "Minor: [description]" --body "From PR #<pr-number> review:
[Claude's feedback]" --label "priority: low"

# Merge the PR anyway
gh pr merge <pr-number> --squash --delete-branch
```

---

## Triggering Claude Review

The Claude GitHub App automatically reviews PRs when:
1. PR is opened/updated
2. Someone comments `@claude` on the PR

To manually trigger a review:
```bash
gh pr comment <pr-number> --body "@claude please review this PR"
```

To request specific review:
```bash
gh pr comment <pr-number> --body "@claude /review"
```

---

## Parallel Worker Management

### Spawn Multiple Workers

```bash
# Spawn workers for Tier 1 issues in parallel
for issue in 22 15 41 35; do
    ./spawn-worker.sh $issue --background
done
```

### Monitor All Workers

```bash
# Watch status updates
watch -n 5 ./check-status.sh

# Or check manually
./check-status.sh
```

### View All Logs

```bash
# Last 5 lines from each log
for log in logs/*.log; do
    echo "=== $log ==="
    tail -5 "$log"
done
```

---

## Git Worktree Commands

```bash
# List all worktrees
git worktree list

# Create worktree for new branch
git worktree add worktrees/issue-42 -b issue-42-feature origin/main

# Remove worktree after PR merged
git worktree remove worktrees/issue-42

# Prune stale worktree references
git worktree prune

# Fix worktree if main repo moved
git worktree repair
```

---

## Troubleshooting

### Worker Stuck

```bash
# Check if claude process is running
ps aux | grep claude

# Kill if needed
pkill -f "claude.*issue-22"

# Mark as failed
cat > status/22.json << EOF
{
  "status": "failed",
  "last_error": "Worker stuck, manually terminated"
}
EOF
```

### PR Checks Failing

```bash
# View check details
gh pr checks <pr-number>

# View run logs
gh run view <run-id> --log-failed

# Common fixes:
# - Lint errors: Run linter in worktree, commit fix
# - Test failures: Check test output, fix code
# - Type errors: Check TypeScript output
```

### Merge Conflicts

```bash
# In the worktree
cd worktrees/issue-22
git fetch origin main
git rebase origin/main
# Fix conflicts...
git add .
git rebase --continue
git push --force-with-lease
```

---

## Status File Management

### Update Status After PR

```bash
ISSUE=22
PR_NUM=$(gh pr list --head "issue-$ISSUE-*" --json number -q '.[0].number')
PR_URL=$(gh pr view $PR_NUM --json url -q '.url')

# Use jq to update
jq --arg pr "$PR_NUM" --arg url "$PR_URL" \
   '.status = "pr_opened" | .pr_number = ($pr|tonumber) | .pr_url = $url' \
   status/$ISSUE.json > tmp.json && mv tmp.json status/$ISSUE.json
```

### Mark as Merged

```bash
jq '.status = "merged"' status/22.json > tmp.json && mv tmp.json status/22.json
```

---

## CI/CD Monitoring

```bash
# Watch main branch CI
gh run list --branch main --limit 10

# View specific run
gh run view <run-id>

# Re-run failed checks
gh run rerun <run-id> --failed

# Cancel stuck run
gh run cancel <run-id>
```

---

## Sources

- [Claude Code GitHub Actions Docs](https://code.claude.com/docs/en/github-actions)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
