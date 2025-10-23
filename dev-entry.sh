
#!/usr/bin/env bash
set -e

echo "[CF EnvyBox] Booting developer environment..."

# Optional read-only GitHub auth
if [ -n "$GH_TOKEN" ]; then
  echo "$GH_TOKEN" | gh auth login --with-token >/dev/null 2>&1 || true
fi

# Cloudflare staging auth
if [ -n "$CF_API_TOKEN" ]; then
  mkdir -p ~/.wrangler/config
  echo "{\"api_token\":\"$CF_API_TOKEN\"}" > ~/.wrangler/config/default
  chmod 600 ~/.wrangler/config/default
fi

# Clean ephemeral env vars
unset GH_TOKEN CF_API_TOKEN

# Prepare workspace
mkdir -p ~/projects ~/.cache/pnpm ~/.config ~/.ssh
chmod 700 ~
echo "[CF EnvyBox] Ready. Persistent storage active at /home/cfuser (2 GB cap)."
echo "[Hint] Use:  cd ~/projects && git clone <repo>  or  gp (pull + install)"
exec zsh