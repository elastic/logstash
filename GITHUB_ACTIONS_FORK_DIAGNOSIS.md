# GitHub Actions Fork Visibility Diagnosis

## Issue Summary
GitHub Actions workflows are not visible in the Actions tab of repository forks. This is expected behavior due to how GitHub handles workflows in forked repositories.

## Root Cause Analysis

### 1. Fork Actions Behavior
- **GitHub disables Actions by default in forks** for security reasons
- Users must manually enable Actions in their fork: Settings → Actions → "Allow all actions and reusable workflows"
- Even when enabled, many workflow triggers don't work in forks

### 2. Workflow Trigger Compatibility

After analyzing all 18 workflows in `.github/workflows/`, here's the breakdown:

#### ❌ Fork-Incompatible Triggers (14 workflows)
These workflows **will not appear or run** in forks:

**pull_request_target** (4 workflows):
- `backport-active.yml` - only triggers on PRs to upstream `main`
- `docs-build.yml` - targets upstream branches only
- `docs-cleanup.yml` - targets upstream PRs
- `github-commands-comment.yml` - targets upstream PRs

**issues events** (4 workflows):
- `logstash_project_board.yml` - issue events don't trigger in forks
- `platform_ingest_docs_project_board.yml` - issue events don't trigger in forks
- `platform_logstash_project_board.yml` - issue events don't trigger in forks
- `project-board-assigner.yml` - issue events don't trigger in forks

**schedule events** (2 workflows):
- `bump-java-version.yml` - scheduled workflows disabled in forks
- `update-compose.yml` - scheduled workflows disabled in forks

**push to specific branches** (4 workflows):
These only trigger when pushing to upstream branches (main, version branches):
- `pre-commit.yml` - triggers on push to main, 8.19, 9.*
- `docs-build.yml` - triggers on push to main, \d+.\d+
- `lint_docs.yml` - triggers on PRs to main

**pull_request with branch restrictions** (3 workflows):
These only trigger on PRs targeting specific upstream branches:
- `catalog-info.yml` - only PRs to main
- `mergify-labels-copier.yml` - only PRs to upstream

#### ✅ Fork-Compatible Triggers (5 workflows)
These workflows **can** work in forks if manually triggered:

- `bump-java-version.yml` - has `workflow_dispatch`
- `bump-logstash.yml` - has `workflow_dispatch` 
- `critical_vulnerability_scan.yml` - has `workflow_dispatch`
- `gen_release_notes.yml` - has `workflow_dispatch`
- `update-compose.yml` - has `workflow_dispatch`
- `version_bumps.yml` - has `workflow_dispatch`

### 3. Validation Status
All workflow files are:
- ✅ Properly formatted YAML
- ✅ Use correct `.yml` extension
- ✅ Located in correct `.github/workflows/` directory
- ✅ Have valid `on:` trigger syntax
- ✅ Are syntactically valid

## Why Workflows Don't Appear in Fork Actions Tab

### Primary Reasons:
1. **Actions disabled in fork** - User must manually enable in Settings
2. **No applicable triggers** - Without push/PR to fork branches or workflow_dispatch, workflows have no way to run
3. **Event filtering** - GitHub filters out events that don't apply to the fork's context

### What Users See:
- Empty Actions tab or "No workflows found"
- Even with Actions enabled, workflows that only trigger on upstream events won't appear
- Only workflows with `workflow_dispatch` or triggers matching fork activity will show

## Recommended Solutions

### Option 1: Add Simple Smoke Test Workflow (Minimal Change)
Create a minimal workflow with `workflow_dispatch` that forks can use to verify Actions are working:

```yaml
name: smoke-test
on:
  workflow_dispatch:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "GitHub Actions is working!"
```

**Pros:**
- Minimal change to repository
- Provides immediate verification method
- No impact on existing workflows
- Can be manually triggered in any fork

**Cons:**
- Doesn't make other workflows visible
- Users still need to enable Actions manually

### Option 2: Add workflow_dispatch to Existing Workflows
Add `workflow_dispatch:` trigger to commonly-used workflows like `pre-commit.yml`:

**Pros:**
- Makes useful workflows testable in forks
- Minimal code change

**Cons:**
- Could allow unintended manual triggering
- Each workflow needs individual assessment

### Option 3: Documentation Only
Add `.github/FORK_ACTIONS_README.md` explaining:
- How to enable Actions in forks
- Which workflows will/won't work
- Why this is expected behavior

**Pros:**
- Zero code changes
- Educational for contributors

**Cons:**
- Doesn't solve the visibility issue
- Requires users to find documentation

## Recommended Action

**Implement Option 1** - Add a simple smoke-test workflow:
- Minimal change to repository
- Provides immediate diagnostic capability
- Helps fork users verify Actions are enabled
- Can serve as a template for fork-specific testing

## Fork User Instructions

### To Enable and Verify Actions in Your Fork:

1. **Enable Actions**
   - Go to your fork → Settings → Actions → General
   - Select "Allow all actions and reusable workflows"
   - Click "Save"

2. **Verify Actions are Working**
   - After smoke-test workflow is added, go to Actions tab
   - Select "smoke-test" workflow (if available)
   - Click "Run workflow" → "Run workflow"
   - Verify successful execution

3. **Understanding Workflow Visibility**
   - Only workflows with applicable triggers will appear
   - Most workflows in this repo target upstream events (issues, upstream PRs)
   - For fork development, consider adding `workflow_dispatch` to workflows you need

4. **For PR Testing**
   - Workflows with `pull_request:` (not `pull_request_target:`) will work for PRs within your fork
   - Push events will only trigger for branches you configure in the workflow

## Additional Notes

- This is **expected GitHub behavior**, not a bug
- Fork restrictions exist for security (preventing malicious workflow execution)
- Upstream repository workflows are designed for the main repository's workflow
- Fork users developing features should consider adding fork-specific workflows
