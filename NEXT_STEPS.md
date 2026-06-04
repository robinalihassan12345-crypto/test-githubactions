# Full CI/CD Pipeline — From Zero to Deployed

This guide walks you through the entire CI/CD pipeline:

```
You push code  ──►  GitHub Actions  ──►  Docker Hub  ──►  Your Server
```

---

## Table of Contents

1. [Create Accounts & Credentials](#1-create-accounts--credentials)
2. [Create GitHub Repo & Push Code](#2-create-github-repo--push-code)
3. [Add Secrets to GitHub](#3-add-secrets-to-github)
4. [Prepare Your Server](#4-prepare-your-server)
5. [Push Code & Watch It Deploy](#5-push-code--watch-it-deploy)
6. [How the Pipeline Works (Detailed)](#6-how-the-pipeline-works-detailed)
7. [Verify It Worked](#7-verify-it-worked)
8. [Make a Change & See It Flow Again](#8-make-a-change--see-it-flow-again)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Create Accounts & Credentials

### GitHub account
- Go to https://github.com/signup
- Create a free account (skip paid plans)
- Verify your email

### Docker Hub account
- Go to https://hub.docker.com/signup
- Create a free account
- Create an **access token** (more secure than password):
  1. Log in to Docker Hub
  2. Click your avatar → **Account Settings** → **Security**
  3. Click **New Access Token**
  4. Name it `github-actions`, select **Read & Write** permissions
  5. **Copy the token now** — it only shows once

### Your server
You need a Linux server with Docker installed. Options:

| Option | How to get it | Cost |
|--------|--------------|------|
| **VPS** | DigitalOcean, Linode, Vultr, Hetzner | ~$5-6/month |
| **Cloud VM** | AWS EC2, GCP Compute, Azure VM | Free tier available |
| **Old laptop** | Install Ubuntu, connect to your home network | Free |
| **Raspberry Pi** | Install Raspberry Pi OS + Docker | ~$50 one-time |

**Minimum requirements:**
- Public IP address (or domain pointing to it)
- SSH access (root or sudo user)
- Docker installed
- Port 8080 open in firewall

---

## 2. Create GitHub Repo & Push Code

### If you already have a GitHub repo:
```bash
# In the helloworld/ directory:
git remote add origin https://github.com/YOUR_USER/helloworld.git
git branch -M main
git push -u origin main
```

### If starting from scratch:
```bash
# 1. Go to https://github.com/new
# 2. Name: helloworld
# 3. Do NOT add README/LICENSE (you already have files)
# 4. Click "Create repository"

# 5. Push your local code:
cd /root/helloworld
git remote add origin https://github.com/YOUR_USER/helloworld.git
git branch -M main
git push -u origin main
```

---

## 3. Add Secrets to GitHub

The workflow needs 5 secrets to deploy. Add them one by one:

1. Go to your repo on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add each one below

### Secret 1: DOCKER_USERNAME
| Field | Value |
|-------|-------|
| Name | `DOCKER_USERNAME` |
| Secret | your Docker Hub username (e.g. `john123`) |

### Secret 2: DOCKER_PASSWORD
| Field | Value |
|-------|-------|
| Name | `DOCKER_PASSWORD` |
| Secret | your Docker Hub access token (not your password) |

### Secret 3: SERVER_HOST
| Field | Value |
|-------|-------|
| Name | `SERVER_HOST` |
| Secret | your server's IP or domain (e.g. `203.0.113.42` or `myserver.com`) |

### Secret 4: SERVER_USER
| Field | Value |
|-------|-------|
| Name | `SERVER_USER` |
| Secret | SSH username (usually `root` or `ubuntu`) |

### Secret 5: SERVER_SSH_KEY
| Field | Value |
|-------|-------|
| Name | `SERVER_SSH_KEY` |
| Secret | your **private SSH key** (the whole file content) |

To get your private SSH key:
```bash
cat ~/.ssh/id_rsa       # or id_ed25519
```
Copy the entire output (including `-----BEGIN...` and `-----END...` lines).

> If you don't have an SSH key yet, create one:
> ```bash
> ssh-keygen -t ed25519 -C "your@email.com"   # press Enter for defaults
> # Then copy the PUBLIC key to your server:
> ssh-copy-id root@<SERVER_IP>
> # Now get your PRIVATE key:
> cat ~/.ssh/id_ed25519    # copy this into the SERVER_SSH_KEY secret
> ```

**Your secrets page should look like this when done:**
```
DOCKER_USERNAME   │  john123
DOCKER_PASSWORD   │  dckr_pat_abc123...
SERVER_HOST       │  203.0.113.42
SERVER_USER       │  root
SERVER_SSH_KEY    │  -----BEGIN OPENSSH PRIVATE KEY-----
```

---

## 4. Prepare Your Server

SSH into your server and run these commands:

```bash
# 1. Install Docker (if not already installed)
curl -fsSL https://get.docker.com | sh

# 2. Add your user to the docker group (so you don't need sudo)
sudo usermod -aG docker $USER
#   Log out and back in for this to take effect:
#   exit && ssh root@<SERVER_IP>

# 3. Open port 8080 in firewall (if using ufw)
sudo ufw allow 8080/tcp
sudo ufw reload

# 4. Copy your SSH public key (run this on your local machine, not the server):
#    ssh-copy-id root@<SERVER_IP>

# 5. Test that Docker works
docker run --rm hello-world
```

---

## 5. Push Code & Watch It Deploy

### Trigger the pipeline

```bash
# Make any change, then commit and push:
git add .
git commit -m "Trigger CI/CD pipeline"
git push origin main
```

### Watch it live

1. Go to your repo on GitHub
2. Click the **Actions** tab
3. You'll see the `CI` workflow running
4. Click the running workflow to see live logs
5. Watch each step:
   - ✅ `test` job runs first (lint + pytest + hello)
   - ✅ `deploy` job starts after tests pass
   - ✅ Docker image builds and pushes to Docker Hub
   - ✅ GitHub Actions SSHs into your server
   - ✅ Server pulls the new image and restarts the container

---

## 6. How the Pipeline Works (Detailed)

Here's exactly what happens, step by step:

### When you run `git push origin main`

```
Your computer
  │  git push
  ▼
GitHub receives the push
  │  triggers workflow
  ▼
GitHub Actions runner (ubuntu-latest VM)
  │
  ├── JOB: test
  │   ├── Checkout code
  │   ├── Setup Python (3.10, 3.11, 3.12 in parallel)
  │   ├── pip install -r requirements.txt
  │   ├── ruff check .           ← lint your code
  │   ├── pytest -v              ← run your tests
  │   └── python hello.py        ← verify app runs
  │
  └── JOB: deploy (only if test passed AND branch is main)
      ├── Checkout code
      ├── docker login           ← logs in with DOCKER_USERNAME + DOCKER_PASSWORD
      ├── docker build -t helloworld .
      ├── docker run --rm helloworld  ← smoke test
      ├── docker push to Docker Hub   ← tagged :latest and :<commit-sha>
      │
      └── SSH into your server
          ├── docker pull <user>/helloworld:latest
          ├── docker stop helloworld
          ├── docker rm helloworld
          ├── docker run -d --name helloworld -p 8080:8080 <user>/helloworld:latest
          └── docker image prune -f    ← clean up old images
```

### Docker Hub after the push

Your Docker Hub repo will show:
- `john123/helloworld:latest` (always the most recent build)
- `john123/helloworld:a1b2c3d4` (one per commit, for rollbacks)

### On your server after deployment

```bash
# The container is running:
docker ps
# CONTAINER ID   IMAGE                       PORTS
# abc123def456   john123/helloworld:latest   0.0.0.0:8080->8080/tcp

# To see logs:
docker logs helloworld

# To stop:
docker stop helloworld && docker rm helloworld
```

---

## 7. Verify It Worked

### Check your server

```bash
# SSH into your server and run:
curl http://localhost:8080
# If your app is a web server, you'll see its response.

# Or check the container logs:
docker logs helloworld
# "Hello, World!" should appear (our app prints once and exits, so it
# will restart in a loop — for a real app you'd run a web server)
```

### Check Docker Hub

1. Go to https://hub.docker.com/repositories
2. Click `helloworld`
3. You'll see `latest` and `a1b2c3d4` tags

### Check GitHub Actions

1. Repo → **Actions** tab
2. Click any workflow run
3. All steps should be green ✅

---

## 8. Make a Change & See It Flow Again

```bash
# Edit the greeting
echo 'def greet(name="World"):
    return f"Hey, {name}!"

def main():
    print(greet("from CI/CD!"))

if __name__ == "__main__":
    main()' > hello.py

# Commit and push
git add .
git commit -m "Change greeting message"
git push origin main
```

Then watch the Actions tab — it will:
1. Run tests on the new code
2. If tests pass → build new Docker image
3. Push to Docker Hub (updates `:latest`)
4. SSH into server → pull new image → restart container

---

## 9. Troubleshooting

### Workflow fails — "secrets not found"

Make sure you added all 5 secrets exactly as named:
`DOCKER_USERNAME`, `DOCKER_PASSWORD`, `SERVER_HOST`, `SERVER_USER`, `SERVER_SSH_KEY`

Secrets are case-sensitive and must match the names in `ci.yml`.

### "docker: command not found" on server

Your server needs Docker installed. SSH in and run:
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

### "Permission denied (publickey)" — SSH failure

Make sure:
1. You added the public key to the server: `ssh-copy-id root@<SERVER_IP>`
2. You pasted the **private** key (not the public one) into the `SERVER_SSH_KEY` secret
3. The private key starts with `-----BEGIN` and has no extra whitespace

### "port 8080 already in use" on server

Another service is using port 8080. Either:
- Stop the other service: `sudo systemctl stop <service>`
- Or change the port in `ci.yml` (edit `-p 8080:8080` to `-p 8081:8080`)

### Tests pass but deploy job is skipped

Check the `if:` condition in `ci.yml`:
```yaml
if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

The deploy job only runs on **push to main**, not on pull requests.
Push directly to main (not a feature branch).

### Docker push fails — "access denied"

Your Docker Hub access token needs **Read & Write** permissions.
Go to Docker Hub → Account Settings → Security → regenerate the token
with the correct scope.

---

## Files in This Project

| File | Purpose |
|------|---------|
| `hello.py` | The app we're deploying |
| `test_hello.py` | Unit tests (run by CI) |
| `requirements.txt` | Python dependencies |
| `Dockerfile` | Tells Docker how to package the app |
| `.dockerignore` | Files to exclude from the Docker image |
| `deploy.sh` | Script showing what a real deploy looks like |
| `.github/workflows/ci.yml` | **The CI/CD pipeline** — heart of the automation |

---

## Summary

```
git push origin main
       │
       ▼
  ┌──────────────────────────────────────────────────────┐
  │  GitHub Actions                                       │
  │                                                        │
  │  1. Checkout code                                      │
  │  2. Run tests (lint + pytest)                          │
  │  3. Build Docker image                                 │
  │  4. Push to Docker Hub                                 │
  │  5. SSH into server                                    │
  │  6. Pull new image & restart container                 │
  └──────────────────────────────────────────────────────┘
       │
       ▼
  Your server is now running the latest code 🚀
```

Every time you `git push origin main`, this whole pipeline runs automatically.
That's **Continuous Deployment**.
