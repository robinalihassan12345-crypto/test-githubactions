#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Simulated deployment script
# =============================================================================
# Usage:  ./deploy.sh <environment>
#         ./deploy.sh staging
#         ./deploy.sh production
#
# This script is called by the GitHub Actions deploy job.
# In a real project it would rsync, run migrations, restart services, etc.
# =============================================================================

set -euo pipefail

ENVIRONMENT="${1:-staging}"
APP_NAME="helloworld"
TIMESTAMP="$(date -u +%Y%m%d-%H%M%S)"

echo ""
echo "=========================================="
echo "  Deploying $APP_NAME to $ENVIRONMENT"
echo "  Timestamp: $TIMESTAMP"
echo "=========================================="
echo ""

case "$ENVIRONMENT" in
  staging)
    echo "→ Staging deploy steps:"
    echo "  1. Pulling Docker image: ghcr.io/$GITHUB_REPOSITORY:latest"
    echo "  2. Stopping old container (if any)"
    echo "  3. Starting new container on port 8080"
    echo "  4. Running smoke test: curl http://localhost:8080"
    echo "  5. Health check passed ✅"
    ;;
  production)
    echo "→ Production deploy steps:"
    echo "  1. Pulling Docker image: ghcr.io/$GITHUB_REPOSITORY:$GITHUB_SHA"
    echo "  2. Draining old connections"
    echo "  3. Rolling out to production cluster"
    echo "  4. Verifying deployment across 3 nodes"
    echo "  5. Health check passed ✅"
    echo "  6. Sending notification to #deploys channel"
    ;;
  *)
    echo "Unknown environment: $ENVIRONMENT"
    echo "Usage: $0 {staging|production}"
    exit 1
    ;;
esac

echo ""
echo "✅ Deploy to $ENVIRONMENT completed successfully."
echo ""
