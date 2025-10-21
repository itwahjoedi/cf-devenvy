#!/usr/bin/env bash
set -e

# Inject Cloudflare token if provided
if [ -n "$CF_API_TOKEN" ]; then
  mkdir -p ~/.config/wrangler
  echo "{\"api_token\":\"$CF_API_TOKEN\"}" > ~/.config/wrangler/config.json
  echo "✅ Cloudflare token configured."
fi

# Inject GitHub token if provided
if [ -n "$GITHUB_TOKEN" ]; then
  mkdir -p ~/.config/gh
  echo "oauth_token: $GITHUB_TOKEN" > ~/.config/gh/hosts.yml
  echo "✅ GitHub token configured."
fi

exec "$@"