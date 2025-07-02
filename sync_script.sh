#!/bin/bash

set -e

SOURCE_REPO_PATH=$1
DEST_REPO_PATH=$2
SUBFOLDER=$3

echo "Syncing subfolder '$SUBFOLDER' from '$SOURCE_REPO_PATH' to '$DEST_REPO_PATH'"

# Go into the source repository
cd "$SOURCE_REPO_PATH"

# Get the last synced commit hash from the destination repository
LAST_SYNCED_COMMIT_HASH_FILE="$DEST_REPO_PATH/.last_synced_commit"
if [ -f "$LAST_SYNCED_COMMIT_HASH_FILE" ]; then
    LAST_SYNCED_COMMIT_HASH=$(cat "$LAST_SYNCED_COMMIT_HASH_FILE")
    echo "Last synced commit: $LAST_SYNCED_COMMIT_HASH"
else
    echo "No last synced commit found. Syncing all commits."
    LAST_SYNCED_COMMIT_HASH=""
fi

# Get the list of commits to sync
if [ -z "$LAST_SYNCED_COMMIT_HASH" ]; then
    COMMITS_TO_SYNC=$(git rev-list --reverse HEAD -- "$SUBFOLDER")
else
    COMMITS_TO_SYNC=$(git rev-list --reverse "$LAST_SYNCED_COMMIT_HASH"..HEAD -- "$SUBFOLDER")
fi

if [ -z "$COMMITS_TO_SYNC" ]; then
    echo "No new commits to sync."
    exit 0
fi

echo "Commits to sync:"
echo "$COMMITS_TO_SYNC"

# Create a temporary directory for patches
PATCHES_DIR=$(mktemp -d)
echo "Created temporary directory for patches: $PATCHES_DIR"

# Generate patches for each commit
for commit in $COMMITS_TO_SYNC; do
    git format-patch -1 $commit --stdout -- "$SUBFOLDER" > "$PATCHES_DIR/$commit.patch"
done

# Go into the destination repository
cd "$DEST_REPO_PATH"

# Apply the patches
for patch in $(ls "$PATCHES_DIR"/*.patch | sort); do
    if git am --directory="$SUBFOLDER" < "$patch"; then
        echo "Successfully applied patch $patch"
    else
        echo "Failed to apply patch $patch. Aborting."
        git am --abort
        exit 1
    fi
done

# Save the last synced commit hash
echo "$commit" > "$LAST_SYNCED_COMMIT_HASH_FILE"

# Clean up the patches directory
rm -rf "$PATCHES_DIR"

echo "Sync complete."
