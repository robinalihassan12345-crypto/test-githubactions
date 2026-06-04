# What To Do Next — From Local To CI

You have a working project and a GitHub Actions workflow.
Now what? Here's your step-by-step roadmap.

---

## 1. Push to GitHub

Create a repo and push your code:

```bash
# In the helloworld/ directory:
git init
git add .
git commit -m "Initial commit: hello world + GitHub Actions CI"

# Create a repo on github.com (DO NOT add README/LICENSE — you already have files)
git remote add origin https://github.com/YOUR_USER/helloworld.git
git branch -M main
git push -u origin main
```

---

## 2. See Your First Workflow Run

1. Go to `https://github.com/YOUR_USER/helloworld`
2. Click the **Actions** tab (top nav bar).
3. You'll see the `CI` workflow running (or already finished).
4. Click the workflow run to see the live logs.

---

## 3. Experiment

Now that it works, break it and learn:

### ☐ Make a test fail

Edit `test_hello.py` and change an assertion:

```python
def test_greet_default():
    assert greet() == "Hello, Everyone!"   # wrong!
```

Commit and push — watch the workflow turn **red**. Then fix it.

### ☐ Trigger a manual run

Go to **Actions → CI → Run workflow** dropdown → click **Run workflow**.
This uses the `workflow_dispatch` trigger.

### ☐ Add a new trigger

Make the workflow also run when you tag a release (`on: push: tags: ['v*']`).
Push a tag and watch it trigger:

```bash
git tag v1.0.0
git push origin v1.0.0
```

### ☐ Add a second job

Uncomment the `deploy` job in `ci.yml` and add `needs: test` to watch job
dependencies in action.

### ☐ Use secrets

Add a fake secret in your repo settings and reference it in the workflow:

```yaml
- run: echo "My secret is $MY_SECRET"
  env:
    MY_SECRET: ${{ secrets.MY_FAKE_SECRET }}
```

### ☐ Add caching

The current workflow uses `setup-python`'s built-in pip cache. Try adding
a manual `actions/cache@v4` step to see how caching works explicitly.

### ☐ Try act locally

Install [act](https://github.com/nektos/act) (needs Docker) and run your
workflow on your own machine:

```bash
act -j test                     # run the test job
act -l                          # list all jobs/workflows
act --pull=false                # skip pulling the runner image
```

---

## 4. CI/CD Learning Roadmap

### CI you already have

| # | Step | What it does |
|---|------|-------------|
| 1 | `pip install -r requirements.txt` | Installs dependencies |
| 2 | `ruff check .` | Lints code for style/errors |
| 3 | `pytest -v --tb=short` | Runs unit tests |
| 4 | `python hello.py` | Verifies the app runs |

### CD added in this project

| # | Step | What it does |
|---|------|-------------|
| 1 | `docker build -t helloworld` | Builds a container image |
| 2 | `docker run --rm helloworld` | Smoke test: runs container to verify |
| 3 | `docker push ghcr.io/...` | Pushes image to GitHub Container Registry |
| 4 | `./deploy.sh staging` | Simulates deploying to staging environment |

### Experiments for you

#### ☐ See the deploy job in action

Push to `main` and watch the `deploy` job run after `test` completes. Then
push to a **feature branch** — the deploy job should be **skipped** (only runs
on main).

#### ☐ Add a production environment

Create a GitHub Environment called "production" in your repo settings
(**Settings → Environments**), then update the deploy job to require manual
approval before deploying to production:

```yaml
deploy-prod:
  needs: deploy
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  runs-on: ubuntu-latest
  environment: production
  steps:
    - run: ./deploy.sh production
      env:
        GITHUB_REPOSITORY: ${{ github.repository }}
        GITHUB_SHA: ${{ github.sha }}
```

#### ☐ Deploy to a real cloud

Try deploying to a free tier:

| Platform | Free tier includes | How |
|----------|-------------------|-----|
| **Render** | Static sites, web services | Use `render.yaml` or GitHub integration |
| **Fly.io** | 3 VMs, 3GB persistent storage | `fly deploy` in workflow |
| **Railway** | $5/month credit, no credit card | Connect GitHub repo directly |
| **AWS EC2** | 750 hrs/month free (12 months) | SSH + docker-compose in workflow |

#### ☐ Add a status badge

After you've pushed to GitHub, add a CI badge to your README:

```markdown
[![CI](https://github.com/YOUR_USER/helloworld/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USER/helloworld/actions/workflows/ci.yml)
```

The badge shows green ✅ or red ❌ for the latest run.

---

## 6. Next Learning Steps

Once you're comfortable with this workflow:

| Topic                          | What to learn                                                         |
|--------------------------------|-----------------------------------------------------------------------|
| **Multi-job pipelines**        | Add `build`, `lint`, `test`, and `deploy` jobs with `needs` deps.     |
| **Artifacts**                  | Upload test reports / coverage with `actions/upload-artifact`.        |
| **Reusable workflows**         | Extract common steps into a reusable workflow to avoid duplication.   |
| **Environments & deployments** | Deploy to staging/production using GitHub Environments with approvals.|
| **Container actions**          | Write your own custom Docker-based action.                            |
| **OIDC / cloud auth**          | Authenticate to AWS/GCP/Azure without static secrets.                 |
| **Scheduled workflows**        | Run nightly builds or weekly dependency bumps with `cron`.            |
| **Status badges**              | Add a badge to your repo's README.                  |

---

## 7. Add a Status Badge

```markdown
[![CI](https://github.com/YOUR_USER/helloworld/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USER/helloworld/actions/workflows/ci.yml)
```

Paste this into your `README.md` and push — you'll see a live "passing/failing"
badge at the top of your repo.

---

## 8. Common Problems

| Symptom                         | Likely fix                                             |
|---------------------------------|--------------------------------------------------------|
| "No workflow runs" on Actions   | Make sure the file is in `.github/workflows/ci.yml` (exact path). |
| Workflow not triggering         | Check branch filters — `on.push.branches: [main]` won't fire on `feature-x`. |
| Step fails but shouldn't        | Remove `set -e` or add `|| true` or `continue-on-error: true`.    |
| Secret not available            | Forks don't get secrets. Push from a branch in the same repo.     |
| "Permission denied"             | Your token may need write access — check Settings → Actions → General. |

---

**You now have CI running on every push. Add more languages, more jobs,
and more triggers as you learn. Happy shipping!** 🚀
