#!/bin/bash
set -e

# 1. Create a temporary directory for the filtered history
FILTERED_REPO_DIR=$(mktemp -d)

# 2. Clone the source repo and filter it
echo "Cloning $SOURCE_REPO..."
git clone --no-local --single-branch "https://github.com/$SOURCE_REPO.git" "$FILTERED_REPO_DIR"
git -C "$FILTERED_REPO_DIR" filter-repo --path "$SUBFOLDER_PATH" --path-rename "$SUBFOLDER_PATH:"

# 3. Sync the subfolder (no need to clone dest repo, we are in it)
# Add the filtered repo as a remote
git remote add filtered "$FILTERED_REPO_DIR"
git fetch filtered

# Use git subtree to merge the histories
echo "Syncing subfolder with commit history..."
git subtree add --prefix "$SUBFOLDER_PATH" filtered/master

echo "Subfolder sync complete. Changes are ready to be committed."