#!/bin/bash
set -e

# 1. Create a temporary directory for the source repo
SOURCE_REPO_DIR=$(mktemp -d)

# 2. Clone the source repo
echo "Cloning $SOURCE_REPO on branch $SOURCE_BRANCH..."
git clone --no-local --branch "$SOURCE_BRANCH" --single-branch "https://github.com/$SOURCE_REPO.git" "$SOURCE_REPO_DIR"

# 3. In the source repo, create a branch with only the subfolder history
echo "Creating branch with subfolder history..."
git -C "$SOURCE_REPO_DIR" subtree split --prefix "$SUBFOLDER_PATH" -b filtered-branch

# We are running inside the destination repo checkout.
# 4. Add the local source repo clone as a remote
git remote add source_clone "$SOURCE_REPO_DIR"
git fetch source_clone

# 5. Use git subtree to add the subfolder from the filtered branch
echo "Syncing subfolder with commit history..."
git subtree add --prefix "$SUBFOLDER_PATH" source_clone/filtered-branch

# 6. Clean up the remote
git remote remove source_clone

echo "Subfolder sync complete. Changes are ready to be committed."