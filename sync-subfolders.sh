#!/bin/bash
set -e

# Configure git
git config --global user.name "$USERNAME"
git config --global user.email "$USERNAME@users.noreply.github.com"

# 1. Create a temporary directory for the filtered history
FILTERED_REPO_DIR=$(mktemp -d)

# 2. Clone the source repo and filter it
echo "Cloning $SOURCE_REPO..."
git clone --no-local --single-branch "https://github.com/$SOURCE_REPO.git" "$FILTERED_REPO_DIR"
git -C "$FILTERED_REPO_DIR" filter-repo --path "$SUBFOLDER_PATH" --path-rename "$SUBFOLDER_PATH:"

# 3. Clone the destination repo
DEST_REPO_DIR=$(mktemp -d)
echo "Cloning $DEST_REPO..."
git clone --no-local --single-branch "https://github.com/$DEST_REPO.git" "$DEST_REPO_DIR"

# 4. Create a new branch and sync the subfolder
cd "$DEST_REPO_DIR"
BRANCH_NAME="sync-$(basename "$SUBFOLDER_PATH")-$(date +%s)"
echo "Creating new branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

# Add the filtered repo as a remote
git remote add filtered "$FILTERED_REPO_DIR"
git fetch filtered

# Use git subtree to merge the histories
# This will replay the commits from the filtered repo into the subfolder
echo "Syncing subfolder with commit history..."
git subtree add --prefix "$SUBFOLDER_PATH" filtered/master

# 5. Push the new branch to the destination repo
echo "Pushing changes to $DEST_REPO..."
git push "https://$USERNAME:$GH_PAT@github.com/$DEST_REPO.git" "$BRANCH_NAME"

echo "Subfolder sync complete. A new branch '$BRANCH_NAME' has been pushed to $DEST_REPO with the synced subfolder and its history."
