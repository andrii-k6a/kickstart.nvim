#!/bin/sh

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.config/nvim"

if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  BACKUP="${TARGET}.bak.$(date +%Y%m%d%H%M%S)"
  echo "Backing up existing $TARGET to $BACKUP"
  mv "$TARGET" "$BACKUP"
fi

ln -s "$REPO_DIR" "$TARGET"
echo "Linked $REPO_DIR -> $TARGET"
echo "Run: nvim"
