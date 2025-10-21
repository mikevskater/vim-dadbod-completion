#!/bin/bash

# vim-dadbod-completion Test Runner
# Clones dependencies and runs tests using vim-themis

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS_DIR="$SCRIPT_DIR/.test_dependencies"

echo "==> Setting up test dependencies..."

# Create dependencies directory
mkdir -p "$DEPS_DIR"

# Clone vim-themis if not present
if [ ! -d "$DEPS_DIR/vim-themis" ]; then
  echo "  -> Cloning vim-themis..."
  git clone https://github.com/thinca/vim-themis.git "$DEPS_DIR/vim-themis"
else
  echo "  -> vim-themis already present"
fi

# Clone vim-dadbod if not present
if [ ! -d "$DEPS_DIR/vim-dadbod" ]; then
  echo "  -> Cloning vim-dadbod..."
  git clone https://github.com/tpope/vim-dadbod.git "$DEPS_DIR/vim-dadbod"
else
  echo "  -> vim-dadbod already present"
fi

# Clone vim-dadbod-ui if not present (for IntelliSense features)
if [ ! -d "$DEPS_DIR/vim-dadbod-ui" ]; then
  echo "  -> Cloning vim-dadbod-ui..."
  git clone https://github.com/kristijanhusak/vim-dadbod-ui.git "$DEPS_DIR/vim-dadbod-ui"
else
  echo "  -> vim-dadbod-ui already present"
fi

echo ""
echo "==> Running tests..."

# Set up runtime path for Vim to find dependencies
export THEMIS_VIM="nvim"
export THEMIS_ARGS="-e -s --headless"

# Add dependencies to runtime path
RTP="$DEPS_DIR/vim-dadbod,$DEPS_DIR/vim-dadbod-ui,$SCRIPT_DIR"

# Run themis
"$DEPS_DIR/vim-themis/bin/themis" \
  --runtimepath "$RTP" \
  --reporter spec \
  "$SCRIPT_DIR/test"

echo ""
echo "==> Tests completed!"
