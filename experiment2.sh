#!/bin/bash -l

set -e # if a command fails, exit the script

# --- User Provided Variables ---
SOURCE_FILES="$1"
DESTINATION_USERNAME="$2"
DESTINATION_REPOSITORY="$3"
DESTINATION_BRANCH="$4"
DESTINATION_DIRECTORY="$5" 
COMMIT_USERNAME="$6"
COMMIT_EMAIL="$7"
COMMIT_MESSAGE="$8"
API_TOKEN_GITHUB="$API_TOKEN_GITHUB"


if [ -z "$COMMIT_USERNAME" ]; then
  COMMIT_USERNAME="$DESTINATION_USERNAME"
fi

git config --global user.email "$COMMIT_EMAIL"
git config --global user.name "$COMMIT_USERNAME"

# --- Initial Setup ---
# Remove git directory if it exists to prevent errors
rm -rf .git

SourceRepo="SourceRepo"
TargetRepo="TargetRepo"
SourceRepo_SubFolder="$SOURCE_FILES"
TargetRepo_SubFolder="$DESTINATION_DIRECTORY"

echo "Cloning source and target repositories..."
git clone "https://$API_TOKEN_GITHUB@github.com/$GITHUB_REPOSITORY.git" $SourceRepo
git clone --single-branch --branch "$DESTINATION_BRANCH" "https://$API_TOKEN_GITHUB@github.com/$DESTINATION_USERNAME/$DESTINATION_REPOSITORY.git" $TargetRepo
echo "Cloned source and target repositories."

# --- Checking for Difference in Commits ---
echo "Checking for differences..."
cd $SourceRepo

# Get the commit history (hashes and subjects) for the specific source subfolder.
# The output is formatted as "commit_hash|commit_subject".
SourceCommits=$(git log --pretty=format:'%H|%s' -- $SourceRepo_SubFolder)

cd ../$TargetRepo

# Get the commit history (subjects only) from the target repository.
# We will use this to check which source commits are already present.
TargetCommitMessages=$(git log --pretty=format:'%s')

# Find commits that are in the source but not in the target.
# It filters out commits whose messages already appear in the target repository.
UnsyncedCommits=""
while IFS= read -r commit_info; do
  CommitMessage=$(echo "$commit_info" | cut -d'|' -f2)
  if ! echo "$TargetCommitMessages" | grep -q -F "$CommitMessage"; then
    UnsyncedCommits="$commit_info"$'\n'"$UnsyncedCommits"
  fi
done <<< "$SourceCommits"

cd ..

# --- Syncing Commits ---
if [ -z "$UnsyncedCommits" ]; then
  echo "Repositories are already in sync. Nothing to do."
  exit 0
fi

echo "Found unsynced commits. Starting sync process..."

# Loop through each unsynced commit, oldest to newest.
while IFS= read -r commit_info; do
  if [ -z "$commit_info" ]; then
    continue
  fi

  CommitHash=$(echo "$commit_info" | cut -d'|' -f1)
  CommitMessage=$(echo "$commit_info" | cut -d'|' -f2)

  echo "Syncing commit: $CommitMessage"

  # Checkout the specific commit from the source repository.
  cd $SourceRepo
  git checkout -q "$CommitHash"

  # Copy the files from the source subfolder to the target subfolder.
  # The -a flag preserves file attributes, and --delete removes files in the destination that are not in the source.
  cd ..
  rsync -a --delete "$SourceRepo/$SourceRepo_SubFolder/" "$TargetRepo/$TargetRepo_SubFolder/"

  # Commit the changes to the target repository.
  cd $TargetRepo
  git add .
  git commit -m "$CommitMessage"

  cd ..
done <<< "$UnsyncedCommits"

# --- Pushing Changes ---
echo "Pushing changes to destination repository..."
cd $TargetRepo
git push origin "$DESTINATION_BRANCH"
echo "Sync complete."