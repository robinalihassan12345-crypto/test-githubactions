# GitHub Actions — Complete Beginner's Guide

This document accompanies the `ci.yml` workflow in the `.github/workflows/` directory.
Read it top to bottom to understand every part of a GitHub Actions workflow.

---

## Table of Contents

1. [What is GitHub Actions?](#1-what-is-github-actions)
2. [Core Concepts](#2-core-concepts)
3. [Anatomy of a Workflow File](#3-anatomy-of-a-workflow-file)
4. [Workflow Reference Table](#4-workflow-reference-table)
5. [Common Triggers (on)](#5-common-triggers-on)
6. [Using Marketplace Actions](#6-using-marketplace-actions)
7. [Secrets & Environment Variables](#7-secrets--environment-variables)
8. [Matrix Builds](#8-matrix-builds)
9. [Artifacts](#9-artifacts)
10. [Example Walkthrough](#10-example-walkthrough)
11. [Tips & Best Practices](#11-tips--best-practices)

---

## 1. What is GitHub Actions?

**GitHub Actions** is a CI/CD (Continuous Integration / Continuous Deployment) platform
built right into GitHub. It lets you:

- **Automatically** run tests, linters, and builds when you push code.
- **Deploy** applications to servers, cloud platforms, or package registries.
- **Schedule** recurring tasks (nightly builds, weekly reports, etc.).
- **Trigger** any custom workflow from GitHub events (issues, releases, comments, etc.).

Actions are **free** for public repositories and include a generous quota for private repos.

---

## 2. Core Concepts

| Concept       | What it is                                                                   |
|---------------|------------------------------------------------------------------------------|
| **Workflow**  | A YAML file (`.yml` / `.yaml`) in `.github/workflows/` that defines an automated process. |
| **Job**       | A unit of work that runs on a single **runner**. A workflow can have 1+ jobs. |
| **Step**      | An individual task inside a job (run a command or use an action).            |
| **Runner**    | A virtual machine (or self-hosted machine) that executes the job.            |
| **Action**    | A reusable, pre-packaged piece of code (like `actions/checkout`).            |
| **Event**     | A GitHub activity that triggers a workflow (push, PR, issue, etc.).          |
| **Matrix**    | A strategy that runs the same job with different configurations.            |

**Flow:** Event → Workflow → Jobs → Steps → (Commands / Actions)

---

## 3. Anatomy of a Workflow File

Every workflow file has three top-level sections:

```yaml
name: <workflow-name>     # appears in the GitHub Actions tab
on: <trigger>              # when should it run?
jobs:                      # what should it do?
  <job-id>:
    runs-on: <os>
    steps:
      - ...
```

### Minimal example

```yaml
name: Hello World
on: [push]
jobs:
  say-hello:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Hello, GitHub Actions!"
```

---

## 4. Workflow Reference Table

| Field                            | Purpose                                            | Example                                    |
|----------------------------------|----------------------------------------------------|--------------------------------------------|
| `name`                           | Display name for the workflow                      | `name: CI`                                 |
| `on`                             | Event(s) that trigger the workflow                 | `on: [push, pull_request]`                 |
| `on.<event>.branches`            | Filter by branch                                   | `on.push.branches: [main]`                 |
| `on.schedule`                    | Cron-based schedule                                | `on.schedule: [{cron: '0 0 * * *'}]`       |
| `on.workflow_dispatch`           | Manual trigger in the UI                           | `on.workflow_dispatch:`                     |
| `jobs`                           | Container for all jobs                             | `jobs:`                                     |
| `<job-id>`                       | Unique identifier for a job                        | `test:`                                     |
| `runs-on`                        | OS runner image                                    | `runs-on: ubuntu-latest`                   |
| `needs`                          | Job dependency (waits for another job)             | `needs: test`                              |
| `if`                             | Conditional run (uses `${{ }}` expressions)        | `if: github.ref == 'refs/heads/main'`      |
| `strategy.matrix`                | Multi-dimensional configuration                    | `strategy.matrix.python-version: [3.9, 3.10]` |
| `continue-on-error`              | Don't fail the workflow if this step fails         | `continue-on-error: true`                  |
| `timeout-minutes`                | Maximum job runtime                                | `timeout-minutes: 10`                      |
| `env`                            | Environment variables at workflow/job/step level   | `env: { NODE_ENV: test }`                  |
| `steps`                          | Ordered list of steps                              | `steps:`                                    |
| `steps[*].name`                 | Human-readable step name                           | `name: Install deps`                       |
| `steps[*].uses`                  | Reference an action                                | `uses: actions/checkout@v4`               |
| `steps[*].run`                   | Run a shell command                                | `run: pytest`                              |
| `steps[*].with`                  | Input parameters for an action                     | `with: { python-version: '3.10' }`         |
| `steps[*].env`                   | Step-specific env variables                        | `env: { TOKEN: ${{ secrets.MY_TOKEN }} }`  |
| `steps[*].working-directory`     | Working directory for the `run` command            | `working-directory: ./backend`             |

---

## 5. Common Triggers (on)

```yaml
# Push to any branch
on: push

# Push only to main
on:
  push:
    branches: [main]

# Pull request targeting main
on:
  pull_request:
    branches: [main]

# Both push & PR
on: [push, pull_request]

# Cron job — every day at midnight UTC
on:
  schedule:
    - cron: "0 0 * * *"

# Manual trigger (with optional input fields)
on:
  workflow_dispatch:
    inputs:
      environment:
        description: "Target environment"
        required: true
        default: staging

# On release published
on:
  release:
    types: [published]

# On issue comment
on:
  issue_comment:
    types: [created]
```

You can **combine** multiple triggers:

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:
```

---

## 6. Using Marketplace Actions

The **GitHub Marketplace** ([github.com/marketplace?type=actions](https://github.com/marketplace?type=actions))
has thousands of pre-built actions. You reference them with:

```
{owner}/{repo}@{version}
```

### Essential official actions

| Action                                     | Purpose                           |
|--------------------------------------------|-----------------------------------|
| `actions/checkout@v4`                      | Check out repo code               |
| `actions/setup-python@v5`                 | Install Python                    |
| `actions/setup-node@v4`                    | Install Node.js                   |
| `actions/setup-java@v4`                    | Install Java / JDK                |
| `actions/cache@v4`                         | Cache dependencies                |
| `actions/upload-artifact@v4`               | Save build outputs                |
| `actions/download-artifact@v4`             | Download previously saved artifacts |
| `github/codeql-action/analyze@v3`          | Security analysis                 |
| `docker/login-action@v3`                   | Log in to a container registry    |

**Always pin to a major version** (e.g., `@v4`) or a specific commit SHA
for security and reproducibility.

---

## 7. Secrets & Environment Variables

### Setting secrets

1. Go to your repo on GitHub: **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Enter name (e.g., `DEPLOY_KEY`) and value.

### Using secrets in a workflow

```yaml
steps:
  - name: Deploy
    run: ./deploy.sh
    env:
      SSH_KEY: ${{ secrets.DEPLOY_KEY }}
```

**Important:**

- Secrets are **masked** in logs (appear as `***`).
- Never hard-code passwords or tokens in the workflow file.
- Use `${{ secrets.MY_SECRET }}` syntax.
- Secrets are **not** available to workflows triggered by a fork's PR
  (for security).

### Environment variables

```yaml
# Workflow-level (available to all jobs)
env:
  NODE_VERSION: "18"

jobs:
  build:
    # Job-level
    env:
      BUILD_DIR: dist
    steps:
      # Step-level
      - run: echo $BUILD_DIR
        env:
          BUILD_DIR: custom-dist
```

---

## 8. Matrix Builds

A **matrix strategy** runs the same job multiple times with different parameters.

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.10", "3.11", "3.12"]
        os: [ubuntu-latest, windows-latest]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - run: pytest
```

This generates **6 jobs** (3 Python versions × 2 OSes). Each job gets its own
`matrix.python-version` and `matrix.os` values.

You can also use **include** / **exclude** to fine-tune combinations:

```yaml
strategy:
  matrix:
    node: [16, 18, 20]
    os: [ubuntu-latest, windows-latest]
    exclude:
      - os: windows-latest
        node: 16
```

---

## 9. Artifacts

Artifacts let you **persist files** from one job to another, or download them
after the workflow finishes.

```yaml
jobs:
  build:
    steps:
      - run: mkdir dist && echo "app" > dist/app.bin
      - uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: dist/

  deploy:
    needs: build
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: build-output
      - run: ls dist/
```

Artifacts are commonly used to pass compiled binaries, test reports,
coverage data, or Docker images between jobs.

---

## 10. Example Walkthrough

Let's walk through our `ci.yml` step by step.

### Declaration & name

```yaml
name: CI
```

This is just a label — it appears in the **Actions** tab of your repo.

### Triggers

```yaml
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
  workflow_dispatch:
```

- **push to main/master** → workflow runs.
- **pull request opened/updated** targeting main/master → workflow runs.
- **Manual trigger** → you can run it anytime from the GitHub UI.

### Jobs & strategy

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.10", "3.11", "3.12"]
```

One job called `test`. The matrix expands it into **3 jobs**, one per Python
version.

### Steps

| # | Step                       | What it does                                                         |
|---|----------------------------|----------------------------------------------------------------------|
| 1 | `actions/checkout@v4`      | Pulls repo code onto the runner so scripts/actions can access it.    |
| 2 | `actions/setup-python@v5`  | Installs the specified Python version and caches pip downloads.      |
| 3 | `pip install -r requirements.txt` | Installs pytest (and any other deps).                        |
| 4 | `ruff check .`             | Lints Python files for style / errors.                               |
| 5 | `pytest -v --tb=short`     | Runs all tests in verbose mode with short tracebacks.                |
| 6 | `python hello.py`          | Executes the hello script to confirm it runs without error.          |

If any step fails (exit code ≠ 0), the job stops and is marked as **failed**.

---

## 11. Tips & Best Practices

1. **Pin action versions** — Use `@v4` or a full commit SHA, not `@main`.
   This prevents unexpected breaking changes.

2. **Keep workflows fast** — Use `actions/cache` to reuse dependencies
   across runs:
   ```yaml
   - uses: actions/cache@v4
     with:
       path: ~/.cache/pip
       key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
   ```
   Many setup actions (like `setup-python`) now have built-in caching.

3. **Fail fast, but know your options** — By default the whole workflow
   fails when a job fails. Use `continue-on-error: true` for non-critical
   steps (e.g., a linter that's advisory).

4. **Use `if` for conditional logic**:
   ```yaml
   - if: github.ref == 'refs/heads/main'
     run: echo "Only on main branch"
   ```

5. **Name your steps** — Without `name`, GitHub shows the raw command.
   Clear names help debugging.

6. **Use `needs` for job ordering** — Jobs run in parallel by default.
   Use `needs` if one job depends on another (e.g., deploy after test).

7. **Use `workflow_dispatch`** — Always add it during development for
   quick testing without a push.

8. **Keep secrets out of logs** — Never `echo ${{ secrets.X }}` or pass
   secrets to `run:` commands directly. Use `env:` instead.

9. **Limit permissions** — In the repo settings, set the default
   `GITHUB_TOKEN` permissions to read-only, then grant write access per-job
   if needed.

10. **Test on multiple OS / language versions** — A matrix strategy catches
    platform-specific bugs early.

11. **Use the official actions** when possible — They're maintained by
    GitHub, well-documented, and follow security best practices.

12. **Monitor usage** — Check your Actions quota under
    **Settings → Billing and plans** (free tier: 2000 min/month for private repos,
    unlimited for public).

---

## Appendix A: Cheat Sheet

```yaml
# Minimal
name: CI
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Done"

# With matrix
name: Matrix
on: [push, pull_request]
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
        node: [16, 18]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      - run: npm test

# Scheduled + manual
name: Nightly
on:
  schedule:
    - cron: "0 2 * * *"
  workflow_dispatch:
jobs:
  nightly:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make nightly-check

# Conditional deploy
name: Deploy
on:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "tests pass"
  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - run: echo "deploying..."
```

---

## Appendix B: Reusable Workflows

You can **call** one workflow from another to avoid duplication:

```yaml
# .github/workflows/ci.yml
jobs:
  call-workflow:
    uses: ./.github/workflows/reusable-test.yml
    with:
      python-version: "3.11"
```

See: [Reusing workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)

---

## Appendix C: Local Testing

To test workflows **before pushing**, use:

- **[act](https://github.com/nektos/act)** — Run GitHub Actions locally with Docker.
  ```bash
  act -l                    # list all workflows
  act -j test               # run the "test" job
  act --pull=false          # don't pull images
  ```

---

Happy automating! 🚀
