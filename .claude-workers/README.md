# Claude Code Multi-Agent Workflow

This directory contains the framework for running multiple Claude Code workers in parallel using git worktrees.

## Roles

| Role | Description | Mode |
|------|-------------|------|
| **Planner** | Sets up framework, creates issues, defines priorities | Interactive session (you) |
| **Manager** | Monitors workers, merges PRs, handles failures | Interactive session |
| **Worker** | Implements single issue, runs tests, opens PR | One-shot `claude --print` |
| **Judge** | Reviews PRs via GitHub App | `@claude` in PR comments |

## Directory Structure

```
.claude-workers/
├── README.md              # This file
├── status/                # Worker status files (JSON)
│   └── {issue-number}.json
├── logs/                  # Worker output logs
│   └── {issue-number}.log
├── worktrees/            # Git worktree references
│   └── .gitkeep
├── spawn-worker.sh       # Spawn a new worker
├── check-status.sh       # Check all worker statuses
└── manager-commands.md   # Commands for the manager role
```

## Status File Format

Each worker has a status file at `status/{issue-number}.json`:

```json
{
  "issue": 22,
  "title": "Rojo Project Configuration",
  "branch": "issue-22-rojo-config",
  "worktree": "../worktrees/issue-22",
  "status": "in_progress",
  "started_at": "2026-01-28T10:00:00Z",
  "updated_at": "2026-01-28T10:05:00Z",
  "pr_number": null,
  "pr_url": null,
  "review_status": null,
  "attempts": 1,
  "last_error": null
}
```

### Status Values

- `pending` - Worker not yet started
- `in_progress` - Worker running
- `pr_opened` - PR created, awaiting review
- `review_passed` - Claude review approved
- `review_failed` - Claude review requested changes
- `merged` - PR merged to main
- `failed` - Worker failed, needs intervention

## Quick Start

### 1. Spawn a Worker

```bash
./spawn-worker.sh 22  # Spawn worker for issue #22
```

### 2. Monitor Workers

```bash
./check-status.sh     # Show all worker statuses
./check-status.sh 22  # Check specific worker
```

### 3. View Worker Log

```bash
tail -f logs/22.log
```

## Git Worktree Commands

```bash
# List all worktrees
git worktree list

# Create worktree for issue branch
git worktree add ../worktrees/issue-22 -b issue-22-rojo-config

# Remove worktree after PR merged
git worktree remove ../worktrees/issue-22

# Prune stale worktree metadata
git worktree prune
```

## Manager Workflow

See `manager-commands.md` for the full manager workflow.

### Quick Reference

```bash
# Check PR status
gh pr list --state open

# View PR checks
gh pr checks <pr-number>

# View Claude's review
gh pr view <pr-number> --comments

# Merge PR
gh pr merge <pr-number> --squash --delete-branch

# Check main branch CI
gh run list --branch main --limit 5
```

## Worker One-Shot Command

Workers are spawned with:

```bash
cd ../worktrees/issue-{N}
claude --print "Implement GitHub issue #{N}.
Read the issue: gh issue view {N}
Follow CLAUDE.md guidelines.
Run tests before committing.
Create a PR when done.
Exit when PR is opened." 2>&1 | tee ../../.claude-workers/logs/{N}.log
```

## Sources

- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Claude Code GitHub Actions](https://code.claude.com/docs/en/github-actions)
- [Git Worktrees for AI Agents](https://nx.dev/blog/git-worktrees-ai-agents)
- [Parallel AI Coding with Worktrees](https://docs.agentinterviews.com/blog/parallel-ai-coding-with-gitworktrees/)
- [incident.io: Shipping Faster with Claude Code](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees)
